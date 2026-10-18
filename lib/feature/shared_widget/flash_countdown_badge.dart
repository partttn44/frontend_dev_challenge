import 'dart:async';
import 'package:flutter/material.dart';

class FlashCountdownBadge extends StatefulWidget {
  final DateTime flashSaleEndsAt;
  final VoidCallback? onExpired;

  const FlashCountdownBadge({
    super.key,
    required this.flashSaleEndsAt,
    this.onExpired,
  });

  @override
  State<FlashCountdownBadge> createState() => _FlashCountdownBadgeState();
}

class _FlashCountdownBadgeState extends State<FlashCountdownBadge> {
  Timer? _timer;
  late Duration _remaining;
  bool _hasTriggeredExpired = false;

  @override
  void initState() {
    super.initState();
    _updateRemaining();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final difference = widget.flashSaleEndsAt.difference(now);

    if (!mounted) return;

    if (difference.isNegative || difference == Duration.zero) {
      _timer?.cancel();
      setState(() {
        _remaining = Duration.zero;
      });

      if (!_hasTriggeredExpired) {
        _hasTriggeredExpired = true;
        widget.onExpired?.call();
      }
    } else {
      setState(() {
        _remaining = difference;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return 'Expired';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _remaining == Duration.zero;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isExpired ? Colors.grey.shade200 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isExpired ? 'Expired' : _formatDuration(_remaining),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isExpired ? Colors.grey.shade700 : Colors.red.shade700,
        ),
      ),
    );
  }
}
