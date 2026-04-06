import '../../auth/domain/auth_session.dart';
import '../domain/transaction_history.dart';

abstract class TransactionRepository {
  Future<TransactionHistoryResponse> fetchTransactions({
    required AuthSession session,
    TransactionHistoryQuery query = const TransactionHistoryQuery(),
    int page = 1,
  });
}

class TransactionException implements Exception {
  const TransactionException(this.message);

  final String message;
}

