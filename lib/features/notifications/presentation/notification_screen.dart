import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/scale_on_tap.dart';

class NotificationItem {
  final String title;
  final String content;
  final String time;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String? detailRoute;

  NotificationItem({
    required this.title,
    required this.content,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    this.detailRoute,
  });
}

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // SmartFinance project specific mock notifications in Vietnamese
    final todayNotifications = [
      NotificationItem(
        title: 'Smart Scan thành công!',
        content: 'Hóa đơn mua văn phòng phẩm vừa được quét tự động thành công. Vui lòng kiểm tra và xác nhận giao dịch.',
        time: '14:30 - Hôm nay',
        icon: Icons.qr_code_scanner_rounded,
        iconColor: const Color(0xFF0284C7), // Light blue
        iconBgColor: const Color(0xFFE0F2FE),
        detailRoute: '/invoices/incoming',
      ),
      NotificationItem(
        title: 'Yêu cầu duyệt chi tiêu',
        content: 'Kế toán chi vừa gửi yêu cầu duyệt khoản chi "Tiền điện văn phòng" trị giá 1.500.000 ₫.',
        time: '11:15 - Hôm nay',
        icon: Icons.rate_review_rounded,
        iconColor: const Color(0xFFEA580C), // Orange
        iconBgColor: const Color(0xFFFFF7ED),
        detailRoute: '/transactions',
      ),
    ];

    final yesterdayNotifications = [
      NotificationItem(
        title: 'Đạt tiến độ mục tiêu tiết kiệm',
        content: 'Mục tiêu "Tiết kiệm mua xe ô tô" của doanh nghiệp đã hoàn thành 65% chặng đường. Tiếp tục cố gắng nhé!',
        time: '17:00 - Hôm qua',
        icon: Icons.savings_rounded,
        iconColor: const Color(0xFF059669), // Green
        iconBgColor: const Color(0xFFECFDF5),
      ),
      NotificationItem(
        title: 'Cảnh báo vượt ngân sách',
        content: 'Ngân sách danh mục "Chi ăn uống tiếp khách" đã sử dụng vượt quá 90% giới hạn tháng này.',
        time: '09:30 - Hôm qua',
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFFE11D48), // Rose red
        iconBgColor: const Color(0xFFFEE2E2),
        detailRoute: '/dashboard',
      ),
    ];

    final olderNotifications = [
      NotificationItem(
        title: 'Báo cáo dòng tiền tháng trước',
        content: 'Báo cáo dòng tiền tuần/tháng vừa được cập nhật đầy đủ. Bạn có thể xuất file PDF ngay bây giờ.',
        time: '16:00 - 2 ngày trước',
        icon: Icons.analytics_rounded,
        iconColor: const Color(0xFF4F46E5), // Indigo
        iconBgColor: const Color(0xFFEEF2FF),
        detailRoute: '/reports',
      ),
      NotificationItem(
        title: 'Hệ thống cập nhật',
        content: 'Tính năng tự động quét hóa đơn PDF bằng AI đã được cải tiến độ chính xác lên 99%.',
        time: '08:00 - 3 ngày trước',
        icon: Icons.system_update_alt_rounded,
        iconColor: const Color(0xFF64748B), // Slate grey
        iconBgColor: const Color(0xFFF1F5F9),
      ),
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF06150F) : const Color(0xFFF4FAF7),
      body: Column(
        children: [
          // Custom Header matching Notification UI template
          Container(
            padding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00D09E), Color(0xFF00B78A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ScaleOnTap(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const Text(
                  'Thông báo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          // Notification List
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                if (todayNotifications.isNotEmpty) ...[
                  _buildSectionHeader('Hôm nay', isDark),
                  ...todayNotifications.map((n) => _buildNotificationCard(context, n, isDark)),
                  const SizedBox(height: 16),
                ],
                if (yesterdayNotifications.isNotEmpty) ...[
                  _buildSectionHeader('Hôm qua', isDark),
                  ...yesterdayNotifications.map((n) => _buildNotificationCard(context, n, isDark)),
                  const SizedBox(height: 16),
                ],
                if (olderNotifications.isNotEmpty) ...[
                  _buildSectionHeader('Cũ hơn', isDark),
                  ...olderNotifications.map((n) => _buildNotificationCard(context, n, isDark)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white60 : Colors.grey.shade600,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationItem item, bool isDark) {
    return ScaleOnTap(
      onTap: () {
        if (item.detailRoute != null) {
          context.push(item.detailRoute!);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0C2C1F) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon background container
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.icon,
                color: item.iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // Title & Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.content,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.time,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white38 : Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
