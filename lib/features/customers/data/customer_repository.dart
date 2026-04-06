import '../../auth/domain/auth_session.dart';
import '../domain/credit_transaction_result.dart';
import '../domain/customer_service_record.dart';

abstract class CustomerRepository {
  Future<List<CustomerServiceRecord>> searchCustomers({
    required AuthSession session,
    String? customerName,
    String? mobile,
    int limit = 20,
  });

  Future<CreditTransactionResult> addCredit({
    required AuthSession session,
    required int customerServiceId,
    required double amount,
    required String paymentMethod,
    String? note,
    String? chequeDate,
  });
}

class CustomerSearchException implements Exception {
  const CustomerSearchException(this.message);

  final String message;
}
