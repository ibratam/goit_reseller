class CustomerServiceRecord {
  const CustomerServiceRecord({
    required this.id,
    required this.customerId,
    required this.serviceId,
    required this.groupId,
    required this.subscriptionName,
    required this.mobile,
    required this.username,
    required this.status,
    required this.radiusStatus,
    required this.startDate,
    required this.endDate,
    required this.isOnline,
    required this.effectivePrice,
    required this.creditBalance,
    required this.debitBalance,
    required this.customer,
    required this.service,
  });

  final int id;
  final int customerId;
  final int serviceId;
  final int groupId;
  final String subscriptionName;
  final String mobile;
  final String username;
  final String? status;
  final String? radiusStatus;
  final String? startDate;
  final String? endDate;
  final bool isOnline;
  final double? effectivePrice;
  final double creditBalance;
  final double debitBalance;
  final CustomerSummary customer;
  final ServiceSummary service;

  factory CustomerServiceRecord.fromJson(Map<String, dynamic> json) {
    final rawCustomer = json['customer'];
    final rawService = json['service'];

    return CustomerServiceRecord(
      id: _toInt(json['id']),
      customerId: _toInt(json['customer_id']),
      serviceId: _toInt(json['service_id']),
      groupId: _toInt(json['group_id']),
      subscriptionName: _toString(json['name']),
      mobile: _toString(json['mobile']),
      username: _toString(json['username']),
      status: _toNullableString(json['status']),
      radiusStatus: _toNullableString(json['radius_status']),
      startDate: _toNullableString(json['start_date']),
      endDate: _toNullableString(json['end_date']),
      isOnline: _toBool(json['is_online']),
      effectivePrice: _toNullableDouble(json['effective_price']),
      creditBalance: _toDouble(json['credit_balance']),
      debitBalance: _toDouble(json['debit_balance']),
      customer: CustomerSummary.fromJson(
        Map<String, dynamic>.from(rawCustomer is Map ? rawCustomer : const {}),
      ),
      service: ServiceSummary.fromJson(
        Map<String, dynamic>.from(rawService is Map ? rawService : const {}),
      ),
    );
  }

  CustomerServiceRecord copyWith({
    double? creditBalance,
    double? debitBalance,
  }) {
    return CustomerServiceRecord(
      id: id,
      customerId: customerId,
      serviceId: serviceId,
      groupId: groupId,
      subscriptionName: subscriptionName,
      mobile: mobile,
      username: username,
      status: status,
      radiusStatus: radiusStatus,
      startDate: startDate,
      endDate: endDate,
      isOnline: isOnline,
      effectivePrice: effectivePrice,
      creditBalance: creditBalance ?? this.creditBalance,
      debitBalance: debitBalance ?? this.debitBalance,
      customer: customer,
      service: service,
    );
  }
}

class CustomerSummary {
  const CustomerSummary({
    required this.id,
    required this.name,
    required this.mobile,
    required this.status,
  });

  final int id;
  final String name;
  final String mobile;
  final String? status;

  factory CustomerSummary.fromJson(Map<String, dynamic> json) {
    return CustomerSummary(
      id: _toInt(json['id']),
      name: _toString(json['name']),
      mobile: _toString(json['mobile']),
      status: _toNullableString(json['status']),
    );
  }
}

class ServiceSummary {
  const ServiceSummary({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory ServiceSummary.fromJson(Map<String, dynamic> json) {
    return ServiceSummary(
      id: _toInt(json['id']),
      name: _toString(json['name']),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _toNullableDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }

  final normalized = value.toString().trim();
  if (normalized.isEmpty) {
    return null;
  }

  return double.tryParse(normalized);
}

bool _toBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  final normalized = value?.toString().toLowerCase().trim();
  return normalized == 'true' || normalized == '1' || normalized == 'yes';
}

String _toString(dynamic value) {
  return value?.toString() ?? '';
}

String? _toNullableString(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) {
    return null;
  }
  return text;
}
