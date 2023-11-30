import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tuiientitymodels/files/calendar/data/models/payout_batch_manifest_model.dart';
import 'package:tuiicalendar_domain_data_firestore/files/domain/repositories/lesson_booking_repository.dart';

class PayoutManifestsStreamManager {
  bool _streamInitialized = false;

  final List<StreamSubscription<List<Future<PayoutBatchManifestModel>>>?>
      _payoutManifestsSubscriptions = [];

  StreamController<List<PayoutBatchManifestModel>>? _streamController;

  PayoutManifestsStreamManager(
      {required this.userId,
      required this.batchStartDate,
      required this.repository}) {
    _streamController = StreamController<List<PayoutBatchManifestModel>>();
  }

  final String userId;
  final DateTime batchStartDate;
  // TB: DEEPLINKS HERE
  final CalendarLessonBookingRepository repository;

  Stream<List<PayoutBatchManifestModel>> get stream =>
      _streamController!.stream.asBroadcastStream();

  void close() {
    // _payloadQueueTimer.cancel();
    for (var sub in _payoutManifestsSubscriptions) {
      try {
        sub?.cancel();
      } catch (e) {
        debugPrint('Payout manifests subscription cancellation failed.');
      }
    }
  }

  void init() {
    if (_streamInitialized != true) {
      _initStream();
    }
  }

  void _initStream() {
    final payoutsEither = repository.getPayoutStream(
        userId: userId, batchStartDate: batchStartDate);
    payoutsEither.fold((error) {
      // TODO: ERROR LOGGING INFRASTRUCTURE
      // errorLog.add(error.message ?? '');
      debugPrint('Failed to open payouts stream.  Message: ${error.message}');
    }, (payoutsStream) {
      _streamInitialized = true;
      var sub = payoutsStream.listen((payoutFutures) async {
        final payouts = await Future.wait(payoutFutures);
        payouts.sort((a, b) => (a.batchRunDate!).compareTo(b.batchRunDate!));

        _streamController?.sink.add(payouts.reversed.toList());
      });

      _payoutManifestsSubscriptions.add(sub);
    });
  }
}
