import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/entities/report_summary_entity.dart';
import '../../../domain/services/report_calculator.dart';

final reportSummaryProvider =
    FutureProvider.autoDispose.family<ReportSummaryEntity, String>((ref, period) async {
  final transactions = await ref.watch(transactionRepositoryProvider).getConfirmed();
  final now = DateTime.now();
  return ReportCalculator.calculateSummary(transactions, now, now);
});
