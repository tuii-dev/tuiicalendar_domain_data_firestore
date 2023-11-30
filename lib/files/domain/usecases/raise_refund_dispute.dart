import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';
import 'package:tuiientitymodels/files/bookings/data/models/dispute_model.dart';
import 'package:tuiientitymodels/files/calendar/data/models/lesson_booking_model.dart';
import 'package:tuiicalendar_domain_data_firestore/files/domain/repositories/lesson_booking_repository.dart';

class RaiseRefundDisputeUseCase
    implements UseCase<LessonBookingModel, RaiseRefundDisputeParams> {
  final CalendarLessonBookingRepository repository;

  RaiseRefundDisputeUseCase({required this.repository});

  @override
  Future<Either<Failure, LessonBookingModel>> call(
      RaiseRefundDisputeParams params) async {
    return await repository.raiseRefundDispute(
        params.refundBooking, params.dispute);
  }
}

class RaiseRefundDisputeParams extends Equatable {
  final LessonBookingModel refundBooking;
  final DisputeModel dispute;

  const RaiseRefundDisputeParams({
    required this.refundBooking,
    required this.dispute,
  });

  @override
  List<Object> get props => [refundBooking, dispute];
}
