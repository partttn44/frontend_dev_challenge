import 'package:get/get.dart';

import '../../model/deal_model.dart';
import '../../repository/deal_repo.dart';
import '../../util/log_service.dart';

class SearchDealsController extends GetxController {
  final DealRepo dealRepo;

  SearchDealsController({required this.dealRepo});

  final results = <DealModel>[].obs;
  final isLoading = false.obs;
  final hasSearched = false.obs;

  String _latestQuery = '';

  void onQueryChanged(String query) {
    _search(query);
  }

  Future<void> _search(String query) async {
    final trimmedQuery = query.trim();

    _latestQuery = trimmedQuery;

    if (trimmedQuery.isEmpty) {
      results.clear();
      hasSearched.value = false;
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    hasSearched.value = true;

    try {
      final found = await dealRepo.search(trimmedQuery);

      if (_latestQuery == trimmedQuery) {
        results.assignAll(found);
        isLoading.value = false;
      }
    } catch (e) {
      if (_latestQuery == trimmedQuery) {
        LogService.error('search failed', e);
        isLoading.value = false;
      }
    }
  }
}
