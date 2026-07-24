import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/app_providers.dart';
import '../../../domain/entities/invoice_entity.dart';
import '../providers/invoice_provider.dart';

class DeletedInvoiceListScreen extends ConsumerStatefulWidget {
  const DeletedInvoiceListScreen({super.key});

  @override
  ConsumerState<DeletedInvoiceListScreen> createState() => _DeletedInvoiceListScreenState();
}

class _DeletedInvoiceListScreenState extends ConsumerState<DeletedInvoiceListScreen> {
  bool _isLoading = true;
  List<InvoiceEntity> _deletedInvoices = [];

  @override
  void initState() {
    super.initState();
    _loadDeletedInvoices();
  }

  Future<void> _loadDeletedInvoices() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(invoiceRepositoryProvider);
      final invoices = await repo.getDeletedInvoices();
      if (mounted) {
        setState(() {
          _deletedInvoices = invoices;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thùng rác: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmRestore(InvoiceEntity invoice) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Khôi phục hóa đơn'),
        content: Text('Bạn có muốn khôi phục hóa đơn ${invoice.invoiceNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(invoiceRepositoryProvider).restore(invoice.id);
                ref.invalidate(allInvoicesProvider);
                _loadDeletedInvoices();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Khôi phục thành công!'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Khôi phục', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmHardDelete(InvoiceEntity invoice) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa vĩnh viễn', style: TextStyle(color: Colors.red)),
        content: Text('Bạn có chắc chắn muốn xóa vĩnh viễn hóa đơn ${invoice.invoiceNumber} không? Hành động này không thể hoàn tác!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(invoiceRepositoryProvider).delete(invoice.id);
                _loadDeletedInvoices();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa vĩnh viễn!'), backgroundColor: Colors.red),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa vĩnh viễn', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormatter = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF06150F) : const Color(0xFFF4FAF7),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF06150F) : const Color(0xFFF4FAF7),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white70 : Colors.black87, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Thùng rác Hóa đơn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _deletedInvoices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      const Text('Thùng rác trống', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _deletedInvoices.length,
                  itemBuilder: (context, index) {
                    final inv = _deletedInvoices[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0E2219) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                        ),
                        title: Text(
                          inv.invoiceNumber,
                          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                        ),
                        subtitle: Text(
                          '${inv.type == InvoiceType.incoming ? inv.sellerName : inv.buyerName}\n${dateFormatter.format(inv.issuedDate)}',
                          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.restore_rounded, color: Colors.green),
                              onPressed: () => _confirmRestore(inv),
                              tooltip: 'Khôi phục',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                              onPressed: () => _confirmHardDelete(inv),
                              tooltip: 'Xóa vĩnh viễn',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
