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

      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/transactions');
      }
    }
  }

  String _getCategoryName(String cat) {
    switch (cat) {
      case 'cat_sales': return 'Doanh thu bán hàng';
      case 'cat_investment': return 'Đầu tư';
      case 'cat_other_income': return 'Thu nhập khác';
      case 'cat_salary': return 'Lương nhân viên';
      case 'cat_rent': return 'Tiền thuê mặt bằng';
      case 'cat_utilities': return 'Điện nước & Tiện ích';
      case 'cat_marketing': return 'Marketing & Quảng cáo';
      case 'cat_other_expense': return 'Chi phí khác';
      default: return 'Khác';
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'cat_sales': return Icons.point_of_sale_rounded;
      case 'cat_investment': return Icons.trending_up_rounded;
      case 'cat_other_income': return Icons.account_balance_wallet_rounded;
      case 'cat_salary': return Icons.people_alt_rounded;
      case 'cat_rent': return Icons.business_rounded;
      case 'cat_utilities': return Icons.bolt_rounded;
      case 'cat_marketing': return Icons.campaign_rounded;
      case 'cat_other_expense': return Icons.local_mall_rounded;
      default: return Icons.category_rounded;
    }
  }

  String _getStatusName(TransactionStatus s) {
    switch (s) {
      case TransactionStatus.draft: return 'Bản nháp';
      case TransactionStatus.confirmed: return 'Đã xác nhận';
      case TransactionStatus.deleted: return 'Đã xóa';
    }
  }

  IconData _getStatusIcon(TransactionStatus s) {
    switch (s) {
      case TransactionStatus.draft: return Icons.edit_document;
      case TransactionStatus.confirmed: return Icons.check_circle_outline_rounded;
      case TransactionStatus.deleted: return Icons.delete_outline_rounded;
    }
  }

  Color _getStatusColor(TransactionStatus s) {
    switch (s) {
      case TransactionStatus.draft: return Colors.orange;
      case TransactionStatus.confirmed: return const Color(0xFF00D09E);
      case TransactionStatus.deleted: return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRole = ref.watch(roleProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF00D09E);

    final List<String> categories = _type == TransactionType.income
        ? ['cat_sales', 'cat_investment', 'cat_other_income']
        : ['cat_salary', 'cat_rent', 'cat_utilities', 'cat_marketing', 'cat_other_expense'];

    final inputFillColor = isDark ? const Color(0xFF0F1E15) : Colors.grey.shade50;
    final inputBorderColor = isDark ? const Color(0xFF1E382B) : Colors.grey.shade300;

    void showCategoryPicker() {
      showModalBottomSheet(
        context: context,
        backgroundColor: isDark ? const Color(0xFF060E0A) : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Chọn danh mục',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = _categoryId == cat || (_categoryId.isEmpty && cat == categories.last);
                        return InkWell(
                          onTap: () {
                            setState(() => _categoryId = cat);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? const Color(0x1500D09E) 
                                  : inputFillColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF00D09E) : inputBorderColor,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getCategoryIcon(cat),
                                  color: isSelected ? const Color(0xFF00D09E) : (isDark ? Colors.white60 : Colors.black54),
                                  size: 22,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    _getCategoryName(cat),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected 
                                          ? const Color(0xFF00D09E) 
                                          : (isDark ? Colors.white : Colors.black87),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_rounded, color: Color(0xFF00D09E), size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    void showStatusPicker() {
      showModalBottomSheet(
        context: context,
        backgroundColor: isDark ? const Color(0xFF060E0A) : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Chọn trạng thái',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: TransactionStatus.values.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final s = TransactionStatus.values[index];
                        final isSelected = _status == s;
                        return InkWell(
                          onTap: () {
                            setState(() => _status = s);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? _getStatusColor(s).withOpacity(0.08) 
                                  : inputFillColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? _getStatusColor(s) : inputBorderColor,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getStatusIcon(s),
                                  color: _getStatusColor(s),
                                  size: 22,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    _getStatusName(s),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected 
                                          ? _getStatusColor(s) 
                                          : (isDark ? Colors.white : Colors.black87),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_rounded, color: _getStatusColor(s), size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF060E0A) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.transactionId == null ? 'Thêm Giao dịch' : 'Sửa Giao dịch',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white70 : Colors.black87, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/transactions');
            }
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            // Amount
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: 'Số tiền (VND)',
                labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14),
                prefixIcon: const Icon(Icons.attach_money_rounded, color: Color(0xFF00D09E)),
                filled: true,
                fillColor: inputFillColor,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: inputBorderColor, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
                ),
              ),
              validator: (val) {
                if (val == null || int.tryParse(val) == null) {
                  return 'Vui lòng nhập số tiền hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Type Segmented Control
            Text(
              'Loại giao dịch',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Opacity(
                    opacity: currentRole == UserRole.expenseAccountant ? 0.5 : 1.0,
                    child: ScaleOnTap(
                      onTap: currentRole == UserRole.expenseAccountant
                          ? () {}
                          : () => setState(() {
                              _type = TransactionType.income;
                              _categoryId = '';
                            }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _type == TransactionType.income
                              ? const Color(0x1500D09E)
                              : inputFillColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _type == TransactionType.income
                                ? const Color(0xFF00D09E)
                                : inputBorderColor,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _type == TransactionType.income ? Icons.check_circle_rounded : Icons.arrow_downward_rounded,
                              color: _type == TransactionType.income ? const Color(0xFF00D09E) : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Doanh thu (Thu)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _type == TransactionType.income
                                    ? const Color(0xFF00D09E)
                                    : (isDark ? Colors.white60 : Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Opacity(
                    opacity: currentRole == UserRole.revenueAccountant ? 0.5 : 1.0,
                    child: ScaleOnTap(
                      onTap: currentRole == UserRole.revenueAccountant
                          ? () {}
                          : () => setState(() {
                              _type = TransactionType.expense;
                              _categoryId = '';
                            }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _type == TransactionType.expense
                              ? const Color(0x15EF4444)
                              : inputFillColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _type == TransactionType.expense
                                ? const Color(0xFFEF4444)
                                : inputBorderColor,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _type == TransactionType.expense ? Icons.check_circle_rounded : Icons.arrow_upward_rounded,
                              color: _type == TransactionType.expense ? const Color(0xFFEF4444) : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Chi phí (Chi)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _type == TransactionType.expense
                                    ? const Color(0xFFEF4444)
                                    : (isDark ? Colors.white60 : Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Category Selection
            Text(
              'Danh mục',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: showCategoryPicker,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: inputFillColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: inputBorderColor, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getCategoryIcon(_categoryId.isEmpty ? categories.last : _categoryId),
                      color: primaryColor,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getCategoryName(_categoryId.isEmpty ? categories.last : _categoryId),
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

             // Notes
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: 'Ghi chú',
                labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14),
                prefixIcon: const Icon(Icons.note_alt_outlined, color: Color(0xFF00D09E)),
                filled: true,
                fillColor: inputFillColor,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: inputBorderColor, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Status Selector
            Text(
              'Trạng thái',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: showStatusPicker,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: inputFillColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: inputBorderColor, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(_status),
                      color: _getStatusColor(_status),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getStatusName(_status),
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            ScaleOnTap(
              onTap: _saveTransaction,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.transactionId == null ? 'Tạo giao dịch' : 'Cập nhật',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF060E0A),
                    ),
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
