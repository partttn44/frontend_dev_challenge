import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rescu/feature/shared_widget/flash_countdown_badge.dart';

import '../../app_config.dart';
import '../shared_widget/the_network_image.dart';
import 'deal_details_controller.dart';

class DealDetailsScreen extends GetView<DealDetailsController> {
  const DealDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()),
        );
      }

      if (controller.errorMessage.isNotEmpty || !controller.hasDeal) {
        return Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                controller.errorMessage.value.isNotEmpty
                    ? controller.errorMessage.value
                    : 'ไม่พบข้อมูลดีล',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
            ),
          ),
        );
      }

      final deal = controller.deal;
      final hasFlashSale = deal.isFlashSale && deal.flashSaleEndsAt != null;
      final isExpired =
          hasFlashSale && DateTime.now().isAfter(deal.flashSaleEndsAt!);

      return Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    TheNetworkImage(url: deal.imageUrl, fit: BoxFit.cover),
                    if (hasFlashSale)
                      Positioned(
                        top: 50,
                        left: 16,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isExpired
                                    ? Colors.grey
                                    : Colors.red.shade600,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'FLASH SALE',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: isExpired
                                  ? const Text(
                                      'Expired',
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    )
                                  : FlashCountdownBadge(
                                      flashSaleEndsAt: deal.flashSaleEndsAt!,
                                      onExpired: () {
                                        controller.update();
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deal.name,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(deal.storeName,
                        style: TextStyle(
                            fontSize: 15, color: Colors.grey.shade700)),
                    Text(deal.storeAddress,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade500)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text('฿${deal.price.toStringAsFixed(0)}',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isExpired
                                    ? Colors.grey
                                    : AppConfig.primaryGreen)),
                        const SizedBox(width: 8),
                        Text('฿${deal.originalPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                                decoration: TextDecoration.lineThrough)),
                        const Spacer(),
                        Chip(
                          avatar:
                              const Icon(Icons.inventory_2_outlined, size: 16),
                          label: Text('${controller.quantityLeft ?? '-'} left'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E5E2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule,
                              color: AppConfig.primaryGreen),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pickup window',
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey)),
                              Text(
                                '${deal.pickupWindow.label}'
                                '${deal.pickupWindow.isToday ? ' · today' : ''}',
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (deal.pickupWindow.isOpenNow)
                            const Chip(
                              label: Text('Open now'),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('What you get',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(deal.description,
                        style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.grey.shade800)),
                    if (deal.tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: deal.tags
                            .map((t) => Chip(
                                  label: Text(t),
                                  visualDensity: VisualDensity.compact,
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomSheet: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          color: Colors.white,
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isExpired ? null : controller.addToCart,
              style: FilledButton.styleFrom(
                backgroundColor: isExpired ? Colors.grey : null,
              ),
              icon: const Icon(Icons.add_shopping_cart),
              label: Text(isExpired ? 'Deal Expired' : 'Add to bag'),
            ),
          ),
        ),
      );
    });
  }
}
