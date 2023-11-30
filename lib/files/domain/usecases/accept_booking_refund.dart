import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuiicalendar_domain_data_firestore/files/domain/repositories/lesson_booking_repository.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';
import 'package:tuiientitymodels/files/auth/domain/entities/user.dart';
import 'package:tuiientitymodels/files/calendar/data/models/accept_booking_refund_response_model.dart';
import 'package:tuiientitymodels/files/calendar/data/models/lesson_booking_model.dart';

class AcceptBookingRefundUseCase
    implements UseCase<AcceptBookingRefundResponse, AcceptBookingRefundParams> {
  final CalendarLessonBookingRepository repository;

  AcceptBookingRefundUseCase({required this.repository});

  @override
  Future<Either<Failure, AcceptBookingRefundResponse>> call(
      AcceptBookingRefundParams params) async {
    return await repository.acceptBookingRefund(
        firebaseToken: params.firebaseToken,
        refundBookingUrl: params.refundBookingUrl,
        refundBooking: params.refundBooking,
        tutor: params.tutor,
        platformTransactionFee: params.platformTransactionFee,
        platformPercentageRate: params.platformPercentageRate);
  }
}

class AcceptBookingRefundParams extends Equatable {
  final String firebaseToken;
  final String refundBookingUrl;
  final LessonBookingModel refundBooking;
  final User tutor;
  final double platformTransactionFee;
  final double platformPercentageRate;

  const AcceptBookingRefundParams({
    required this.firebaseToken,
    required this.refundBookingUrl,
    required this.refundBooking,
    required this.tutor,
    required this.platformTransactionFee,
    required this.platformPercentageRate,
  });

  @override
  List<Object> get props => [
        firebaseToken,
        refundBookingUrl,
        refundBooking,
        tutor,
        platformTransactionFee,
        platformPercentageRate,
      ];
}
