import 'package:get/get.dart';

import '../../model/order_model.dart';
import '../../repository/order_repo.dart';
import '../../util/log_service.dart';

class OrdersController extends GetxController {
  final OrderRepo orderRepo;

  OrdersController({required this.orderRepo});

  final orders = <OrderModel>[].obs;
  final isLoading = true.obs;

  List<OrderModel> get activeOrders => orders.where((o) => o.isActive).toList();
  List<OrderModel> get pastOrders => orders.where((o) => !o.isActive).toList();

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    isLoading.value = true;
    try {
      final fetchedOrders = await orderRepo.fetchOrders();

      if (isClosed) return;

      orders.assignAll(fetchedOrders);
    } catch (e) {
      if (isClosed) return;
      LogService.error('fetch orders failed', e);
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }
}
