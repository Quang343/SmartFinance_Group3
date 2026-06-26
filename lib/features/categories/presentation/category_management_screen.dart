import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
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
      Navigator.pop(context);
      setState(() {});
    }
  }

  void _showAddCategoryDialog(String type) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text('Thêm danh mục ${type == 'income' ? 'Doanh thu' : 'Chi phí'}'),
          content: TextField(
            controller: _newCategoryController,
            decoration: const InputDecoration(
              hintText: 'Nhập tên danh mục...',
            ),
          ),
          actions: [
            ScaleOnTap(
              onTap: () => Navigator.pop(context),
              child: TextButton(
                onPressed: null,
                child: const Text('Hủy'),
              ),
            ),
            ScaleOnTap(
              onTap: () => _addCategory(type),
              child: ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: theme.colorScheme.primary,
                  disabledForegroundColor: Colors.white,
                ),
                child: const Text('Thêm'),
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

    final showIncome = currentRole == UserRole.financeManager || currentRole == UserRole.revenueAccountant;
    final showExpense = currentRole == UserRole.financeManager || currentRole == UserRole.expenseAccountant;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Danh mục'),
      ),
      body: FutureBuilder<List<CategoryEntity>>(
        future: categoryRepo.getAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final allCats = snapshot.data ?? [];
          final incomeCats = allCats.where((c) => c.type == 'income').toList();
          final expenseCats = allCats.where((c) => c.type == 'expense').toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (showIncome) ...[
                _buildHeader(
                  title: 'Danh mục Doanh thu (Thu)',
                  onAdd: currentRole == UserRole.revenueAccountant
                      ? () => _showAddCategoryDialog('income')
                      : null,
                ),
                ...incomeCats.map((cat) => _buildCategoryTile(cat, currentRole)),
                const SizedBox(height: 24),
              ],
              if (showExpense) ...[
                _buildHeader(
                  title: 'Danh mục Chi phí (Chi)',
                  onAdd: currentRole == UserRole.expenseAccountant
                      ? () => _showAddCategoryDialog('expense')
                      : null,
                ),
                ...expenseCats.map((cat) => _buildCategoryTile(cat, currentRole)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader({required String title, VoidCallback? onAdd}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (onAdd != null)
            ScaleOnTap(
              onTap: onAdd,
              child: IconButton(
                icon: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
                onPressed: null,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(CategoryEntity cat, UserRole role) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canEdit = (cat.type == 'income' && role == UserRole.revenueAccountant) ||
                    (cat.type == 'expense' && role == UserRole.expenseAccountant);

    return ScaleOnTap(
      onTap: () {},
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: cat.type == 'income' 
                ? (isDark ? Colors.green.withOpacity(0.15) : Colors.green.shade50)
                : (isDark ? Colors.red.withOpacity(0.15) : Colors.red.shade50),
            child: Icon(
              cat.type == 'income' ? Icons.trending_up : Icons.trending_down,
              color: cat.type == 'income' ? Colors.green : Colors.red,
            ),
          ),
          title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: canEdit
              ? Switch(
                  value: cat.isActive,
                  activeColor: theme.colorScheme.primary,
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
                    setState(() {});
                  },
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cat.isActive 
                        ? (isDark ? Colors.green.withOpacity(0.15) : Colors.green.shade50)
                        : (isDark ? Colors.grey.withOpacity(0.15) : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    cat.isActive ? 'Hoạt động' : 'Tạm ngưng',
                    style: TextStyle(
                      color: cat.isActive ? Colors.green : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
