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
  String _searchQuery = '';
  late Future<List<InvoiceEntity>> _invoicesFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _invoicesFuture = ref.read(invoiceRepositoryProvider).getAll();
  }

  void _refreshInvoices() {
    setState(() {
      _invoicesFuture = ref.read(invoiceRepositoryProvider).getAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentRole = ref.watch(roleProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncoming = widget.type == 'incoming';
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final dateFormatter = DateFormat('dd/MM/yyyy');
    
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
          Center(
            child: ScaleOnTap(
              onTap: _refreshInvoices,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0D281E) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                  ],
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFEDF2F7),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.refresh_rounded,
                  color: isDark ? (isIncoming ? const Color(0xFFFED7AA) : const Color(0xFF86EFAC)) : primaryColor,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: FutureBuilder<List<InvoiceEntity>>(
        future: _invoicesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          var list = snapshot.data ?? [];
          // Filter by invoice type
          list = list.where((inv) => inv.type == (isIncoming ? InvoiceType.incoming : InvoiceType.outgoing)).toList();

          // Filter by search query
          if (_searchQuery.isNotEmpty) {
            list = list.where((inv) {
              final partner = inv.partnerName.toLowerCase();
              final invNum = inv.invoiceNumber.toLowerCase();
              return partner.contains(_searchQuery) || invNum.contains(_searchQuery);
            }).toList();
          }

          // Calculate overview stats
          final totalAmount = list.fold<double>(0.0, (sum, inv) => sum + inv.totalAmount);
          final totalSubtotal = list.fold<double>(0.0, (sum, inv) => sum + inv.subtotal);
          final totalVat = list.fold<double>(0.0, (sum, inv) => sum + inv.vatAmount);

          return Column(
            children: [
              // Header balance layout matching the transaction screen style
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    // Total Invoice Amount Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                size: 16,
                                color: isDark ? primaryColor.withOpacity(0.7) : primaryColor.withOpacity(0.8),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isIncoming ? 'Tổng Tiền Mua Vào' : 'Tổng Tiền Bán Ra',
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black54,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
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
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Subtotal & VAT Side by Side Cards
                    Row(
                      children: [
                        // Subtotal Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0D251C) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark 
                                      ? Colors.black.withOpacity(0.15) 
                                      : Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.attach_money_rounded,
                                        color: primaryColor,
                                        size: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Chưa thuế',
                                      style: TextStyle(
                                        color: isDark ? Colors.white70 : Colors.black54,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    currencyFormatter.format(totalSubtotal),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isDark ? primaryColor : const Color(0xFF093021),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // VAT Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0D251C) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark 
                                      ? Colors.black.withOpacity(0.15) 
                                      : Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.percent_rounded,
                                        color: Colors.blue,
                                        size: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Thuế VAT',
                                      style: TextStyle(
                                        color: isDark ? Colors.white70 : Colors.black54,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    currencyFormatter.format(totalVat),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search Bar
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
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

              // Invoice List Area
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              size: 64,
                              color: isDark ? Colors.white24 : Colors.black12,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Không tìm thấy hóa đơn nào',
                              style: TextStyle(
                                color: isDark ? Colors.white38 : Colors.black45,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: list.length,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemBuilder: (context, index) {
                          final inv = list[index];
                          return Container(
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
                                  context.go('/invoices/incoming/${inv.id}');
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
                                            Text(
                                              inv.partnerName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? Colors.white : const Color(0xFF093021),
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Số HĐ: ${inv.invoiceNumber} • ${dateFormatter.format(inv.issuedDate)}',
                                              style: TextStyle(
                                                color: isDark ? Colors.white38 : Colors.black45,
                                                fontSize: 12,
                                              ),
                                            ),
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
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
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
  }
}
