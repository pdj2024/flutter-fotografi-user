class CreatePesananResult {
  final String noBukti;
  final String noTracking;
  final bool paymentSuccess;
  final String? paymentMessage;

  CreatePesananResult({
    required this.noBukti,
    required this.noTracking,
    required this.paymentSuccess,
    this.paymentMessage,
  });

  factory CreatePesananResult.fromJson(Map<String, dynamic> json) {
    final buat = json['BuatPesanan'];
    final payment = json['Payment'];

    return CreatePesananResult(
      noBukti: buat['NewId'],
      noTracking: buat['NoTrackingPesanan'],
      paymentSuccess: payment?['StatusCode'] == 200,
      paymentMessage: payment?['Message'],
    );
  }
}
