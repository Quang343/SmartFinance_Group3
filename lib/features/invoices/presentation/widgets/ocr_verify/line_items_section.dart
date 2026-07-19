import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_finance/domain/entities/invoice_item_entity.dart';
import '../../providers/ocr_verify_provider.dart';
import 'ocr_verify_constants.dart';

class LineItemsSection extends ConsumerWidget {
  const LineItemsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only rebuild when the items list changes structurally (add/remove)
    final items = ref.watch(ocrVerifyProvider.select((s) => s.draft?.items ?? []));
    
    return Semantics(
      container: true,
      label: 'Chi tiết mặt hàng',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chi tiết mặt hàng',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      final draft = ref.read(ocrVerifyProvider).draft;
                      if (draft == null) return;
                      final newItems = List<InvoiceItemEntity>.from(draft.items);
                      newItems.add(InvoiceItemEntity(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        itemCode: '',
                        itemName: '',
                        unit: '',
                        quantity: 0,
                        unitPrice: 0,
                        totalAmount: 0,
                      ));
                      ref.read(ocrVerifyProvider.notifier).updateDraft(draft.copyWith(items: newItems));
                    },
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Thêm'),
                  )
                ],
              ),
              const SizedBox(height: OcrVerifyDimens.spacingSmall),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: OcrVerifyDimens.spacingMedium),
                  child: Center(child: Text('Chưa có mặt hàng nào.')),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const Divider(height: OcrVerifyDimens.spacingExtraLarge),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _LineItemRow(
                      key: ValueKey(item.id),
                      index: index,
                      itemId: item.id,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineItemRow extends ConsumerStatefulWidget {
  final int index;
  final String itemId;

  const _LineItemRow({
    super.key,
    required this.index,
    required this.itemId,
  });

  @override
  ConsumerState<_LineItemRow> createState() => _LineItemRowState();
}

class _LineItemRowState extends ConsumerState<_LineItemRow> {
  late final TextEditingController _nameController;
  late final TextEditingController _qtyController;
  late final TextEditingController _unitPriceController;
  late final TextEditingController _totalController;

  late final FocusNode _nameFocus;
  late final FocusNode _qtyFocus;
  late final FocusNode _unitPriceFocus;
  late final FocusNode _totalFocus;

  InvoiceItemEntity? _getCurrentItem() {
    final draft = ref.read(ocrVerifyProvider).draft;
    if (draft == null || widget.index >= draft.items.length) return null;
    final item = draft.items[widget.index];
    if (item.id != widget.itemId) return null; // ID mismatch (list reordered)
    return item;
  }

  @override
  void initState() {
    super.initState();
    final item = _getCurrentItem();
    _nameController = TextEditingController(text: item?.itemName ?? '');
    _qtyController = TextEditingController(text: item?.quantity.toString() ?? '0');
    _unitPriceController = TextEditingController(text: item?.unitPrice.toString() ?? '0');
    _totalController = TextEditingController(text: item?.totalAmount.toString() ?? '0');

    _nameFocus = FocusNode()..addListener(_onFocusChange);
    _qtyFocus = FocusNode()..addListener(_onFocusChange);
    _unitPriceFocus = FocusNode()..addListener(_onFocusChange);
    _totalFocus = FocusNode()..addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_nameFocus.hasFocus && !_qtyFocus.hasFocus && !_unitPriceFocus.hasFocus && !_totalFocus.hasFocus) {
      _dispatchChange();
    }
  }

  void _dispatchChange() {
    final draft = ref.read(ocrVerifyProvider).draft;
    if (draft == null || widget.index >= draft.items.length) return;
    
    final currentItem = draft.items[widget.index];
    if (currentItem.id != widget.itemId) return; // Stale index

    final newQuantity = double.tryParse(_qtyController.text) ?? 0.0;
    final newUnitPrice = int.tryParse(_unitPriceController.text) ?? 0;
    int newTotalAmount = int.tryParse(_totalController.text) ?? 0;

    // Tự động tính Thành tiền = SL * Đơn giá nếu người dùng sửa SL hoặc Đơn giá
    if (newQuantity != currentItem.quantity || newUnitPrice != currentItem.unitPrice) {
      newTotalAmount = (newQuantity * newUnitPrice).round();
      _totalController.text = newTotalAmount.toString();
    }

    final updatedItem = currentItem.copyWith(
      itemName: _nameController.text.trim(),
      quantity: newQuantity,
      unitPrice: newUnitPrice,
      totalAmount: newTotalAmount,
    );

    if (updatedItem != currentItem) {
      final newItems = List<InvoiceItemEntity>.from(draft.items);
      newItems[widget.index] = updatedItem;
      ref.read(ocrVerifyProvider.notifier).updateDraft(draft.copyWith(items: newItems));
    }
  }

  @override
  void dispose() {
    _nameFocus.removeListener(_onFocusChange);
    _qtyFocus.removeListener(_onFocusChange);
    _unitPriceFocus.removeListener(_onFocusChange);
    _totalFocus.removeListener(_onFocusChange);

    _nameFocus.dispose();
    _qtyFocus.dispose();
    _unitPriceFocus.dispose();
    _totalFocus.dispose();

    _nameController.dispose();
    _qtyController.dispose();
    _unitPriceController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes in this specific item
    ref.listen(ocrVerifyProvider.select((s) {
      final items = s.draft?.items;
      if (items == null || widget.index >= items.length) return null;
      return items[widget.index];
    }), (_, next) {
      if (next == null || next.id != widget.itemId) return;
      
      if (!_nameFocus.hasFocus && _nameController.text != next.itemName) {
        _nameController.text = next.itemName;
      }
      if (!_qtyFocus.hasFocus && _qtyController.text != next.quantity.toString()) {
        _qtyController.text = next.quantity.toString();
      }
      if (!_unitPriceFocus.hasFocus && _unitPriceController.text != next.unitPrice.toString()) {
        _unitPriceController.text = next.unitPrice.toString();
      }
      if (!_totalFocus.hasFocus && _totalController.text != next.totalAmount.toString()) {
        _totalController.text = next.totalAmount.toString();
      }
    });

    final nameError = null;
    final qtyError = null;
    final unitPriceError = null;
    final totalError = null;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _nameController,
                focusNode: _nameFocus,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Tên hàng hóa',
                  errorText: nameError,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: OcrVerifyDimens.cardRadius, vertical: OcrVerifyDimens.cardRadius),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                final draft = ref.read(ocrVerifyProvider).draft;
                if (draft == null || widget.index >= draft.items.length) return;
                final newItems = List<InvoiceItemEntity>.from(draft.items);
                newItems.removeAt(widget.index);
                ref.read(ocrVerifyProvider.notifier).updateDraft(draft.copyWith(items: newItems));
              },
              tooltip: 'Xóa mặt hàng',
            ),
          ],
        ),
        const SizedBox(height: OcrVerifyDimens.cardRadius),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: _qtyController,
                focusNode: _qtyFocus,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'SL',
                  errorText: qtyError,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: OcrVerifyDimens.cardRadius, vertical: OcrVerifyDimens.cardRadius),
                ),
              ),
            ),
            const SizedBox(width: OcrVerifyDimens.spacingSmall),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _unitPriceController,
                focusNode: _unitPriceFocus,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Đơn giá',
                  errorText: unitPriceError,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: OcrVerifyDimens.cardRadius, vertical: OcrVerifyDimens.cardRadius),
                ),
              ),
            ),
            const SizedBox(width: OcrVerifyDimens.spacingSmall),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _totalController,
                focusNode: _totalFocus,
                textInputAction: TextInputAction.next, // next item
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Thành tiền',
                  errorText: totalError,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: OcrVerifyDimens.cardRadius, vertical: OcrVerifyDimens.cardRadius),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
