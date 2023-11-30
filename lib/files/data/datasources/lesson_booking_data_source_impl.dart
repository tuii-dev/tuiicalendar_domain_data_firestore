import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:tuiicalendar_domain_data_firestore/files/common/common.dart';
import 'package:tuiicalendar_domain_data_firestore/files/data/datasources/lesson_booking_data_source.dart';
import 'package:tuiicore/core/common/common.dart';
import 'package:tuiicore/core/common/tutor_lesson_index_model.dart';
import 'package:tuiicore/core/config/paths.dart';
import 'package:tuiicore/core/enums/enums.dart';
import 'package:tuiicore/core/enums/lesson_booking_refund_type.dart';
import 'package:tuiicore/core/enums/lesson_booking_status_type.dart';
import 'package:tuiicore/core/enums/payout_cadence_type.dart';
import 'package:tuiicore/core/enums/payout_type.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/models/stripe_dynamic_line_item.dart';
import 'package:tuiicore/core/models/stripe_payment_model.dart';
import 'package:tuiicore/core/models/stripe_product_line_item_model.dart';
import 'package:tuiicore/core/models/system_constants.dart';
import 'package:tuiientitymodels/files/auth/domain/entities/user.dart';
import 'package:tuiientitymodels/files/bookings/data/models/dispute_model.dart';
import 'package:tuiientitymodels/files/calendar/data/models/accept_booking_refund_response_model.dart';
import 'package:tuiientitymodels/files/calendar/data/models/lesson_booking_model.dart';
import 'package:tuiientitymodels/files/calendar/data/models/lesson_booking_refund_payload_model.dart';
import 'package:tuiientitymodels/files/calendar/data/models/payout_batch_manifest_model.dart';
import 'package:tuiientitymodels/files/calendar/data/models/refund_response_model.dart';
import 'package:tuiientitymodels/files/calendar/data/models/stripe_redirect_response_model.dart';
import 'package:tuiientitymodels/files/classroom/data/models/lesson_payout_directive_model.dart';
import 'package:tuiientitymodels/files/home/domain/entities/lesson_appointment.dart';
import 'package:tuiientitymodels/files/classroom/data/models/classroom_model.dart';
import 'package:tuiientitymodels/files/classroom/data/models/lesson_model.dart';
import 'package:tuiientitymodels/files/classroom/data/models/student_home_model.dart';
import 'package:tuiientitymodels/files/classroom/data/models/tutor_home_model.dart';

class CalendarLessonBookingDataSourceImpl
    implements CalendarLessonBookingDataSource {
  final FirebaseFirestore firestore;
  final SystemConstants constants;

  CalendarLessonBookingDataSourceImpl({
    required this.firestore,
    required this.constants,
  });

  @override
  Future<List<LessonBookingModel>> getStudentLessonBookings(
      {required String studentId}) async {
    try {
      final docs = await firestore
          .collection(Paths.lessonBookings)
          .where('studentId', isEqualTo: studentId)
          .orderBy('lastUpdatedDate', descending: true)
          .get();

      if (docs.docs.isNotEmpty) {
        return docs.docs
            .map((doc) => LessonBookingModel.fromMap(doc.data()))
            .toList();
      } else {
        return [];
      }
    } on FirebaseException catch (e) {
      debugPrint(e.message);
      throw const Failure(message: 'Failed to get student lesson bookings!');
    } on Exception {
      throw const Failure(message: 'Failed to get student lesson bookings!');
    }
  }

  @override
  Future<List<LessonBookingModel>> getTutorLessonBookings(
      {required String tutorId}) async {
    try {
      final docs = await firestore
          .collection(Paths.lessonBookings)
          .where('tutorId', isEqualTo: tutorId)
          .orderBy('lastUpdatedDate', descending: true)
          .get();

      if (docs.docs.isNotEmpty) {
        return docs.docs
            .map((doc) => LessonBookingModel.fromMap(doc.data()))
            .toList();
      } else {
        return [];
      }
    } on FirebaseException catch (e) {
      debugPrint(e.message);
      throw const Failure(message: 'Failed to get tutor lesson bookings!');
    } on Exception {
      throw const Failure(message: 'Failed to get tutor lesson bookings!');
    }
  }

  @override
  String getNewLessonBookingId() {
    final docRef = firestore.collection(Paths.lessonBookings).doc();

    return docRef.id;
  }

  @override
  Future<LessonBookingModel> addLessonBooking(
      {required LessonBookingModel lessonBooking,
      required bool isRefundBooking}) async {
    try {
      DocumentReference docRef;
      String subjectName = lessonBooking.subjectName;
      if (isRefundBooking != true) {
        for (int i = 0; i < lessonBooking.lessonBookings.length; i++) {
          LessonAppointment appointment = lessonBooking.lessonBookings[i];
          final bookingId = appointment.bookingId;
          docRef = firestore
              .collection(Paths.classrooms)
              .doc(appointment.classroom.id)
              .collection(Paths.lessons)
              .doc();
          lessonBooking.lessonBookings[i] = appointment.copyWith(
              lesson: appointment.lesson.copyWith(
                  id: docRef.id,
                  bookingId: bookingId,
                  subjectName: subjectName),
              lessonIndex: appointment.lessonIndex
                  .copyWith(id: docRef.id, bookingId: bookingId));
        }

        if (lessonBooking.id == null) {
          docRef = firestore.collection(Paths.lessonBookings).doc();

          lessonBooking = lessonBooking.copyWith(id: docRef.id);
        }
      }

      final map = isRefundBooking
          ? lessonBooking.toMapWithStripeInfo()
          : lessonBooking.toMap();

      await firestore
          .collection(Paths.lessonBookings)
          .doc(lessonBooking.id)
          .set(map);

      return lessonBooking;
    } on FirebaseException catch (e) {
      debugPrint(e.message);
      throw const Failure(message: 'Failed to add lesson booking!');
    } on Exception {
      throw const Failure(message: 'Failed to add lesson booking.');
    }
  }

  @override
  Future<LessonBookingModel> updateLessonBooking(
      {required LessonBookingModel lessonBooking}) async {
    try {
      await firestore
          .collection(Paths.lessonBookings)
          .doc(lessonBooking.id!)
          .set(lessonBooking.toMap(), SetOptions(merge: true));

      return lessonBooking;
    } on Exception {
      throw const Failure(message: 'Failed to update lesson booking.');
    }
  }

  @override
  Future<LessonBookingModel> acceptLessonBooking(
      {required LessonBookingModel lessonBooking}) async {
    try {
      WriteBatch writeBatch = firestore.batch();
      bool runNextLessonDateUpdate = false;
      final now = DateTime.now();
      final epochDate = DateTime(1971, 1, 1);
      final lessonBookingId = lessonBooking.id!;
      final firstBooking = lessonBooking.lessonBookings[0];
      final classroomRef =
          firestore.collection(Paths.classrooms).doc(firstBooking.classroom.id);

      final studentRef = firestore
          .collection(Paths.users)
          .doc(firstBooking.classroom.studentId);

      final studentHomeRef = firestore
          .collection(Paths.studentHome)
          .doc(firstBooking.classroom.studentId);

      final tutorRef =
          firestore.collection(Paths.users).doc(firstBooking.classroom.tutorId);

      final tutorHomeRef = firestore
          .collection(Paths.tutorHome)
          .doc(firstBooking.classroom.tutorId);

      ClassroomModel classroom = await classroomRef
          .get()
          .then((doc) => ClassroomModel.fromMap(doc.data()!));

      TutorHomeModel tutorHome = await tutorHomeRef
          .get()
          .then((doc) => TutorHomeModel.fromMap(doc.data()!));

      StudentHomeModel studentHome = await studentHomeRef
          .get()
          .then((doc) => StudentHomeModel.fromMap(doc.data()!));

      DateTime? nextLessonStartDate = classroom.nextLessonStartDate;

      final costStructure = lessonBooking.costStructure;

      for (int i = 0; i < lessonBooking.lessonBookings.length; i++) {
        LessonAppointment booking = lessonBooking.lessonBookings[i];
        var costOfLesson = booking.costOfLesson ?? 0;

        final lineItemIndex = costStructure.lineItems!
            .indexWhere((li) => li.bookingId == booking.bookingId);

        if (lineItemIndex > -1) {
          costOfLesson =
              getLessonPrice(costStructure.lineItems![lineItemIndex]);
        }

        String lessonTitle = lessonBooking.subjectName;
        //'${DateFormat.MMMd().format(booking.startTime)} ${DateFormat.jm().format(booking.startTime)} ${lessonBooking.subjectName}';
        LessonIndexModel lessonIndex = booking.lessonIndex;
        lessonIndex = lessonIndex.copyWith(
          studentHasCustodian: lessonBooking.studentHasCustodian,
          studentCustodianId: lessonBooking.studentCustodianId,
          jobBookingId: lessonBooking.id,
          zoomMeetingCreationIndex: i,
        );

        LessonModel lesson = booking.lesson.copyWith(
          bookingId: booking.bookingId,
          studentHasCustodian: lessonBooking.studentHasCustodian,
          studentCustodianId: lessonBooking.studentCustodianId,
          startDate: booking.startTime,
          lessonBookingId: lessonBookingId,
          lessonTitle: lessonTitle,
          lessonDescription: '',
          lessonDescriptionDocument: '',
          lessonLength: lessonIndex.lessonLength,
          lessonRefunded: false,
          lessonCanceled: false,
          lessonCompleted: false,
          attendanceStatusType: AttendanceStatusType.pending,
          lessonDelivery: lessonIndex.lessonDelivery,
          lessonCategory: booking.subjectModel.name,
          lessonStarted: false,
          linkedResourceIds: [],
          linkedTaskIds: [],
          subjectId: booking.subjectModel.subjectId,
          subjectName: booking.subjectModel.name,
          costOfLesson: costOfLesson,
        );

        final lessonRef = firestore
            .collection(Paths.classrooms)
            .doc(booking.classroom.id)
            .collection(Paths.lessons)
            .doc(lesson.id);

        lessonIndex = lessonIndex.copyWith(
            lessonBookingId: lessonBookingId,
            bookingId: booking.bookingId,
            studentId: studentRef.id,
            subjectId: booking.subjectModel.subjectId,
            startDate: booking.startTime,
            originalStartTime: booking.startTime,
            lessonRefunded: false,
            lessonCompleted: false,
            attendanceStatusType: AttendanceStatusType.pending,
            lessonTitle: lessonTitle,
            costOfLesson: costOfLesson,
            classroomRef: classroomRef,
            lessonRef: lessonRef,
            studentRef: studentRef,
            tutorRef: tutorRef);

        final lessonIndexRef =
            firestore.collection(Paths.tutorLessonIndex).doc(lessonIndex.id);

        booking = booking.copyWith(
            isUnconfirmed: false, lesson: lesson, lessonIndex: lessonIndex);
        lessonBooking.lessonBookings[i] = booking;

        writeBatch.set(lessonRef, lesson.toMap());
        writeBatch.set(lessonIndexRef, lessonIndex.toMap());

        if (nextLessonStartDate == null || nextLessonStartDate == epochDate) {
          // writeBatch = _processClassroomForNextLessonDate(
          //     writeBatch,
          //     classroom,
          //     tutorHome,
          //     studentHome,
          //     classroomRef,
          //     tutorHomeRef,
          //     studentHomeRef,
          //     lessonIndex.startDate!);
          runNextLessonDateUpdate = true;
          nextLessonStartDate = lessonIndex.startDate!;
        } else {
          if (lessonIndex.startDate!.isBefore(nextLessonStartDate) &&
              lessonIndex.startDate!.isAfter(now)) {
            // lessonIndex.startDate! is before nextLessonStartDate from classroom and
            // lessonIndex.startDate! is after now
            runNextLessonDateUpdate = true;
            nextLessonStartDate = lessonIndex.startDate!;
          }
        }
      }

      if (runNextLessonDateUpdate) {
        writeBatch = _processClassroomForNextLessonDate(
            writeBatch,
            classroom,
            tutorHome,
            studentHome,
            classroomRef,
            tutorHomeRef,
            studentHomeRef,
            nextLessonStartDate!);
      }

      LessonBookingModel newLessonBooking = lessonBooking.copyWith(
          status: LessonBookingStatusType.paid,
          lastUpdatedDate: DateTime.now());

      final lessonBookingRef =
          firestore.collection(Paths.lessonBookings).doc(lessonBooking.id);

      writeBatch.set(
          lessonBookingRef, newLessonBooking.toMap(), SetOptions(merge: true));

      await writeBatch.commit();

      return newLessonBooking;
    } on Exception {
      throw const Failure(message: 'Failed to accept lesson booking.');
    }
  }

  @override
  Future<LessonBookingModel> updateAcceptedLessonBooking(
      {required LessonBookingModel lessonBooking}) async {
    try {
      List<LessonAppointment> lessonBookings =
          List.from(lessonBooking.lessonBookings);
      // List<LessonAppointment> deleteAppointments = [];
      List<LessonAppointment> updateAppointments = [];

      WriteBatch writeBatch = firestore.batch();

      for (int i = 0; i < lessonBookings.length; i++) {
        if (lessonBookings[i].isPendingSubsequentApproval == true) {
          lessonBookings[i] =
              lessonBookings[i].copyWith(isPendingSubsequentApproval: false);
          updateAppointments.add(lessonBookings[i]);
        }
      }

      if (updateAppointments.isNotEmpty) {
        for (var appt in updateAppointments) {
          if (appt.lessonIndex.lessonRef != null) {
            // final lesson = appt.lesson.copyWith(startDate: appt.startTime, lessonDelivery appt.del, )
            final lessonDoc = await appt.lessonIndex.lessonRef!.get();
            final data = lessonDoc.data()! as Map<String, dynamic>;
            final lessonData = LessonModel.fromMap(data);
            final lesson = appt.lesson.copyWith(
              zoomMeetingId: lessonData.zoomMeetingId,
              zoomStartUrl: lessonData.zoomStartUrl,
              zoomJoinUrl: lessonData.zoomJoinUrl,
              attendanceStatusType: AttendanceStatusType.pending,
              lessonCompleted: false,
            );

            writeBatch.update(appt.lessonIndex.lessonRef!, lesson.toMap());
          }
          LessonIndexModel lessonIndex = appt.lessonIndex.copyWith(
            isPendingSubsequentApproval: false,
            attendanceStatusType: AttendanceStatusType.pending,
            lessonCompleted: false,
          );
          final lessonIndexRef = firestore
              .collection(Paths.tutorLessonIndex)
              .doc(appt.lessonIndex.id);
          writeBatch.update(lessonIndexRef, lessonIndex.toMap());
        }
      }

      if (updateAppointments.isNotEmpty) {
        lessonBooking = lessonBooking.copyWith(lessonBookings: lessonBookings);
        final bookingRef =
            firestore.collection(Paths.lessonBookings).doc(lessonBooking.id);
        writeBatch.set(
            bookingRef, lessonBooking.toMap(), SetOptions(merge: true));

        await writeBatch.commit();
      }

      return lessonBooking;
    } on Exception {
      throw const Failure(message: 'Failed to update accepted lesson booking.');
    }
  }

  @override
  Future<void> deleteLessonBooking(
      {required LessonBookingModel lessonBooking}) async {
    try {
      await firestore
          .collection(Paths.lessonBookings)
          .doc(lessonBooking.id!)
          .delete();

      return;
    } on Exception {
      throw const Failure(message: 'Failed to delete lesson booking.');
    }
  }

  @override
  Future<String> getStripeCheckoutUrl(
      {required String firebaseToken,
      required String createSessionUrl,
      required StripePaymentModel payment}) async {
    final url = Uri.parse(createSessionUrl);
    debugPrint('Firebase token: $firebaseToken');

    final channelPayment = payment.copyWith(channel: constants.channel);

    final res = await http.post(url,
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer $firebaseToken',
        },
        body: channelPayment.toJson());
    final sessionResponse = StripeRedirectResponse.fromJson(res.body);

    return sessionResponse.url ?? '';
  }

  @override
  Stream<List<Future<LessonBookingModel>>> getLessonBookingStream(
      {required TuiiRoleType roleType,
      required String userId,
      required DateTime lessonBookingStartDate}) {
    try {
      final field = roleType == TuiiRoleType.tutor
          ? 'tutorId'
          : roleType == TuiiRoleType.student
              ? 'studentId'
              : 'studentCustodianId';
      return firestore
          .collection(Paths.lessonBookings)
          .where(field, isEqualTo: userId)
          .where('lastUpdatedDate',
              isGreaterThanOrEqualTo:
                  lessonBookingStartDate.toUtc().millisecondsSinceEpoch)
          .snapshots()
          .map((snaps) => snaps.docs.map((doc) async {
                var booking = LessonBookingModel.fromMap(doc.data());
                booking = booking.copyWith(id: doc.id);
                return booking;
              }).toList());
    } on FirebaseException catch (e) {
      debugPrint(e.message);
      throw const Failure(message: 'Failed to get lessson bookings');
    } on Exception {
      throw const Failure(message: 'Failed to get lessson bookings');
    }
  }

  @override
  Stream<List<Future<PayoutBatchManifestModel>>> getPayoutStream(
      {required String userId, required DateTime batchStartDate}) {
    try {
      return firestore
          .collection(Paths.payoutManifests)
          .where('tutorId', isEqualTo: userId)
          .where('batchRunDate',
              isGreaterThanOrEqualTo:
                  batchStartDate.toUtc().millisecondsSinceEpoch)
          .snapshots()
          .map((snaps) => snaps.docs.map((doc) async {
                return PayoutBatchManifestModel.fromMap(doc.data());
              }).toList());
    } on FirebaseException catch (e) {
      debugPrint(e.message);
      throw const Failure(message: 'Failed to get batch manifests');
    } on Exception {
      throw const Failure(message: 'Failed to get batch manifests');
    }
  }

  @override
  Future<LessonBookingModel> rejectBookingRefund(
      LessonBookingModel refundBooking) async {
    // Update the parent booking
    final paidBookingId = refundBooking.paidBookingId;
    if (refundBooking.refundBookingType == LessonBookingRefundType.fullRefund) {
      if (paidBookingId != null && paidBookingId.isNotEmpty) {
        final docRef = firestore
            .collection(Paths.lessonBookings)
            .doc(refundBooking.paidBookingId);

        final doc = await docRef.get();
        if (doc.exists) {
          LessonBookingModel paidLessonBooking =
              LessonBookingModel.fromMap(doc.data()!);

          paidLessonBooking = paidLessonBooking.copyWith(
              hasAssociatedRefundBooking: false,
              refundBookingType: LessonBookingRefundType.unknown,
              refundBookingIds: [],
              refundLessonBookingIds: []);

          await docRef.update(paidLessonBooking.toMapWithStripeInfo());
        }
      }
    } else if (refundBooking.refundBookingType ==
        LessonBookingRefundType.lessonRefund) {
      final paidLessonBookingId = refundBooking.paidLessonBookingId;

      if (paidBookingId != null &&
          paidBookingId.isNotEmpty &&
          paidLessonBookingId != null &&
          paidLessonBookingId.isNotEmpty) {
        final docRef = firestore
            .collection(Paths.lessonBookings)
            .doc(refundBooking.paidBookingId);

        final doc = await docRef.get();

        if (doc.exists) {
          LessonBookingModel paidBooking =
              LessonBookingModel.fromMap(doc.data()!);
          List<LessonAppointment> appointments =
              List.from(paidBooking.lessonBookings);

          int index = appointments
              .indexWhere((a) => a.bookingId == paidLessonBookingId);

          if (index > -1) {
            appointments[index] =
                appointments[index].copyWith(isPendingRefund: false);
          }

          List<String> refundBookingIds =
              List.from(paidBooking.refundBookingIds ?? []);
          List<String> refundLessonBookingIds =
              List.from(paidBooking.refundLessonBookingIds ?? []);

          refundBookingIds.remove(refundBooking.id);

          LessonAppointment? refundAppointment =
              refundBooking.lessonBookings.isNotEmpty
                  ? refundBooking.lessonBookings.first
                  : null;
          if (refundAppointment != null) {
            refundLessonBookingIds.remove(refundAppointment.bookingId);
          }

          final bookingType = paidBooking.refundBookingType;

          paidBooking = paidBooking.copyWith(
              hasAssociatedRefundBooking: refundBookingIds.isNotEmpty,
              refundBookingType: refundBookingIds.isNotEmpty
                  ? bookingType
                  : LessonBookingRefundType.unknown,
              refundBookingIds: refundBookingIds,
              refundLessonBookingIds: refundLessonBookingIds,
              lessonBookings: appointments);

          await docRef.update(paidBooking.toMapWithStripeInfo());
        }
      }
    } else {
      // Additional Cost Refund
      final paidAdditionalCostId = refundBooking.paidAdditionalCostId;

      if (paidBookingId != null &&
          paidBookingId.isNotEmpty &&
          paidAdditionalCostId != null &&
          paidAdditionalCostId.isNotEmpty) {
        final docRef = firestore
            .collection(Paths.lessonBookings)
            .doc(refundBooking.paidBookingId);

        final doc = await docRef.get();

        if (doc.exists) {
          LessonBookingModel paidBooking =
              LessonBookingModel.fromMap(doc.data()!);
          List<StripeDynamicLineItem> additionalCosts =
              List.from(paidBooking.additionalCosts);

          int index =
              additionalCosts.indexWhere((a) => a.id == paidAdditionalCostId);

          if (index > -1) {
            additionalCosts[index] =
                additionalCosts[index].copyWith(isPendingRefund: false);
          }

          List<String> refundBookingIds =
              List.from(paidBooking.refundBookingIds ?? []);
          List<String> refundAdditionalCostIds =
              List.from(paidBooking.refundAdditionalCostIds ?? []);

          refundBookingIds.remove(refundBooking.id);

          StripeDynamicLineItem? refundAdditionalCost =
              refundBooking.additionalCosts.isNotEmpty
                  ? refundBooking.additionalCosts.first
                  : null;
          if (refundAdditionalCost != null) {
            refundAdditionalCostIds.remove(refundAdditionalCost.id);
          }

          final bookingType = paidBooking.refundBookingType;

          paidBooking = paidBooking.copyWith(
              hasAssociatedRefundBooking: refundBookingIds.isNotEmpty,
              refundBookingType: refundBookingIds.isNotEmpty
                  ? bookingType
                  : LessonBookingRefundType.unknown,
              refundBookingIds: refundBookingIds,
              refundAdditionalCostIds: refundAdditionalCostIds,
              additionalCosts: additionalCosts);

          await docRef.update(paidBooking.toMapWithStripeInfo());
        }
      }
    }

    // Update the refund booking
    refundBooking =
        refundBooking.copyWith(status: LessonBookingStatusType.refundRejected);

    await firestore
        .collection(Paths.lessonBookings)
        .doc(refundBooking.id)
        .update(refundBooking.toMapWithStripeInfo());

    // Return the refund booking

    return refundBooking;
  }

  @override
  Future<LessonBookingModel> raiseRefundDispute(
      LessonBookingModel refundBooking, DisputeModel dispute) async {
    final booking = refundBooking.copyWith(
        status: LessonBookingStatusType.disputed,
        disputeNumber: dispute.disputeNumber);

    WriteBatch writeBatch = firestore.batch();
    final paidBookingId = refundBooking.paidBookingId;
    final bookingRef =
        firestore.collection(Paths.lessonBookings).doc(booking.id!);
    writeBatch.update(bookingRef, booking.toMap());

    final disputeRef = firestore.collection(Paths.disputes).doc();
    writeBatch.set(disputeRef, dispute.toMap());

    if (refundBooking.refundBookingType == LessonBookingRefundType.fullRefund) {
      if (paidBookingId != null && paidBookingId.isNotEmpty) {
        final bookingRef =
            firestore.collection(Paths.lessonBookings).doc(paidBookingId);

        final bookingDoc = await bookingRef.get();
        LessonBookingModel booking =
            LessonBookingModel.fromMap(bookingDoc.data()!);
        booking =
            booking.copyWith(refundStatus: LessonBookingStatusType.refunded);

        for (int i = 0; i < booking.lessonBookings.length; i++) {
          booking.lessonBookings[i] = booking.lessonBookings[i].copyWith(
              isPendingRefund: false,
              isRefunded: false,
              isDisputed: true,
              paidBookingId: paidBookingId,
              refundBookingId: refundBooking.id);
        }

        for (int i = 0; i < booking.additionalCosts.length; i++) {
          booking.additionalCosts[i] = booking.additionalCosts[i].copyWith(
              isPendingRefund: false,
              isRefunded: false,
              isDisputed: true,
              paidBookingId: paidBookingId,
              refundBookingId: refundBooking.id);
        }

        writeBatch.set(bookingRef, booking.toMap(), SetOptions(merge: true));

        for (LessonAppointment appointment in refundBooking.lessonBookings) {
          final lessonRef = firestore
              .collection(Paths.classrooms)
              .doc(appointment.classroom.id)
              .collection(Paths.lessons)
              .doc(appointment.lesson.id);
          writeBatch.set(
              lessonRef, {'lessonDisputed': true}, SetOptions(merge: true));

          final lessonIndexRef = firestore
              .collection(Paths.tutorLessonIndex)
              .doc(appointment.lesson.id);

          writeBatch.set(lessonIndexRef, {'lessonDisputed': true},
              SetOptions(merge: true));
        }
      }
    } else {
      if (refundBooking.refundBookingType ==
          LessonBookingRefundType.lessonRefund) {
        final paidLessonBookingId = refundBooking.paidLessonBookingId;

        if (paidBookingId != null &&
            paidBookingId.isNotEmpty &&
            paidLessonBookingId != null &&
            paidLessonBookingId.isNotEmpty) {
          final paidBookingRef = firestore
              .collection(Paths.lessonBookings)
              .doc(refundBooking.paidBookingId);

          final doc = await paidBookingRef.get();

          if (doc.exists) {
            LessonBookingModel paidBooking =
                LessonBookingModel.fromMap(doc.data()!);

            List<LessonAppointment> appointments =
                List.from(paidBooking.lessonBookings);

            List<StripeDynamicLineItem> additionalCosts =
                List.from(paidBooking.additionalCosts);

            int index = appointments
                .indexWhere((a) => a.bookingId == paidLessonBookingId);

            if (index > -1) {
              appointments[index] = appointments[index].copyWith(
                  isPendingRefund: false,
                  isRefunded: false,
                  isDisputed: true,
                  paidBookingId: paidBookingId,
                  refundBookingId: refundBooking.id);
            }

            List<String> refundBookingIds =
                List.from(paidBooking.refundBookingIds ?? []);
            List<String> refundLessonBookingIds =
                List.from(paidBooking.refundLessonBookingIds ?? []);

            LessonAppointment? refundAppointment =
                refundBooking.lessonBookings.isNotEmpty
                    ? refundBooking.lessonBookings.first
                    : null;

            if (refundAppointment != null) {
              refundLessonBookingIds.remove(refundAppointment.bookingId);
            }

            if (refundLessonBookingIds.isEmpty) {
              refundBookingIds.remove(refundBooking.id);
            }

            final bookingType = paidBooking.refundBookingType;

            paidBooking = paidBooking.copyWith(
                refundStatus:
                    _allLineItemsRefunded(appointments, additionalCosts)
                        ? LessonBookingStatusType.refunded
                        : LessonBookingStatusType.partiallyRefunded,
                hasAssociatedRefundBooking: refundBookingIds.isNotEmpty,
                refundBookingType: refundBookingIds.isNotEmpty
                    ? bookingType
                    : LessonBookingRefundType.unknown,
                refundBookingIds: refundBookingIds,
                refundLessonBookingIds: refundLessonBookingIds,
                lessonBookings: appointments);

            writeBatch.update(
                paidBookingRef, paidBooking.toMapWithStripeInfo());

            for (LessonAppointment appointment
                in refundBooking.lessonBookings) {
              final payload = appointment.attendanceStatus != null
                  ? {
                      'lessonDisputed': true,
                      'attendanceStatusType':
                          appointment.attendanceStatus!.toMap(),
                    }
                  : {
                      'lessonDisputed': true,
                    };
              final lessonRef = firestore
                  .collection(Paths.classrooms)
                  .doc(appointment.classroom.id)
                  .collection(Paths.lessons)
                  .doc(appointment.lesson.id);
              writeBatch.set(lessonRef, payload, SetOptions(merge: true));

              final lessonIndexRef = firestore
                  .collection(Paths.tutorLessonIndex)
                  .doc(appointment.lesson.id);

              writeBatch.set(lessonIndexRef, payload, SetOptions(merge: true));
            }
          }
        }
      } else {
        final paidAdditionalCostId = refundBooking.paidAdditionalCostId;
        if (paidBookingId != null &&
            paidBookingId.isNotEmpty &&
            paidAdditionalCostId != null &&
            paidAdditionalCostId.isNotEmpty) {
          final paidBookingRef = firestore
              .collection(Paths.lessonBookings)
              .doc(refundBooking.paidBookingId);

          final doc = await paidBookingRef.get();

          if (doc.exists) {
            LessonBookingModel paidBooking =
                LessonBookingModel.fromMap(doc.data()!);
            List<LessonAppointment> appointments =
                List.from(paidBooking.lessonBookings);

            List<StripeDynamicLineItem> additionalCosts =
                List.from(paidBooking.additionalCosts);

            int index =
                additionalCosts.indexWhere((a) => a.id == paidAdditionalCostId);

            if (index > -1) {
              additionalCosts[index] = additionalCosts[index].copyWith(
                  isPendingRefund: false,
                  isRefunded: false,
                  isDisputed: true,
                  paidBookingId: paidBookingId,
                  refundBookingId: refundBooking.id);
            }

            List<String> refundBookingIds =
                List.from(paidBooking.refundBookingIds ?? []);
            List<String> refundAdditionalCostIds =
                List.from(paidBooking.refundAdditionalCostIds ?? []);

            StripeDynamicLineItem? refundAdditionalCost =
                refundBooking.additionalCosts.isNotEmpty
                    ? refundBooking.additionalCosts.first
                    : null;

            if (refundAdditionalCost != null) {
              refundAdditionalCostIds.remove(refundAdditionalCost.id);
            }

            if (refundAdditionalCostIds.isEmpty) {
              refundBookingIds.remove(refundBooking.id);
            }

            final bookingType = paidBooking.refundBookingType;

            paidBooking = paidBooking.copyWith(
                refundStatus:
                    _allLineItemsRefunded(appointments, additionalCosts)
                        ? LessonBookingStatusType.refunded
                        : LessonBookingStatusType.partiallyRefunded,
                hasAssociatedRefundBooking: refundBookingIds.isNotEmpty,
                refundBookingType: refundBookingIds.isNotEmpty
                    ? bookingType
                    : LessonBookingRefundType.unknown,
                refundBookingIds: refundBookingIds,
                refundAdditionalCostIds: refundAdditionalCostIds,
                additionalCosts: additionalCosts);

            writeBatch.update(
                paidBookingRef, paidBooking.toMapWithStripeInfo());
          }
        }
      }
    }

    await writeBatch.commit();

    return booking;
  }

  @override
  Future<AcceptBookingRefundResponse> acceptBookingRefund({
    required String firebaseToken,
    required String refundBookingUrl,
    required LessonBookingModel refundBooking,
    required User tutor,
    required double platformTransactionFee,
    required double platformPercentageRate,
  }) async {
    final url = Uri.parse(refundBookingUrl);
    debugPrint('Firebase token: $firebaseToken');

    double taxRate = 0;
    if (tutor.taxableRate != null && tutor.taxableRate! > 1) {
      taxRate = tutor.taxableRate! / 100;
    }
    final currencyCode = tutor.currencyCode ?? "AUD";

    final refundPayload = LessonBookingRefundPayload(
      paymentIntent: refundBooking.stripeCheckoutInfo!.paymentIntentId,
      bookingId: refundBooking.id,
      studentId: refundBooking.studentId,
      tutorId: refundBooking.tutorId,
      tutorAccountId: refundBooking.tutorAccountId,
      refundType: refundBooking.refundBookingType,
      lessonLineItems: refundBooking.costStructure.lineItems!
          .map((item) => StripeProductLineItem(
              price: item.stripePriceId!,
              quantity: 1,
              discount: item.discountDescription))
          .toList(),
      additionalCosts: refundBooking.additionalCosts,
      amount: refundBooking.costStructure.totalAmount,
      tutorNetRefundedAmount: refundBooking.costStructure.tutorNetIncome,
      paidBookingId: refundBooking.paidBookingId,
      taxRate: taxRate,
      taxLabel: tutor.taxLabel ?? "",
      currencyCode: currencyCode,
      currencySymbol: getCurrencySymbol(currencyCode),
      platformTransactionFee: platformTransactionFee,
      platformPercentageRate: platformPercentageRate,
    );

    final res = await http.post(url,
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer $firebaseToken',
        },
        body: refundPayload.toJson());

    if (res.statusCode == 200) {
      WriteBatch writeBatch = firestore.batch();
      final paidBookingId = refundBooking.paidBookingId;
      if (refundBooking.refundBookingType ==
          LessonBookingRefundType.fullRefund) {
        if (paidBookingId != null && paidBookingId.isNotEmpty) {
          final bookingRef =
              firestore.collection(Paths.lessonBookings).doc(paidBookingId);

          final bookingDoc = await bookingRef.get();
          LessonBookingModel booking =
              LessonBookingModel.fromMap(bookingDoc.data()!);
          booking =
              booking.copyWith(refundStatus: LessonBookingStatusType.refunded);

          for (int i = 0; i < booking.lessonBookings.length; i++) {
            booking.lessonBookings[i] = booking.lessonBookings[i].copyWith(
                isPendingRefund: false,
                isRefunded: true,
                paidBookingId: paidBookingId,
                refundBookingId: refundBooking.id);
          }

          for (int i = 0; i < booking.additionalCosts.length; i++) {
            booking.additionalCosts[i] = booking.additionalCosts[i].copyWith(
                isPendingRefund: false,
                isRefunded: true,
                paidBookingId: paidBookingId,
                refundBookingId: refundBooking.id);
          }

          writeBatch.set(bookingRef, booking.toMap(), SetOptions(merge: true));

          for (LessonAppointment appointment in refundBooking.lessonBookings) {
            final lessonRef = firestore
                .collection(Paths.classrooms)
                .doc(appointment.classroom.id)
                .collection(Paths.lessons)
                .doc(appointment.lesson.id);
            writeBatch.set(
                lessonRef, {'lessonRefunded': true}, SetOptions(merge: true));

            final lessonIndexRef = firestore
                .collection(Paths.tutorLessonIndex)
                .doc(appointment.lesson.id);

            writeBatch.set(lessonIndexRef, {'lessonRefunded': true},
                SetOptions(merge: true));
          }
        }
      } else {
        if (refundBooking.refundBookingType ==
            LessonBookingRefundType.lessonRefund) {
          final paidLessonBookingId = refundBooking.paidLessonBookingId;

          if (paidBookingId != null &&
              paidBookingId.isNotEmpty &&
              paidLessonBookingId != null &&
              paidLessonBookingId.isNotEmpty) {
            final paidBookingRef = firestore
                .collection(Paths.lessonBookings)
                .doc(refundBooking.paidBookingId);

            final doc = await paidBookingRef.get();

            if (doc.exists) {
              LessonBookingModel paidBooking =
                  LessonBookingModel.fromMap(doc.data()!);

              List<LessonAppointment> appointments =
                  List.from(paidBooking.lessonBookings);

              List<StripeDynamicLineItem> additionalCosts =
                  List.from(paidBooking.additionalCosts);

              if (additionalCosts.isNotEmpty &&
                  _getNumberOfNonRefundedBookings(appointments) <= 1) {
                final payoutSchedule = getNextPayoutExecutionKey(
                    tutor.payoutCadence ?? PayoutCadenceType.daily,
                    tutor.lastPayoutDate,
                    3);

                for (int i = 0; i < additionalCosts.length; i++) {
                  var additionalCost = additionalCosts[i];
                  if (_additionalCostRequiresPayout(additionalCost)) {
                    await _addPayoutDirectiveToQueue(PayoutDirectiveModel(
                      payoutType: PayoutType.additionalCost,
                      tutorId: tutor.id,
                      tutorEmail: tutor.email,
                      tutorFirstName: tutor.firstName ?? '',
                      tutorLastName: tutor.lastName ?? '',
                      stripeAccountId: tutor.stripeAccountId,
                      tutorCountryCode: tutor.countryCode,
                      tutorCurrencyCode: tutor.currencyCode,
                      tutorCurrencySymbol:
                          getCurrencySymbol(tutor.currencyCode ?? 'AUD'),
                      classroomId:
                          '${refundBooking.tutorId}_${refundBooking.studentId}',
                      subjectId: "",
                      lessonBookingId: refundBooking.paidBookingId,
                      bookingId: additionalCost.bookingId,
                      executionKey: payoutSchedule.executionKey,
                      maxAttempts: 14,
                      numberOfAttempts: 0,
                      logs: const [],
                      processed: false,
                    ));

                    additionalCosts[i] = additionalCost.copyWith(
                        isPendingPayOut: true,
                        scheduledPayoutDate:
                            payoutSchedule.scheduledPayoutDate);

                    paidBooking =
                        paidBooking.copyWith(additionalCosts: additionalCosts);
                  }
                }
              }

              int index = appointments
                  .indexWhere((a) => a.bookingId == paidLessonBookingId);

              if (index > -1) {
                appointments[index] = appointments[index].copyWith(
                    isPendingRefund: false,
                    isRefunded: true,
                    paidBookingId: paidBookingId,
                    refundBookingId: refundBooking.id);
              }

              List<String> refundBookingIds =
                  List.from(paidBooking.refundBookingIds ?? []);
              List<String> refundLessonBookingIds =
                  List.from(paidBooking.refundLessonBookingIds ?? []);

              LessonAppointment? refundAppointment =
                  refundBooking.lessonBookings.isNotEmpty
                      ? refundBooking.lessonBookings.first
                      : null;

              if (refundAppointment != null) {
                refundLessonBookingIds.remove(refundAppointment.bookingId);
              }

              if (refundLessonBookingIds.isEmpty) {
                refundBookingIds.remove(refundBooking.id);
              }

              final bookingType = paidBooking.refundBookingType;

              paidBooking = paidBooking.copyWith(
                  refundStatus:
                      _allLineItemsRefunded(appointments, additionalCosts)
                          ? LessonBookingStatusType.refunded
                          : LessonBookingStatusType.partiallyRefunded,
                  hasAssociatedRefundBooking: refundBookingIds.isNotEmpty,
                  refundBookingType: refundBookingIds.isNotEmpty
                      ? bookingType
                      : LessonBookingRefundType.unknown,
                  refundBookingIds: refundBookingIds,
                  refundLessonBookingIds: refundLessonBookingIds,
                  lessonBookings: appointments);

              writeBatch.update(
                  paidBookingRef, paidBooking.toMapWithStripeInfo());

              for (LessonAppointment appointment
                  in refundBooking.lessonBookings) {
                final payload = appointment.attendanceStatus != null
                    ? {
                        'lessonRefunded': true,
                        'attendanceStatusType':
                            appointment.attendanceStatus!.toMap(),
                      }
                    : {
                        'lessonRefunded': true,
                      };
                final lessonRef = firestore
                    .collection(Paths.classrooms)
                    .doc(appointment.classroom.id)
                    .collection(Paths.lessons)
                    .doc(appointment.lesson.id);
                writeBatch.set(lessonRef, payload, SetOptions(merge: true));

                final lessonIndexRef = firestore
                    .collection(Paths.tutorLessonIndex)
                    .doc(appointment.lesson.id);

                writeBatch.set(
                    lessonIndexRef, payload, SetOptions(merge: true));
              }
            }
          }
        } else {
          // Additional Cost Refund
          final paidAdditionalCostId = refundBooking.paidAdditionalCostId;
          if (paidBookingId != null &&
              paidBookingId.isNotEmpty &&
              paidAdditionalCostId != null &&
              paidAdditionalCostId.isNotEmpty) {
            final paidBookingRef = firestore
                .collection(Paths.lessonBookings)
                .doc(refundBooking.paidBookingId);

            final doc = await paidBookingRef.get();

            if (doc.exists) {
              LessonBookingModel paidBooking =
                  LessonBookingModel.fromMap(doc.data()!);
              List<LessonAppointment> appointments =
                  List.from(paidBooking.lessonBookings);

              List<StripeDynamicLineItem> additionalCosts =
                  List.from(paidBooking.additionalCosts);

              int index = additionalCosts
                  .indexWhere((a) => a.id == paidAdditionalCostId);

              if (index > -1) {
                additionalCosts[index] = additionalCosts[index].copyWith(
                    isPendingRefund: false,
                    isRefunded: true,
                    paidBookingId: paidBookingId,
                    refundBookingId: refundBooking.id);
              }

              List<String> refundBookingIds =
                  List.from(paidBooking.refundBookingIds ?? []);
              List<String> refundAdditionalCostIds =
                  List.from(paidBooking.refundAdditionalCostIds ?? []);

              StripeDynamicLineItem? refundAdditionalCost =
                  refundBooking.additionalCosts.isNotEmpty
                      ? refundBooking.additionalCosts.first
                      : null;

              if (refundAdditionalCost != null) {
                refundAdditionalCostIds.remove(refundAdditionalCost.id);
              }

              if (refundAdditionalCostIds.isEmpty) {
                refundBookingIds.remove(refundBooking.id);
              }

              final bookingType = paidBooking.refundBookingType;

              paidBooking = paidBooking.copyWith(
                  refundStatus:
                      _allLineItemsRefunded(appointments, additionalCosts)
                          ? LessonBookingStatusType.refunded
                          : LessonBookingStatusType.partiallyRefunded,
                  hasAssociatedRefundBooking: refundBookingIds.isNotEmpty,
                  refundBookingType: refundBookingIds.isNotEmpty
                      ? bookingType
                      : LessonBookingRefundType.unknown,
                  refundBookingIds: refundBookingIds,
                  refundAdditionalCostIds: refundAdditionalCostIds,
                  additionalCosts: additionalCosts);

              writeBatch.update(
                  paidBookingRef, paidBooking.toMapWithStripeInfo());
            }
          }
        }
      }

      // Update the refund booking
      refundBooking =
          refundBooking.copyWith(status: LessonBookingStatusType.refunded);

      final refundBookingRef =
          firestore.collection(Paths.lessonBookings).doc(refundBooking.id);
      if (refundBooking.refundInitiatorRoleType == TuiiRoleType.tutor) {
        writeBatch.set(refundBookingRef, refundBooking.toMapWithStripeInfo());
      } else {
        writeBatch.update(
            refundBookingRef, refundBooking.toMapWithStripeInfo());
      }

      await writeBatch.commit();

      final bookingDoc = await firestore
          .collection(Paths.lessonBookings)
          .doc(paidBookingId)
          .get();

      final paidBooking = LessonBookingModel.fromMap(bookingDoc.data()!);

      // Return the refund booking
      return AcceptBookingRefundResponse(
          refundBooking: refundBooking, paidBooking: paidBooking);
    } else if (res.statusCode == 402) {
      throw const Failure(
          message:
              'Refund failed: Insufficient funds available in Stripe account.');
    } else {
      final response = RefundResponseModel.fromJson(res.body);
      throw Failure(message: response.message ?? 'Stripe refund failed!');
    }
  }

  @override
  Future<LessonBookingModel?> getLessonBooking(
      {required String bookingId,
      required TuiiRoleType roleType,
      required String userId}) async {
    final fieldName = roleType == TuiiRoleType.tutor ? 'tutorId' : 'studentId';
    final doc = await firestore
        .collection(Paths.lessonBookings)
        .where(fieldName, isEqualTo: userId)
        .where('id', isEqualTo: bookingId)
        .get();

    if (doc.docs.isNotEmpty) {
      return LessonBookingModel.fromMap(doc.docs[0].data());
    }

    return null;
  }

  int _getNumberOfNonRefundedBookings(List<LessonAppointment> appointments) {
    return appointments.fold(
        0, (count, apt) => apt.isRefunded != true ? ++count : count);
  }

  bool _additionalCostRequiresPayout(StripeDynamicLineItem additionalCost) {
    return (additionalCost.isPendingRefund != true &&
        additionalCost.isRefunded != true &&
        additionalCost.isDisputed != true &&
        additionalCost.isPaidOut != true &&
        additionalCost.isPendingPayOut != true &&
        getAdditionalCostPrice(additionalCost) > 0);
  }

  Future<bool> _addPayoutDirectiveToQueue(
      PayoutDirectiveModel payoutDirective) async {
    try {
      DocumentReference directiveRef =
          firestore.collection(Paths.payoutQueue).doc();

      final directive = payoutDirective.copyWith(id: directiveRef.id);
      await firestore
          .collection(Paths.payoutQueue)
          .doc(directiveRef.id)
          .set(directive.toMap());

      return true;
    } catch (e) {
      return false;
    }
  }

  bool _allLineItemsRefunded(List<LessonAppointment> appointments,
      List<StripeDynamicLineItem> additionalCosts) {
    bool allRefunded = true;
    for (LessonAppointment appt in appointments) {
      if (appt.isRefunded != true) {
        allRefunded = false;
        break;
      }
    }

    if (allRefunded == true) {
      for (StripeDynamicLineItem cost in additionalCosts) {
        if (cost.isRefunded != true) {
          allRefunded = false;
          break;
        }
      }
    }

    return allRefunded;
  }

  WriteBatch _processClassroomForNextLessonDate(
      WriteBatch writeBatch,
      ClassroomModel classroom,
      TutorHomeModel tutorHome,
      StudentHomeModel studentHome,
      DocumentReference classroomRef,
      DocumentReference tutorHomeRef,
      DocumentReference studentHomeRef,
      DateTime nextLessonStartDate) {
    classroom = classroom.copyWith(nextLessonStartDate: nextLessonStartDate);

    List<ClassroomModel> tutorHomeClassrooms =
        List.from(tutorHome.classrooms ?? []);
    tutorHome = tutorHome.copyWith(
        classrooms: _processHomeClassrooms(classroom, tutorHomeClassrooms));

    List<ClassroomModel> studentHomeClassrooms =
        List.from(studentHome.classrooms ?? []);
    studentHome = studentHome.copyWith(
        classrooms: _processHomeClassrooms(classroom, studentHomeClassrooms));

    writeBatch.set(classroomRef, classroom.toMap());
    writeBatch.set(tutorHomeRef, tutorHome.toMap());
    writeBatch.set(studentHomeRef, studentHome.toMap());
    return writeBatch;
  }

  List<ClassroomModel> _processHomeClassrooms(
      ClassroomModel classroom, List<ClassroomModel> homeClassrooms) {
    for (int i = 0; i < homeClassrooms.length; i++) {
      ClassroomModel room = homeClassrooms[i];
      if (room.id == classroom.id) {
        room =
            room.copyWith(nextLessonStartDate: classroom.nextLessonStartDate);
        homeClassrooms[i] = room;
        break;
      }
    }

    return homeClassrooms;
  }
}
