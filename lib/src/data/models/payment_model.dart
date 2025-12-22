class PaymentModel {
  final int statusCode;
  final String message;
  final MidtransPayment midtrans;

  PaymentModel({
    required this.statusCode,
    required this.message,
    required this.midtrans,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      statusCode: json['StatusCode'],
      message: json['Message'],
      midtrans: MidtransPayment.fromJson(json['MidtransResponse']),
    );
  }
}

class MidtransPayment {
  final String transactionId;
  final String orderId;
  final String paymentType;
  final String transactionStatus;
  final String grossAmount;
  final String currency;
  final DateTime transactionTime;
  final DateTime expiryTime;
  final List<PaymentAction> actions;

  MidtransPayment({
    required this.transactionId,
    required this.orderId,
    required this.paymentType,
    required this.transactionStatus,
    required this.grossAmount,
    required this.currency,
    required this.transactionTime,
    required this.expiryTime,
    required this.actions,
  });

  factory MidtransPayment.fromJson(Map<String, dynamic> json) {
    return MidtransPayment(
      transactionId: json['transaction_id'],
      orderId: json['order_id'],
      paymentType: json['payment_type'],
      transactionStatus: json['transaction_status'],
      grossAmount: json['gross_amount'],
      currency: json['currency'],
      transactionTime: DateTime.parse(json['transaction_time']),
      expiryTime: DateTime.parse(json['expiry_time']),
      actions: (json['actions'] as List)
          .map((e) => PaymentAction.fromJson(e))
          .toList(),
    );
  }

  /// 🔥 Helper status
  bool get isPending => transactionStatus == 'pending';
  bool get isSuccess => transactionStatus == 'settlement';
  bool get isExpired => DateTime.now().isAfter(expiryTime);

  /// 🔥 Helper URL
  String? get qrUrl => actions
      .firstWhere(
        (a) => a.name.contains('qr'),
        orElse: () => PaymentAction.empty(),
      )
      .url;
}

class PaymentAction {
  final String name;
  final String method;
  final String url;

  PaymentAction({
    required this.name,
    required this.method,
    required this.url,
  });

  factory PaymentAction.fromJson(Map<String, dynamic> json) {
    return PaymentAction(
      name: json['name'],
      method: json['method'],
      url: json['url'],
    );
  }

  factory PaymentAction.empty() => PaymentAction(name: '', method: '', url: '');
}
