import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/role_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../../domain/entities/invoice_entity.dart';
import '../../../core/widgets/scale_on_tap.dart';

class InvoiceListScreen extends ConsumerStatefulWidget {
  final String type; // 'incoming' or 'outgoing'

  const InvoiceListScreen({super.key, required this.type});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
  @override
  Widget build(BuildContext context) {
    final currentRole = ref.watch(roleProvider);
    final isIncoming = widget.type == 'incoming';
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final dateFormatter = DateFormat('dd/MM/yyyy');
    
    final invoiceRepo = ref.watch(invoiceRepositoryProvider);

    // Permission checks
    final canView = isIncoming ? currentRole.canViewIncomingInvoices : currentRole.canViewOutgoingInvoices;
    final canManage = isIncoming ? currentRole.canManageIncomingInvoices : currentRole.canManageOutgoingInvoices;

    if (!canView) {
      return Scaffold(
        appBar: AppBar(title: Text(isIncoming ? 'Hóa đơn đầu vào' : 'Hóa đơn đầu ra')),
        body: const Center(
          child: Text(
            'Bạn không có quyền truy cập màn hình này.',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isIncoming ? 'Hóa đơn mua vào (Incoming)' : 'Hóa đơn bán ra (Outgoing)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: FutureBuilder<List<InvoiceEntity>>(
        future: invoiceRepo.getAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          var list = snapshot.data ?? [];
          // Filter by invoice type
          list = list.where((inv) => inv.type == (isIncoming ? InvoiceType.incoming : InvoiceType.outgoing)).toList();

          if (list.isEmpty) {
            return const Center(
              child: Text('Không có hóa đơn nào.'),
            );
          }

          return ListView.builder(
            itemCount: list.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final inv = list[index];
              return ScaleOnTap(
                onTap: () {
                  context.go('/invoices/incoming/${inv.id}');
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isIncoming ? Colors.orange.shade50 : Colors.green.shade50,
                      child: Icon(
                        isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isIncoming ? Colors.orange : Colors.green,
                      ),
                    ),
                    title: Text(
                      inv.partnerName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Số HD: ${inv.invoiceNumber} • Ngày: ${dateFormatter.format(inv.issuedDate)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currencyFormatter.format(inv.totalAmount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isIncoming ? Colors.orange : Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, size: 16),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: canManage
          ? ScaleOnTap(
              onTap: () {
                if (isIncoming) {
                  context.go('/invoices/scan');
                } else {
                  context.go('/invoices/outgoing/new');
                }
              },
              child: FloatingActionButton.extended(
                onPressed: null,
                backgroundColor: isIncoming ? Colors.orange : Colors.green,
                icon: Icon(isIncoming ? Icons.qr_code_scanner : Icons.add, color: Colors.white),
                label: Text(
                  isIncoming ? 'Quét hóa đơn' : 'Tạo Hóa đơn',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            )
          : null,
    );
  }
}
