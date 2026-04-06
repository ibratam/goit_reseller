import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../../core/utils/formatters.dart';
import '../domain/transaction_history.dart';

class TransactionExcelExportFile {
  const TransactionExcelExportFile({
    required this.fileName,
    required this.bytes,
  });

  final String fileName;
  final Uint8List bytes;
}

class TransactionExcelExporter {
  TransactionExcelExportFile buildWorkbook(List<UserTransaction> transactions) {
    final excel = Excel.createExcel();
    const sheetName = 'Transactions';
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != sheetName) {
      excel.rename(defaultSheet, sheetName);
    }

    final sheet = excel[sheetName];
    sheet.appendRow(_headerRow);

    for (final transaction in transactions) {
      sheet.appendRow([
        TextCellValue('${transaction.transactionNumber ?? transaction.number}'),
        TextCellValue(transaction.createdAt ?? ''),
        TextCellValue(formatMoney(transaction.effectiveAmount)),
        TextCellValue(
          formatApiMessage(
            transaction.transactionType,
            fallback: '',
          ),
        ),
        TextCellValue(
          formatApiMessage(
            transaction.operationType,
            fallback: '',
          ),
        ),
        TextCellValue(
          formatApiMessage(
            transaction.paymentMethod,
            fallback: '',
          ),
        ),
        TextCellValue(transaction.resolvedFromName ?? ''),
        TextCellValue(transaction.resolvedToName ?? ''),
        TextCellValue('${transaction.transfersCount}'),
        TextCellValue(formatMoney(transaction.debit)),
        TextCellValue(formatMoney(transaction.credit)),
        TextCellValue(formatMoney(transaction.balance)),
        TextCellValue(formatMoney(transaction.lastBalance)),
        TextCellValue(transaction.chequeDate ?? ''),
        TextCellValue(transaction.note ?? ''),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null || bytes.isEmpty) {
      throw const FormatException('Unable to build the Excel file.');
    }

    return TransactionExcelExportFile(
      fileName: _buildFileName(),
      bytes: Uint8List.fromList(bytes),
    );
  }

  List<CellValue> get _headerRow => [
        TextCellValue('Transaction Number'),
        TextCellValue('Created At'),
        TextCellValue('Amount'),
        TextCellValue('Transaction Type'),
        TextCellValue('Operation Type'),
        TextCellValue('Payment Method'),
        TextCellValue('From'),
        TextCellValue('To'),
        TextCellValue('Transfers Count'),
        TextCellValue('Debit'),
        TextCellValue('Credit'),
        TextCellValue('Balance'),
        TextCellValue('Last Balance'),
        TextCellValue('Cheque Date'),
        TextCellValue('Note'),
      ];

  String _buildFileName() {
    final now = DateTime.now();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');

    return 'transactions_$year$month${day}_$hour$minute$second.xlsx';
  }
}
