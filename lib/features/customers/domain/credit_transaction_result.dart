class CreditTransactionResult {
  const CreditTransactionResult({
    required this.message,
    required this.transactionNumber,
    required this.customerId,
    required this.customerName,
    required this.subscriptionId,
    required this.mobile,
    required this.creditBalance,
    required this.debitBalance,
  });

  final String message;
  final int transactionNumber;
  final int customerId;
  final String customerName;
  final int subscriptionId;
  final String mobile;
  final double creditBalance;
  final double debitBalance;

  factory CreditTransactionResult.fromJson(Map<String, dynamic> json) {
    final rawCustomer = json['customer'];
    final rawSubscription = json['subscription'];
    final customer = Map<String, dynamic>.from(rawCustomer is Map ? rawCustomer : const {});
    final subscription =
        Map<String, dynamic>.from(rawSubscription is Map ? rawSubscription : const {});

    return CreditTransactionResult(
      message: json['message']?.toString() ?? '',
      transactionNumber: _toInt(json['transaction_number']),
      customerId: _toInt(customer['id']),
      customerName: customer['name']?.toString() ?? '',
      subscriptionId: _toInt(subscription['id']),
      mobile: subscription['mobile']?.toString() ?? '',
      creditBalance: _toDouble(subscription['credit_balance']),
      debitBalance: _toDouble(subscription['debit_balance']),
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

