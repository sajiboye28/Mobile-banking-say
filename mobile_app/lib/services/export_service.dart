import 'package:intl/intl.dart';

/// ExportService — generates CSV exports and formatted bank statements
/// from a list of transaction maps.
class ExportService {
  static final NumberFormat _currencyFormat =
      NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  static final DateFormat _dateFormat =
      DateFormat('yyyy-MM-dd HH:mm:ss');

  // ── CSV Generation ─────────────────────────────────────────────────────────

  /// Generates a CSV string from a list of transaction maps.
  ///
  /// Expected map keys (all optional, falls back to empty string):
  ///   date, type, description, amount, status, transactionId
  static String generateCsv(List<Map<String, dynamic>> transactions) {
    final buffer = StringBuffer();

    // Header row
    buffer.writeln('Date,Type,Description,Amount,Status,Transaction ID');

    for (final tx in transactions) {
      final date = _escapeCsvField(_formatDate(tx['date'] ?? tx['timestamp']));
      final type = _escapeCsvField((tx['type'] ?? '').toString());
      final description =
          _escapeCsvField((tx['description'] ?? '').toString());
      final rawAmount = (tx['amount'] ?? 0);
      final amount = _escapeCsvField(
          _currencyFormat.format(rawAmount is num ? rawAmount.toDouble() : 0.0));
      final status = _escapeCsvField((tx['status'] ?? '').toString());
      final txId = _escapeCsvField(
          (tx['transactionId'] ?? tx['id'] ?? '').toString());

      buffer.writeln('$date,$type,$description,$amount,$status,$txId');
    }

    return buffer.toString();
  }

  // ── Statement Generation ───────────────────────────────────────────────────

  /// Generates a formatted plain-text bank statement.
  ///
  /// The output resembles a real bank statement with header, account info,
  /// a transaction table, running balance column, and footer.
  static String generateStatement({
    required String accountHolder,
    required String accountNumber,
    required String period,
    required List<Map<String, dynamic>> transactions,
    required double openingBalance,
    required double closingBalance,
  }) {
    final generatedAt =
        DateFormat('MMMM d, yyyy  h:mm a').format(DateTime.now());
    final maskedAccount = _maskAccountNumber(accountNumber);

    final buffer = StringBuffer();

    // ── Bank header ──────────────────────────────────────────────────────────
    buffer.writeln(_repeat('═', 72));
    buffer.writeln(_center('NEXUS DIGITAL BANKING', 72));
    buffer.writeln(_center('Official Account Statement', 72));
    buffer.writeln(_repeat('═', 72));
    buffer.writeln();

    // ── Account information block ────────────────────────────────────────────
    buffer.writeln('  Account Holder : $accountHolder');
    buffer.writeln('  Account Number : $maskedAccount');
    buffer.writeln('  Statement For  : $period');
    buffer.writeln('  Generated On   : $generatedAt');
    buffer.writeln();
    buffer.writeln(_repeat('─', 72));

    // ── Balance summary ──────────────────────────────────────────────────────
    buffer.writeln();
    buffer.writeln(_padRight('  Opening Balance', 40) +
        _padLeft(_currencyFormat.format(openingBalance), 30));
    buffer.writeln(_padRight('  Closing Balance', 40) +
        _padLeft(_currencyFormat.format(closingBalance), 30));

    // Compute totals from transaction list
    double totalCredits = 0;
    double totalDebits = 0;
    for (final tx in transactions) {
      final type = (tx['type'] ?? '').toString().toLowerCase();
      final amt =
          (tx['amount'] ?? 0) is num ? (tx['amount'] as num).toDouble() : 0.0;
      final status = (tx['status'] ?? '').toString().toLowerCase();
      if (status == 'success') {
        if (type == 'credit') totalCredits += amt;
        if (type == 'debit') totalDebits += amt;
      }
    }

    buffer.writeln(_padRight('  Total Credits', 40) +
        _padLeft(_currencyFormat.format(totalCredits), 30));
    buffer.writeln(_padRight('  Total Debits', 40) +
        _padLeft(_currencyFormat.format(totalDebits), 30));
    buffer.writeln(_padRight('  Net Change', 40) +
        _padLeft(
            _currencyFormat.format(totalCredits - totalDebits), 30));
    buffer.writeln();
    buffer.writeln(_repeat('─', 72));

    // ── Transaction table header ─────────────────────────────────────────────
    buffer.writeln();
    buffer.writeln(
      _padRight('  Date', 20) +
          _padRight('Type', 8) +
          _padRight('Description', 24) +
          _padLeft('Amount', 12) +
          _padLeft('Status', 10),
    );
    buffer.writeln(_repeat('─', 72));

    // ── Transaction rows ─────────────────────────────────────────────────────
    double runningBalance = openingBalance;

    if (transactions.isEmpty) {
      buffer.writeln();
      buffer.writeln(_center('No transactions in this period.', 72));
      buffer.writeln();
    } else {
      for (final tx in transactions) {
        final dateStr =
            _padRight('  ${_formatDateShort(tx['date'] ?? tx['timestamp'])}', 20);
        final typeStr = _padRight(
            _capitalize((tx['type'] ?? '').toString()), 8);
        final desc = _truncate(
            (tx['description'] ?? '').toString(), 22);
        final descStr = _padRight(desc, 24);

        final rawAmt = (tx['amount'] ?? 0);
        final amt = rawAmt is num ? rawAmt.toDouble() : 0.0;
        final typeRaw = (tx['type'] ?? '').toString().toLowerCase();
        final statusRaw = (tx['status'] ?? '').toString().toLowerCase();
        final sign = typeRaw == 'credit' ? '+' : '-';
        final amtStr =
            _padLeft('$sign${_currencyFormat.format(amt)}', 12);

        final status = _truncate(
            _capitalize((tx['status'] ?? '').toString()), 10);
        final statusStr = _padLeft(status, 10);

        // Update running balance for successful transactions
        if (statusRaw == 'success') {
          if (typeRaw == 'credit') {
            runningBalance += amt;
          } else if (typeRaw == 'debit') {
            runningBalance -= amt;
          }
        }

        buffer.writeln('$dateStr$typeStr$descStr$amtStr$statusStr');
      }
    }

    buffer.writeln(_repeat('─', 72));
    buffer.writeln();

    // ── Closing balance confirmation ─────────────────────────────────────────
    buffer.writeln(_padRight('  Closing Balance', 40) +
        _padLeft(_currencyFormat.format(closingBalance), 30));
    buffer.writeln();
    buffer.writeln(_repeat('═', 72));

    // ── Footer ───────────────────────────────────────────────────────────────
    buffer.writeln();
    buffer.writeln(_center('This statement is auto-generated by Nexus Digital', 72));
    buffer.writeln(_center('Banking. For disputes contact support@nexusbank.io', 72));
    buffer.writeln(_center(
        'or call 1-800-NEXUS-BK (Mon–Fri, 9 AM–6 PM EST).', 72));
    buffer.writeln();
    buffer.writeln(_center(
        'Nexus Digital Banking is a registered financial service.', 72));
    buffer.writeln(_center(
        'FDIC Insured. Member FDIC. Equal Housing Lender.', 72));
    buffer.writeln();
    buffer.writeln(_repeat('═', 72));

    return buffer.toString();
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Escapes a CSV field by wrapping in quotes if it contains commas, quotes,
  /// or newlines. Internal double-quotes are escaped as "".
  static String _escapeCsvField(String field) {
    if (field.contains(',') ||
        field.contains('"') ||
        field.contains('\n') ||
        field.contains('\r')) {
      final escaped = field.replaceAll('"', '""');
      return '"$escaped"';
    }
    return field;
  }

  /// Formats a date value (DateTime, Timestamp-like, or String) to full ISO.
  static String _formatDate(dynamic value) {
    if (value == null) return '';
    if (value is DateTime) return _dateFormat.format(value);
    // Firestore Timestamp duck-type
    if (value.runtimeType.toString().contains('Timestamp')) {
      try {
        return _dateFormat.format(value.toDate() as DateTime);
      } catch (_) {}
    }
    return value.toString();
  }

  /// Formats a date value to a short readable form for the statement.
  static String _formatDateShort(dynamic value) {
    if (value == null) return '—';
    DateTime? dt;
    if (value is DateTime) {
      dt = value;
    } else if (value.runtimeType.toString().contains('Timestamp')) {
      try {
        dt = value.toDate() as DateTime;
      } catch (_) {}
    }
    if (dt != null) return DateFormat('MMM d, yyyy').format(dt);
    return value.toString();
  }

  /// Masks all but last 4 digits of an account number.
  static String _maskAccountNumber(String accountNumber) {
    if (accountNumber.length <= 4) return accountNumber;
    final visible = accountNumber.substring(accountNumber.length - 4);
    final masked = '•' * (accountNumber.length - 4);
    return '$masked$visible';
  }

  static String _repeat(String char, int count) =>
      char * count;

  static String _center(String text, int width) {
    if (text.length >= width) return text;
    final padding = (width - text.length) ~/ 2;
    return ' ' * padding + text;
  }

  static String _padRight(String text, int width) {
    if (text.length >= width) return text.substring(0, width);
    return text.padRight(width);
  }

  static String _padLeft(String text, int width) {
    if (text.length >= width) return text.substring(0, width);
    return text.padLeft(width);
  }

  static String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 1)}…';
  }

  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
