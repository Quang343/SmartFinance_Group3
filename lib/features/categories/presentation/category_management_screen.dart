import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/role_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../core/widgets/scale_on_tap.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends ConsumerState<CategoryManagementScreen> {
  final _newCategoryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _displayLimit = 10;
  List<CategoryEntity> _allCats = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData(withDelay: true);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
        setState(() {
          _displayLimit += 10;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  void _loadData({bool withDelay = false}) async {
    final repo = ref.read(categoryRepositoryProvider);
    if (withDelay && mounted) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(seconds: 1));
    }
    try {
      final cats = await repo.getAll();
      if (mounted) {
        setState(() {
          _allCats = cats;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _addCategory(String type) async {
    final name = _newCategoryController.text.trim();
    if (name.isEmpty) return;

    final repo = ref.read(categoryRepositoryProvider);
    final newCat = CategoryEntity(
      id: 'cat_${const Uuid().v4().substring(0, 8)}',
      name: name,
      type: type,
      isDefault: false,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await repo.create(newCat);
    _newCategoryController.clear();
    if (mounted) {
      _loadData(withDelay: false);
    }
  }

  void _showAddCategoryDialog(String type) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryColor = const Color(0xFF00D09E);
        final inputFillColor = isDark ? const Color(0xFF060E0A) : Colors.grey.shade50;
        final inputBorderColor = isDark ? const Color(0xFF1E382B) : Colors.grey.shade300;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0F1E15) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Thêm danh mục ${type == 'income' ? 'Doanh thu' : 'Chi phí'}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          content: TextField(
            controller: _newCategoryController,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: 'Nhập tên danh mục...',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: inputFillColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: inputBorderColor, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () {
                if (dialogContext.canPop()) dialogContext.pop();
              },
              child: Text(
                'Hủy',
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              ),
            ),
            ScaleOnTap(
              onTap: () {
                if (dialogContext.canPop()) dialogContext.pop();
                _addCategory(type);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Thêm',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF060E0A),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditCategoryDialog(CategoryEntity cat) {
    _newCategoryController.text = cat.name;
    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryColor = const Color(0xFF00D09E);
        final inputFillColor = isDark ? const Color(0xFF060E0A) : Colors.grey.shade50;
        final inputBorderColor = isDark ? const Color(0xFF1E382B) : Colors.grey.shade300;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0F1E15) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Sửa tên danh mục',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          content: TextField(
            controller: _newCategoryController,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: 'Nhập tên danh mục...',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: inputFillColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: inputBorderColor, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () {
                _newCategoryController.clear();
                if (dialogContext.canPop()) dialogContext.pop();
              },
              child: Text(
                'Hủy',
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              ),
            ),
            ScaleOnTap(
              onTap: () async {
                final newName = _newCategoryController.text.trim();
                if (newName.isNotEmpty) {
                  final updated = CategoryEntity(
                    id: cat.id,
                    name: newName,
                    type: cat.type,
                    iconCode: cat.iconCode,
                    colorHex: cat.colorHex,
                    isDefault: cat.isDefault,
                    isActive: cat.isActive,
                    createdAt: cat.createdAt,
                    updatedAt: DateTime.now(),
                  );
                  await ref.read(categoryRepositoryProvider).update(updated);
                  _newCategoryController.clear();
                  if (mounted) _loadData(withDelay: false);
                }
                if (dialogContext.canPop()) dialogContext.pop();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Lưu',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF060E0A),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleDeleteAction(CategoryEntity cat) async {
    final allTxs = await ref.read(transactionRepositoryProvider).getAll();
    final hasTransactions = allTxs.any((tx) => tx.categoryId == cat.id);
    if (!mounted) return;
    _showDeleteConfirmDialog(cat, hasTransactions);
  }

  void _onReorder(int oldIndex, int newIndex, List<CategoryEntity> list) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = list.removeAt(oldIndex);
      list.insert(newIndex, item);

      for (int i = 0; i < list.length; i++) {
        final catIndex = _allCats.indexWhere((c) => c.id == list[i].id);
        if (catIndex != -1) {
          final old = _allCats[catIndex];
          _allCats[catIndex] = CategoryEntity(
            id: old.id,
            name: old.name,
            type: old.type,
            iconCode: old.iconCode,
            colorHex: old.colorHex,
            isDefault: old.isDefault,
            isActive: old.isActive,
            orderIndex: i,
            createdAt: old.createdAt,
            updatedAt: DateTime.now(),
          );
        }
      }
    });

    final repo = ref.read(categoryRepositoryProvider);
    for (int i = 0; i < list.length; i++) {
      final catIndex = _allCats.indexWhere((c) => c.id == list[i].id);
      if (catIndex != -1) {
        await repo.update(_allCats[catIndex]);
      }
    }
  }

  void _showDeleteConfirmDialog(CategoryEntity cat, bool hasTransactions) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0F1E15) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            hasTransactions ? 'Danh mục đang được sử dụng' : 'Xác nhận xóa',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          content: Text(
            hasTransactions
                ? 'Danh mục "${cat.name}" đang chứa giao dịch nên không thể xóa vĩnh viễn.\n\nBạn có muốn Ẩn (Lưu trữ) danh mục này không? Các giao dịch cũ vẫn được giữ lại nhưng danh mục sẽ không hiện ra khi tạo giao dịch mới.'
                : 'Bạn có chắc chắn muốn xóa danh mục "${cat.name}" không?',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () {
                if (dialogContext.canPop()) dialogContext.pop();
              },
              child: Text(
                'Hủy',
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              ),
            ),
            ScaleOnTap(
              onTap: () async {
                if (hasTransactions) {
                  await ref.read(categoryRepositoryProvider).deactivate(cat.id);
                } else {
                  await ref.read(categoryRepositoryProvider).delete(cat.id);
                }
                
                if (context.mounted) {
                  _loadData(withDelay: false);
                }
                if (dialogContext.canPop()) dialogContext.pop();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: hasTransactions ? Colors.orange : Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  hasTransactions ? 'Ẩn danh mục' : 'Xóa vĩnh viễn',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRole = ref.watch(roleProvider);
    final categoryRepo = ref.watch(categoryRepositoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final showIncome = currentRole == UserRole.financeManager || currentRole == UserRole.revenueAccountant;
    final showExpense = currentRole == UserRole.financeManager || currentRole == UserRole.expenseAccountant;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF06150F) : const Color(0xFFF4FAF7),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/images/loadingGif.gif',
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                ),
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
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF06150F) : const Color(0xFFF4FAF7),
        body: Center(child: Text('Lỗi: $_error', style: const TextStyle(color: Colors.red))),
      );
    }

    final allCats = _allCats;
        final incomeCats = allCats.where((c) => c.type == 'income').toList()
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
        final expenseCats = allCats.where((c) => c.type == 'expense').toList()
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

        final displayIncome = incomeCats.take(_displayLimit).toList();
        final displayExpense = expenseCats.take(_displayLimit).toList();

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF06150F) : const Color(0xFFF4FAF7),
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF06150F) : const Color(0xFFF4FAF7),
            elevation: 0,
            centerTitle: false,
            titleSpacing: 20,
            title: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFF00D09E),
                  Color(0xFF34D399),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Text(
                'Quản lý Danh mục',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 22,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          body: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              if (showIncome) ...[
                _buildHeader(
                  title: 'Danh mục Doanh thu',
                  onAdd: currentRole == UserRole.revenueAccountant
                      ? () => _showAddCategoryDialog('income')
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Nhấn giữ biểu tượng ☰ và kéo để đổi thứ tự',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                  ),
                ),
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  proxyDecorator: (child, index, animation) => Material(
                    type: MaterialType.transparency,
                    child: IgnorePointer(child: child),
                  ),
                  itemCount: displayIncome.length,
                  itemBuilder: (context, index) => _buildCategoryTile(displayIncome[index], currentRole, index),
                  onReorder: (oldIndex, newIndex) => _onReorder(oldIndex, newIndex, displayIncome),
                ),
                if (incomeCats.length > _displayLimit)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF00D09E))),
                  ),
                const SizedBox(height: 24),
              ],
              if (showExpense) ...[
                _buildHeader(
                  title: 'Danh mục Chi phí',
                  onAdd: currentRole == UserRole.expenseAccountant
                      ? () => _showAddCategoryDialog('expense')
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Nhấn giữ biểu tượng ☰ và kéo để đổi thứ tự',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                  ),
                ),
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  proxyDecorator: (child, index, animation) => Material(
                    type: MaterialType.transparency,
                    child: IgnorePointer(child: child),
                  ),
                  itemCount: displayExpense.length,
                  itemBuilder: (context, index) => _buildCategoryTile(displayExpense[index], currentRole, index),
                  onReorder: (oldIndex, newIndex) => _onReorder(oldIndex, newIndex, displayExpense),
                ),
                if (expenseCats.length > _displayLimit)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF00D09E))),
                  ),
              ],
            ],
          ),
        );
  }

  Widget _buildHeader({required String title, VoidCallback? onAdd}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          if (onAdd != null)
            ScaleOnTap(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0x1500D09E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Color(0xFF00D09E),
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(CategoryEntity cat, UserRole role, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canManage = role == UserRole.financeManager;
    final canEdit = canManage || 
                    (cat.type == 'income' && role == UserRole.revenueAccountant) ||
                    (cat.type == 'expense' && role == UserRole.expenseAccountant);

    return Padding(
      key: ValueKey(cat.id),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1E15) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E382B) : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (canEdit)
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Icon(Icons.drag_handle_rounded, color: isDark ? Colors.white38 : Colors.black38),
                ),
              ),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cat.type == 'income' 
                    ? const Color(0x1500D09E) 
                    : const Color(0x15EF4444),
                shape: BoxShape.circle,
              ),
              child: Icon(
                cat.type == 'income' ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                color: cat.type == 'income' ? const Color(0xFF00D09E) : const Color(0xFFEF4444),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                cat.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (canEdit) ...[
              Switch(
                value: cat.isActive,
                activeColor: const Color(0xFF00D09E),
                activeTrackColor: const Color(0xFF00D09E).withOpacity(0.3),
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.grey.withOpacity(0.3),
                onChanged: (val) async {
                  final updated = CategoryEntity(
                    id: cat.id,
                    name: cat.name,
                    type: cat.type,
                    iconCode: cat.iconCode,
                    colorHex: cat.colorHex,
                    isDefault: cat.isDefault,
                    isActive: val,
                    createdAt: cat.createdAt,
                    updatedAt: DateTime.now(),
                  );
                  await ref.read(categoryRepositoryProvider).update(updated);
                  if (mounted) _loadData(withDelay: false);
                },
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: isDark ? Colors.white70 : Colors.black54),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditCategoryDialog(cat);
                  } else if (value == 'delete') {
                    _handleDeleteAction(cat);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Sửa')]),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 8), Text('Xóa', style: TextStyle(color: Colors.red))]),
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cat.isActive 
                      ? const Color(0x1500D09E) 
                      : (isDark ? Colors.white10 : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  cat.isActive ? 'Hoạt động' : 'Tạm ngưng',
                  style: TextStyle(
                    color: cat.isActive ? const Color(0xFF00D09E) : Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }
}
