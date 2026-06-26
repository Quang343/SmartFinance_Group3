import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_finance/core/providers/app_providers.dart';
import 'package:smart_finance/domain/entities/invoice_entity.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
    final invoiceRepository = ref.watch(invoiceRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết hóa đơn'),
      ),
      body: FutureBuilder<InvoiceEntity?>(
        future: invoiceRepository.getById(invoiceId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('Không tìm thấy hóa đơn hoặc có lỗi xảy ra.'),
            );
          }

          final invoice = snapshot.data!;
          final isIncoming = invoice.type == InvoiceType.incoming;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isIncoming ? 'Hóa đơn đầu vào (Incoming)' : 'Hóa đơn đầu ra (Outgoing)',
                              style: TextStyle(
                                color: isIncoming ? Colors.orange : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isIncoming ? Colors.orange.shade50 : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                invoice.ocrStatus.name.toUpperCase(),
                                style: TextStyle(
                                  color: isIncoming ? Colors.orange : Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          invoice.invoiceNumber,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormatter.format(invoice.totalAmount),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Detail fields
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thông tin chung',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const Divider(height: 24),
                        _DetailRow(
                          label: 'Đối tác',
                          value: invoice.partnerName,
                        ),
                        _DetailRow(
                          label: 'Mã số thuế đối tác',
                          value: invoice.partnerTaxCode,
                        ),
                        _DetailRow(
                          label: 'Ngày phát hành',
                          value: dateFormatter.format(invoice.issuedDate),
                        ),
                        _DetailRow(
                          label: 'Tiền trước thuế',
                          value: currencyFormatter.format(invoice.subtotal),
                        ),
                        _DetailRow(
                          label: 'Thuế suất VAT',
                          value: '${invoice.vatRate}%',
                        ),
                        _DetailRow(
                          label: 'Tiền thuế VAT',
                          value: currencyFormatter.format(invoice.vatAmount),
                        ),
                        if (invoice.ocrConfidence != null)
                          _DetailRow(
                            label: 'Độ tin cậy OCR',
                            value: '${(invoice.ocrConfidence! * 100).toStringAsFixed(1)}%',
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Image view if available
                if (invoice.imagePath != null && invoice.imagePath!.isNotEmpty) ...[
                  const Text(
                    'Ảnh hóa đơn đã chụp / tải lên',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 250,
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: Icon(
                          Icons.image,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
