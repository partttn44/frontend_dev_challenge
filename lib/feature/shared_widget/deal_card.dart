import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app_config.dart';
import '../../model/deal_model.dart';
import '../../routes/routes.dart';
import 'the_network_image.dart';
import 'flash_countdown_badge.dart';

/// Deal card used in the home feed and search results.
class DealCard extends StatelessWidget {
  final DealModel deal;
  final String source;

  const DealCard({super.key, required this.deal, this.source = 'home'});

  @override
  Widget build(BuildContext context) {
    final hasFlashSale = deal.isFlashSale && deal.flashSaleEndsAt != null;
    final isExpired =
        hasFlashSale && DateTime.now().isAfter(deal.flashSaleEndsAt!);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      color: isExpired ? Colors.grey.shade100 : Colors.white,
      elevation: 0.5,
      child: InkWell(
        onTap: isExpired
            ? null
            : () => Get.toNamed(
                  Routes.dealRoute(deal.id, source: source),
                  arguments: deal,
                ),
        child: Opacity(
          opacity: isExpired ? 0.6 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  TheNetworkImage(
                      url: deal.imageUrl, height: 160, width: double.infinity),
                  if (hasFlashSale)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  isExpired ? Colors.grey : Colors.red.shade600,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'FLASH SALE',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: isExpired
                                ? const Text(
                                    'Expired',
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold),
                                  )
                                : FlashCountdownBadge(
                                    flashSaleEndsAt: deal.flashSaleEndsAt!,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${deal.quantityLeft} left',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deal.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(deal.storeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12.5, color: Colors.grey.shade600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.schedule,
                            size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text('Pick up ${deal.pickupWindow.label}',
                            style: TextStyle(
                                fontSize: 12.5, color: Colors.grey.shade700)),
                        const Spacer(),
                        if (deal.rating != null) ...[
                          const Icon(Icons.star_rounded,
                              size: 15, color: Colors.amber),
                          Text(deal.rating!.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 12.5)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('฿${deal.price.toStringAsFixed(0)}',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isExpired
                                    ? Colors.grey
                                    : AppConfig.primaryGreen)),
                        const SizedBox(width: 6),
                        Text('฿${deal.originalPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                                decoration: TextDecoration.lineThrough)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                AppConfig.primaryGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('-${deal.discountPercent}%',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppConfig.primaryGreen)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
