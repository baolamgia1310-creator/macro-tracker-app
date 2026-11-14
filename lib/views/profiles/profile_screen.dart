import 'package:flutter/material.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../core/constants/app_colors.dart';
import '../calculator/bmr_tdee_calculator_screen.dart';

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

  void _showEditNameDialog(BuildContext context, Color cardColor, Color textColor) {
    final nameCtrl = TextEditingController(text: _controller.displayName);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Edit Display Name',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: textColor),
          ),
          content: TextField(
            controller: nameCtrl,
            style: TextStyle(color: textColor),
            decoration: const InputDecoration(
              hintText: 'Enter your name',
              hintStyle: TextStyle(color: AppColors.greySubtext),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.greySubtext)),
            ),
            ElevatedButton(
              onPressed: () async {
                await _controller.updateDisplayName(nameCtrl.text);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lime,
                foregroundColor: Colors.black,
              ),
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showEditMacrosSheet(BuildContext context, bool isDark, Color cardColor, Color textColor) {
    final calCtrl = TextEditingController(text: '${_controller.targetCalories}');
    int pPct = _controller.proteinPercent;
    int cPct = _controller.carbsPercent;
    int fPct = _controller.fatPercent;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final totalPct = pPct + cPct + fPct;
            final isValid = totalPct == 100;
            final currentCal = int.tryParse(calCtrl.text.trim()) ?? _controller.targetCalories;

            final pGrams = ((currentCal * (pPct / 100.0)) / 4).round();
            final cGrams = ((currentCal * (cPct / 100.0)) / 4).round();
            final fGrams = ((currentCal * (fPct / 100.0)) / 9).round();

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Customize Target Macros',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.greySubtext),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Daily Calorie Goal Input
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: calCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setModalState(() {}),
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                        decoration: const InputDecoration(
                          labelText: 'Daily Calorie Goal (kcal)',
                          labelStyle: TextStyle(fontSize: 12, color: AppColors.greySubtext),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Protein Slider
                    _buildMacroSliderRow(
                      label: 'Protein',
                      percent: pPct,
                      grams: pGrams,
                      color: AppColors.protein,
                      textColor: textColor,
                      onChanged: (val) => setModalState(() => pPct = val.round()),
                    ),
                    const SizedBox(height: 10),

                    // Carbs Slider
                    _buildMacroSliderRow(
                      label: 'Carbs',
                      percent: cPct,
                      grams: cGrams,
                      color: AppColors.carbs,
                      textColor: textColor,
                      onChanged: (val) => setModalState(() => cPct = val.round()),
                    ),
                    const SizedBox(height: 10),

                    // Fat Slider
                    _buildMacroSliderRow(
                      label: 'Fat',
                      percent: fPct,
                      grams: fGrams,
                      color: AppColors.fat,
                      textColor: textColor,
                      onChanged: (val) => setModalState(() => fPct = val.round()),
                    ),
                    const SizedBox(height: 12),

                    // Total validation badge
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      decoration: BoxDecoration(
                        color: isValid
                            ? AppColors.lime.withOpacity(isDark ? 0.15 : 0.3)
                            : Colors.redAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isValid
                            ? 'Total: 100% • Ready to save'
                            : 'Total must equal 100% (Currently: $totalPct%)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: isValid
                              ? (isDark ? AppColors.lime : const Color(0xFF365314))
                              : Colors.redAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: (!isValid || isSaving)
                          ? null
                          : () async {
                              setModalState(() => isSaving = true);
                              await _controller.updateTargetMacros(
                                targetCalories: currentCal,
                                proteinPct: pPct,
                                carbsPct: cPct,
                                fatPct: fPct,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lime,
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Text(
                              'Save Target Macros',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMacroSliderRow({
    required String label,
    required int percent,
    required int grams,
    required Color color,
    required Color textColor,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: textColor),
            ),
            Text(
              '$percent% ($grams g)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            thumbColor: color,
            inactiveTrackColor: color.withOpacity(0.2),
          ),
          child: Slider(
            value: percent.toDouble().clamp(5.0, 80.0),
            min: 5,
            max: 80,
            divisions: 15,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  void _showThemeSelectionSheet(BuildContext context, Color cardColor, Color textColor, Color borderColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'Theme Appearance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildThemeItem(
                  ctx: ctx,
                  title: 'System Default',
                  subtitle: 'Match device settings',
                  mode: ThemeMode.system,
                  icon: Icons.settings_suggest_outlined,
                  textColor: textColor,
                ),
                Divider(height: 1, color: borderColor.withOpacity(0.5)),
                _buildThemeItem(
                  ctx: ctx,
                  title: 'Light Mode',
                  subtitle: 'Clean white appearance',
                  mode: ThemeMode.light,
                  icon: Icons.light_mode_outlined,
                  textColor: textColor,
                ),
                Divider(height: 1, color: borderColor.withOpacity(0.5)),
                _buildThemeItem(
                  ctx: ctx,
                  title: 'Dark Mode',
                  subtitle: 'High contrast dark theme',
                  mode: ThemeMode.dark,
                  icon: Icons.dark_mode_outlined,
                  textColor: textColor,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeItem({
    required BuildContext ctx,
    required String title,
    required String subtitle,
    required ThemeMode mode,
    required IconData icon,
    required Color textColor,
  }) {
    final isSelected = widget.themeController.themeMode == mode;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.lime : AppColors.greySubtext,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: textColor,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.greySubtext),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.lime, size: 20)
          : null,
      onTap: () {
        widget.themeController.setThemeMode(mode);
        Navigator.pop(ctx);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_controller, widget.themeController]),
      builder: (context, _) {
        final isDark = widget.themeController.isDarkMode(context);
        final cardColor = Theme.of(context).colorScheme.surface;
        final textColor = isDark ? AppColors.darkText : AppColors.lightText;
        final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            title: Text(
              'Profile & Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: textColor,
              ),
            ),
          ),
          body: _controller.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.lime, strokeWidth: 2.5),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  children: [
                    // 1. User Profile Tile (Click to edit Display Name)
                    GestureDetector(
                      onTap: () => _showEditNameDialog(context, cardColor, textColor),
                      child: Container(
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
                                size: 30,
                                color: isDark ? Colors.black : Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
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
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.greySubtext,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.edit_outlined, size: 18, color: AppColors.greySubtext),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 2. BMR & TDEE Badges
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

                    // 3. Target Macros Card
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Target Macros',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    'Daily Goal: ${_controller.targetCalories} kcal',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.greySubtext,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () => _showEditMacrosSheet(context, isDark, cardColor, textColor),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.lime.withOpacity(0.15) : Colors.black.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    'Edit',
                                    style: TextStyle(
                                      color: isDark ? AppColors.lime : Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildMacroRow(
                            'Protein',
                            '${_controller.proteinPercent}% (${_controller.proteinGrams.round()}g)',
                            textColor,
                          ),
                          Divider(height: 20, color: borderColor.withOpacity(0.6)),
                          _buildMacroRow(
                            'Carbs',
                            '${_controller.carbsPercent}% (${_controller.carbsGrams.round()}g)',
                            textColor,
                          ),
                          Divider(height: 20, color: borderColor.withOpacity(0.6)),
                          _buildMacroRow(
                            'Fat',
                            '${_controller.fatPercent}% (${_controller.fatGrams.round()}g)',
                            textColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. Preferences & Body Calibration
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: borderColor.withOpacity(0.5)),
                      ),
                      child: Column(
                        children: [
                          _buildSettingTile(
                            icon: Icons.calculate_outlined,
                            title: 'Recalculate BMR & TDEE',
                            value: '${_controller.weightKg} kg',
                            textColor: textColor,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (calcCtx) => BmrTdeeCalculatorScreen(
                                    onSetupCompleted: () => Navigator.of(calcCtx).maybePop(),
                                  ),
                                ),
                              );
                            },
                          ),
                          Divider(height: 1, color: borderColor.withOpacity(0.6)),
                          ListTile(
                            leading: Icon(
                              isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                              color: textColor,
                              size: 22,
                            ),
                            title: Text(
                              'Theme Appearance',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                            ),
                            subtitle: Text(
                              widget.themeController.themeModeTitle,
                              style: const TextStyle(fontSize: 12, color: AppColors.greySubtext),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.themeController.themeModeTitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.lime : Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right, size: 18, color: AppColors.greySubtext),
                              ],
                            ),
                            onTap: () => _showThemeSelectionSheet(context, cardColor, textColor, borderColor),
                          ),
                          Divider(height: 1, color: borderColor.withOpacity(0.6)),
                          _buildSettingTile(
                            icon: Icons.straighten_outlined,
                            title: 'Units',
                            value: _controller.unitSystem,
                            textColor: textColor,
                            onTap: () {},
                          ),
                          Divider(height: 1, color: borderColor.withOpacity(0.6)),
                          _buildSettingTile(
                            icon: Icons.notifications_none_outlined,
                            title: 'Notifications',
                            value: _controller.notificationsEnabled ? 'On' : 'Off',
                            textColor: textColor,
                            onTap: () => _controller.toggleNotifications(!_controller.notificationsEnabled),
                          ),
                          Divider(height: 1, color: borderColor.withOpacity(0.6)),
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

                    // 5. Log Out Button
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
                        onTap: () async {
                          await _controller.logOut();
                          if (widget.onLogOut != null) {
                            widget.onLogOut!();
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
        );
      },
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