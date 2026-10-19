import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../model/deal_model.dart';
import '../../repository/deal_repo.dart';
import '../../util/log_service.dart';

class HomeController extends GetxController {
  final DealRepo dealRepo;

  HomeController({required this.dealRepo});

  final deals = <DealModel>[].obs;
  final flashDeals = <DealModel>[].obs;
  final isLoading = true.obs;
  final todayOnly = false.obs;
  final scrollOffset = 0.0.obs;

  final scrollController = ScrollController();
  final refreshController = RefreshController();

  int _page = 1;
  int _totalPages = 1;
  bool _isFetchingMore = false;

  final Set<int> _trackedImpressions = {};

  final List<Map<String, dynamic>> _pendingAnalyticsEvents = [];

  static const int _batchSize = 10;

  bool get hasMore => _page < _totalPages;

  List<DealModel> get visibleDeals => todayOnly.value
      ? deals.where((d) => d.pickupWindow.isToday).toList()
      : deals.toList();

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    _initialLoad();
  }

  void _onScroll() {
    scrollOffset.value = scrollController.offset;
  }

  Future<void> _initialLoad() async {
    isLoading.value = true;
    try {
      await Future.wait([refreshDeals(), _loadFlashDeals()]);
    } catch (e) {
      LogService.error('initial load failed', e);
    }
    isLoading.value = false;
  }

  Future<void> _loadFlashDeals() async {
    flashDeals.assignAll(await dealRepo.fetchFlashDeals());
  }

  Future<void> refreshDeals() async {
    await _flushAnalyticsBatch();

    _page = 1;
    final res = await dealRepo.fetchDeals(page: 1);
    _totalPages = res.totalPages;
    deals.assignAll(res.items);

    _trackedImpressions.clear();

    refreshController.refreshCompleted();
  }

  Future<void> loadMore() async {
    if (_isFetchingMore) return;
    if (!hasMore) {
      refreshController.loadNoData();
      return;
    }
    _isFetchingMore = true;
    _page++;
    try {
      final res = await dealRepo.fetchDeals(page: _page);
      _totalPages = res.totalPages;

      final existingIds = deals.map((d) => d.id).toSet();
      final uniqueNewItems =
          res.items.where((d) => !existingIds.contains(d.id)).toList();

      deals.addAll(uniqueNewItems);
      refreshController.loadComplete();
    } catch (e) {
      LogService.error('loadMore failed', e);
      _page--;
      refreshController.loadFailed();
    } finally {
      _isFetchingMore = false;
    }
  }

  void trackDealImpression(int dealId) {
    if (_trackedImpressions.contains(dealId)) return;

    _trackedImpressions.add(dealId);

    final event = {
      'type': 'impression',
      'dealId': dealId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _pendingAnalyticsEvents.add(event);

    if (_pendingAnalyticsEvents.length >= _batchSize) {
      _flushAnalyticsBatch();
    }
  }

  Future<void> _flushAnalyticsBatch() async {
    if (_pendingAnalyticsEvents.isEmpty) return;

    final eventsToSend =
        List<Map<String, dynamic>>.from(_pendingAnalyticsEvents);
    _pendingAnalyticsEvents.clear();

    try {
      await dealRepo.sendAnalyticsBatch(eventsToSend);
    } catch (e) {
      LogService.error('Failed to send analytics batch', e);
    }
  }

  void scrollToTop() {
    scrollController.animateTo(0,
        duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
  }

  @override
  void onClose() {
    _flushAnalyticsBatch();
    scrollController.dispose();
    refreshController.dispose();
    super.onClose();
  }
}
