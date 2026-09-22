class RefundRuleModel {
  final String noId;
  final int jamLimit;
  final double persen;
  final String keterangan;

  RefundRuleModel({
    required this.noId,
    required this.jamLimit,
    required this.persen,
    this.keterangan = "",
  });

  factory RefundRuleModel.fromJson(Map<String, dynamic> json) {
    return RefundRuleModel(
      noId: json['No_Id']?.toString() ?? '',
      jamLimit: (json['Jam_Limit'] as num?)?.toInt() ?? 0,
      persen: (json['Persen'] as num?)?.toDouble() ?? 0.0,
      keterangan: json['Keterangan']?.toString() ?? '',
    );
  }
}
