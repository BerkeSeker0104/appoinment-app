class SystemConfigModel {
  final double productCommissionRate;
  final double commissionRate;
  final double refundRate;

  SystemConfigModel({
    required this.productCommissionRate,
    required this.commissionRate,
    required this.refundRate,
  });

  factory SystemConfigModel.fromJson(Map<String, dynamic> json) {
    return SystemConfigModel(
      productCommissionRate:
          double.tryParse(json['productCommissionRate'].toString()) ?? 0.0,
      commissionRate: double.tryParse(json['commissionRate'].toString()) ?? 0.0,
      refundRate: double.tryParse(json['refundRate'].toString()) ?? 0.0,
    );
  }
}


