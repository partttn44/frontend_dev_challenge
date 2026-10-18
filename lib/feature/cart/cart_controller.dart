import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../repository/order_repo.dart';
import '../../service/api_exception.dart';
import '../../service/cart_service.dart';
import '../../util/log_service.dart';

class CartController extends GetxController {
  final CartService cartService;
  final OrderRepo orderRepo;

  CartController({required this.cartService, required this.orderRepo});

  final isCheckingOut = false.obs;

  @override
  void onInit() {
    super.onInit();

    _cleanExpiredFlashSales();
  }

  void _cleanExpiredFlashSales() {
    Future.microtask(() {
      final now = DateTime.now();
      final expiredItems = cartService.items.where((item) {
        final deal = item.deal;
        final hasFlashSale = deal.isFlashSale && deal.flashSaleEndsAt != null;
        return hasFlashSale && now.isAfter(deal.flashSaleEndsAt!);
      }).toList();

      if (expiredItems.isNotEmpty) {
        for (final item in expiredItems) {
          cartService.remove(item.deal.id);
        }

        Get.snackbar(
          'Items Expired',
          'Some expired flash sale items were automatically removed.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          duration: const Duration(seconds: 3),
        );
      }
    });
  }

  Future<void> checkout() async {
    if (cartService.items.isEmpty || isCheckingOut.value) return;
    isCheckingOut.value = true;

    try {
      final reservationIds = cartService.items
          .map((item) => item.reservation?.id)
          .where((id) => id != null)
          .cast<String>()
          .toList();

      final order = await orderRepo.checkout(
        items: cartService.items.toList(),
        reservationIds: reservationIds,
      );

      cartService.clear();
      Get.snackbar(
        'Order confirmed',
        'Order #${order.id} — pick up soon!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on ApiException catch (e) {
      LogService.error('checkout failed', e);

      if (e.statusCode == 410 || e.message.toLowerCase().contains('expired')) {
        Get.snackbar(
          'Reservation Expired',
          'Some items in your bag have expired reservations. Please review your bag.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Checkout failed',
          e.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      LogService.error('unexpected checkout error', e);
      Get.snackbar(
        'Checkout failed',
        'An unexpected error occurred. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isCheckingOut.value = false;
    }
  }
}
