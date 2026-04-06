class AppUser {
  const AppUser({
    required this.id,
    required this.ownerId,
    required this.username,
    required this.name,
    required this.email,
    required this.mobile,
    required this.status,
    required this.userType,
    required this.hasCreditAccount,
    required this.creditBalance,
    required this.debitBalance,
  });

  final int id;
  final int ownerId;
  final String username;
  final String name;
  final String? email;
  final String? mobile;
  final String? status;
  final String? userType;
  final bool hasCreditAccount;
  final double creditBalance;
  final double debitBalance;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: _toInt(json['id']),
      ownerId: _toInt(json['owner_id']),
      username: _toString(json['username']),
      name: _toString(json['name']),
      email: _toNullableString(json['email']),
      mobile: _toNullableString(json['mobile']),
      status: _toNullableString(json['status']),
      userType: _toNullableString(json['user_type']),
      hasCreditAccount:
          _toString(json['credit_account']).toLowerCase() == 'yes',
      creditBalance: _toDouble(json['credit_balance']),
      debitBalance: _toDouble(json['debit_balance']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'username': username,
      'name': name,
      'email': email,
      'mobile': mobile,
      'status': status,
      'user_type': userType,
      'credit_account': hasCreditAccount ? 'yes' : 'no',
      'credit_balance': creditBalance,
      'debit_balance': debitBalance,
    };
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
