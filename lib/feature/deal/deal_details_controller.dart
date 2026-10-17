import 'package:get/get.dart';

import '../../model/deal_model.dart';
import '../../repository/deal_repo.dart';
import '../../service/analytics_service.dart';
import '../../service/cart_service.dart';
import '../../util/log_service.dart';

class DealDetailsController extends GetxController {
  final DealRepo dealRepo;
  final CartService cartService;
  final AnalyticsService analytics;

  DealDetailsController({
    required this.dealRepo,
    required this.cartService,
    required this.analytics,
  });

  final Rxn<DealModel> _deal = Rxn<DealModel>();
  DealModel get deal => _deal.value!;
  bool get hasDeal => _deal.value != null;

  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  final _quantityLeft = RxnInt();
  int? get quantityLeft => _quantityLeft.value;

  Worker? _cartWorker;

  @override
  void onInit() {
    super.onInit();
    _loadDealData();
  }

  Future<void> _loadDealData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final arg = Get.arguments;
      if (arg is DealModel) {
        _deal.value = arg;
        _initAfterDealLoaded();
        return;
      }

      int? dealId;
      final paramId = Get.parameters['id'];
      if (paramId != null) {
        dealId = int.tryParse(paramId);
      }

      if (dealId == null && Get.rawRoute != null) {
        final uri = Uri.parse(Get.rawRoute!.settings.name ?? '');
        final queryId = uri.queryParameters['id'];
        if (queryId != null) {
          dealId = int.tryParse(queryId);
        }
      }

      if (dealId != null) {
        final fetchedDeal = await dealRepo.fetchById(dealId);
        _deal.value = fetchedDeal;
        _initAfterDealLoaded();
      } else {
        errorMessage.value = 'Deal ID not found in the provided link';
      }
    } catch (e) {
      errorMessage.value = 'Failed to load deal data: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void _initAfterDealLoaded() {
    if (_deal.value == null) return;

    _quantityLeft.value = deal.quantityLeft;

    analytics.logEvent('deal_details_view', {
      'deal_id': deal.id,
      'source':
          Get.parameters['source'] ?? Get.parameters['source'] ?? 'unknown',
    });

    _cartWorker = ever(cartService.itemCount, (_) => _recheckAvailability());
  }

  @override
  void onClose() {
    _cartWorker?.dispose();
    super.onClose();
  }

  Future<void> _recheckAvailability() async {
    if (!hasDeal) return;
    LogService.log('re-checking availability for deal ${deal.id}');
    final fresh = await dealRepo.fetchById(deal.id);
    _quantityLeft.value = fresh.quantityLeft;
  }

  void addToCart() {
    if (!hasDeal) return;
    cartService.add(deal);
    Get.snackbar(
      'Added to bag',
      '${deal.name} — pick up ${deal.pickupWindow.label}',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
}
