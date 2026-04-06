String formatApiMessage(
  String? rawMessage, {
  String fallback = 'Something went wrong.',
}) {
  final message = rawMessage?.trim() ?? '';
  if (message.isEmpty) {
    return fallback;
  }

  if (_looksLikeInternalServerError(message)) {
    return fallback;
  }

  final withSpaces = message.replaceAll(RegExp(r'[_-]+'), ' ').trim();
  if (withSpaces.isEmpty) {
    return fallback;
  }

  return withSpaces[0].toUpperCase() + withSpaces.substring(1);
}

bool _looksLikeInternalServerError(String message) {
  final normalized = message.toLowerCase();

  return normalized.contains('illuminate\\') ||
      normalized.contains('stack trace') ||
      normalized.contains('vendor/laravel') ||
      normalized.contains('vendor\\\\laravel') ||
      normalized.contains('access level to ') ||
      normalized.contains('must be public') ||
      normalized.contains('uncaught') ||
      normalized.contains('syntax error');
}

String formatMoney(num? amount) {
  final value = (amount ?? 0).toDouble();
  return value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
}
