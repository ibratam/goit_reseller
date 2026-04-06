class TransactionHistoryQuery {
  const TransactionHistoryQuery({
    this.perPage = 20,
    this.transactionType,
    this.operationType,
    this.paymentMethod,
    this.startDate,
    this.endDate,
  });

  final int perPage;
  final String? transactionType;
  final String? operationType;
  final String? paymentMethod;
  final String? startDate;
  final String? endDate;

  TransactionHistoryQuery copyWith({
    int? perPage,
    String? transactionType,
    bool clearTransactionType = false,
    String? operationType,
    bool clearOperationType = false,
    String? paymentMethod,
    bool clearPaymentMethod = false,
    String? startDate,
    bool clearStartDate = false,
    String? endDate,
    bool clearEndDate = false,
  }) {
    return TransactionHistoryQuery(
      perPage: perPage ?? this.perPage,
      transactionType: clearTransactionType
          ? null
          : (transactionType ?? this.transactionType),
      operationType: clearOperationType
          ? null
          : (operationType ?? this.operationType),
      paymentMethod: clearPaymentMethod
          ? null
          : (paymentMethod ?? this.paymentMethod),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
    );
  }
}

class TransactionHistoryResponse {
  const TransactionHistoryResponse({
    required this.transactions,
    required this.meta,
  });

  final List<UserTransaction> transactions;
  final TransactionMeta meta;

  factory TransactionHistoryResponse.fromJson(Map<String, dynamic> json) {
    final rawTransactions = json['transactions'];
    final rawMeta = json['meta'];

    final transactions = rawTransactions is List
        ? rawTransactions
            .whereType<Map>()
            .map(
              (item) => UserTransaction.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false)
        : const <UserTransaction>[];

    final meta = rawMeta is Map
        ? TransactionMeta.fromJson(Map<String, dynamic>.from(rawMeta))
        : const TransactionMeta();

    return TransactionHistoryResponse(
      transactions: transactions,
      meta: meta,
    );
  }
}

class TransactionMeta {
  const TransactionMeta({
    this.currentPage = 1,
    this.lastPage = 1,
    this.perPage = 20,
    this.total = 0,
  });

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  factory TransactionMeta.fromJson(Map<String, dynamic> json) {
    return TransactionMeta(
      currentPage: _toInt(json['current_page'], fallback: 1),
      lastPage: _toInt(json['last_page'], fallback: 1),
      perPage: _toInt(json['per_page'], fallback: 20),
      total: _toInt(json['total']),
    );
  }
}

class UserTransaction {
  const UserTransaction({
    required this.id,
    required this.number,
    required this.transactionNumber,
    required this.amount,
    required this.debit,
    required this.credit,
    required this.balance,
    required this.lastBalance,
    required this.operationType,
    required this.transactionType,
    required this.paymentMethod,
    required this.chequeDate,
    required this.note,
    required this.invoiceableId,
    required this.invoiceableType,
    required this.createdAt,
    required this.fromName,
    required this.toCustomerName,
    required this.customerName,
    required this.transfersCount,
    required this.transfers,
    required this.fromAccount,
    required this.toAccount,
  });

  final int id;
  final int number;
  final int? transactionNumber;
  final double amount;
  final double debit;
  final double credit;
  final double balance;
  final double lastBalance;
  final String? operationType;
  final String? transactionType;
  final String? paymentMethod;
  final String? chequeDate;
  final String? note;
  final int? invoiceableId;
  final String? invoiceableType;
  final String? createdAt;
  final String? fromName;
  final String? toCustomerName;
  final String? customerName;
  final int transfersCount;
  final List<TransactionTransfer> transfers;
  final TransactionAccount? fromAccount;
  final TransactionAccount? toAccount;

  factory UserTransaction.fromJson(Map<String, dynamic> json) {
    final rawFromAccount = json['from_account'];
    final rawToAccount = json['to_account'];
    final rawTransfers = json['transfers'];

    final transfers = rawTransfers is List
        ? rawTransfers
            .whereType<Map>()
            .map(
              (item) => TransactionTransfer.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false)
        : const <TransactionTransfer>[];

    final amount = _toDouble(json['amount']);
    final credit = _toDouble(json['credit']);
    final debit = _toDouble(json['debit']);

    return UserTransaction(
      id: _toInt(json['id']),
      number: _toInt(json['number']),
      transactionNumber: _toNullableInt(json['transaction_number']),
      amount: amount,
      debit: debit,
      credit: credit,
      balance: _toDouble(json['balance']),
      lastBalance: _toDouble(json['last_balance']),
      operationType: _toNullableString(json['operation_type']),
      transactionType: _toNullableString(json['transaction_type']),
      paymentMethod: _toNullableString(json['payment_method']),
      chequeDate: _toNullableString(json['cheque_date']),
      note: _toNullableString(json['note']),
      invoiceableId: _toNullableInt(json['invoiceable_id']),
      invoiceableType: _toNullableString(json['invoiceable_type']),
      createdAt: _toNullableString(json['created_at']),
      fromName: _toNullableString(json['from_name']),
      toCustomerName: _toNullableString(json['to_customer_name']),
      customerName: _toNullableString(json['customer_name']),
      transfersCount: _toInt(
        json['transfers_count'],
        fallback: transfers.length,
      ),
      transfers: transfers,
      fromAccount: rawFromAccount is Map
          ? TransactionAccount.fromJson(Map<String, dynamic>.from(rawFromAccount))
          : null,
      toAccount: rawToAccount is Map
          ? TransactionAccount.fromJson(Map<String, dynamic>.from(rawToAccount))
          : null,
    );
  }

  double get effectiveAmount {
    if (amount > 0) {
      return amount;
    }
    if (credit > 0) {
      return credit;
    }
    if (debit > 0) {
      return debit;
    }
    return 0;
  }

  String? get resolvedFromName {
    return fromName ??
        fromAccount?.informationName ??
        fromAccount?.name;
  }

  String? get resolvedToName {
    return toCustomerName ??
        customerName ??
        toAccount?.informationName ??
        toAccount?.name;
  }

  bool get hasLegacyBalanceFields =>
      debit > 0 || credit > 0 || balance != 0 || lastBalance != 0;
}

class TransactionAccount {
  const TransactionAccount({
    required this.id,
    required this.name,
    required this.accountType,
    required this.accountNature,
    required this.informationName,
  });

  final int id;
  final String name;
  final String? accountType;
  final String? accountNature;
  final String? informationName;

  factory TransactionAccount.fromJson(Map<String, dynamic> json) {
    return TransactionAccount(
      id: _toInt(json['id']),
      name: _toString(json['name']),
      accountType: _toNullableString(json['account_type']),
      accountNature: _toNullableString(json['account_nature']),
      informationName: _toNullableString(json['information_name']),
    );
  }
}

class TransactionTransfer {
  const TransactionTransfer({
    required this.amount,
    required this.fromAccount,
    required this.toAccount,
  });

  final double amount;
  final TransactionAccount? fromAccount;
  final TransactionAccount? toAccount;

  factory TransactionTransfer.fromJson(Map<String, dynamic> json) {
    final rawFromAccount = json['from_account'];
    final rawToAccount = json['to_account'];

    return TransactionTransfer(
      amount: _toDouble(json['amount']),
      fromAccount: rawFromAccount is Map
          ? TransactionAccount.fromJson(Map<String, dynamic>.from(rawFromAccount))
          : null,
      toAccount: rawToAccount is Map
          ? TransactionAccount.fromJson(Map<String, dynamic>.from(rawToAccount))
          : null,
    );
  }
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _toNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString());
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
