import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuiicalendar_domain_data_firestore/files/domain/repositories/lesson_booking_repository.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';
import 'package:tuiientitymodels/files/calendar/data/models/lesson_booking_model.dart';

class AcceptLessonBookingUseCase
    implements UseCase<LessonBookingModel, AcceptLessonBookingParams> {
  final CalendarLessonBookingRepository repository;

  AcceptLessonBookingUseCase({required this.repository});

  @override
  Future<Either<Failure, LessonBookingModel>> call(
      AcceptLessonBookingParams params) async {
    return await repository.acceptLessonBooking(params.lessonBooking);
  }
}

class AcceptLessonBookingParams extends Equatable {
  final LessonBookingModel lessonBooking;

  const AcceptLessonBookingParams({
    required this.lessonBooking,
  });

  @override
  List<Object> get props => [lessonBooking];
}
