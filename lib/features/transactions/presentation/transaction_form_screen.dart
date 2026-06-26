import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/role_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../core/widgets/scale_on_tap.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final String? transactionId;

  const TransactionFormScreen({super.key, this.transactionId});

  @override
  ConsumerState<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  TransactionType _type = TransactionType.expense;
  String _categoryId = '';
  TransactionStatus _status = TransactionStatus.confirmed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final role = ref.read(roleProvider);
    if (role == UserRole.revenueAccountant) {
      _type = TransactionType.income;
    } else {
      _type = TransactionType.expense;
    }

    if (widget.transactionId != null) {
      final repo = ref.read(transactionRepositoryProvider);
      final list = await repo.getAll();
      final index = list.indexWhere((tx) => tx.id == widget.transactionId);
      if (index != -1) {
        final tx = list[index];
        setState(() {
          _amountController.text = tx.amount.toString();
          _noteController.text = tx.note ?? '';
          _type = tx.type;
          _categoryId = tx.categoryId;
          _status = tx.status;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final repo = ref.read(transactionRepositoryProvider);
      
      final String id = widget.transactionId ?? const Uuid().v4();
      final int amount = int.parse(_amountController.text);
      
      // Default category if empty
      final String catId = _categoryId.isEmpty 
          ? (_type == TransactionType.income ? 'cat_revenue' : 'cat_expense')
          : _categoryId;

      final transaction = TransactionEntity(
        id: id,
        amount: amount,
        type: _type,
        categoryId: catId,
        transactionDate: DateTime.now(),
        status: _status,
        note: _noteController.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.transactionId == null) {
        await repo.create(transaction);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo giao dịch thành công!'), backgroundColor: Colors.green),
        );
      } else {
        await repo.update(transaction);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật giao dịch thành công!'), backgroundColor: Colors.green),
        );
      }

      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRole = ref.watch(roleProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final List<String> categories = _type == TransactionType.income
        ? ['cat_sales', 'cat_investment', 'cat_other_income']
        : ['cat_salary', 'cat_rent', 'cat_utilities', 'cat_marketing', 'cat_other_expense'];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transactionId == null ? 'Thêm Giao dịch' : 'Sửa Giao dịch'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Amount
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Số tiền (VND)',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
              ),
              validator: (val) {
                if (val == null || int.tryParse(val) == null) {
                  return 'Vui lòng nhập số tiền hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Type Segmented Control
            Text(
              'Loại giao dịch',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Doanh thu (Thu)'),
                    selected: _type == TransactionType.income,
                    selectedColor: primaryColor.withOpacity(0.2),
                    checkmarkColor: primaryColor,
                    onSelected: currentRole == UserRole.expenseAccountant
                        ? null // Expense Accountant cannot create revenue
                        : (selected) {
                            if (selected) setState(() => _type = TransactionType.income);
                          },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Chi phí (Chi)'),
                    selected: _type == TransactionType.expense,
                    selectedColor: primaryColor.withOpacity(0.2),
                    checkmarkColor: primaryColor,
                    onSelected: currentRole == UserRole.revenueAccountant
                        ? null // Revenue Accountant cannot create expense
                        : (selected) {
                            if (selected) setState(() => _type = TransactionType.expense);
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Category Selection
            Text(
              'Danh mục',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: categories.contains(_categoryId) ? _categoryId : categories.last,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF2C2C40) : Colors.grey.shade50,
              ),
              items: categories.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat.replaceAll('cat_', '').toUpperCase()),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _categoryId = val);
              },
            ),
            const SizedBox(height: 20),

            // Notes
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Ghi chú',
                prefixIcon: const Icon(Icons.note_alt_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Status Selector
            DropdownButtonFormField<TransactionStatus>(
              value: _status,
              decoration: InputDecoration(
                labelText: 'Trạng thái',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
              ),
              items: TransactionStatus.values.map((s) {
                return DropdownMenuItem(
                  value: s,
                  child: Text(s.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _status = val);
              },
            ),
            const SizedBox(height: 40),

            ScaleOnTap(
              onTap: _saveTransaction,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.transactionId == null ? 'Tạo giao dịch' : 'Cập nhật',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
