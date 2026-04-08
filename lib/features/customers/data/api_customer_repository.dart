import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/auth_session.dart';
import '../domain/credit_transaction_result.dart';
import '../domain/customer_lookup_result.dart';
import '../domain/customer_service_record.dart';
import '../domain/service_extension_result.dart';
import 'customer_repository.dart';

class ApiCustomerRepository implements CustomerRepository {
  const ApiCustomerRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<CustomerServiceRecord>> searchCustomers({
    required AuthSession session,
    String? customerName,
    String? mobile,
    bool? expired,
    int? expiresInDays,
    int limit = 20,
  }) async {
    final trimmedName = customerName?.trim();
    final trimmedMobile = mobile?.trim();
    final hasFilter = expired != null || expiresInDays != null;
    if (!hasFilter &&
        (trimmedName == null || trimmedName.isEmpty) &&
        (trimmedMobile == null || trimmedMobile.isEmpty)) {
      throw const CustomerSearchException(
        'Enter a customer name or mobile number.',
      );
    }

    final safeLimit = limit < 1 ? 1 : (limit > 100 ? 100 : limit);

    try {
      final response = await _apiClient.get(
        '/api/customers/services/search',
        authorization: session.authorizationValue,
        queryParameters: {
          if (trimmedName != null) 'customer_name': trimmedName,
          if (trimmedMobile != null) 'mobile': trimmedMobile,
          if (expired != null) 'expired': expired ? '1' : '0',
          if (expiresInDays != null) 'expires_in_days': '$expiresInDays',
          'limit': '$safeLimit',
        },
      );

      if (response.data['success'] == true) {
        final rawItems = response.data['customer_services'];
        if (rawItems is! List) {
          return const [];
        }

        return rawItems
            .whereType<Map>()
            .map(
              (item) => CustomerServiceRecord.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false);
      }

      throw CustomerSearchException(
        _resolveMessage(
          response.data,
          fallback: 'Customer search failed.',
        ),
      );
    } on ApiException catch (error) {
      throw CustomerSearchException(error.message);
    }
  }

  @override
  Future<CreditTransactionResult> addCredit({
    required AuthSession session,
    required int customerServiceId,
    required double amount,
    required String paymentMethod,
    String? note,
    String? chequeDate,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/customers/add-credit',
        authorization: session.authorizationValue,
        body: {
          'customer_service_id': customerServiceId,
          'amount': amount,
          'payment_method': paymentMethod.trim(),
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
          if (paymentMethod.trim() == 'cheque' &&
              chequeDate != null &&
              chequeDate.trim().isNotEmpty)
            'cheque_date': chequeDate.trim(),
        },
      );

      if (response.data['success'] == true) {
        return CreditTransactionResult.fromJson(response.data);
      }

      throw CustomerSearchException(
        _resolveCreditError(response.data),
      );
    } on ApiException catch (error) {
      throw CustomerSearchException(error.message);
    } on FormatException {
      throw const CustomerSearchException(
        'The credit response is missing required data.',
      );
    }
  }

  String _resolveCreditError(Map<String, dynamic> data) {
    final messageCode = data['message']?.toString();
    if (messageCode == 'amount_must_cover_debit_balance') {
      final requiredAmount = data['required_amount']?.toString();
      if (requiredAmount != null && requiredAmount.isNotEmpty) {
        return 'Amount must cover debit balance. Required amount: $requiredAmount';
      }
    }

    return _resolveMessage(
      data,
      fallback: 'Unable to add credit.',
    );
  }

  String _resolveMessage(
    Map<String, dynamic> data, {
    required String fallback,
  }) {
    final message = formatApiMessage(
      data['message']?.toString(),
      fallback: fallback,
    );
    final details = data['details']?.toString().trim();
    if (details != null && details.isNotEmpty) {
      return '$message: $details';
    }
    return message;
  }

  @override
  Future<CustomerLookupResult> lookupCustomer({required String mobile}) async {
    final trimmedMobile = mobile.trim();
    if (trimmedMobile.isEmpty) {
      throw const CustomerSearchException('Mobile number is required.');
    }

    try {
      final response = await _apiClient.post(
        '/api/customers/lookup',
        body: {'mobile': trimmedMobile},
      );

      return CustomerLookupResult.fromJson(response.data);
    } on ApiException catch (error) {
      throw CustomerSearchException(error.message);
    }
  }

  @override
  Future<AppUser> fetchCurrentUser({required AuthSession session}) async {
    try {
      final response = await _apiClient.get(
        '/api/customers',
        authorization: session.authorizationValue,
      );

      return AppUser.fromJson(response.data);
    } on ApiException catch (error) {
      throw CustomerSearchException(error.message);
    }
  }

  @override
  Future<CustomerLookupResult> mobileExists({
    required AuthSession session,
    required String mobile,
  }) async {
    final trimmedMobile = mobile.trim();
    if (trimmedMobile.isEmpty) {
      throw const CustomerSearchException('Mobile number is required.');
    }

    try {
      final response = await _apiClient.post(
        '/api/customers/mobile-exists',
        authorization: session.authorizationValue,
        body: {'mobile': trimmedMobile},
      );

      return CustomerLookupResult.fromJson(response.data);
    } on ApiException catch (error) {
      throw CustomerSearchException(error.message);
    }
  }

  @override
  Future<ServiceExtensionResult> extendSubscriptionOneDay({
    required AuthSession session,
    required int customerServiceId,
  }) async {
    if (customerServiceId <= 0) {
      throw const CustomerSearchException('Customer service ID is required.');
    }

    try {
      final response = await _apiClient.post(
        '/api/customers/subscription-extend-one-day?id=$customerServiceId',
        authorization: session.authorizationValue,
        body: {
          'id': customerServiceId,
          'customer_service_id': customerServiceId,
        },
      );

      if (response.data['success'] == true) {
        return ServiceExtensionResult.fromJson(response.data);
      }

      throw CustomerSearchException(
        _resolveMessage(response.data, fallback: 'Unable to extend service.'),
      );
    } on ApiException catch (error) {
      throw CustomerSearchException(error.message);
    }
  }

  @override
  Future<ServiceExtensionResult> extendService({
    required AuthSession session,
    required int customerServiceId,
  }) async {
    if (customerServiceId <= 0) {
      throw const CustomerSearchException('Customer service ID is required.');
    }

    try {
      final response = await _apiClient.post(
        '/api/customers/extend-service',
        authorization: session.authorizationValue,
        body: {
          'id': customerServiceId,
          'customer_service_id': customerServiceId,
        },
      );

      if (response.data['success'] == true) {
        return ServiceExtensionResult.fromJson(response.data);
      }

      throw CustomerSearchException(
        _resolveMessage(response.data, fallback: 'Unable to extend service.'),
      );
    } on ApiException catch (error) {
      throw CustomerSearchException(error.message);
    }
  }
}
