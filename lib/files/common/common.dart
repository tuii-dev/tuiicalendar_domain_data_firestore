import 'package:tuiicore/core/enums/discount_type.dart';
import 'package:tuiicore/core/enums/payout_cadence_type.dart';
import 'package:tuiicore/core/models/stripe_dynamic_line_item.dart';
import 'package:tuiientitymodels/files/calendar/data/models/lesson_booking_line_item_model.dart';
import 'package:tuiientitymodels/files/classroom/data/models/payout_directive_schedule_model.dart';

double getLessonPrice(LessonBookingLineItemModel lineItem) {
  if (lineItem.discountedCostOfLesson != null) {
    return lineItem.discountedCostOfLesson!;
  } else {
    return lineItem.costOfLesson!;
  }
}

PayoutDirectiveScheduleModel getNextPayoutExecutionKey(
    PayoutCadenceType payoutCadence,
    DateTime? lastPayoutDate,
    int dailyPayoutCadence) {
  final now = DateTime.now();
  if (payoutCadence == PayoutCadenceType.daily) {
    final payoutDate = now.add(Duration(days: dailyPayoutCadence));
    final keyString = payoutDate.year.toString() +
        _getDatePortion(payoutDate.month) +
        _getDatePortion(payoutDate.day);

    return PayoutDirectiveScheduleModel(
        executionKey: int.parse(keyString), scheduledPayoutDate: payoutDate);
  } else {
    return const PayoutDirectiveScheduleModel(
      executionKey: -1,
    );
  }
}

String _getDatePortion(int portion) {
  return (portion < 10) ? '0$portion' : portion.toString();
}

double getAdditionalCostPrice(StripeDynamicLineItem additionalCost) {
  int price = 0;
  final quantity = additionalCost.quantity ?? 0;
  final unitAmount = additionalCost.priceData?.unitAmount ?? 0;
  price = quantity * unitAmount;

  double discountedUnitAmount =
      (additionalCost.priceData?.unitAmount ?? 0).toDouble();
  if (additionalCost.discount != null &&
      additionalCost.discount?.discountType != DiscountType.none) {
    var discountValue = 0.0;
    if (additionalCost.discount!.discountType! == DiscountType.percentage) {
      discountValue = unitAmount * (additionalCost.discount!.percentage! / 100);
      discountedUnitAmount = unitAmount.toDouble() - discountValue;
    } else {
      discountValue =
          ((additionalCost.discount!.fixedAmount! * 100) / quantity);
      discountedUnitAmount = unitAmount - discountValue;
    }

    double discountedAdditionalCostPrice = quantity * discountedUnitAmount;
    return discountedAdditionalCostPrice;
  } else {
    return price / 100;
  }
}
