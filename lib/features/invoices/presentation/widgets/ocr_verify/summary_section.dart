import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/ocr_verify_provider.dart';
import 'ocr_verify_constants.dart';

class SummarySection extends ConsumerStatefulWidget {
  const SummarySection({super.key});

  @override
  ConsumerState<SummarySection> createState() => _SummarySectionState();
}

class _SummarySectionState extends ConsumerState<SummarySection> {
  late final TextEditingController _subtotalController;
  late final TextEditingController _vatController;
  late final TextEditingController _totalController;

  late final FocusNode _subtotalFocus;
  late final FocusNode _vatFocus;
  late final FocusNode _totalFocus;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(ocrVerifyProvider).draft;
    _subtotalController = TextEditingController(text: draft?.subtotal.toString() ?? '0');
    _vatController = TextEditingController(text: draft?.vatRate.toString() ?? '0');
    _totalController = TextEditingController(text: draft?.totalAmount.toString() ?? '0');

    _subtotalFocus = FocusNode()..addListener(_onFocusChange);
    _vatFocus = FocusNode()..addListener(_onFocusChange);
    _totalFocus = FocusNode()..addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_subtotalFocus.hasFocus && !_vatFocus.hasFocus && !_totalFocus.hasFocus) {
      _dispatchChange();
    }
  }

  void _dispatchChange() {
    final currentDraft = ref.read(ocrVerifyProvider).draft;
    if (currentDraft == null) return;
    
    final updated = currentDraft.copyWith(
      subtotal: int.tryParse(_subtotalController.text) ?? 0,
      vatRate: int.tryParse(_vatController.text) ?? 0,
      totalAmount: int.tryParse(_totalController.text) ?? 0,
    );
    
    if (updated != currentDraft) {
      ref.read(ocrVerifyProvider.notifier).updateDraft(updated);
    }
  }

  @override
  void dispose() {
    _subtotalFocus.removeListener(_onFocusChange);
    _vatFocus.removeListener(_onFocusChange);
    _totalFocus.removeListener(_onFocusChange);

    _subtotalFocus.dispose();
    _vatFocus.dispose();
    _totalFocus.dispose();

    _subtotalController.dispose();
    _vatController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(ocrVerifyProvider.select((s) => s.draft?.subtotal), (_, next) {
      if (!_subtotalFocus.hasFocus && _subtotalController.text != next?.toString()) {
        _subtotalController.text = next?.toString() ?? '0';
      }
    });
    ref.listen(ocrVerifyProvider.select((s) => s.draft?.vatRate), (_, next) {
      if (!_vatFocus.hasFocus && _vatController.text != next?.toString()) {
        _vatController.text = next?.toString() ?? '0';
      }
    });
    ref.listen(ocrVerifyProvider.select((s) => s.draft?.totalAmount), (_, next) {
      if (!_totalFocus.hasFocus && _totalController.text != next?.toString()) {
        _totalController.text = next?.toString() ?? '0';
      }
    });

    final subtotalError = null;
    final vatError = null;
    final totalError = null;

    return Semantics(
      container: true,
      label: 'Tổng kết',
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(OcrVerifyDimens.cardRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(OcrVerifyDimens.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tổng kết',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: OcrVerifyDimens.spacingMedium),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _subtotalController,
                      focusNode: _subtotalFocus,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Tiền hàng',
                        errorText: subtotalError,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: OcrVerifyDimens.spacingMedium),
                  Expanded(
                    child: TextFormField(
                      controller: _vatController,
                      focusNode: _vatFocus,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Thuế suất (%)',
                        errorText: vatError,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: OcrVerifyDimens.spacingMedium),
              TextFormField(
                controller: _totalController,
                focusNode: _totalFocus,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Tổng cộng',
                  errorText: totalError,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
