import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';
import 'package:tuiientitymodels/files/calendar/data/models/lesson_booking_model.dart';
import 'package:tuiicalendar_domain_data_firestore/files/domain/repositories/lesson_booking_repository.dart';

class RejectBookingRefundUseCase
    implements UseCase<LessonBookingModel, RejectBookingRefundParams> {
  final CalendarLessonBookingRepository repository;

  RejectBookingRefundUseCase({required this.repository});

  @override
  Future<Either<Failure, LessonBookingModel>> call(
      RejectBookingRefundParams params) async {
    return await repository.rejectBookingRefund(params.refundBooking);
  }
}

class RejectBookingRefundParams extends Equatable {
  final LessonBookingModel refundBooking;

  const RejectBookingRefundParams({
    required this.refundBooking,
  });

  @override
  List<Object> get props => [refundBooking];
}
