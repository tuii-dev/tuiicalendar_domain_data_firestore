import 'package:dartz/dartz.dart';
import 'package:tuiicore/core/enums/tuii_role_type.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/models/stripe_payment_model.dart';
import 'package:tuiientitymodels/files/auth/domain/entities/user.dart';
import 'package:tuiientitymodels/files/bookings/data/models/dispute_model.dart';
import 'package:tuiientitymodels/files/calendar/data/models/accept_booking_refund_response_model.dart';
import 'package:tuiientitymodels/files/calendar/data/models/lesson_booking_model.dart';
import 'package:tuiientitymodels/files/calendar/data/models/payout_batch_manifest_model.dart';

abstract class CalendarLessonBookingRepository {
  Future<Either<Failure, List<LessonBookingModel>>> getStudentLessonBookings(
      String studentId);
  Future<Either<Failure, List<LessonBookingModel>>> getTutorLessonBookings(
      String tutorId);
  Future<Either<Failure, LessonBookingModel>> addLessonBooking(
      LessonBookingModel lessonBooking, bool isRefundBooking);
  Future<Either<Failure, LessonBookingModel>> updateLessonBooking(
      LessonBookingModel lessonBooking);
  Future<Either<Failure, bool>> deleteLessonBooking(
      LessonBookingModel lessonBooking);

  Future<Either<Failure, LessonBookingModel>> acceptLessonBooking(
      LessonBookingModel lessonBooking);

  Future<Either<Failure, LessonBookingModel>> updateAcceptedLessonBooking(
      LessonBookingModel lessonBooking);

  Either<Failure, Stream<List<Future<LessonBookingModel>>>>
      getLessonBookingStream(
          {required TuiiRoleType roleType,
          required String userId,
          required DateTime lessonBookingStartDate});

  Either<Failure, Stream<List<Future<PayoutBatchManifestModel>>>>
      getPayoutStream(
          {required String userId, required DateTime batchStartDate});

  Future<Either<Failure, String>> getStripeCheckoutUrl(
      {required String firebaseToken,
      required String createSessionUrl,
      required StripePaymentModel payment});

  Future<Either<Failure, LessonBookingModel>> rejectBookingRefund(
      LessonBookingModel refundBooking);

  Future<Either<Failure, LessonBookingModel>> raiseRefundDispute(
      LessonBookingModel refundBooking, DisputeModel dispute);

  Future<Either<Failure, AcceptBookingRefundResponse>> acceptBookingRefund({
    required String firebaseToken,
    required String refundBookingUrl,
    required LessonBookingModel refundBooking,
    required User tutor,
    required double platformTransactionFee,
    required double platformPercentageRate,
  });

  // Deep Linking
  Future<LessonBookingModel?> getLessonBooking(
      {required String bookingId,
      required TuiiRoleType roleType,
      required String userId});
}
