import 'package:flutter_riverpod/flutter_riverpod.dart';

class OneOffTicket {
  final DateTime expiresAt;
  const OneOffTicket({required this.expiresAt});
  bool get isActive => expiresAt.isAfter(DateTime.now());
}

class PaymentTransaction {
  final String id;
  final DateTime createdAt;
  final double amount;
  final String currency;
  final String methodType;
  final String methodLabel;
  final String reason;

  final String status;

  const PaymentTransaction({
    required this.id,
    required this.createdAt,
    required this.amount,
    required this.currency,
    required this.methodType,
    required this.methodLabel,
    required this.reason,
    required this.status,
  });
}

class PaymentState {
  final String? method;

  final String? defaultMethodType;

  final OneOffTicket? activeTicket;
  final double? lastCharge;
  final bool preAuthorized;

  final List<PaymentTransaction> history;

  const PaymentState({
    this.method,
    this.defaultMethodType,
    this.activeTicket,
    this.lastCharge,
    this.preAuthorized = false,
    this.history = const [],
  });

  bool get hasMethod => method != null && method!.isNotEmpty;

  bool get hasDefaultMethod =>
      defaultMethodType != null && defaultMethodType!.isNotEmpty;

  String get defaultMethodLabel {
    switch (defaultMethodType) {
      case 'apple_pay':
        return 'Apple Pay';
      case 'google_pay':
        return 'Google Pay';
      case 'card':
        return hasMethod ? 'Card •••• $method' : 'Card';
      default:
        return hasMethod ? 'Card •••• $method' : 'Not selected';
    }
  }

  PaymentState copyWith({
    String? method,
    String? defaultMethodType,
    OneOffTicket? activeTicket,
    double? lastCharge,
    bool? preAuthorized,
    List<PaymentTransaction>? history,
    bool clearDefaultMethodType = false,
  }) {
    return PaymentState(
      method: method ?? this.method,
      defaultMethodType: clearDefaultMethodType
          ? null
          : (defaultMethodType ?? this.defaultMethodType),
      activeTicket: activeTicket ?? this.activeTicket,
      lastCharge: lastCharge ?? this.lastCharge,
      preAuthorized: preAuthorized ?? this.preAuthorized,
      history: history ?? this.history,
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  PaymentNotifier() : super(const PaymentState());

  void save(String method) {
    state = state.copyWith(method: method);
  }

  void setPaymentMethod(String number) {
    final cleaned = number.replaceAll(' ', '');
    final last4 =
        cleaned.length >= 4 ? cleaned.substring(cleaned.length - 4) : cleaned;
    state = state.copyWith(method: last4);
  }

  void setDefaultMethodType(String type) {
    state = state.copyWith(defaultMethodType: type);
  }

  void clearDefaultMethodType() {
    state = state.copyWith(clearDefaultMethodType: true);
  }

  void buyTicket3h() {
    final expiresAt = DateTime.now().add(const Duration(hours: 3));
    state = state.copyWith(activeTicket: OneOffTicket(expiresAt: expiresAt));
  }

  Future<void> charge(
    double amount, {
    String currency = 'EUR',
    String reason = 'Payment',
    String? placeLabel,
  }) async {
    final now = DateTime.now();

    final methodType =
        state.defaultMethodType ?? (state.hasMethod ? 'card' : 'card');
    final methodLabel = state.defaultMethodLabel;

    final tx = PaymentTransaction(
      id: '${now.microsecondsSinceEpoch}',
      createdAt: now,
      amount: amount,
      currency: currency,
      methodType: methodType,
      methodLabel: methodLabel,
      reason: reason,
      status: (placeLabel ?? '').trim(),
    );

    state = state.copyWith(
      lastCharge: amount,
      history: [tx, ...state.history],
    );

    await Future.delayed(const Duration(milliseconds: 300));
  }

  void setPreAuthorized(bool value) {
    state = state.copyWith(preAuthorized: value);
  }

  void resetPreAuthorization() {
    state = state.copyWith(preAuthorized: false);
  }

  void clearHistory() {
    state = state.copyWith(history: []);
  }
}

final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>(
  (ref) => PaymentNotifier(),
);
