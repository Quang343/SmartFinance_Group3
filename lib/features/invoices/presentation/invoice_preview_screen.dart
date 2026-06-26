import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_finance/core/providers/app_providers.dart';
import 'package:smart_finance/domain/entities/invoice_entity.dart';

class InvoicePreviewScreen extends ConsumerWidget {
  const InvoicePreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceRepo = ref.watch(invoiceRepositoryProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final dateFormatter = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xem trước Hóa đơn (PDF)'),
      ),
      body: FutureBuilder<List<InvoiceEntity>>(
        future: invoiceRepo.getAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không tìm thấy hóa đơn để xem trước.'));
          }

          // Show the latest outgoing invoice
          final list = snapshot.data!.where((inv) => inv.type == InvoiceType.outgoing).toList();
          if (list.isEmpty) {
            return const Center(child: Text('Không có hóa đơn đầu ra nào được tìm thấy.'));
          }
          
          final invoice = list.last;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Simulated PDF view
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24.0),
                    color: Colors.white,
                    child: DefaultTextStyle(
                      style: const TextStyle(color: Colors.black87),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SMARTFINANCE JSC',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent),
                                  ),
                                  Text('Tòa nhà FPT, Khu Công nghệ cao Hòa Lạc'),
                                  Text('MST: 0102030405'),
                                ],
                              ),
                              Icon(Icons.account_balance_wallet, size: 48, color: Colors.blueAccent.shade200),
                            ],
                          ),
                          const Divider(height: 32, color: Colors.black26),
                          const Center(
                            child: Text(
                              'HÓA ĐƠN GIÁ TRỊ GIA TĂNG',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Số hóa đơn: ${invoice.invoiceNumber}',
                              style: const TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text('Đơn vị mua hàng: ${invoice.partnerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Mã số thuế khách hàng: ${invoice.partnerTaxCode}'),
                          Text('Ngày phát hành: ${dateFormatter.format(invoice.issuedDate)}'),
                          const Divider(height: 32, color: Colors.black26),
                          
                          // Items table
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(flex: 3, child: Text('Tên sản phẩm / Dịch vụ', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(child: Text('Số lượng', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 2, child: Text('Thành tiền', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                          ),
                          const Divider(height: 16, color: Colors.black12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(flex: 3, child: Text('Dịch vụ phần mềm SmartFinance SaaS')),
                              const Expanded(child: Text('1', textAlign: TextAlign.right)),
                              Expanded(flex: 2, child: Text(currencyFormatter.format(invoice.subtotal), textAlign: TextAlign.right)),
                            ],
                          ),
                          const Divider(height: 32, color: Colors.black26),
                          
                          // Summary
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Cộng tiền hàng (Subtotal):'),
                              Text(currencyFormatter.format(invoice.subtotal), style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Thuế suất GTGT (VAT): ${invoice.vatRate}%'),
                              Text(currencyFormatter.format(invoice.vatAmount), style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const Divider(height: 16, color: Colors.black12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tổng cộng tiền thanh toán:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(currencyFormatter.format(invoice.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đang xuất PDF và in hóa đơn...'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('In / Xuất hóa đơn PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
