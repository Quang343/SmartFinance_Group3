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
      setState(() {});
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

  @override
  Widget build(BuildContext context) {
    final currentRole = ref.watch(roleProvider);
    final categoryRepo = ref.watch(categoryRepositoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final showIncome = currentRole == UserRole.financeManager || currentRole == UserRole.revenueAccountant;
    final showExpense = currentRole == UserRole.financeManager || currentRole == UserRole.expenseAccountant;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF060E0A) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Quản lý Danh mục',
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
              context.go('/dashboard');
            }
          },
        ),
      ),
      body: FutureBuilder<List<CategoryEntity>>(
        future: categoryRepo.getAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00D09E)));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          final allCats = snapshot.data ?? [];
          final incomeCats = allCats.where((c) => c.type == 'income').toList();
          final expenseCats = allCats.where((c) => c.type == 'expense').toList();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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

  Widget _buildCategoryTile(CategoryEntity cat, UserRole role) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canEdit = (cat.type == 'income' && role == UserRole.revenueAccountant) ||
                    (cat.type == 'expense' && role == UserRole.expenseAccountant);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
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
            if (canEdit)
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
                  setState(() {});
                },
              )
            else
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
        ),
      ),
    );
  }
}
