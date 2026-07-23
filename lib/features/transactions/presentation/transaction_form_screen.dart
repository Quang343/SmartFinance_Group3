import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/number_to_text.dart';
import '../../../core/utils/money_formatter.dart';

import '../../../core/providers/role_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/transaction_providers.dart';
import '../../../domain/entities/transaction_entity.dart';
import 'package:smart_finance/core/constants/route_names.dart';
import '../../../domain/entities/attachment_entity.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/invoice_entity.dart';
import '../../../data/repositories/storage_repository.dart';
import '../../../core/widgets/scale_on_tap.dart';
import '../../../core/widgets/app_dialogs.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final String? transactionId;
  final String? initialTitle;
  final int? initialAmount;
  final String? initialNote;
  final String? invoiceId;
  final bool readOnly;

  const TransactionFormScreen({
    super.key, 
    this.transactionId,
    this.initialTitle,
    this.initialAmount,
    this.initialNote,
    this.invoiceId,
    this.readOnly = false,
  });

  @override
  ConsumerState<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
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

  bool _showCategoryError = false;
  final _titleKey = GlobalKey();
  final _amountKey = GlobalKey();
  final _categoryKey = GlobalKey();

  bool _isSaving = false;
  late bool _isReadOnly;
  String _amountText = '';

  @override
  void initState() {
    super.initState();
    _isReadOnly = widget.readOnly;
    _amountController.addListener(_updateAmountText);
    if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
    if (widget.initialAmount != null) {
      _amountController.text = NumberFormat.decimalPattern('vi_VN').format(widget.initialAmount);
    }
    if (widget.initialNote != null) {
      _noteController.text = widget.initialNote!;
    }
    _invoiceId = widget.invoiceId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _updateAmountText() {
    final text = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.isEmpty) {
      if (_amountText.isNotEmpty) {
        setState(() {
          _amountText = '';
        });
      }
      return;
    }
    
    final number = int.tryParse(text);
    if (number != null && number > 0) {
      final newText = NumberToText.convert(number);
      if (_amountText != newText) {
        setState(() {
          _amountText = newText;
        });
      }
    } else {
      if (_amountText.isNotEmpty) {
        setState(() {
          _amountText = '';
        });
      }
    }
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
          _titleController.text = tx.title;
          _amountController.text = NumberFormat.decimalPattern('vi_VN').format(tx.amount);
          _noteController.text = tx.note ?? '';
          _type = tx.type;
          _categoryId = tx.categoryId;
          _status = tx.status;
          _invoiceId = tx.invoiceId;
          _transactionDate = tx.transactionDate;
          _createdAt = tx.createdAt;
          _isReadOnly = tx.status == TransactionStatus.confirmed || tx.status == TransactionStatus.deleted;
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

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedImagePath = result.files.single.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateAmountText);
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveTransaction() async {
    if (_isSaving) return;

    final isAmountValid = _formKey.currentState!.validate();
    final isCategoryValid = _categoryId.isNotEmpty;

    setState(() {
      _showCategoryError = !isCategoryValid;
    });

    if (!isAmountValid || !isCategoryValid) {
      if (!isAmountValid) {
        // Simple check to see which one failed by checking their text. 
        // Form validate doesn't tell us WHICH field failed, but we can guess.
        if (_titleController.text.trim().isEmpty && _titleKey.currentContext != null) {
          Scrollable.ensureVisible(_titleKey.currentContext!, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        } else if (_amountKey.currentContext != null) {
          Scrollable.ensureVisible(_amountKey.currentContext!, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        }
      } else if (!isCategoryValid && _categoryKey.currentContext != null) {
        Scrollable.ensureVisible(_categoryKey.currentContext!, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repo = ref.read(transactionRepositoryProvider);
      final storageRepo = ref.read(storageRepositoryProvider);
      
      final String id = widget.transactionId ?? const Uuid().v4();
      final int amount = int.parse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), ''));

      // Verify file existence right before saving to prevent ghost paths
      if (_selectedImagePath != null && !kIsWeb && !File(_selectedImagePath!).existsSync() && !_selectedImagePath!.startsWith('http')) {
        _selectedImagePath = null;
      }

      // Upload image if it is a local file
      String? finalImagePath = _selectedImagePath;
      if (_selectedImagePath != null && !_selectedImagePath!.startsWith('http')) {
        try {
          if (kIsWeb) {
            final response = await http.get(Uri.parse(_selectedImagePath!));
            if (response.statusCode == 200) {
              final uploadedUrl = await storageRepo.uploadTransactionImage(id, webFile: response.bodyBytes, fileName: 'transaction.png');
              if (uploadedUrl != null) {
                finalImagePath = uploadedUrl;
              }
            }
          } else {
            final uploadedUrl = await storageRepo.uploadTransactionImage(id, file: File(_selectedImagePath!));
            if (uploadedUrl != null) {
              finalImagePath = uploadedUrl;
            }
          }
        } catch (e) {
          debugPrint('Không thể tải ảnh đính kèm lên ImgBB (giữ đường dẫn local/fallback): $e');
          // Không return; để cho phép giao dịch tiếp tục được lưu vào Firestore!
        }
      }

      final transaction = TransactionEntity(
        id: id,
        amount: amount,
        type: _type,
        categoryId: _categoryId,
        transactionDate: _transactionDate,
        status: _status,
        title: _titleController.text,
        note: _noteController.text,
        invoiceId: _invoiceId,
        createdAt: _createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        tags: const [],
      );

      if (widget.transactionId == null) {
        await repo.create(transaction);
        if (finalImagePath != null) {
          final attachmentRepo = ref.read(attachmentRepositoryProvider);
          final attachment = AttachmentEntity(
            id: const Uuid().v4(),
            ownerId: id,
            ownerType: 'transaction',
            filePath: finalImagePath,
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
        if (finalImagePath != null) {
          final attachmentRepo = ref.read(attachmentRepositoryProvider);
          final existing = await attachmentRepo.getByOwnerId(id);
          if (existing.isEmpty || existing.first.filePath != finalImagePath) {
            if (existing.isNotEmpty) {
              await attachmentRepo.delete(existing.first.id);
            }
            final attachment = AttachmentEntity(
              id: const Uuid().v4(),
              ownerId: id,
              ownerType: 'transaction',
              filePath: finalImagePath,
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



      // Refresh list
      ref.invalidate(allTransactionsProvider);
      ref.invalidate(incomeTransactionsProvider);
      ref.invalidate(expenseTransactionsProvider);

      if (mounted) {
        if (Navigator.canPop(context)) {
          context.pop(true);
        } else {
          context.go('/transactions');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Có lỗi xảy ra: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _confirmDelete() {
    AppDialogs.showConfirmDialog(
      context: context,
      title: 'Xác nhận xóa',
      message: 'Bạn có chắc chắn muốn xóa giao dịch này không? Giao dịch sẽ được chuyển vào thùng rác.',
      icon: Icons.delete_outline_rounded,
      color: Colors.redAccent,
      confirmText: 'Xóa giao dịch',
      onConfirm: () async {
        final repo = ref.read(transactionRepositoryProvider);
        await repo.softDelete(widget.transactionId!);


        
        // Refresh list
        ref.invalidate(allTransactionsProvider);
        ref.invalidate(incomeTransactionsProvider);
        ref.invalidate(expenseTransactionsProvider);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa giao dịch thành công!'), backgroundColor: Colors.red),
          );
          if (Navigator.canPop(context)) {
            context.pop();
          } else {
            context.go('/transactions');
          }
        }
      },
    );
  }

  void _confirmRestore() {
    AppDialogs.showConfirmDialog(
      context: context,
      title: 'Khôi phục giao dịch',
      message: 'Bạn có chắc chắn muốn khôi phục giao dịch này? Giao dịch sẽ được chuyển về trạng thái Bản nháp.',
      icon: Icons.restore_rounded,
      color: const Color(0xFF00D09E),
      confirmText: 'Khôi phục',
      onConfirm: () async {
        final repo = ref.read(transactionRepositoryProvider);
        await repo.restore(widget.transactionId!);


        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã khôi phục giao dịch thành Bản nháp!'), backgroundColor: Colors.green),
          );
          if (Navigator.canPop(context)) {
            context.pop();
          } else {
            context.go('/transactions');
          }
        }
      },
    );
  }

  Future<void> _selectDateTime() async {
    final now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _transactionDate.isAfter(now) ? now : _transactionDate,
      firstDate: DateTime(2000),
      lastDate: now,
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
        DateTime finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        
        final currentTime = DateTime.now();
        if (finalDateTime.isAfter(currentTime)) {
          finalDateTime = currentTime;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể chọn thời gian trong tương lai. Đã tự động chuyển về hiện tại.'),
              backgroundColor: Colors.orange,
            ),
          );
        }

        setState(() {
          _transactionDate = finalDateTime;
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
      if (cat.iconCode != null && cat.iconCode!.isNotEmpty) {
        final code = int.tryParse(cat.iconCode!);
        if (code != null) return IconData(code, fontFamily: 'MaterialIcons');
      }
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

  void _showFullScreenImage(String path, {bool isNetwork = false}) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) => _FullScreenImageViewer(
        path: path,
        isNetwork: isNetwork,
      ),
    );
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
                          final catColor = cat.colorHex != null 
                              ? Color(int.parse(cat.colorHex!.replaceFirst('#', '0xFF'))) 
                              : const Color(0xFF00D09E);
                              
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
                                    ? catColor.withOpacity(0.1) 
                                    : inputFillColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? catColor : inputBorderColor,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: catColor.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _getCategoryIcon(cat.id),
                                      color: catColor,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      _getCategoryName(cat.id),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected 
                                            ? catColor 
                                            : (isDark ? Colors.white : Colors.black87),
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(Icons.check_rounded, color: catColor, size: 20),
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
            widget.transactionId == null ? 'Thêm Giao dịch' : (_isReadOnly ? 'Chi tiết Giao dịch' : 'Sửa Giao dịch'),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
        ),
        actions: [
          if (widget.transactionId != null && !_isReadOnly)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Xóa giao dịch',
              onPressed: _confirmDelete,
            ),
        ],

      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            // Title
            TextFormField(
              key: _titleKey,
              controller: _titleController,
              readOnly: _isReadOnly,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: 'Tiêu đề giao dịch (*)',
                labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14),
                prefixIcon: const Icon(Icons.title_rounded, color: Color(0xFF00D09E)),
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
                if (val == null || val.trim().isEmpty) {
                  return 'Vui lòng nhập tiêu đề giao dịch';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Amount
            TextFormField(
              key: _amountKey,
              controller: _amountController,
              readOnly: _isReadOnly,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9\.]')),
                CurrencyInputFormatter(),
                LengthLimitingTextInputFormatter(19),
              ],
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
                if (val == null || val.isEmpty) {
                  return 'Vui lòng nhập số tiền hợp lệ';
                }
                final numVal = int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), ''));
                if (numVal == null) {
                  return 'Số tiền quá lớn hoặc không hợp lệ';
                }
                if (numVal <= 0) {
                  return 'Số tiền phải lớn hơn 0';
                }
                if (numVal > 999999999999999) {
                  return 'Số tiền vượt quá giới hạn (tối đa 15 chữ số)';
                }
                return null;
              },
            ),
            if (_amountText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  _amountText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF00D09E),
                  ),
                ),
              ),
            ],
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
              onTap: _isReadOnly ? () {} : () => _selectDateTime(),
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
                      onTap: (_isReadOnly || currentRole == UserRole.expenseAccountant)
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
                      onTap: (_isReadOnly || currentRole == UserRole.revenueAccountant)
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
              key: _categoryKey,
              onTap: _isReadOnly ? null : () {
                setState(() => _showCategoryError = false);
                showCategoryPicker();
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: inputFillColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _showCategoryError ? const Color(0xFFEF4444) : inputBorderColor, 
                    width: _showCategoryError ? 2.0 : 1.5,
                  ),
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
            if (_showCategoryError)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 16),
                child: Text(
                  'Vui lòng chọn danh mục giao dịch!',
                  style: TextStyle(
                    color: const Color(0xFFEF4444),
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            

            const SizedBox(height: 24),

             // Notes
            TextFormField(
              controller: _noteController,
              readOnly: _isReadOnly,
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
              onTap: _isReadOnly ? null : showStatusPicker,
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
                  Text('Đính kèm', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF093021))),
                  const SizedBox(height: 8),
                  
                  if (_type == TransactionType.income) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0D251C) : const Color(0xFFF1F8F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF00D09E).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF00D09E)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Giao dịch được tạo từ Hóa đơn. Bạn có thể xem và tải bản PDF gốc.',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white70 : const Color(0xFF093021),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ScaleOnTap(
                      onTap: () {
                        context.pushNamed(
                          RouteNames.invoicePreview,
                          pathParameters: {'id': _invoiceId!},
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: inputFillColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF00D09E), width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.remove_red_eye_rounded, color: Color(0xFF00D09E), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Xem / Tải Hóa đơn PDF',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (_invoiceImagePath != null && (_invoiceImagePath!.startsWith('http') || kIsWeb || File(_invoiceImagePath!).existsSync())) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0D251C) : const Color(0xFFF1F8F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF00D09E).withValues(alpha: 0.3)),
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
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        final isNet = _invoiceImagePath!.startsWith('http');
                        _showFullScreenImage(_invoiceImagePath!, isNetwork: isNet);
                      },
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxHeight: 250),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F1E15) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: inputBorderColor, width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              _invoiceImagePath!.startsWith('http')
                                  ? Image.network(
                                      _invoiceImagePath!,
                                      fit: BoxFit.contain,
                                      loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator(color: Color(0xFF00D09E))),
                                      errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image_rounded, size: 64, color: Colors.grey)),
                                    )
                                  : Image.file(
                                      File(_invoiceImagePath!),
                                      fit: BoxFit.contain,
                                    ),
                              Positioned(
                                bottom: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.zoom_in_rounded, color: Colors.white, size: 18),
                                      SizedBox(width: 6),
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
                    ),
                  ],
                ],
              )
            else if (_selectedImagePath != null && (_selectedImagePath!.startsWith('http') || kIsWeb || File(_selectedImagePath!).existsSync()))
              Stack(
                alignment: Alignment.topRight,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (!_selectedImagePath!.toLowerCase().endsWith('.pdf')) {
                        final isNet = _selectedImagePath!.startsWith('http');
                        _showFullScreenImage(_selectedImagePath!, isNetwork: isNet);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 250),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F1E15) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: inputBorderColor, width: 1.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _selectedImagePath!.toLowerCase().endsWith('.pdf')
                            ? Container(
                                color: isDark ? const Color(0xFF0D251C) : const Color(0xFFF1F8F5),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.picture_as_pdf_rounded, size: 64, color: Color(0xFF00D09E)),
                                    const SizedBox(height: 12),
                                    Text(
                                      _selectedImagePath!.split(Platform.pathSeparator).last,
                                      style: TextStyle(
                                        color: isDark ? Colors.white70 : const Color(0xFF093021),
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : Stack(
                                alignment: Alignment.center,
                                children: [
                                  _selectedImagePath!.startsWith('http')
                                      ? Image.network(
                                          _selectedImagePath!,
                                          fit: BoxFit.contain,
                                          loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator(color: Color(0xFF00D09E))),
                                          errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image_rounded, size: 64, color: Colors.grey)),
                                        )
                                      : Image.file(
                                          File(_selectedImagePath!),
                                          fit: BoxFit.contain,
                                        ),
                                  Positioned(
                                    bottom: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.zoom_in_rounded, color: Colors.white, size: 18),
                                          SizedBox(width: 6),
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
                  ),
                  if (!_isReadOnly)
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
            else if (!_isReadOnly)
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
                            Text('Chụp ảnh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                            Text('Thư viện', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: _pickFile,
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
                            Icon(Icons.attach_file_rounded, color: Color(0xFF00D09E), size: 20),
                            SizedBox(width: 8),
                            Text('File', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 40),

            if (!_isReadOnly)
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
                    child: _isSaving 
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Lưu Giao Dịch',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                  ),
                ),
              ),
            if (_isReadOnly && _status == TransactionStatus.deleted)
              ScaleOnTap(
                onTap: _confirmRestore,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Khôi phục Giao dịch',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              )
            else if (_isReadOnly)
              const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _FullScreenImageViewer extends StatefulWidget {
  final String path;
  final bool isNetwork;

  const _FullScreenImageViewer({super.key, required this.path, required this.isNetwork});

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
              child: widget.isNetwork
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
