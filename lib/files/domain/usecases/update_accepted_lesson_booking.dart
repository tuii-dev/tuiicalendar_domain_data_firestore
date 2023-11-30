import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';
import 'package:tuiientitymodels/files/calendar/data/models/lesson_booking_model.dart';
import 'package:tuiicalendar_domain_data_firestore/files/domain/repositories/lesson_booking_repository.dart';

class UpdateAcceptedLessonBookingUseCase
    implements UseCase<LessonBookingModel, UpdateAcceptedLessonBookingParams> {
  final CalendarLessonBookingRepository repository;

  UpdateAcceptedLessonBookingUseCase({required this.repository});

  @override
  Future<Either<Failure, LessonBookingModel>> call(
      UpdateAcceptedLessonBookingParams params) async {
    return await repository.updateAcceptedLessonBooking(params.lessonBooking);
  }
}

class UpdateAcceptedLessonBookingParams extends Equatable {
  final LessonBookingModel lessonBooking;

  const UpdateAcceptedLessonBookingParams({
    required this.lessonBooking,
  });

  @override
  List<Object> get props => [lessonBooking];
}
