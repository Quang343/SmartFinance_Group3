import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/role_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/sync/sync_queue_service.dart';
import 'package:collection/collection.dart';
import '../../../core/widgets/scale_on_tap.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../domain/entities/invoice_entity.dart';
import '../providers/invoice_provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../../core/sync/sync_item.dart';
import '../../../data/models/invoice_model.dart';

class InvoiceListScreen extends ConsumerStatefulWidget {
  final String type; // 'incoming' or 'outgoing'

  const InvoiceListScreen({super.key, required this.type});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
  String _searchQuery = '';
  String _selectedPeriod = 'all'; // 'all', 'today', 'month', 'year', 'custom'
  DateTimeRange? _customDateRange;
  String _selectedStatus = 'all'; // null = all, notCreated, created

  Future<void> _refreshInvoices() async {
    ref.invalidate(allInvoicesProvider);
  }

  void _confirmSoftDelete(InvoiceEntity invoice) {
    AppDialogs.showConfirmDialog(
      context: context,
      title: 'Xác nhận xóa',
      message: 'Bạn có chắc chắn muốn xóa hóa đơn ${invoice.invoiceNumber}? Hóa đơn sẽ được chuyển vào thùng rác.',
      icon: Icons.delete_outline_rounded,
      color: Colors.redAccent,
      confirmText: 'Xóa hóa đơn',
      onConfirm: () async {
        final queueService = ref.read(syncQueueServiceProvider);
        final invoiceRepo = ref.read(invoiceRepositoryProvider);
        
        final updatedModel = InvoiceModel(
          id: invoice.id,
          invoiceNumber: invoice.invoiceNumber,
          formNumber: invoice.formNumber,
          serialNumber: invoice.serialNumber,
          sellerName: invoice.sellerName,
          sellerTaxCode: invoice.sellerTaxCode,
          sellerAddress: invoice.sellerAddress,
          sellerPhone: invoice.sellerPhone,
          sellerBankName: invoice.sellerBankName,
          sellerBankAccount: invoice.sellerBankAccount,
          buyerContactName: invoice.buyerContactName,
          buyerName: invoice.buyerName,
          buyerTaxCode: invoice.buyerTaxCode,
          buyerAddress: invoice.buyerAddress,
          buyerBankName: invoice.buyerBankName,
          buyerBankAccount: invoice.buyerBankAccount,
          paymentMethod: invoice.paymentMethod,
          items: invoice.items,
          subtotal: invoice.subtotal,
          vatRate: invoice.vatRate,
          vatAmount: invoice.vatAmount,
          totalAmount: invoice.totalAmount,
          ocrStatus: invoice.ocrStatus,
          transactionStatus: invoice.transactionStatus,
          ocrConfidence: invoice.ocrConfidence,
          type: invoice.type,
          issuedDate: invoice.issuedDate,
          createdAt: invoice.createdAt,
          updatedAt: DateTime.now(),
          imagePath: invoice.imagePath,
          status: InvoiceStatus.deleted, // Update status
        );

        final syncItem = SyncItem(
          id: const Uuid().v4(),
          collection: 'invoices',
          action: SyncAction.update,
          entityId: invoice.id,
          payload: updatedModel.toJson(),
        );

        await queueService.enqueue(syncItem);

        try {
          await invoiceRepo.softDelete(invoice.id).timeout(const Duration(seconds: 3));
          await queueService.removeItem(syncItem.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã chuyển hóa đơn vào thùng rác'), backgroundColor: Colors.green),
            );
          }
        } on TimeoutException {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã lưu ngoại tuyến (Chuyển vào thùng rác)'), backgroundColor: Colors.orange),
            );
          }
        } catch (e) {
          await queueService.markAsError(syncItem.id, e.toString());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
            );
          }
        } finally {
          _refreshInvoices();
        }
      },
    );
  }

  Future<void> _confirmRestore(InvoiceEntity invoice) async {
    AppDialogs.showConfirmDialog(
      context: context,
      title: 'Khôi phục hóa đơn',
      message: 'Bạn có muốn khôi phục hóa đơn ${invoice.invoiceNumber}?',
      icon: Icons.restore_rounded,
      color: const Color(0xFF00D09E),
      confirmText: 'Khôi phục',
      onConfirm: () async {
        final queueService = ref.read(syncQueueServiceProvider);
        final invoiceRepo = ref.read(invoiceRepositoryProvider);
        
        final updatedModel = InvoiceModel(
          id: invoice.id,
          invoiceNumber: invoice.invoiceNumber,
          formNumber: invoice.formNumber,
          serialNumber: invoice.serialNumber,
          sellerName: invoice.sellerName,
          sellerTaxCode: invoice.sellerTaxCode,
          sellerAddress: invoice.sellerAddress,
          sellerPhone: invoice.sellerPhone,
          sellerBankName: invoice.sellerBankName,
          sellerBankAccount: invoice.sellerBankAccount,
          buyerContactName: invoice.buyerContactName,
          buyerName: invoice.buyerName,
          buyerTaxCode: invoice.buyerTaxCode,
          buyerAddress: invoice.buyerAddress,
          buyerBankName: invoice.buyerBankName,
          buyerBankAccount: invoice.buyerBankAccount,
          paymentMethod: invoice.paymentMethod,
          items: invoice.items,
          subtotal: invoice.subtotal,
          vatRate: invoice.vatRate,
          vatAmount: invoice.vatAmount,
          totalAmount: invoice.totalAmount,
          ocrStatus: invoice.ocrStatus,
          transactionStatus: invoice.transactionStatus,
          ocrConfidence: invoice.ocrConfidence,
          type: invoice.type,
          issuedDate: invoice.issuedDate,
          createdAt: invoice.createdAt,
          updatedAt: DateTime.now(),
          imagePath: invoice.imagePath,
          status: InvoiceStatus.active, // Khôi phục
        );

        final syncItem = SyncItem(
          id: const Uuid().v4(),
          collection: 'invoices',
          action: SyncAction.update,
          entityId: invoice.id,
          payload: updatedModel.toJson(),
        );

        await queueService.enqueue(syncItem);

        try {
          await invoiceRepo.restore(invoice.id).timeout(const Duration(seconds: 3));
          await queueService.removeItem(syncItem.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Khôi phục thành công!'), backgroundColor: Colors.green),
            );
          }
        } on TimeoutException {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã lưu ngoại tuyến (Khôi phục)'), backgroundColor: Colors.orange),
            );
          }
        } catch (e) {
          await queueService.markAsError(syncItem.id, e.toString());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
            );
          }
        } finally {
          _refreshInvoices();
        }
      },
    );
  }

  Future<void> _confirmHardDelete(InvoiceEntity invoice) async {
    AppDialogs.showConfirmDialog(
      context: context,
      title: 'Xóa vĩnh viễn',
      message: 'Hành động này không thể hoàn tác! Bạn có chắc chắn muốn xóa vĩnh viễn hóa đơn ${invoice.invoiceNumber} không?',
      icon: Icons.delete_forever_rounded,
      color: Colors.red,
      confirmText: 'Xóa vĩnh viễn',
      onConfirm: () async {
        final queueService = ref.read(syncQueueServiceProvider);
        final invoiceRepo = ref.read(invoiceRepositoryProvider);

        final syncItem = SyncItem(
          id: const Uuid().v4(),
          collection: 'invoices',
          action: SyncAction.delete,
          entityId: invoice.id,
          payload: {},
        );

        await queueService.enqueue(syncItem);

        try {
          await invoiceRepo.delete(invoice.id).timeout(const Duration(seconds: 3));
          await queueService.removeItem(syncItem.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã xóa vĩnh viễn hóa đơn'), backgroundColor: Colors.red),
            );
          }
        } on TimeoutException {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã lưu ngoại tuyến (Xóa vĩnh viễn)'), backgroundColor: Colors.orange),
            );
          }
        } catch (e) {
          await queueService.markAsError(syncItem.id, e.toString());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
            );
          }
        } finally {
          _refreshInvoices();
        }
      },
    );
  }

  Widget _buildStatusChip(InvoiceTransactionStatus status) {
    Color color;
    String text;
    switch (status) {
      case InvoiceTransactionStatus.confirmedCreated:
        color = const Color(0xFF00D09E);
        text = 'Đã xác nhận GD';
        break;
      case InvoiceTransactionStatus.draftCreated:
        color = const Color(0xFF3B82F6); // Blue
        text = 'Đã tạo GD nháp';
        break;
      case InvoiceTransactionStatus.notCreated:
        color = const Color(0xFFF97316); // Orange
        text = 'Chưa tạo GD';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, bool isDark, Color primaryColor, int count) {
    final isSelected = _selectedStatus == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatus = value;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : (isDark ? const Color(0xFF152F23) : const Color(0xFFEDF2F7)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? primaryColor : Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _buildTrashChip(bool isDark) {
    final isSelected = _selectedStatus == 'deleted';
    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatus = 'deleted';
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.red
              : (isDark ? const Color(0xFF3F1616) : const Color(0xFFFEE2E2)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.red
                : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_outline_rounded,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626)),
            ),
            const SizedBox(width: 4),
            Text(
              'Thùng rác',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRole = ref.watch(roleProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncoming = widget.type == 'incoming';
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final queueItems = ref.watch(syncQueueServiceProvider).queue;
    
    // Orange for incoming invoices, Teal/Green for outgoing invoices
    final primaryColor = isIncoming ? const Color(0xFFF97316) : const Color(0xFF00D09E);
    final gradientEnd = isIncoming ? const Color(0xFFFB923C) : const Color(0xFF34D399);

    // Permission checks
    final canView = isIncoming ? currentRole.canViewIncomingInvoices : currentRole.canViewOutgoingInvoices;
    final canManage = isIncoming ? currentRole.canManageIncomingInvoices : currentRole.canManageOutgoingInvoices;

    if (!canView) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF06150F) : const Color(0xFFF4FAF7),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF06150F) : const Color(0xFFF4FAF7),
          elevation: 0,
          title: Text(isIncoming ? 'Hóa đơn đầu vào' : 'Hóa đơn đầu ra'),
        ),
        body: const Center(
          child: Text(
            'Bạn không có quyền truy cập màn hình này.',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      );
    }

    final invoicesAsync = ref.watch(allInvoicesProvider);

    return invoicesAsync.when(
      loading: () => Scaffold(
        backgroundColor: isDark ? const Color(0xFF06150F) : const Color(0xFFF4FAF7),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SpinKitWaveSpinner(
                color: const Color(0xFF00D09E),
                size: 100,
                trackColor: const Color(0xFF00D09E).withValues(alpha: 0.2),
                waveColor: const Color(0xFF00D09E).withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Đang tải dữ liệu...',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: isDark ? const Color(0xFF06150F) : const Color(0xFFF4FAF7),
        body: Center(
          child: Text(
            'Lỗi: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
      data: (invoices) {
        var list = invoices;
         // Filter by invoice type
        list = list.where((inv) => inv.type == (isIncoming ? InvoiceType.incoming : InvoiceType.outgoing)).toList();

        // Filter by time period
        list = list.where((inv) => _isWithinPeriod(inv.issuedDate)).toList();

        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          list = list.where((inv) {
            final partner = (inv.type == InvoiceType.incoming ? inv.sellerName : inv.buyerName).toLowerCase();
            final invNum = inv.invoiceNumber.toLowerCase();
            return partner.contains(_searchQuery) || invNum.contains(_searchQuery);
          }).toList();
        }

        final timeFilteredList = list;
        final allCount = timeFilteredList.where((inv) => inv.status != InvoiceStatus.deleted).length;
        final confirmedCount = timeFilteredList.where((inv) => inv.status != InvoiceStatus.deleted && inv.transactionStatus == InvoiceTransactionStatus.confirmedCreated).length;
        final draftCount = timeFilteredList.where((inv) => inv.status != InvoiceStatus.deleted && inv.transactionStatus == InvoiceTransactionStatus.draftCreated).length;
        final notCreatedCount = timeFilteredList.where((inv) => inv.status != InvoiceStatus.deleted && inv.transactionStatus == InvoiceTransactionStatus.notCreated).length;

        if (_selectedStatus == 'deleted') {
          list = list.where((inv) => inv.status == InvoiceStatus.deleted).toList();
        } else {
          list = list.where((inv) => inv.status != InvoiceStatus.deleted).toList();
          if (_selectedStatus == 'confirmed') {
            list = list.where((inv) => inv.transactionStatus == InvoiceTransactionStatus.confirmedCreated).toList();
          } else if (_selectedStatus == 'draft') {
            list = list.where((inv) => inv.transactionStatus == InvoiceTransactionStatus.draftCreated).toList();
          } else if (_selectedStatus == 'notCreated') {
            list = list.where((inv) => inv.transactionStatus == InvoiceTransactionStatus.notCreated).toList();
          }
        }

        // Sort by date descending
        list.sort((a, b) => b.issuedDate.compareTo(a.issuedDate));

        // Calculate overview stats
        final totalAmount = list.fold<double>(0.0, (sum, inv) => sum + inv.totalAmount);
        final totalSubtotal = list.fold<double>(0.0, (sum, inv) => sum + inv.subtotal);
        final totalVat = list.fold<double>(0.0, (sum, inv) => sum + inv.vatAmount);

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF06150F) : const Color(0xFFF4FAF7),
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF06150F) : const Color(0xFFF4FAF7),
            elevation: 0,
            centerTitle: false,
            titleSpacing: 20,
            title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [primaryColor, gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  isIncoming ? 'Hóa đơn đầu vào' : 'Hóa đơn đầu ra',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 22,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.red),
                tooltip: 'Xóa toàn bộ data',
                onPressed: () async {
                  final db = FirebaseFirestore.instance;
                  final invs = await db.collection('invoices').get();
                  for(var doc in invs.docs) { await doc.reference.delete(); }
                  final trans = await db.collection('transactions').get();
                  for(var doc in trans.docs) { await doc.reference.delete(); }
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa toàn bộ data!')));
                  _refreshInvoices();
                },
              )
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refreshInvoices,
            color: primaryColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
              // Period Filter Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0D251C) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildPeriodTab('all', 'Tất cả'),
                      _buildPeriodTab('today', 'Hôm nay'),
                      _buildPeriodTab('month', 'Tháng này'),
                      _buildPeriodTab('year', 'Năm nay'),
                      Container(
                        height: 20,
                        width: 1,
                        color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            locale: const Locale('vi', 'VN'),
                            initialDateRange: _customDateRange ?? DateTimeRange(
                              start: DateTime.now().subtract(const Duration(days: 7)),
                              end: DateTime.now(),
                            ),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData(
                                  useMaterial3: true,
                                  brightness: isDark ? Brightness.dark : Brightness.light,
                                  colorScheme: isDark
                                      ? ColorScheme.dark(
                                          primary: primaryColor,
                                          onPrimary: Colors.white,
                                          surface: const Color(0xFF0D251C),
                                          onSurface: Colors.white,
                                        )
                                      : ColorScheme.light(
                                          primary: primaryColor,
                                          onPrimary: Colors.white,
                                          surface: Colors.white,
                                          onSurface: const Color(0xFF1E293B),
                                        ),
                                  appBarTheme: AppBarTheme(
                                    backgroundColor: isDark ? const Color(0xFF0C2C1F) : primaryColor,
                                    foregroundColor: Colors.white,
                                    iconTheme: const IconThemeData(color: Colors.white),
                                    actionsIconTheme: const IconThemeData(color: Colors.white),
                                    titleTextStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                    toolbarTextStyle: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  datePickerTheme: DatePickerThemeData(
                                    headerBackgroundColor: isDark ? const Color(0xFF0C2C1F) : primaryColor,
                                    headerForegroundColor: Colors.white,
                                    backgroundColor: isDark ? const Color(0xFF0D251C) : Colors.white,
                                    headerHeadlineStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                    headerHelpStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              _customDateRange = picked;
                              _selectedPeriod = 'custom';
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: _selectedPeriod == 'custom' ? primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: _selectedPeriod == 'custom' 
                                ? Colors.white 
                                : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Header balance layout matching the transaction screen style
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    // Consolidated Compact Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0D251C) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: isDark 
                                ? Colors.black.withOpacity(0.2) 
                                : Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Left side: Total amount
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.receipt_long_rounded,
                                      size: 14,
                                      color: isDark ? primaryColor.withOpacity(0.7) : primaryColor.withOpacity(0.8),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _getPeriodTitle(isIncoming ? 'Tổng Mua Vào' : 'Tổng Bán Ra'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isDark ? Colors.white70 : Colors.black54,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    currencyFormatter.format(totalAmount),
                                    style: TextStyle(
                                      color: isDark ? primaryColor : const Color(0xFF093021),
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Vertical divider
                          Container(
                            height: 36,
                            width: 1,
                            color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          // Right side: Subtotal & VAT (Compact)
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Chưa thuế: ${currencyFormatter.format(totalSubtotal)}',
                                    style: TextStyle(
                                      color: isDark ? Colors.white70 : Colors.black87,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Thuế VAT: ${currencyFormatter.format(totalVat)}',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar & Filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo đối tác, số HĐ...',
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                    prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white38 : Colors.black38),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0D251C) : Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.toLowerCase();
                    });
                  },
                ),
              ),

              // Status Filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Trạng thái:',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('all', 'Tất cả', isDark, primaryColor, allCount),
                            const SizedBox(width: 8),
                            _buildFilterChip('confirmed', 'Đã xác nhận', isDark, primaryColor, confirmedCount),
                            const SizedBox(width: 8),
                            _buildFilterChip('draft', 'Bản nháp', isDark, primaryColor, draftCount),
                            const SizedBox(width: 8),
                            _buildFilterChip('notCreated', 'Chưa tạo', isDark, primaryColor, notCreatedCount),
                          ],
                        ),
                      ),
                    ),
                    if (canManage) ...[
                      const SizedBox(width: 8),
                      _buildTrashChip(isDark),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Note about editing
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 12, color: primaryColor.withOpacity(0.8)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Chỉ có thể sửa hoặc xóa đối với hóa đơn "Chưa tạo GD"',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),


              // Invoice List Area
              list.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_rounded, size: 80, color: Colors.grey.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          const Text('Không có hóa đơn nào', style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final isMobile = MediaQuery.of(context).size.width < 600;
                            final inv = list[index];
                            Widget card = Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0E2219) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  if (!isDark)
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                ],
                                border: Border.all(
                                  color: isDark ? const Color(0xFF1A382B) : const Color(0xFFEDF2F7),
                                  width: 1,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    if (isIncoming) {
                                      context.push('/invoices/incoming/${inv.id}');
                                    } else {
                                      context.push('/invoices/outgoing/${inv.id}');
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: primaryColor.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isIncoming ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                            color: primaryColor,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      inv.invoiceNumber,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: isDark ? Colors.white : const Color(0xFF093021),
                                                        fontSize: 16,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Builder(builder: (context) {
                                                    final syncItem = queueItems.firstWhereOrNull((e) => e.entityId == inv.id);
                                                    if (syncItem != null) {
                                                      if (syncItem.status == SyncStatus.pending) {
                                                        return const Icon(Icons.sync, color: Colors.blue, size: 16);
                                                      } else {
                                                        return const Icon(Icons.error_outline, color: Colors.red, size: 16);
                                                      }
                                                    } else {
                                                      return const Icon(Icons.cloud_done_outlined, color: Colors.green, size: 16);
                                                    }
                                                  }),
                                                ],
                                              ),
                                              if (queueItems.any((e) => e.entityId == inv.id && e.status == SyncStatus.error))
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4),
                                                  child: Text(
                                                    queueItems.firstWhereOrNull((e) => e.entityId == inv.id)?.errorMessage ?? 'Lỗi đồng bộ',
                                                    style: const TextStyle(color: Colors.red, fontSize: 11, fontStyle: FontStyle.italic),
                                                  ),
                                                ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${inv.type == InvoiceType.incoming ? inv.sellerName : inv.buyerName} • ${dateFormatter.format(inv.issuedDate)}',
                                                style: TextStyle(
                                                  color: isDark ? Colors.white38 : Colors.black45,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              _buildStatusChip(inv.transactionStatus),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              currencyFormatter.format(inv.totalAmount),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? primaryColor : const Color(0xFF093021),
                                                fontSize: 15,
                                              ),
                                            ),
                                            if (inv.vatAmount > 0) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Thuế: +${currencyFormatter.format(inv.vatAmount)}',
                                                style: const TextStyle(
                                                  color: Colors.blue,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (!isMobile && canManage && (inv.status == InvoiceStatus.deleted || inv.transactionStatus == InvoiceTransactionStatus.notCreated)) ...[
                                          const SizedBox(width: 8),
                                          PopupMenuButton<String>(
                                            icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.white54 : Colors.black54),
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                if (isIncoming) {
                                                  context.push('/invoices/incoming/edit/${inv.id}');
                                                } else {
                                                  context.push('/invoices/outgoing/edit/${inv.id}');
                                                }
                                              } else if (value == 'delete') {
                                                _confirmSoftDelete(inv);
                                              } else if (value == 'restore') {
                                                _confirmRestore(inv);
                                              } else if (value == 'hard_delete') {
                                                _confirmHardDelete(inv);
                                              }
                                            },
                                            itemBuilder: (context) {
                                              if (inv.status == InvoiceStatus.deleted) {
                                                return [
                                                  const PopupMenuItem(
                                                    value: 'restore',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.restore_rounded, size: 18, color: Colors.green),
                                                        SizedBox(width: 8),
                                                        Text('Khôi phục'),
                                                      ],
                                                    ),
                                                  ),
                                                  const PopupMenuItem(
                                                    value: 'hard_delete',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.delete_forever_rounded, size: 18, color: Colors.red),
                                                        SizedBox(width: 8),
                                                        Text('Xóa vĩnh viễn', style: TextStyle(color: Colors.red)),
                                                      ],
                                                    ),
                                                  ),
                                                ];
                                              }
                                              return [
                                                const PopupMenuItem(
                                                  value: 'edit',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.edit_rounded, size: 18, color: Colors.blue),
                                                      SizedBox(width: 8),
                                                      Text('Sửa'),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                                                      SizedBox(width: 8),
                                                      Text('Xóa'),
                                                    ],
                                                  ),
                                                ),
                                              ];
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );

                            if (canManage && (inv.status == InvoiceStatus.deleted || inv.transactionStatus == InvoiceTransactionStatus.notCreated) && isMobile) {
                              card = Slidable(
                                key: ValueKey(inv.id),
                                endActionPane: ActionPane(
                                  motion: const ScrollMotion(),
                                  children: inv.status == InvoiceStatus.deleted
                                      ? [
                                          SlidableAction(
                                            onPressed: (context) => _confirmRestore(inv),
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            icon: Icons.restore_rounded,
                                            label: 'Khôi phục',
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(16),
                                              bottomLeft: Radius.circular(16),
                                            ),
                                          ),
                                          SlidableAction(
                                            onPressed: (context) => _confirmHardDelete(inv),
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            icon: Icons.delete_forever_rounded,
                                            label: 'Xóa VV',
                                            borderRadius: const BorderRadius.only(
                                              topRight: Radius.circular(16),
                                              bottomRight: Radius.circular(16),
                                            ),
                                          ),
                                        ]
                                      : [
                                          SlidableAction(
                                            onPressed: (context) {
                                              if (isIncoming) {
                                                context.push('/invoices/incoming/edit/${inv.id}');
                                              } else {
                                                context.push('/invoices/outgoing/edit/${inv.id}');
                                              }
                                            },
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                            icon: Icons.edit_rounded,
                                            label: 'Sửa',
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(16),
                                              bottomLeft: Radius.circular(16),
                                            ),
                                          ),
                                          SlidableAction(
                                            onPressed: (context) => _confirmSoftDelete(inv),
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            icon: Icons.delete_rounded,
                                            label: 'Xóa',
                                            borderRadius: const BorderRadius.only(
                                              topRight: Radius.circular(16),
                                              bottomRight: Radius.circular(16),
                                            ),
                                          ),
                                        ],
                                ),
                                child: card,
                              );
                            }

                            return card;
                            },
                          ),
                  ],
                ),
              ),
            ),
          floatingActionButton: canManage
              ? ScaleOnTap(
                  onTap: () {
                    if (isIncoming) {
                      context.push('/invoices/capture');
                    } else {
                      context.push('/invoices/outgoing/new');
                    }
                  },
                  child: FloatingActionButton.extended(
                    onPressed: null,
                    backgroundColor: primaryColor,
                    icon: Icon(isIncoming ? Icons.qr_code_scanner_rounded : Icons.add_rounded, color: Colors.white),
                    label: Text(
                      isIncoming ? 'Quét hóa đơn' : 'Tạo Hóa đơn',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }


  bool _isWithinPeriod(DateTime date) {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'today':
        return date.year == now.year && date.month == now.month && date.day == now.day;
      case 'month':
        return date.year == now.year && date.month == now.month;
      case 'year':
        return date.year == now.year;
      case 'custom':
        if (_customDateRange == null) return true;
        final start = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
        final end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
        return date.isAfter(start.subtract(const Duration(seconds: 1))) && date.isBefore(end.add(const Duration(seconds: 1)));
      case 'all':
      default:
        return true;
    }
  }

  String _getPeriodTitle(String prefix) {
    switch (_selectedPeriod) {
      case 'today':
        return '$prefix Hôm Nay';
      case 'month':
        return '$prefix Tháng Này';
      case 'year':
        return '$prefix Năm Nay';
      case 'custom':
        if (_customDateRange != null) {
          final df = DateFormat('dd/MM');
          return '$prefix (${df.format(_customDateRange!.start)} - ${df.format(_customDateRange!.end)})';
        }
        return '$prefix Tùy Chọn';
      case 'all':
      default:
        return prefix;
    }
  }

  Widget _buildPeriodTab(String id, String label) {
    final isSelected = _selectedPeriod == id;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncoming = widget.type == 'incoming';
    final primaryColor = isIncoming ? const Color(0xFFF97316) : const Color(0xFF00D09E);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = id;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
