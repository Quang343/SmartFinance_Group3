import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/role_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/entities/attachment_entity.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../core/widgets/scale_on_tap.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final String? transactionId;
  final int? initialAmount;
  final String? initialNote;
  final String? invoiceId;

  const TransactionFormScreen({
    super.key, 
    this.transactionId,
    this.initialAmount,
    this.initialNote,
    this.invoiceId,
  });

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

  String? _invoiceId;
  String? _invoiceImagePath;
  final _picker = ImagePicker();
  String? _selectedImagePath;

  DateTime _transactionDate = DateTime.now();
  DateTime? _createdAt;

  List<CategoryEntity> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount.toString();
    }
    if (widget.initialNote != null) {
      _noteController.text = widget.initialNote!;
    }
    _invoiceId = widget.invoiceId;
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

    // Fetch categories
    final categoryRepo = ref.read(categoryRepositoryProvider);
    final fetchedCategories = await categoryRepo.getAll();
    if (mounted) {
      setState(() {
        _categories = fetchedCategories;
        _isLoadingCategories = false;
      });
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
          _invoiceId = tx.invoiceId;
          _transactionDate = tx.transactionDate;
          _createdAt = tx.createdAt;
        });

        // Also fetch attachment if exists
        final attachmentRepo = ref.read(attachmentRepositoryProvider);
        final attachments = await attachmentRepo.getByOwnerId(widget.transactionId!);
        if (attachments.isNotEmpty) {
          setState(() {
            _selectedImagePath = attachments.first.filePath;
          });
        }
      }
    }
    
    // If we have an invoice linked, fetch its image
    if (_invoiceId != null) {
      final invoiceRepo = ref.read(invoiceRepositoryProvider);
      final invoice = await invoiceRepo.getById(_invoiceId!);
      if (invoice != null && invoice.imagePath != null && invoice.imagePath != 'mock_path_ocr.png') {
        if (mounted) {
          setState(() {
            _invoiceImagePath = invoice.imagePath;
          });
        }
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Lỗi chọn ảnh: $e';
        if (e.toString().contains('cameraDelegate')) {
          errorMsg = 'Tính năng chụp ảnh chưa được hỗ trợ trên thiết bị này (Windows/Desktop). Vui lòng chọn từ Thư viện!';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
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
      if (_categoryId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn danh mục giao dịch!'), backgroundColor: Colors.red),
        );
        return;
      }

      final repo = ref.read(transactionRepositoryProvider);
      
      final String id = widget.transactionId ?? const Uuid().v4();
      final int amount = int.parse(_amountController.text);

      // Verify file existence right before saving to prevent ghost paths
      if (_selectedImagePath != null && !File(_selectedImagePath!).existsSync()) {
        _selectedImagePath = null;
      }

      final transaction = TransactionEntity(
        id: id,
        amount: amount,
        type: _type,
        categoryId: _categoryId,
        transactionDate: _transactionDate,
        status: _status,
        note: _noteController.text,
        invoiceId: _invoiceId,
        createdAt: _createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.transactionId == null) {
        await repo.create(transaction);
        if (_selectedImagePath != null) {
          final attachmentRepo = ref.read(attachmentRepositoryProvider);
          final attachment = AttachmentEntity(
            id: const Uuid().v4(),
            ownerId: id,
            ownerType: 'transaction',
            filePath: _selectedImagePath!,
            createdAt: DateTime.now(),
          );
          await attachmentRepo.create(attachment);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tạo giao dịch thành công!'), backgroundColor: Colors.green),
          );
        }
      } else {
        await repo.update(transaction);
        if (_selectedImagePath != null) {
          final attachmentRepo = ref.read(attachmentRepositoryProvider);
          final existing = await attachmentRepo.getByOwnerId(id);
          if (existing.isEmpty || existing.first.filePath != _selectedImagePath) {
            if (existing.isNotEmpty) {
              await attachmentRepo.delete(existing.first.id);
            }
            final attachment = AttachmentEntity(
              id: const Uuid().v4(),
              ownerId: id,
              ownerType: 'transaction',
              filePath: _selectedImagePath!,
              createdAt: DateTime.now(),
            );
            await attachmentRepo.create(attachment);
          }
        } else {
          final attachmentRepo = ref.read(attachmentRepositoryProvider);
          final existing = await attachmentRepo.getByOwnerId(id);
          if (existing.isNotEmpty) {
            await attachmentRepo.delete(existing.first.id);
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật giao dịch thành công!'), backgroundColor: Colors.green),
          );
        }
      }

      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/transactions');
        }
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        title: const Text('Xác nhận xóa', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn xóa giao dịch này không? Giao dịch sẽ được chuyển vào thùng rác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final repo = ref.read(transactionRepositoryProvider);
              await repo.softDelete(widget.transactionId!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa giao dịch thành công!'), backgroundColor: Colors.red),
                );
                context.go('/transactions');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00D09E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_transactionDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF00D09E),
              ),
            ),
            child: child!,
          );
        },
      );
      if (pickedTime != null && mounted) {
        setState(() {
          _transactionDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  String _getCategoryName(String id) {
    if (id.isEmpty) return 'Khác';
    try {
      final cat = _categories.firstWhere((c) => c.id == id);
      return cat.name;
    } catch (_) {
      return 'Khác';
    }
  }

  IconData _getCategoryIcon(String id) {
    if (id.isEmpty) return Icons.category_rounded;
    try {
      final cat = _categories.firstWhere((c) => c.id == id);
      // Since icons aren't stored natively, use a generic icon based on type
      return cat.type == 'income' ? Icons.trending_up_rounded : Icons.trending_down_rounded;
    } catch (_) {
      return Icons.category_rounded;
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

    final List<CategoryEntity> categories = _categories
        .where((c) => c.type == _type.name && c.isActive)
        .toList();

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
                  if (_isLoadingCategories)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (categories.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('Không có danh mục nào.'),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final isSelected = _categoryId == cat.id;
                          return InkWell(
                            onTap: () {
                              setState(() => _categoryId = cat.id);
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
                                    _getCategoryIcon(cat.id),
                                    color: isSelected ? const Color(0xFF00D09E) : (isDark ? Colors.white60 : Colors.black54),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      _getCategoryName(cat.id),
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
                      itemCount: TransactionStatus.values.where((s) => s != TransactionStatus.deleted).length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final s = TransactionStatus.values.where((s) => s != TransactionStatus.deleted).toList()[index];
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
        backgroundColor: isDark ? const Color(0xFF060E0A) : Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: Center(
          child: ScaleOnTap(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/transactions');
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
                  color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFEDF2F7),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF00D09E),
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
          child: Text(
            widget.transactionId == null ? 'Thêm Giao dịch' : 'Sửa Giao dịch',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
        ),
        actions: [

          if (widget.transactionId != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Xóa giao dịch',
              onPressed: _confirmDelete,
            ),
        ],

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
                if (int.parse(val) <= 0) {
                  return 'Số tiền phải lớn hơn 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Transaction Date Picker
            Text(
              'Ngày giao dịch',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            ScaleOnTap(
              onTap: _selectDateTime,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: inputFillColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: inputBorderColor, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: Color(0xFF00D09E)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(_transactionDate),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, color: isDark ? Colors.white54 : Colors.black54, size: 16),
                  ],
                ),
              ),
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
                      _categoryId.isEmpty ? Icons.category_outlined : _getCategoryIcon(_categoryId),
                      color: _categoryId.isEmpty ? Colors.grey : primaryColor,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _categoryId.isEmpty ? 'Chọn danh mục' : _getCategoryName(_categoryId),
                        style: TextStyle(
                          fontSize: 15,
                          color: _categoryId.isEmpty 
                              ? (isDark ? Colors.white54 : Colors.black54)
                              : (isDark ? Colors.white : Colors.black87),
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
            const SizedBox(height: 24),

            // Attachment Picker
            Text(
              'Đính kèm hóa đơn/biên lai',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            
            // Hide attachment upload if coming from an invoice, as it's already linked
            if (_invoiceId != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0D251C) : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF00D09E).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.link_rounded, color: Color(0xFF00D09E)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ảnh đính kèm đã được liên kết tự động từ Hóa đơn gốc.',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : const Color(0xFF093021),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_invoiceImagePath != null && File(_invoiceImagePath!).existsSync()) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: inputFillColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: inputBorderColor, width: 1.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_invoiceImagePath!),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ],
              )
            else if (_selectedImagePath != null && File(_selectedImagePath!).existsSync())
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: inputFillColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: inputBorderColor, width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_selectedImagePath!),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: () => setState(() => _selectedImagePath = null),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickImage(ImageSource.camera),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: inputFillColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: inputBorderColor, width: 1.5),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_rounded, color: Color(0xFF00D09E), size: 20),
                            SizedBox(width: 8),
                            Text('Chụp ảnh', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickImage(ImageSource.gallery),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: inputFillColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: inputBorderColor, width: 1.5),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_rounded, color: Color(0xFF00D09E), size: 20),
                            SizedBox(width: 8),
                            Text('Thư viện', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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
