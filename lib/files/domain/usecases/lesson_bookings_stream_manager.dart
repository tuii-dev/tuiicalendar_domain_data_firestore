import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tuiicore/core/enums/tuii_role_type.dart';
import 'package:tuiientitymodels/files/calendar/data/models/lesson_booking_model.dart';
import 'package:tuiicalendar_domain_data_firestore/files/domain/repositories/lesson_booking_repository.dart';

class LessonBookingsStreamManager {
  final List<StreamSubscription<List<Future<LessonBookingModel>>>?>
      _lessonBookingsSubscriptions = [];

  StreamController<List<LessonBookingModel>>? _streamController;

  LessonBookingsStreamManager(
      {required this.roleType,
      required this.userId,
      required this.lessonBookingStartDate,
      required this.repository}) {
    _streamController = StreamController<List<LessonBookingModel>>();
  }

  final TuiiRoleType roleType;
  final String userId;
  final DateTime lessonBookingStartDate;
  // TB: DEEPLINKS HERE
  final CalendarLessonBookingRepository repository;

  Stream<List<LessonBookingModel>> get stream =>
      _streamController!.stream.asBroadcastStream();

  void close() {
    // _payloadQueueTimer.cancel();
    for (var sub in _lessonBookingsSubscriptions) {
      try {
        sub?.cancel();
      } catch (e) {
        debugPrint('Lesson index subscription cancellation failed.');
      }
    }
  }

  void init() {
    _initStream();
  }

  void _initStream() {
    final lessonBookingsEither = repository.getLessonBookingStream(
        roleType: roleType,
        userId: userId,
        lessonBookingStartDate: lessonBookingStartDate);
    lessonBookingsEither.fold((error) {
      // TODO: ERROR LOGGING INFRASTRUCTURE
      // errorLog.add(error.message ?? '');
      debugPrint(
          'Failed to open lesson booking stream.  Message: ${error.message}');
    }, (lessonBookingStream) {
      var sub = lessonBookingStream.listen((lessonBookingFutures) async {
        final lessonBookings = await Future.wait(lessonBookingFutures);
        lessonBookings
            .sort((a, b) => (a.lastUpdatedDate).compareTo(b.lastUpdatedDate));

        _streamController?.sink.add(lessonBookings.reversed.toList());
      });

      _lessonBookingsSubscriptions.add(sub);
    });
  }
}
