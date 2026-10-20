import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rescu/feature/shared_widget/flash_countdown_badge.dart';

import '../../app_config.dart';
import '../shared_widget/the_network_image.dart';
import 'cart_controller.dart';

class CartScreen extends GetView<CartController> {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = controller.cartService;

    return Scaffold(
      appBar: AppBar(title: const Text('My bag')),
      body: Obx(() {
        if (cart.items.isEmpty) {
          return const Center(
            child: Text(
              'Your bag is empty',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: cart.items.length,
          itemBuilder: (context, index) {
            final item = cart.items[index];
            final deal = item.deal;
            final remainingTime = item.remainingReservationTime;
            final isReservationExpired = item.isReservationExpired;

            final hasFlashSale =
                deal.isFlashSale && deal.flashSaleEndsAt != null;
            final isFlashSaleExpired =
                hasFlashSale && DateTime.now().isAfter(deal.flashSaleEndsAt!);

            final isItemExpired = isReservationExpired || isFlashSaleExpired;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: isItemExpired ? Colors.grey.shade100 : Colors.white,
              elevation: 0.5,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Stack(
                          children: [
                            TheNetworkImage(
                              url: deal.imageUrl,
                              width: 64,
                              height: 64,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            if (hasFlashSale)
                              Positioned(
                                top: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade600,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'FLASH',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                deal.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: isItemExpired
                                      ? Colors.grey.shade600
                                      : Colors.black,
                                ),
                              ),
                              Text(
                                deal.storeName,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '฿${deal.price.toStringAsFixed(0)} each',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isItemExpired
                                          ? Colors.grey
                                          : AppConfig.primaryGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  if (deal.originalPrice > deal.price)
                                    Text(
                                      '฿${deal.originalPrice.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Colors.grey.shade500,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  const Spacer(),
                                  if (hasFlashSale && !isFlashSaleExpired)
                                    FlashCountdownBadge(
                                      flashSaleEndsAt: deal.flashSaleEndsAt!,
                                      onExpired: () {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          cart.remove(deal.id);
                                        });
                                      },
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.remove_circle_outline,
                                      size: 20),
                                  onPressed: () => cart.decrement(deal.id),
                                ),
                                Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.add_circle_outline,
                                      size: 20),
                                  onPressed: isItemExpired
                                      ? null
                                      : () => cart.add(deal),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: () => cart.remove(deal.id),
                              icon: const Icon(Icons.delete_outline,
                                  size: 14, color: Colors.red),
                              label: const Text(
                                'Remove',
                                style:
                                    TextStyle(fontSize: 11, color: Colors.red),
                              ),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (remainingTime != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: isReservationExpired
                                ? Colors.red
                                : Colors.orange.shade800,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isReservationExpired
                                ? 'Reservation expired'
                                : 'Reservation holds for ${_formatDuration(remainingTime)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isReservationExpired
                                  ? Colors.red
                                  : Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      }),
      bottomNavigationBar: Obx(() {
        if (cart.items.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          color: Colors.white,
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Total', style: TextStyle(fontSize: 13)),
                  Text(
                    '฿${cart.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: FilledButton(
                  onPressed: controller.isCheckingOut.value
                      ? null
                      : controller.checkout,
                  child: controller.isCheckingOut.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Checkout'),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
