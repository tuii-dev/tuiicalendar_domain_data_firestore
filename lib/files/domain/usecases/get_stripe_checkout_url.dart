import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/models/stripe_payment_model.dart';
import 'package:tuiicore/core/usecases/usecase.dart';
import 'package:tuiicalendar_domain_data_firestore/files/domain/repositories/lesson_booking_repository.dart';

class GetStripeCheckoutUrlUseCase
    implements UseCase<String, GetStripeCheckoutUrlParams> {
  final CalendarLessonBookingRepository repository;

  GetStripeCheckoutUrlUseCase({required this.repository});

  @override
  Future<Either<Failure, String>> call(
      GetStripeCheckoutUrlParams params) async {
    return await repository.getStripeCheckoutUrl(
        firebaseToken: params.firebaseToken,
        createSessionUrl: params.createSessionUrl,
        payment: params.payment);
  }
}

class GetStripeCheckoutUrlParams extends Equatable {
  final String firebaseToken;
  final String createSessionUrl;
  final StripePaymentModel payment;

  const GetStripeCheckoutUrlParams({
    required this.firebaseToken,
    required this.createSessionUrl,
    required this.payment,
  });

  @override
  List<Object> get props => [firebaseToken, createSessionUrl, payment];
}
