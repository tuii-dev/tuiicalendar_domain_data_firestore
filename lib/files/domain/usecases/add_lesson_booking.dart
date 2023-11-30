import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';
import 'package:tuiientitymodels/files/calendar/data/models/lesson_booking_model.dart';
import 'package:tuiicalendar_domain_data_firestore/files/domain/repositories/lesson_booking_repository.dart';

class AddLessonBookingUseCase
    implements UseCase<LessonBookingModel, AddLessonBookingParams> {
  final CalendarLessonBookingRepository repository;

  AddLessonBookingUseCase({required this.repository});

  @override
  Future<Either<Failure, LessonBookingModel>> call(
      AddLessonBookingParams params) async {
    return await repository.addLessonBooking(
        params.lessonBooking, params.isRefundBooking);
  }
}

class AddLessonBookingParams extends Equatable {
  final LessonBookingModel lessonBooking;
  final bool isRefundBooking;

  const AddLessonBookingParams({
    required this.lessonBooking,
    this.isRefundBooking = false,
  });

  @override
  List<Object> get props => [lessonBooking, isRefundBooking];
}
