import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuiicalendar_domain_data_firestore/files/domain/usecases/lesson_bookings_stream_manager.dart';
import 'package:tuiicore/core/enums/tuii_role_type.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';
import 'package:tuiicalendar_domain_data_firestore/files/domain/repositories/lesson_booking_repository.dart';

class GetLessonBookingsStreamManager
    implements
        SyncUseCase<LessonBookingsStreamManager,
            GetLessonBookingsStreamManagerParams> {
  final CalendarLessonBookingRepository repository;

  GetLessonBookingsStreamManager({required this.repository});

  @override
  Either<Failure, LessonBookingsStreamManager> call(
      GetLessonBookingsStreamManagerParams params) {
    final streamManager = LessonBookingsStreamManager(
        roleType: params.roleType,
        userId: params.userId,
        lessonBookingStartDate: params.lessonBookingStartDate,
        repository: repository);

    return Right(streamManager);
  }
}

class GetLessonBookingsStreamManagerParams extends Equatable {
  final TuiiRoleType roleType;
  final String userId;
  final DateTime lessonBookingStartDate;

  const GetLessonBookingsStreamManagerParams(
      {required this.roleType,
      required this.userId,
      required this.lessonBookingStartDate});

  @override
  List<Object> get props => [roleType, userId, lessonBookingStartDate];
}
