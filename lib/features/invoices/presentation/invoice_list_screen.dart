import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../core/providers/role_provider.dart';
import '../../../core/providers/category_providers.dart';
import '../../../domain/entities/invoice_entity.dart';
import '../../../core/widgets/scale_on_tap.dart';
import '../providers/invoice_provider.dart';


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
  InvoiceTransactionStatus? _filterTransactionStatus; // null = all, notCreated, created
  // Mobile: infinite scroll limit
  int _displayLimit = 15;
  // Desktop/Web: pagination
  int _currentPage = 1;
  int _itemsPerPage = 10;

  Future<void> _refreshInvoices() async {
    ref.invalidate(allInvoicesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final currentRole = ref.watch(roleProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);
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
        // ignore: unused_local_variable
        final categories = categoriesAsync.value ?? [];

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

        // Filter by transaction status
        if (_filterTransactionStatus != null) {
          list = list.where((inv) => inv.transactionStatus == _filterTransactionStatus).toList();
        }

        // Sort by date descending
        list.sort((a, b) => b.issuedDate.compareTo(a.issuedDate));

        // Calculate overview stats
        final totalAmount = list.fold<double>(0.0, (sum, inv) => sum + inv.totalAmount);
        final totalSubtotal = list.fold<double>(0.0, (sum, inv) => sum + inv.subtotal);
        final totalVat = list.fold<double>(0.0, (sum, inv) => sum + inv.vatAmount);

        // Adaptive layout: Desktop/Web = fixed viewport + pagination; Mobile = infinite scroll
        final isDesktopOrWeb = kIsWeb ||
            (!Platform.isAndroid && !Platform.isIOS) ||
            MediaQuery.of(context).size.width >= 900;
        final totalCount = list.length;
        final totalPages = max(1, (totalCount / _itemsPerPage).ceil());
        final currentPage = _currentPage.clamp(1, totalPages);
        final startIndex = (currentPage - 1) * _itemsPerPage;
        final endIndex = min(startIndex + _itemsPerPage, totalCount);
        final displayList = isDesktopOrWeb
            ? ((totalCount > 0) ? list.sublist(startIndex, endIndex) : <InvoiceEntity>[])
            : list;

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
            // Desktop/Web: action button in AppBar so no FAB overlapping pagination bar
            actions: isDesktopOrWeb && canManage
                ? [
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (isIncoming) {
                            context.push('/invoices/capture');
                          } else {
                            context.push('/invoices/outgoing/new');
                          }
                        },
                        icon: Icon(
                          isIncoming ? Icons.qr_code_scanner_rounded : Icons.add_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: Text(
                          isIncoming ? 'Quét hóa đơn' : 'Tạo Hóa đơn',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ]
                : null,
          ),
          body: isDesktopOrWeb
              // ── DESKTOP / WEB: Fixed Viewport Layout ─────────────────────────────
              // Header is fixed; only the list scrolls; pagination bar always visible
              ? Column(
                  children: [
                    // Fixed header (filters, stats, search)
                    _buildFiltersHeader(
                      isDark: isDark,
                      primaryColor: primaryColor,
                      isIncoming: isIncoming,
                      totalAmount: totalAmount,
                      totalSubtotal: totalSubtotal,
                      totalVat: totalVat,
                    ),
                    // Scrollable list fills remaining viewport
                    Expanded(
                      child: list.isEmpty
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
                              padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
                              itemCount: displayList.length,
                              itemBuilder: (context, index) {
                                return _buildInvoiceCard(
                                  inv: displayList[index],
                                  primaryColor: primaryColor,
                                  isDark: isDark,
                                  isIncoming: isIncoming,
                                  dateFormatter: dateFormatter,
                                  currencyFormatter: currencyFormatter,
                                );
                              },
                            ),
                    ),
                    // Sticky pagination bar always visible at bottom
                    _buildPaginationBar(
                      context: context,
                      totalCount: totalCount,
                      totalPages: totalPages,
                      currentPage: currentPage,
                      startIndex: startIndex,
                      endIndex: endIndex,
                      primaryColor: primaryColor,
                      isDark: isDark,
                    ),
                  ],
                )
              // ── MOBILE: Infinite Scroll Layout ───────────────────────────────────
              : RefreshIndicator(
                  onRefresh: _refreshInvoices,
                  color: primaryColor,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      if (scrollInfo.metrics.extentAfter < 50 && list.length > _displayLimit) {
                        if (_displayLimit < list.length) {
                          setState(() {
                            _displayLimit = min(_displayLimit + 15, list.length);
                          });
                        }
                        return true;
                      }
                      return false;
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          _buildFiltersHeader(
                            isDark: isDark,
                            primaryColor: primaryColor,
                            isIncoming: isIncoming,
                            totalAmount: totalAmount,
                            totalSubtotal: totalSubtotal,
                            totalVat: totalVat,
                          ),
                          // Invoice list with infinite scroll trigger
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
                                  itemCount: min(_displayLimit, list.length) + 1,
                                  itemBuilder: (context, index) {
                                    if (index == min(_displayLimit, list.length)) {
                                      // Footer: loading indicator or "all shown" message
                                      if (_displayLimit < list.length) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                                          child: Center(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF0F2C20) : const Color(0xFFF0FDF4),
                                                borderRadius: BorderRadius.circular(24),
                                                border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: primaryColor)),
                                                  const SizedBox(width: 10),
                                                  Text('Đang tải thêm hóa đơn...', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? primaryColor : const Color(0xFF065F46))),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                                        child: Center(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.check_circle_outline_rounded, size: 16, color: isDark ? Colors.white38 : Colors.grey),
                                              const SizedBox(width: 6),
                                              Text('Đã hiển thị tất cả ${list.length} hóa đơn', style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey, fontWeight: FontWeight.w500)),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                    return _buildInvoiceCard(
                                      inv: list[index],
                                      primaryColor: primaryColor,
                                      isDark: isDark,
                                      isIncoming: isIncoming,
                                      dateFormatter: dateFormatter,
                                      currencyFormatter: currencyFormatter,
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
          // Mobile FAB only (Desktop/Web uses AppBar button)
          floatingActionButton: !isDesktopOrWeb && canManage
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
                    label: Text(isIncoming ? 'Quét hóa đơn' : 'Tạo Hóa đơn', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              : null,
        );
      },
    );
  }

  /// Shared filter header (period tabs + stats card + search/filter row).
  /// Used by both Desktop/Web (Column child) and Mobile (scroll Column child).
  Widget _buildFiltersHeader({
    required bool isDark,
    required Color primaryColor,
    required bool isIncoming,
    required double totalAmount,
    required double totalSubtotal,
    required double totalVat,
  }) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return Column(
      children: [
        // Period Filter Tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0D251C) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                _buildPeriodTab('all', 'Tất cả'),
                _buildPeriodTab('today', 'Hôm nay'),
                _buildPeriodTab('month', 'Tháng này'),
                _buildPeriodTab('year', 'Năm nay'),
                Container(height: 20, width: 1, color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08), margin: const EdgeInsets.symmetric(horizontal: 4)),
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
                                ? ColorScheme.dark(primary: primaryColor, onPrimary: Colors.white, surface: const Color(0xFF0D251C), onSurface: Colors.white)
                                : ColorScheme.light(primary: primaryColor, onPrimary: Colors.white, surface: Colors.white, onSurface: const Color(0xFF1E293B)),
                            appBarTheme: AppBarTheme(
                              backgroundColor: isDark ? const Color(0xFF0C2C1F) : primaryColor,
                              foregroundColor: Colors.white,
                              iconTheme: const IconThemeData(color: Colors.white),
                              actionsIconTheme: const IconThemeData(color: Colors.white),
                              titleTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                              toolbarTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                            textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: Colors.white, textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                            datePickerTheme: DatePickerThemeData(
                              headerBackgroundColor: isDark ? const Color(0xFF0C2C1F) : primaryColor,
                              headerForegroundColor: Colors.white,
                              backgroundColor: isDark ? const Color(0xFF0D251C) : Colors.white,
                              headerHeadlineStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                              headerHelpStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
                        _currentPage = 1;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: _selectedPeriod == 'custom' ? primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.calendar_today_rounded, size: 16, color: _selectedPeriod == 'custom' ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Stats Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0D251C) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
              border: Border.all(color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.receipt_long_rounded, size: 14, color: isDark ? primaryColor.withOpacity(0.7) : primaryColor.withOpacity(0.8)),
                        const SizedBox(width: 4),
                        Expanded(child: Text(_getPeriodTitle(isIncoming ? 'Tổng Mua Vào' : 'Tổng Bán Ra'), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.2))),
                      ]),
                      const SizedBox(height: 4),
                      FittedBox(fit: BoxFit.scaleDown, child: Text(currencyFormatter.format(totalAmount), style: TextStyle(color: isDark ? primaryColor : const Color(0xFF093021), fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
                    ],
                  ),
                ),
                Container(height: 36, width: 1, color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08), margin: const EdgeInsets.symmetric(horizontal: 10)),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(fit: BoxFit.scaleDown, child: Text('Chưa thuế: ${currencyFormatter.format(totalSubtotal)}', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 11, fontWeight: FontWeight.w500))),
                      const SizedBox(height: 4),
                      FittedBox(fit: BoxFit.scaleDown, child: Text('Thuế VAT: ${currencyFormatter.format(totalVat)}', style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Search Bar & Filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Expanded(
                flex: 3,
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
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 1.5)),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.toLowerCase();
                      _currentPage = 1;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0D251C) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<InvoiceTransactionStatus?>(
                      isExpanded: true,
                      value: _filterTransactionStatus,
                      icon: Icon(Icons.filter_list_rounded, color: isDark ? Colors.white54 : Colors.black54, size: 20),
                      dropdownColor: isDark ? const Color(0xFF0D251C) : Colors.white,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Tất cả trạng thái')),
                        DropdownMenuItem(value: InvoiceTransactionStatus.created, child: Text('Đã tạo GD')),
                        DropdownMenuItem(value: InvoiceTransactionStatus.notCreated, child: Text('Chưa tạo GD')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _filterTransactionStatus = val;
                          _currentPage = 1;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceCard({
    required InvoiceEntity inv,
    required Color primaryColor,
    required bool isDark,
    required bool isIncoming,
    required DateFormat dateFormatter,
    required NumberFormat currencyFormatter,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E2219) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: isDark ? const Color(0xFF1A382B) : const Color(0xFFEDF2F7), width: 1),
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
                  decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(isIncoming ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(inv.invoiceNumber, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF093021), fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        '${inv.type == InvoiceType.incoming ? inv.sellerName : inv.buyerName} • ${dateFormatter.format(inv.issuedDate)}',
                        style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: inv.transactionStatus == InvoiceTransactionStatus.created
                              ? const Color(0xFF00D09E).withOpacity(0.1)
                              : const Color(0xFFF97316).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: inv.transactionStatus == InvoiceTransactionStatus.created
                                ? const Color(0xFF00D09E).withOpacity(0.3)
                                : const Color(0xFFF97316).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          inv.transactionStatus == InvoiceTransactionStatus.created ? 'Đã tạo GD' : 'Chưa tạo GD',
                          style: TextStyle(
                            color: inv.transactionStatus == InvoiceTransactionStatus.created ? const Color(0xFF00D09E) : const Color(0xFFF97316),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(currencyFormatter.format(inv.totalAmount), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? primaryColor : const Color(0xFF093021), fontSize: 15)),
                    if (inv.vatAmount > 0) ...[
                      const SizedBox(height: 2),
                      Text('Thuế: +${currencyFormatter.format(inv.vatAmount)}', style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.w500)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
            _currentPage = 1;
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
                color: isSelected ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationBar({
    required BuildContext context,
    required int totalCount,
    required int totalPages,
    required int currentPage,
    required int startIndex,
    required int endIndex,
    required Color primaryColor,
    required bool isDark,
  }) {
    if (totalCount == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E2219) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1A382B) : const Color(0xFFE2E8F0), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 650;

          final infoText = Text(
            'Hiển thị ${totalCount > 0 ? startIndex + 1 : 0} - $endIndex trên tổng số $totalCount hóa đơn',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.black87),
          );

          final itemsPerPageDropdown = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Số dòng:', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: isDark ? const Color(0xFF13362A) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _itemsPerPage,
                    isDense: true,
                    dropdownColor: isDark ? const Color(0xFF0D251C) : Colors.white,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                    items: const [10, 15, 30, 50].map((val) => DropdownMenuItem<int>(value: val, child: Text('$val dòng'))).toList(),
                    onChanged: (newVal) {
                      if (newVal != null) setState(() { _itemsPerPage = newVal; _currentPage = 1; });
                    },
                  ),
                ),
              ),
            ],
          );

          final List<Widget> pageButtons = [];
          pageButtons.add(_buildPageIconButton(icon: Icons.first_page_rounded, enabled: currentPage > 1, onTap: () => setState(() => _currentPage = 1), isDark: isDark));
          pageButtons.add(const SizedBox(width: 4));
          pageButtons.add(_buildPageIconButton(icon: Icons.chevron_left_rounded, enabled: currentPage > 1, onTap: () => setState(() => _currentPage = currentPage - 1), isDark: isDark));
          pageButtons.add(const SizedBox(width: 6));

          for (int p = 1; p <= totalPages; p++) {
            if (totalPages > 7) {
              if (p != 1 && p != totalPages && (p < currentPage - 1 || p > currentPage + 1)) {
                if (p == currentPage - 2 || p == currentPage + 2) {
                  pageButtons.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 2.0), child: Text('...', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey))));
                }
                continue;
              }
            }
            final isSelected = p == currentPage;
            pageButtons.add(
              GestureDetector(
                onTap: () => setState(() => _currentPage = p),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : (isDark ? const Color(0xFF13362A) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('$p', style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87))),
                ),
              ),
            );
          }

          pageButtons.add(const SizedBox(width: 6));
          pageButtons.add(_buildPageIconButton(icon: Icons.chevron_right_rounded, enabled: currentPage < totalPages, onTap: () => setState(() => _currentPage = currentPage + 1), isDark: isDark));
          pageButtons.add(const SizedBox(width: 4));
          pageButtons.add(_buildPageIconButton(icon: Icons.last_page_rounded, enabled: currentPage < totalPages, onTap: () => setState(() => _currentPage = totalPages), isDark: isDark));

          if (isCompact) {
            return Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [infoText, itemsPerPageDropdown]),
                const SizedBox(height: 10),
                SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: pageButtons)),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [infoText, Row(children: [itemsPerPageDropdown, const SizedBox(width: 16), Row(children: pageButtons)])],
          );
        },
      ),
    );
  }

  Widget _buildPageIconButton({required IconData icon, required bool enabled, required VoidCallback onTap, required bool isDark}) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF13362A) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: enabled ? (isDark ? Colors.white70 : Colors.black87) : (isDark ? Colors.white24 : Colors.grey.shade400)),
      ),
    );
  }
}
