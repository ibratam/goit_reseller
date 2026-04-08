class ServiceExtensionResult {
  const ServiceExtensionResult({
    required this.customerServiceId,
    required this.startExtendedDate,
    required this.endExtendedDate,
    this.extendDays,
    this.extendPrice,
  });

  final int customerServiceId;
  final String startExtendedDate;
  final String endExtendedDate;
  final int? extendDays;
  final double? extendPrice;

  factory ServiceExtensionResult.fromJson(Map<String, dynamic> json) {
    return ServiceExtensionResult(
      customerServiceId: _toInt(json['customer_service_id']),
      startExtendedDate: _toString(json['start_extended_date']),
      endExtendedDate: _toString(json['end_extended_date']),
      extendDays: json.containsKey('extend_days') ? _toInt(json['extend_days']) : null,
      extendPrice: _toNullableDouble(json['extend_price']),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _toString(dynamic value) => value?.toString() ?? '';

double? _toNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  final normalized = value.toString().trim();
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}
