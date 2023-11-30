import 'package:tuiicore/core/enums/tuii_role_type.dart';
import 'package:tuiicore/core/models/stripe_payment_model.dart';
import 'package:tuiientitymodels/files/auth/domain/entities/user.dart';
import 'package:tuiientitymodels/files/bookings/data/models/dispute_model.dart';
import 'package:tuiientitymodels/files/calendar/data/models/accept_booking_refund_response_model.dart';
import 'package:tuiientitymodels/files/calendar/data/models/lesson_booking_model.dart';
import 'package:tuiientitymodels/files/calendar/data/models/payout_batch_manifest_model.dart';

abstract class CalendarLessonBookingDataSource {
  Future<List<LessonBookingModel>> getStudentLessonBookings(
      {required String studentId});
  Future<List<LessonBookingModel>> getTutorLessonBookings(
      {required String tutorId});
  Future<LessonBookingModel> addLessonBooking(
      {required LessonBookingModel lessonBooking,
      required bool isRefundBooking});
  Future<LessonBookingModel> updateLessonBooking(
      {required LessonBookingModel lessonBooking});

  Future<void> deleteLessonBooking({required LessonBookingModel lessonBooking});

  Future<LessonBookingModel> acceptLessonBooking(
      {required LessonBookingModel lessonBooking});

  Future<LessonBookingModel> updateAcceptedLessonBooking(
      {required LessonBookingModel lessonBooking});

  Stream<List<Future<LessonBookingModel>>> getLessonBookingStream(
      {required TuiiRoleType roleType,
      required String userId,
      required DateTime lessonBookingStartDate});

  Stream<List<Future<PayoutBatchManifestModel>>> getPayoutStream(
      {required String userId, required DateTime batchStartDate});

  Future<String> getStripeCheckoutUrl(
      {required String firebaseToken,
      required String createSessionUrl,
      required StripePaymentModel payment});

  String getNewLessonBookingId();

  Future<LessonBookingModel> rejectBookingRefund(
      LessonBookingModel refundBooking);

  Future<LessonBookingModel> raiseRefundDispute(
      LessonBookingModel refundBooking, DisputeModel dispute);

  Future<AcceptBookingRefundResponse> acceptBookingRefund({
    required String firebaseToken,
    required String refundBookingUrl,
    required LessonBookingModel refundBooking,
    required User tutor,
    required double platformTransactionFee,
    required double platformPercentageRate,
  });

  Future<LessonBookingModel?> getLessonBooking(
      {required String bookingId,
      required TuiiRoleType roleType,
      required String userId});
}
