import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:smart_finance/core/providers/app_providers.dart';
import 'package:smart_finance/core/providers/role_provider.dart';
import 'package:smart_finance/domain/entities/invoice_entity.dart';
import 'package:smart_finance/domain/entities/transaction_entity.dart';
import 'package:smart_finance/core/widgets/scale_on_tap.dart';
import 'package:smart_finance/core/constants/route_names.dart';

Color _parseColor(String? hexString) {
  if (hexString == null || hexString.isEmpty) return Colors.grey;
  try {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  } catch (e) {
    return Colors.grey;
  }
}

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<InvoiceDetailScreen> createState() =>
      _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  String _getOcrStatusText(OcrStatus status) {
    switch (status) {
      case OcrStatus.notStarted:
        return 'Chưa bắt đầu';
      case OcrStatus.imageSelected:
        return 'Đã chọn ảnh';
      case OcrStatus.scanning:
        return 'Đang quét';
      case OcrStatus.extracted:
        return 'Đã trích xuất';
      case OcrStatus.failed:
        return 'Quét thất bại';
    }
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D251C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDark ? Colors.white : const Color(0xFF093021),
            ),
          ),
          const SizedBox(height: 8),
          Divider(
            color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

    String formatQuantity(double q) {
      return q == q.toInt() ? q.toInt().toString() : q.toString().replaceAll('.', ',');
    }

    final invoiceRepository = ref.watch(invoiceRepositoryProvider);
    final transactionRepository = ref.watch(transactionRepositoryProvider);
    final currentRole = ref.watch(roleProvider);
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        invoiceRepository.getById(widget.invoiceId),
        transactionRepository.getAll(),
      ]),
      builder: (context, snapshot) {
        final invoice = snapshot.data?[0] as InvoiceEntity?;
        final transactions = (snapshot.data?[1] as List<TransactionEntity>?) ?? [];
        final linkedTxs = transactions.where((tx) => tx.invoiceId == widget.invoiceId && tx.status != TransactionStatus.deleted).toList();
        final confirmedTx = linkedTxs.where((tx) => tx.status == TransactionStatus.confirmed).firstOrNull;
        final hasTransaction = linkedTxs.isNotEmpty;

        final isIncoming = invoice?.type != InvoiceType.outgoing;

        String txStatusText = 'Chưa tạo GD';
        Color txStatusColor = const Color(0xFFF97316);
        if (confirmedTx != null) {
          txStatusText = 'Đã tạo GD';
          txStatusColor = const Color(0xFF00D09E);
        }

        return Scaffold(
          backgroundColor: isDark
              ? const Color(0xFF06150F)
              : const Color(0xFFF4FAF7),
          appBar: AppBar(
            backgroundColor: isDark
                ? const Color(0xFF06150F)
                : const Color(0xFFF4FAF7),
            elevation: 0,
            centerTitle: false,
            titleSpacing: 0,
            leading: Center(
              child: ScaleOnTap(
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go(
                      isIncoming ? '/invoices/incoming' : '/invoices/outgoing',
                    );
                  }
                },
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
                      color: isDark
                          ? const Color(0xFF1E3A2F)
                          : const Color(0xFFEDF2F7),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: isDark
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFF00D09E),
                    size: 16,
                  ),
                ),
              ),
            ),
            title: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF00D09E), Color(0xFF34D399)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Text(
                'Chi tiết hóa đơn',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 22,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            actions: [
              if (invoice != null && invoice.type == InvoiceType.outgoing)
                Center(
                  child: ScaleOnTap(
                    onTap: () => context.push(
                      '/invoices/outgoing/preview/${invoice.id}',
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(right: 20),
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
                          color: isDark
                              ? const Color(0xFF1E3A2F)
                              : const Color(0xFFEDF2F7),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.picture_as_pdf_rounded,
                        color: isDark
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFF00D09E),
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00D09E)),
                )
              : invoice == null
              ? Center(
                  child: Text(
                    'Không tìm thấy hóa đơn hoặc có lỗi xảy ra.',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Screenshot(
                    controller: _screenshotController,
                    child: Container(
                      color: isDark
                          ? const Color(0xFF06150F)
                          : const Color(0xFFF4FAF7),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header Receipt Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0D251C)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF1E3A2F)
                                    : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withOpacity(0.2)
                                      : Colors.black.withOpacity(0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isIncoming
                                            ? 'Hóa đơn đầu vào'
                                            : 'Hóa đơn đầu ra',
                                        style: TextStyle(
                                          color: isIncoming
                                              ? const Color(0xFFF97316)
                                              : const Color(0xFF00D09E),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? (isIncoming
                                                  ? const Color(0xFF431407)
                                                  : const Color(0xFF064E3B))
                                            : (isIncoming
                                                  ? const Color(0xFFFFF7ED)
                                                  : const Color(0xFFECFDF5)),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _getOcrStatusText(
                                          invoice.ocrStatus,
                                        ).toUpperCase(),
                                        style: TextStyle(
                                          color: isIncoming
                                              ? const Color(0xFFF97316)
                                              : const Color(0xFF00D09E),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Số: ${invoice.invoiceNumber}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF093021),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  currencyFormatter.format(invoice.totalAmount),
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: isIncoming
                                        ? const Color(0xFFF97316)
                                        : const Color(0xFF00D09E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Invoice Format Info Section
                          _buildSection(
                            title: 'Thông tin hóa đơn',
                            isDark: isDark,
                            children: [
                              _DetailRow(label: 'Mẫu số', value: invoice.formNumber ?? '-'),
                              _DetailRow(label: 'Ký hiệu', value: invoice.serialNumber ?? '-'),
                              _DetailRow(label: 'Số hóa đơn', value: invoice.invoiceNumber.split('-').last.replaceAll(RegExp(r'[^0-9]'), '').padLeft(7, '0')),
                            ],
                          ),
                            
                          // Detail Fields Card
                          _buildSection(
                            title: 'Thông tin đơn vị bán',
                            isDark: isDark,
                            children: [
                              _DetailRow(label: 'Tên đơn vị bán', value: invoice.sellerName),
                              _DetailRow(label: 'Mã số thuế', value: invoice.sellerTaxCode),
                              if (invoice.sellerAddress != null && invoice.sellerAddress!.isNotEmpty)
                                _DetailRow(label: 'Địa chỉ', value: invoice.sellerAddress!),
                              if (invoice.sellerPhone != null && invoice.sellerPhone!.isNotEmpty)
                                _DetailRow(label: 'Số điện thoại', value: invoice.sellerPhone!),
                              if (invoice.sellerBankName != null && invoice.sellerBankName!.isNotEmpty)
                                _DetailRow(label: 'Ngân hàng', value: '${invoice.sellerBankName} - ${invoice.sellerBankAccount ?? ""}'),
                            ],
                          ),
                          _buildSection(
                            title: 'Thông tin người mua',
                            isDark: isDark,
                            children: [
                              if (invoice.buyerContactName != null && invoice.buyerContactName!.isNotEmpty)
                                _DetailRow(label: 'Họ tên người mua', value: invoice.buyerContactName!),
                              _DetailRow(label: 'Tên đơn vị', value: invoice.buyerName),
                              _DetailRow(label: 'Mã số thuế', value: invoice.buyerTaxCode),
                              if (invoice.buyerAddress != null && invoice.buyerAddress!.isNotEmpty)
                                _DetailRow(label: 'Địa chỉ', value: invoice.buyerAddress!),
                            ],
                          ),
                          _buildSection(
                            title: 'Chi tiết thanh toán',
                            isDark: isDark,
                            children: [
                              _DetailRow(label: 'Ngày phát hành', value: dateFormatter.format(invoice.issuedDate)),
                              _DetailRow(label: 'Hình thức thanh toán', value: invoice.paymentMethod ?? 'TM/CK'),
                              _DetailRow(label: 'Tiền trước thuế', value: currencyFormatter.format(invoice.subtotal)),
                              _DetailRow(label: 'Thuế suất VAT', value: '${invoice.vatRate}%'),
                              _DetailRow(label: 'Tiền thuế VAT', value: currencyFormatter.format(invoice.vatAmount)),
                              _DetailRow(
                                label: 'Trạng thái giao dịch',
                                value: txStatusText,
                                valueColor: txStatusColor,
                              ),
                              if (invoice.ocrConfidence != null && invoice.type == InvoiceType.incoming)
                                _DetailRow(label: 'Độ tin cậy OCR', value: '${(invoice.ocrConfidence! * 100).toStringAsFixed(1)}%'),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          if (invoice.items.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0D251C)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF1E3A2F)
                                      : const Color(0xFFE2E8F0),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark
                                        ? Colors.black.withOpacity(0.2)
                                        : Colors.black.withOpacity(0.04),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Danh sách dịch vụ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF093021),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Divider(
                                    color: isDark
                                        ? const Color(0xFF1E3A2F)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                  const SizedBox(height: 8),
                                  ...invoice.items.map((item) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF153326) : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item.itemName,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark
                                                        ? Colors.white
                                                        : const Color(0xFF093021),
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                currencyFormatter.format(item.totalAmount),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(0xFF093021),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'SL: ${formatQuantity(item.quantity)} ${item.unit} x ${currencyFormatter.format(item.unitPrice)}',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isDark
                                                      ? Colors.white54
                                                      : Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          if (hasTransaction && !kIsWeb) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _shareScreenshot(context),
                                    icon: const Icon(
                                      Icons.share_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    label: const Text(
                                      'Chia sẻ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00D09E),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _saveScreenshot(context),
                                    icon: const Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    label: const Text(
                                      'Chụp',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Image/PDF View Section
                          if (invoice.imagePath != null &&
                              invoice.imagePath!.isNotEmpty) ...[
                            Text(
                              'Ảnh hóa đơn đính kèm',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF093021),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildAttachmentPreview(
                              context: context,
                              path: invoice.imagePath!,
                              isDark: isDark,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
          bottomNavigationBar: invoice != null
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: confirmedTx != null
                        ? ScaleOnTap(
                            onTap: () {
                              context.pushNamed(
                                RouteNames.transactionForm,
                                extra: {
                                  'transactionId': confirmedTx.id,
                                  'readOnly': true,
                                },
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00D09E),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00D09E).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.remove_red_eye_rounded, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Xem giao dịch đã xác nhận',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _buildInvoiceAction(invoice, linkedTxs, isIncoming, isDark, currentRole),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildInvoiceAction(InvoiceEntity invoice, List<TransactionEntity> linkedTxs, bool isIncoming, bool isDark, UserRole currentRole) {
    final isFmReadOnly = currentRole == UserRole.financeManager;
    if (linkedTxs.isNotEmpty) {
      if (isFmReadOnly) {
        return ScaleOnTap(
          onTap: () {
            if (linkedTxs.length == 1) {
              context.pushNamed(RouteNames.transactionForm, extra: {'transactionId': linkedTxs.first.id, 'readOnly': true});
            } else {
              _showDraftTransactionsModal(context, linkedTxs, isDark, isFmReadOnly);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.orangeAccent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orangeAccent.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(linkedTxs.length == 1 ? Icons.visibility_rounded : Icons.list_alt_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    linkedTxs.length == 1 ? 'Xem bản nháp' : 'Danh sách nháp (${linkedTxs.length})',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return Row(
        children: [
          Expanded(
            child: ScaleOnTap(
              onTap: () {
                if (linkedTxs.length == 1) {
                  context.pushNamed(RouteNames.transactionForm, extra: {'transactionId': linkedTxs.first.id});
                } else {
                  _showDraftTransactionsModal(context, linkedTxs, isDark, false);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.orangeAccent.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(linkedTxs.length == 1 ? Icons.edit_note_rounded : Icons.list_alt_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        linkedTxs.length == 1 ? 'Sửa bản nháp' : 'Danh sách nháp (${linkedTxs.length})',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ScaleOnTap(
              onTap: () {
                context.pushNamed(RouteNames.transactionForm, extra: {
                  'initialAmount': invoice.totalAmount,
                  'initialTitle': isIncoming ? 'Thanh toán hóa đơn: ${invoice.invoiceNumber}' : 'Doanh thu từ hóa đơn: ${invoice.invoiceNumber}',
                  'invoiceId': invoice.id,
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D09E),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: const Color(0xFF00D09E).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isIncoming ? Icons.add_card_rounded : Icons.payments_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        isIncoming ? 'Tạo khoản chi' : 'Tạo khoản thu',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (isFmReadOnly) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.visibility_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              isIncoming ? 'Chỉ xem, liên hệ Kế toán CP để tạo GD' : 'Chỉ xem, liên hệ Kế toán DT để tạo GD',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      );
    }
    return ScaleOnTap(
      onTap: () {
        context.pushNamed(RouteNames.transactionForm, extra: {
          'initialAmount': invoice.totalAmount,
          'initialTitle': isIncoming ? 'Thanh toán hóa đơn: ${invoice.invoiceNumber}' : 'Doanh thu từ hóa đơn: ${invoice.invoiceNumber}',
          'invoiceId': invoice.id,
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF00D09E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFF00D09E).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isIncoming ? Icons.add_card_rounded : Icons.payments_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              isIncoming ? 'Tạo khoản chi' : 'Tạo khoản thu',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _showDraftTransactionsModal(BuildContext context, List<TransactionEntity> drafts, bool isDark, bool isReadOnly) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D251C) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Danh sách bản nháp (${drafts.length})',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF093021),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: isDark ? Colors.white54 : Colors.black54),
                  ),
                ],
              ),
              Text(
                isReadOnly ? 'Chọn 1 bản nháp bên dưới để xem chi tiết:' : 'Chọn 1 bản nháp bên dưới để mở giao diện chỉnh sửa:',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: drafts.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final tx = drafts[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF14382B) : const Color(0xFFF4FAF7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF1E4837) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isReadOnly ? Colors.blueAccent.withValues(alpha: 0.15) : Colors.orangeAccent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isReadOnly ? Icons.visibility_rounded : Icons.edit_note_rounded,
                            color: isReadOnly ? Colors.blueAccent : Colors.orangeAccent,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          tx.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white : const Color(0xFF093021),
                          ),
                        ),
                        subtitle: Text(
                          '${currencyFormatter.format(tx.amount)} • ${dateFormatter.format(tx.transactionDate)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          context.pushNamed(
                            RouteNames.transactionForm,
                            extra: {
                              'transactionId': tx.id,
                              'readOnly': isReadOnly,
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _shareScreenshot(BuildContext context) async {
    try {
      final imageBytes = await _screenshotController.capture(pixelRatio: 2.0, delay: const Duration(milliseconds: 100));
      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = await File('${directory.path}/hoadon.png').create();
        await imagePath.writeAsBytes(imageBytes);
        await Share.shareXFiles([
          XFile(imagePath.path),
        ], text: 'Hóa đơn từ Smart Finance');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chia sẻ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveScreenshot(BuildContext context) async {
    try {
      final imageBytes = await _screenshotController.capture(pixelRatio: 2.0, delay: const Duration(milliseconds: 100));
      if (imageBytes != null) {
        Directory? directory;
        if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
          directory = await getDownloadsDirectory();
          if (directory != null) {
            final file = File(
              '${directory.path}/hoadon_${DateTime.now().millisecondsSinceEpoch}.png',
            );
            await file.writeAsBytes(imageBytes);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã lưu ảnh tại:\n${file.path}'),
                  backgroundColor: const Color(0xFF10B981),
                  duration: const Duration(seconds: 5),
                  action: SnackBarAction(
                    label: 'Mở ngay',
                    textColor: Colors.white,
                    onPressed: () {
                      OpenFilex.open(file.path);
                    },
                  ),
                ),
              );
            }
          }
        } else {
          directory = await getTemporaryDirectory();
          final file = File(
            '${directory.path}/hoadon_${DateTime.now().millisecondsSinceEpoch}.png',
          );
          await file.writeAsBytes(imageBytes);
          
          final hasAccess = await Gal.hasAccess();
          if (!hasAccess) {
            await Gal.requestAccess();
          }
          await Gal.putImage(file.path);
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã lưu ảnh vào thư viện trên điện thoại!'),
                backgroundColor: Color(0xFF10B981),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lưu ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isWebOrNetworkPath(String? path) {
    if (path == null || path.isEmpty) return false;
    return kIsWeb || path.startsWith('http://') || path.startsWith('https://') || path.startsWith('blob:') || path.startsWith('data:');
  }

  bool _isPdfFile(String path, {String? fileName, String? mimeType}) {
    if (mimeType == 'application/pdf') return true;
    if (fileName != null && fileName.toLowerCase().endsWith('.pdf')) return true;
    final lower = path.toLowerCase();
    return lower.endsWith('.pdf') || lower.contains('.pdf') || lower.startsWith('data:application/pdf');
  }

  void _openPdfFile(String path) async {
    try {
      if (path.startsWith('data:application/pdf;base64,')) {
        final base64Str = path.split(',').last;
        final bytes = base64Decode(base64Str);
        if (kIsWeb) {
          await Printing.sharePdf(bytes: bytes, filename: 'HoaDon_DinhKem.pdf');
        } else {
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/HoaDon_DinhKem.pdf');
          await tempFile.writeAsBytes(bytes);
          final result = await OpenFilex.open(tempFile.path);
          if (result.type != ResultType.done && mounted) {
            await Printing.layoutPdf(onLayout: (_) async => bytes, name: 'HoaDon_DinhKem.pdf');
          }
        }
      } else if (kIsWeb) {
        final response = await http.get(Uri.parse(path));
        if (response.statusCode == 200) {
          await Printing.sharePdf(bytes: response.bodyBytes, filename: 'HoaDon_DinhKem.pdf');
        }
      } else {
        final result = await OpenFilex.open(path);
        if (result.type != ResultType.done && mounted) {
          final file = File(path);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            await Printing.layoutPdf(onLayout: (_) async => bytes);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi mở file PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showFullScreenImage(String path, {required bool isNetwork}) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) => _FullScreenImageViewer(path: path, isNetwork: isNetwork),
    );
  }

  Widget _buildAttachmentPreview({
    required BuildContext context,
    required String path,
    required bool isDark,
  }) {
    final isPdf = _isPdfFile(path);
    final displayFileName = path.split(RegExp(r'[/\\]')).last.split('?').first;

    if (isPdf) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F261C) : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF00D09E).withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00D09E).withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D09E), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D09E).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tệp đính kèm PDF',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF064E3B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    displayFileName.startsWith('data:') ? 'HoaDon_DinhKem.pdf' : displayFileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ScaleOnTap(
              onTap: () => _openPdfFile(path),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D09E), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D09E).withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Xem PDF',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isNet = _isWebOrNetworkPath(path);
    return GestureDetector(
      onTap: () => _showFullScreenImage(path, isNetwork: isNet),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 400),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B1712) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF00D09E).withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            alignment: Alignment.center,
            children: [
              path == 'mock_path_ocr.png'
                  ? const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(
                        child: Icon(Icons.image_outlined, size: 64, color: Colors.grey),
                      ),
                    )
                  : isNet
                      ? Image.network(
                          path,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) => progress == null
                              ? child
                              : const Center(
                                  child: CircularProgressIndicator(color: Color(0xFF00D09E)),
                                ),
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.broken_image_rounded, size: 64, color: Colors.grey),
                          ),
                        )
                      : ((kIsWeb || File(path).existsSync())
                          ? Image.file(File(path), fit: BoxFit.contain)
                          : const Padding(
                              padding: EdgeInsets.all(40.0),
                              child: Center(
                                child: Icon(Icons.broken_image_rounded, size: 64, color: Colors.grey),
                              ),
                            )),
              Positioned(
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_in_rounded, color: Color(0xFF00D09E), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Xem chi tiết',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: valueColor ?? (isDark ? Colors.white : const Color(0xFF093021)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenImageViewer extends StatefulWidget {
  final String path;
  final bool isNetwork;

  const _FullScreenImageViewer({required this.path, required this.isNetwork});

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  final TransformationController _controller = TransformationController();

  void _zoomBy(double factor) {
    final Matrix4 matrix = _controller.value.clone();
    final double currentScale = matrix.getMaxScaleOnAxis();
    final double targetScale = (currentScale * factor).clamp(1.0, 4.0);
    final double actualFactor = targetScale / currentScale;

    if (actualFactor == 1.0) return;

    final Size screenSize = MediaQuery.of(context).size;
    final Offset screenCenter = Offset(screenSize.width / 2, screenSize.height / 2);

    final double currentDx = matrix.getTranslation().x;
    final double currentDy = matrix.getTranslation().y;

    final double newDx = screenCenter.dx - (screenCenter.dx - currentDx) * actualFactor;
    final double newDy = screenCenter.dy - (screenCenter.dy - currentDy) * actualFactor;

    matrix.scale(actualFactor);
    matrix.setTranslationRaw(newDx, newDy, 0.0);

    _controller.value = matrix;
  }

  void _zoomIn() => _zoomBy(1.5);
  void _zoomOut() => _zoomBy(1 / 1.5);

  void _resetZoom() {
    _controller.value = Matrix4.identity();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isMobile {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.95),
            ),
          ),
          InteractiveViewer(
            transformationController: _controller,
            panEnabled: true,
            boundaryMargin: EdgeInsets.zero,
            minScale: 1.0,
            maxScale: 4.0,
            child: Center(
              child: (kIsWeb || widget.isNetwork || widget.path.startsWith('http://') || widget.path.startsWith('https://') || widget.path.startsWith('blob:') || widget.path.startsWith('data:'))
                  ? Image.network(widget.path, fit: BoxFit.contain)
                  : Image.file(File(widget.path), fit: BoxFit.contain),
            ),
          ),
          if (!_isMobile)
            Positioned(
              bottom: 40,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildToolbarBtn(Icons.remove_rounded, _zoomOut, 'Thu nhỏ'),
                        const SizedBox(width: 24),
                        _buildToolbarBtn(Icons.fit_screen_rounded, _resetZoom, 'Khôi phục', isPrimary: true),
                        const SizedBox(width: 24),
                        _buildToolbarBtn(Icons.add_rounded, _zoomIn, 'Phóng to'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 40,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
              ),
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarBtn(IconData icon, VoidCallback onTap, String tooltip, {bool isPrimary = false}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isPrimary ? const Color(0xFF00D09E).withOpacity(0.8) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: isPrimary ? 28 : 24,
          ),
        ),
      ),
    );
  }
}
