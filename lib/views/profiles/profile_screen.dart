import 'package:flutter/material.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../core/constants/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  final ThemeController themeController;
  final VoidCallback? onLogOut;

  const ProfileScreen({
    super.key,
    required this.themeController,
    this.onLogOut,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileController _controller = ProfileController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeController.isDarkMode;
    final cardColor = Theme.of(context).colorScheme.surface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Profile & Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: textColor,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([_controller, widget.themeController]),
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // 1. Thẻ thông tin cá nhân (User Profile Tile)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: borderColor.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.lime : Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 32,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _controller.displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _controller.email,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.greySubtext,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: AppColors.greySubtext),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2. Hai thẻ chỉ số BMR / TDEE
              Row(
                children: [
                  _buildCalorieBadge(
                    title: 'BMR',
                    value: '${_controller.bmr} kcal',
                    cardColor: cardColor,
                    borderColor: borderColor,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),
                  _buildCalorieBadge(
                    title: 'TDEE',
                    value: '${_controller.tdee} kcal',
                    cardColor: cardColor,
                    borderColor: borderColor,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 3. Thẻ Target Macros (%)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: borderColor.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Target Macros',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: textColor,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // Xử lý mở dialog chỉnh % Macro
                          },
                          child: Text(
                            'Edit',
                            style: TextStyle(
                              color: isDark ? AppColors.lime : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildMacroRow('Protein', '${_controller.proteinPercent}%', textColor),
                    Divider(height: 20, color: borderColor.withOpacity(0.6)),
                    _buildMacroRow('Carbs', '${_controller.carbsPercent}%', textColor),
                    Divider(height: 20, color: borderColor.withOpacity(0.6)),
                    _buildMacroRow('Fat', '${_controller.fatPercent}%', textColor),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Khối danh sách Cài đặt (Preferences & Theme)
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: borderColor.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    // Công tắc Theme Sáng / Tối
                    ListTile(
                      leading: Icon(
                        isDark ? Icons.dark_mode : Icons.light_mode,
                        color: textColor,
                        size: 22,
                      ),
                      title: Text(
                        'Theme Appearance',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                      ),
                      subtitle: Text(
                        isDark ? 'Dark Mode' : 'Light Mode',
                        style: const TextStyle(fontSize: 12, color: AppColors.greySubtext),
                      ),
                      trailing: Switch(
                        value: isDark,
                        activeColor: AppColors.lime,
                        activeTrackColor: Colors.grey[800],
                        onChanged: (val) => widget.themeController.toggleTheme(val),
                      ),
                    ),
                    Divider(height: 1, color: borderColor.withOpacity(0.6)),

                    // Đơn vị
                    _buildSettingTile(
                      icon: Icons.straighten_outlined,
                      title: 'Units',
                      value: _controller.unitSystem,
                      textColor: textColor,
                      onTap: () {},
                    ),
                    Divider(height: 1, color: borderColor.withOpacity(0.6)),

                    // Thông báo
                    _buildSettingTile(
                      icon: Icons.notifications_none_outlined,
                      title: 'Notifications',
                      value: _controller.notificationsEnabled ? 'On' : 'Off',
                      textColor: textColor,
                      onTap: () => _controller.toggleNotifications(!_controller.notificationsEnabled),
                    ),
                    Divider(height: 1, color: borderColor.withOpacity(0.6)),

                    // Quyền riêng tư
                    _buildSettingTile(
                      icon: Icons.lock_outline,
                      title: 'Privacy & Security',
                      value: '',
                      textColor: textColor,
                      onTap: () {},
                    ),
                    Divider(height: 1, color: borderColor.withOpacity(0.6)),

                    // Giới thiệu
                    _buildSettingTile(
                      icon: Icons.info_outline,
                      title: 'About Macro',
                      value: _controller.appVersion,
                      textColor: textColor,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5. Nút Đăng Xuất (Log Out)
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor.withOpacity(0.5)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.fat, size: 22),
                  title: const Text(
                    'Log Out',
                    style: TextStyle(
                      color: AppColors.fat,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  onTap: () {
                    _controller.logOut();
                    if (widget.onLogOut != null) {
                      widget.onLogOut!();
                    }
                  },
                ),
              ),
              const SizedBox(height: 28),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCalorieBadge({
    required String title,
    required String value,
    required Color cardColor,
    required Color borderColor,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: AppColors.greySubtext, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.lime : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroRow(String label, String value, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.greySubtext),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String value,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 22, color: textColor),
      title: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value.isNotEmpty)
            Text(
              value,
              style: const TextStyle(fontSize: 12, color: AppColors.greySubtext),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.greySubtext),
        ],
      ),
    );
  }
}