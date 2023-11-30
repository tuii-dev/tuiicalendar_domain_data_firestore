import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuiicalendar_domain_data_firestore/files/domain/usecases/payouts_stream_manager.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';
import 'package:tuiicalendar_domain_data_firestore/files/domain/repositories/lesson_booking_repository.dart';

class GetPayoutManifestsStreamManager
    implements
        SyncUseCase<PayoutManifestsStreamManager,
            GetPayoutManifestsStreamManagerParams> {
  final CalendarLessonBookingRepository repository;

  GetPayoutManifestsStreamManager({required this.repository});

  @override
  Either<Failure, PayoutManifestsStreamManager> call(
      GetPayoutManifestsStreamManagerParams params) {
    final streamManager = PayoutManifestsStreamManager(
        userId: params.userId,
        batchStartDate: params.batchStartDate,
        repository: repository);

    return Right(streamManager);
  }
}

class GetPayoutManifestsStreamManagerParams extends Equatable {
  final String userId;
  final DateTime batchStartDate;

  const GetPayoutManifestsStreamManagerParams(
      {required this.userId, required this.batchStartDate});

  @override
  List<Object> get props => [userId, batchStartDate];
}
