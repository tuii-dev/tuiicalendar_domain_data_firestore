import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';
import 'package:tuiientitymodels/files/calendar/data/models/lesson_booking_model.dart';
import 'package:tuiicalendar_domain_data_firestore/files/domain/repositories/lesson_booking_repository.dart';

class UpdateLessonBookingUseCase
    implements UseCase<LessonBookingModel, UpdateLessonBookingParams> {
  final CalendarLessonBookingRepository repository;

  UpdateLessonBookingUseCase({required this.repository});

  @override
  Future<Either<Failure, LessonBookingModel>> call(
      UpdateLessonBookingParams params) async {
    return await repository.updateLessonBooking(params.lessonBooking);
  }
}

class UpdateLessonBookingParams extends Equatable {
  final LessonBookingModel lessonBooking;

  const UpdateLessonBookingParams({
    required this.lessonBooking,
  });

  @override
  List<Object> get props => [lessonBooking];
}
