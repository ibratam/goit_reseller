import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/domain/auth_session.dart';
import '../domain/transaction_history.dart';
import 'transaction_repository.dart';

class ApiTransactionRepository implements TransactionRepository {
  const ApiTransactionRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<TransactionHistoryResponse> fetchTransactions({
    required AuthSession session,
    TransactionHistoryQuery query = const TransactionHistoryQuery(),
    int page = 1,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/users/transactions',
        authorization: session.authorizationValue,
        queryParameters: {
          'page': '$page',
          'per_page': '${query.perPage}',
          'transaction_type': query.transactionType,
          'operation_type': query.operationType,
          'payment_method': query.paymentMethod,
          'start_date': query.startDate,
          'end_date': query.endDate,
        },
      );

      if (response.data['success'] == true) {
        return TransactionHistoryResponse.fromJson(response.data);
      }

      throw TransactionException(
        _resolveMessage(
          response.data,
          fallback: 'Unable to load transactions.',
        ),
      );
    } on ApiException catch (error) {
      throw TransactionException(error.message);
    } on FormatException {
      throw const TransactionException(
        'The transaction response is missing required data.',
      );
    }
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
}

