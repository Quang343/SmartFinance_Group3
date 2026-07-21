import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/ocr_verify_provider.dart';

class SummarySection extends ConsumerStatefulWidget {
  const SummarySection({super.key});

  @override
  ConsumerState<SummarySection> createState() => _SummarySectionState();
}

class _SummarySectionState extends ConsumerState<SummarySection> {
  late final TextEditingController _vatController;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(ocrVerifyProvider).draft;
    _vatController = TextEditingController(text: draft?.vatRate.toString() ?? '0');
    _vatController.addListener(_dispatchChange);
  }

  void _dispatchChange() {
    final currentDraft = ref.read(ocrVerifyProvider).draft;
    if (currentDraft == null) return;
    
    final updated = currentDraft.copyWith(
      vatRate: int.tryParse(_vatController.text) ?? 0,
    );
    
    if (updated.vatRate != currentDraft.vatRate) {
      Future.microtask(() {
         ref.read(ocrVerifyProvider.notifier).updateDraft(updated);
      });
    }
  }

  @override
  void dispose() {
    _vatController.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDeco(String label, IconData? icon, bool isDark, Color primaryColor, Color inputFillColor, Color inputBorderColor) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13),
      prefixIcon: icon != null ? Icon(icon, color: primaryColor, size: 18) : null,
      filled: true,
      fillColor: inputFillColor,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: inputBorderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ocrVerifyProvider);
    final draft = state.draft;
    if (draft == null) return const SizedBox.shrink();

    // Listen to changes from other parts (e.g. OCR process)
    ref.listen(ocrVerifyProvider.select((s) => s.draft?.vatRate), (_, nextVat) {
      if (nextVat != null && _vatController.text != nextVat.toString()) {
        _vatController.text = nextVat.toString();
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF00D09E);
    final inputFillColor = isDark ? const Color(0xFF13231A) : Colors.grey[50]!;
    final inputBorderColor = isDark ? const Color(0xFF1F3327) : Colors.grey[300]!;
    final textStyle = TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w500);

    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'VND');

    final subtotal = draft.subtotal;
    final vatRate = draft.vatRate;
    final vatAmount = (subtotal * vatRate / 100).round();
    final totalAmount = draft.totalAmount; // Automatically calculated by provider

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('TỔNG KẾT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 12),
        
        TextFormField(
          controller: _vatController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: textStyle,
          decoration: _buildInputDeco('Thuế suất VAT (%)', Icons.percent, isDark, primaryColor, inputFillColor, inputBorderColor),
        ),
        
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2621) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: inputBorderColor, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cộng tiền hàng:', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14)),
                  Text(
                    formatter.format(subtotal), 
                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15, fontWeight: FontWeight.w600)
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Thuế VAT:', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14)),
                  Text(
                    formatter.format(vatAmount), 
                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15, fontWeight: FontWeight.w600)
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: Colors.grey),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tổng tiền thanh toán:', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    formatter.format(totalAmount), 
                    style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.w800)
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
