class CustomerLookupResult {
  const CustomerLookupResult({
    required this.exists,
    this.customer,
    this.subscription,
  });

  final bool exists;
  final LookupCustomer? customer;
  final LookupSubscription? subscription;

  factory CustomerLookupResult.fromJson(Map<String, dynamic> json) {
    final exists = _toBool(json['exists']);
    if (!exists) {
      return const CustomerLookupResult(exists: false);
    }

    final rawCustomer = json['customer'];
    final rawSubscription = json['subscription'];

    return CustomerLookupResult(
      exists: true,
      customer: rawCustomer is Map
          ? LookupCustomer.fromJson(Map<String, dynamic>.from(rawCustomer))
          : null,
      subscription: rawSubscription is Map
          ? LookupSubscription.fromJson(Map<String, dynamic>.from(rawSubscription))
          : null,
    );
  }
}

class LookupCustomer {
  const LookupCustomer({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.mobile,
    required this.status,
  });

  final int id;
  final String name;
  final String username;
  final String? email;
  final String? phone;
  final String mobile;
  final String? status;

  factory LookupCustomer.fromJson(Map<String, dynamic> json) {
    return LookupCustomer(
      id: _toInt(json['id']),
      name: _toString(json['name']),
      username: _toString(json['username']),
      email: _toNullableString(json['email']),
      phone: _toNullableString(json['phone']),
      mobile: _toString(json['mobile']),
      status: _toNullableString(json['status']),
    );
  }
}

class LookupSubscription {
  const LookupSubscription({
    required this.id,
    required this.serviceId,
    required this.groupId,
    required this.status,
    required this.radiusStatus,
    required this.startDate,
    required this.endDate,
    required this.isOnline,
    required this.debitBalance,
  });

  final int id;
  final int serviceId;
  final int groupId;
  final String? status;
  final String? radiusStatus;
  final String? startDate;
  final String? endDate;
  final bool isOnline;
  final double debitBalance;

  factory LookupSubscription.fromJson(Map<String, dynamic> json) {
    return LookupSubscription(
      id: _toInt(json['id']),
      serviceId: _toInt(json['service_id']),
      groupId: _toInt(json['group_id']),
      status: _toNullableString(json['status']),
      radiusStatus: _toNullableString(json['radius_status']),
      startDate: _toNullableString(json['start_date']),
      endDate: _toNullableString(json['end_date']),
      isOnline: _toBool(json['is_online']),
      debitBalance: _toDouble(json['debit_balance']),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value?.toString().toLowerCase().trim();
  return normalized == 'true' || normalized == '1' || normalized == 'yes';
}

String _toString(dynamic value) => value?.toString() ?? '';

String? _toNullableString(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}
