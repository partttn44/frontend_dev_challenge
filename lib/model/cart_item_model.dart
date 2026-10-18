import 'deal_model.dart';
import 'reservation_model.dart';

class CartItemModel {
  final DealModel deal;
  int quantity;

  /// Stock hold for this line item (F-3: Stock reservations).
  ReservationModel? reservation;

  CartItemModel({required this.deal, this.quantity = 1, this.reservation});

  num get lineTotal => deal.price * quantity;

  bool get hasValidReservation {
    if (reservation == null) return false;
    return DateTime.now().isBefore(reservation!.expiresAt);
  }

  bool get isReservationExpired {
    if (reservation == null) return false;
    return DateTime.now().isAfter(reservation!.expiresAt);
  }

  Duration? get remainingReservationTime {
    if (reservation == null) return null;
    final remaining = reservation!.expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }
}
