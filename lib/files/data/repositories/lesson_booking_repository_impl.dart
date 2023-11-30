import 'package:dartz/dartz.dart';
import 'package:tuiicalendar_domain_data_firestore/files/data/datasources/lesson_booking_data_source.dart';
import 'package:tuiicalendar_domain_data_firestore/files/domain/repositories/lesson_booking_repository.dart';
import 'package:tuiicore/core/enums/tuii_role_type.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/models/stripe_payment_model.dart';
import 'package:tuiientitymodels/files/auth/domain/entities/user.dart';
import 'package:tuiientitymodels/files/bookings/data/models/dispute_model.dart';
import 'package:tuiientitymodels/files/calendar/data/models/accept_booking_refund_response_model.dart';
import 'package:tuiientitymodels/files/calendar/data/models/lesson_booking_model.dart';
import 'package:tuiientitymodels/files/calendar/data/models/payout_batch_manifest_model.dart';

class CalendarLessonBookingRepositoryImpl
    implements CalendarLessonBookingRepository {
  final CalendarLessonBookingDataSource dataSource;

  CalendarLessonBookingRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<LessonBookingModel>>> getStudentLessonBookings(
      String studentId) async {
    try {
      final lessonBookings =
          await dataSource.getStudentLessonBookings(studentId: studentId);

      return Right(lessonBookings);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, List<LessonBookingModel>>> getTutorLessonBookings(
      String tutorId) async {
    try {
      final lessonBookings =
          await dataSource.getTutorLessonBookings(tutorId: tutorId);

      return Right(lessonBookings);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, LessonBookingModel>> addLessonBooking(
      LessonBookingModel lessonBooking, bool isRefundBooking) async {
    try {
      final newBooking = await dataSource.addLessonBooking(
          lessonBooking: lessonBooking, isRefundBooking: isRefundBooking);

      return Right(newBooking);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, LessonBookingModel>> updateLessonBooking(
      LessonBookingModel lessonBooking) async {
    try {
      final updateBooking =
          await dataSource.updateLessonBooking(lessonBooking: lessonBooking);

      return Right(updateBooking);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, LessonBookingModel>> acceptLessonBooking(
      LessonBookingModel lessonBooking) async {
    try {
      final acceptedBooking =
          await dataSource.acceptLessonBooking(lessonBooking: lessonBooking);

      return Right(acceptedBooking);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, LessonBookingModel>> updateAcceptedLessonBooking(
      LessonBookingModel lessonBooking) async {
    try {
      final updatedBooking = await dataSource.updateAcceptedLessonBooking(
          lessonBooking: lessonBooking);

      return Right(updatedBooking);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, bool>> deleteLessonBooking(
      LessonBookingModel lessonBooking) async {
    try {
      await dataSource.deleteLessonBooking(lessonBooking: lessonBooking);

      return const Right(true);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Either<Failure, Stream<List<Future<LessonBookingModel>>>>
      getLessonBookingStream(
          {required TuiiRoleType roleType,
          required String userId,
          required DateTime lessonBookingStartDate}) {
    try {
      final stream = dataSource.getLessonBookingStream(
          roleType: roleType,
          userId: userId,
          lessonBookingStartDate: lessonBookingStartDate);
      return Right(stream);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Either<Failure, Stream<List<Future<PayoutBatchManifestModel>>>>
      getPayoutStream(
          {required String userId, required DateTime batchStartDate}) {
    try {
      final stream = dataSource.getPayoutStream(
          userId: userId, batchStartDate: batchStartDate);
      return Right(stream);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, String>> getStripeCheckoutUrl(
      {required String firebaseToken,
      required String createSessionUrl,
      required StripePaymentModel payment}) async {
    try {
      final url = await dataSource.getStripeCheckoutUrl(
          firebaseToken: firebaseToken,
          createSessionUrl: createSessionUrl,
          payment: payment);

      return Right(url);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, LessonBookingModel>> rejectBookingRefund(
      LessonBookingModel refundBooking) async {
    try {
      final booking = await dataSource.rejectBookingRefund(refundBooking);

      return Right(booking);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, LessonBookingModel>> raiseRefundDispute(
      LessonBookingModel refundBooking, DisputeModel dispute) async {
    try {
      final booking =
          await dataSource.raiseRefundDispute(refundBooking, dispute);

      return Right(booking);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, AcceptBookingRefundResponse>> acceptBookingRefund({
    required String firebaseToken,
    required String refundBookingUrl,
    required LessonBookingModel refundBooking,
    required User tutor,
    required double platformTransactionFee,
    required double platformPercentageRate,
  }) async {
    try {
      final response = await dataSource.acceptBookingRefund(
        firebaseToken: firebaseToken,
        refundBookingUrl: refundBookingUrl,
        refundBooking: refundBooking,
        tutor: tutor,
        platformTransactionFee: platformTransactionFee,
        platformPercentageRate: platformPercentageRate,
      );

      return Right(response);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  // Deep linking
  @override
  Future<LessonBookingModel?> getLessonBooking(
      {required String bookingId,
      required TuiiRoleType roleType,
      required String userId}) async {
    try {
      return await dataSource.getLessonBooking(
          bookingId: bookingId, roleType: roleType, userId: userId);
    } on Failure {
      return null;
    }
  }
}
