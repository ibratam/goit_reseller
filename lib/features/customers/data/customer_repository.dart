import '../../auth/domain/auth_session.dart';
import '../../auth/domain/app_user.dart';
import '../domain/credit_transaction_result.dart';
import '../domain/customer_lookup_result.dart';
import '../domain/customer_service_record.dart';
import '../domain/service_extension_result.dart';

abstract class CustomerRepository {
  Future<List<CustomerServiceRecord>> searchCustomers({
    required AuthSession session,
    String? customerName,
    String? mobile,
    bool? expired,
    int? expiresInDays,
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

  Future<CustomerLookupResult> lookupCustomer({ required String mobile });

  Future<AppUser> fetchCurrentUser({ required AuthSession session });

  Future<CustomerLookupResult> mobileExists({
    required AuthSession session,
    required String mobile,
  });

  Future<ServiceExtensionResult> extendSubscriptionOneDay({
    required AuthSession session,
    required int customerServiceId,
  });

  Future<ServiceExtensionResult> extendService({
    required AuthSession session,
    required int customerServiceId,
  });
}

class CustomerSearchException implements Exception {
  const CustomerSearchException(this.message);

  final String message;
}
