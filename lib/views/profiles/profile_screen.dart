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

  static const Color _lightModeLimeText = Color(0xFF365314);
  static const Color _emeraldGreen = Color(0xFF10B981);
  static const Color _warningAmber = Color(0xFFF59E0B);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showEditNameDialog(
    BuildContext context,
    Color cardColor,
    Color textColor,
  ) {
    final nameCtrl = TextEditingController(text: _controller.displayName);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Edit Display Name',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: textColor,
            ),
          ),
          content: TextField(
            controller: nameCtrl,
            autofocus: true,
            style: TextStyle(color: textColor),
            decoration: const InputDecoration(
              hintText: 'Enter your name',
              hintStyle: TextStyle(color: AppColors.greySubtext),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.greySubtext),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final text = nameCtrl.text;
                Navigator.pop(ctx);
                _controller.updateDisplayName(text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lime,
                foregroundColor: Colors.black,
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // Hộp thoại chỉnh sửa Macro 2 chế độ: Smart Balance (Tự động) & Free Grams (Tự do)
  void _showEditMacrosSheet(
    BuildContext context,
    bool isDark,
    Color cardColor,
    Color textColor,
  ) {
    bool isFreeMode = false;

    int targetCal = _controller.targetCalories;
    int pPct = _controller.proteinPercent;
    int cPct = _controller.carbsPercent;
    int fPct = (100 - pPct - cPct).clamp(10, 70);

    final calCtrl = TextEditingController(text: '$targetCal');
    final proGramCtrl = TextEditingController(
      text: '${_controller.proteinGrams.round()}',
    );
    final carbGramCtrl = TextEditingController(
      text: '${_controller.carbsGrams.round()}',
    );
    final fatGramCtrl = TextEditingController(
      text: '${_controller.fatGrams.round()}',
    );

    final double userWeight = _controller.weightKg;
    final int userTdee = _controller.tdee;

    // Hàm tự động cân bằng tổng 100% khi người dùng kéo thanh trượt ở Smart Mode
    void autoBalanceSliders(String changedMacro, int newVal) {
      final clamped = newVal.clamp(10, 75);
      if (changedMacro == 'P') {
        pPct = clamped;
        final remaining = 100 - pPct;
        // Ưu tiên điều chỉnh Carbs, giữ Fat ổn định (tối thiểu 15%)
        if (remaining - fPct >= 15) {
          cPct = remaining - fPct;
        } else {
          cPct = 15;
          fPct = (remaining - cPct).clamp(10, 75);
        }
      } else if (changedMacro == 'C') {
        cPct = clamped;
        final remaining = 100 - cPct;
        if (remaining - pPct >= 15) {
          fPct = remaining - pPct;
        } else {
          fPct = 15;
          pPct = (remaining - fPct).clamp(10, 75);
        }
      } else {
        fPct = clamped;
        final remaining = 100 - fPct;
        if (remaining - pPct >= 15) {
          cPct = remaining - pPct;
        } else {
          cPct = 15;
          pPct = (remaining - cPct).clamp(10, 75);
        }
      }
    }

    // Đồng bộ số gram sang các ô TextField khi chuyển từ Smart sang Free Mode
    void syncGramsFromSmart() {
      final cal = int.tryParse(calCtrl.text.trim()) ?? targetCal;
      proGramCtrl.text = '${((cal * (pPct / 100.0)) / 4.0).round()}';
      carbGramCtrl.text = '${((cal * (cPct / 100.0)) / 4.0).round()}';
      fatGramCtrl.text = '${((cal * (fPct / 100.0)) / 9.0).round()}';
    }

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
            final currentSmartCal =
                int.tryParse(calCtrl.text.trim()) ?? targetCal;

            // Tính toán chỉ số theo chế độ đang chọn
            final double pGrams = isFreeMode
                ? (double.tryParse(proGramCtrl.text.trim()) ?? 0.0)
                : ((currentSmartCal * (pPct / 100.0)) / 4.0);
            final double cGrams = isFreeMode
                ? (double.tryParse(carbGramCtrl.text.trim()) ?? 0.0)
                : ((currentSmartCal * (cPct / 100.0)) / 4.0);
            final double fGrams = isFreeMode
                ? (double.tryParse(fatGramCtrl.text.trim()) ?? 0.0)
                : ((currentSmartCal * (fPct / 100.0)) / 9.0);

            final int freeTotalCal =
                ((pGrams * 4.0) + (cGrams * 4.0) + (fGrams * 9.0)).round();
            final int finalCalories =
                isFreeMode ? freeTotalCal : currentSmartCal;

            final int displayPPct = finalCalories > 0
                ? (((pGrams * 4.0) / finalCalories) * 100).round()
                : 0;
            final int displayCPct = finalCalories > 0
                ? (((cGrams * 4.0) / finalCalories) * 100).round()
                : 0;
            final int displayFPct =
                (100 - displayPPct - displayCPct).clamp(0, 100);

            final double proteinPerKg =
                userWeight > 0 ? (pGrams / userWeight) : 0.0;

            return Padding(
              padding: EdgeInsets.only(
                left: 22,
                right: 22,
                top: 18,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
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
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.greySubtext,
                          ),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 1. Thanh chuyển đổi 2 chế độ: Smart Balance vs Free Grams
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (isFreeMode) {
                                  setModalState(() {
                                    isFreeMode = false;
                                    if (freeTotalCal >= 1000) {
                                      targetCal = freeTotalCal;
                                      calCtrl.text = '$freeTotalCal';
                                      pPct = displayPPct.clamp(10, 75);
                                      cPct = displayCPct.clamp(10, 75);
                                      fPct = (100 - pPct - cPct).clamp(10, 75);
                                    }
                                  });
                                }
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !isFreeMode
                                      ? AppColors.lime
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Smart Balance (Auto)',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: !isFreeMode
                                        ? Colors.black
                                        : AppColors.greySubtext,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (!isFreeMode) {
                                  syncGramsFromSmart();
                                  setModalState(() => isFreeMode = true);
                                }
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isFreeMode
                                      ? AppColors.lime
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Free Grams (Gym/Pro)',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: isFreeMode
                                        ? Colors.black
                                        : AppColors.greySubtext,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ================= CHẾ ĐỘ 1: SMART BALANCE =================
                    if (!isFreeMode) ...[
                      // Quick Presets cho người mới
                      Row(
                        children: [
                          _buildPresetChip(
                            label: 'Balanced',
                            subtitle: '30/45/25',
                            isDark: isDark,
                            textColor: textColor,
                            onTap: () {
                              setModalState(() {
                                pPct = 30;
                                cPct = 45;
                                fPct = 25;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildPresetChip(
                            label: '2x Gym Protein',
                            subtitle: '${(userWeight * 2).round()}g Pro',
                            isDark: isDark,
                            textColor: textColor,
                            onTap: () {
                              setModalState(() {
                                final cal =
                                    int.tryParse(calCtrl.text.trim()) ??
                                        targetCal;
                                final desiredProCal = userWeight * 2.0 * 4.0;
                                pPct = ((desiredProCal / cal) * 100)
                                    .round()
                                    .clamp(20, 45);
                                fPct = 25;
                                cPct = 100 - pPct - fPct;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildPresetChip(
                            label: 'Low Carb',
                            subtitle: '35/25/40',
                            isDark: isDark,
                            textColor: textColor,
                            onTap: () {
                              setModalState(() {
                                pPct = 35;
                                cPct = 25;
                                fPct = 40;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Daily Calorie Goal Input
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.black.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          controller: calCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setModalState(() {}),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          decoration: InputDecoration(
                            labelText:
                                'Daily Calorie Goal (TDEE: $userTdee kcal)',
                            labelStyle: const TextStyle(
                              fontSize: 12,
                              color: AppColors.greySubtext,
                            ),
                            suffixText: 'kcal',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildMacroSliderRow(
                        label:
                            'Protein (${proteinPerKg.toStringAsFixed(1)}g/kg)',
                        percent: pPct,
                        grams: pGrams.round(),
                        color: AppColors.protein,
                        textColor: textColor,
                        onChanged: (val) => setModalState(
                          () => autoBalanceSliders('P', val.round()),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildMacroSliderRow(
                        label: 'Carbs',
                        percent: cPct,
                        grams: cGrams.round(),
                        color: AppColors.carbs,
                        textColor: textColor,
                        onChanged: (val) => setModalState(
                          () => autoBalanceSliders('C', val.round()),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildMacroSliderRow(
                        label: 'Fat',
                        percent: fPct,
                        grams: fGrams.round(),
                        color: AppColors.fat,
                        textColor: textColor,
                        onChanged: (val) => setModalState(
                          () => autoBalanceSliders('F', val.round()),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lime.withOpacity(isDark ? 0.14 : 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Auto-balanced at 100% • ${finalCalories} kcal/day',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.lime : _lightModeLimeText,
                          ),
                        ),
                      ),
                    ]

                    // ================= CHẾ ĐỘ 2: FREE GRAMS (GYM / PRO) =================
                    else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Quick Protein by Weight (${userWeight.toStringAsFixed(1)} kg)',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          Text(
                            '${proteinPerKg.toStringAsFixed(1)} g/kg',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.protein,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 4 nút chọn nhanh hệ số nhân Protein (1.6x, 1.8x, 2.0x, 2.2x)
                      Row(
                        children: [1.6, 1.8, 2.0, 2.2].map((mult) {
                          final gVal = (userWeight * mult).round();
                          final isCurrent = (pGrams.round() - gVal).abs() <= 2;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    proGramCtrl.text = '$gVal';
                                  });
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? AppColors.protein.withOpacity(0.2)
                                        : (isDark
                                            ? Colors.white.withOpacity(0.05)
                                            : Colors.black.withOpacity(0.04)),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isCurrent
                                          ? AppColors.protein
                                          : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '${mult}x',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: isCurrent
                                              ? AppColors.protein
                                              : textColor,
                                        ),
                                      ),
                                      Text(
                                        '${gVal}g',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: AppColors.greySubtext,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // 3 ô nhập số Gram trực tiếp: Protein, Carbs, Fat
                      Row(
                        children: [
                          Expanded(
                            child: _buildDirectGramInput(
                              label: 'Protein',
                              percent: displayPPct,
                              controller: proGramCtrl,
                              color: AppColors.protein,
                              isDark: isDark,
                              textColor: textColor,
                              onChanged: () => setModalState(() {}),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildDirectGramInput(
                              label: 'Carbs',
                              percent: displayCPct,
                              controller: carbGramCtrl,
                              color: AppColors.carbs,
                              isDark: isDark,
                              textColor: textColor,
                              onChanged: () => setModalState(() {}),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildDirectGramInput(
                              label: 'Fat',
                              percent: displayFPct,
                              controller: fatGramCtrl,
                              color: AppColors.fat,
                              isDark: isDark,
                              textColor: textColor,
                              onChanged: () => setModalState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Nút tự động tính Carbs để khớp lại mức Calo mục tiêu ban đầu
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            setModalState(() {
                              final usedCal = (pGrams * 4.0) + (fGrams * 9.0);
                              final remainCal =
                                  (_controller.targetCalories - usedCal)
                                      .clamp(0.0, 5000.0);
                              carbGramCtrl.text =
                                  '${(remainCal / 4.0).round()}';
                            });
                          },
                          icon: Icon(
                            Icons.auto_fix_high,
                            size: 15,
                            color: isDark ? AppColors.lime : _lightModeLimeText,
                          ),
                          label: Text(
                            'Auto-fit Carbs to ${_controller.targetCalories} kcal goal',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color:
                                  isDark ? AppColors.lime : _lightModeLimeText,
                            ),
                          ),
                        ),
                      ),

                      // Thanh tổng kết Calo từ số Gram nhập tự do so với TDEE
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (finalCalories > userTdee)
                              ? _warningAmber.withOpacity(0.14)
                              : _emeraldGreen.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Total: $finalCalories kcal / day',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              finalCalories <= userTdee
                                  ? '${userTdee - finalCalories} kcal below TDEE ($userTdee kcal) • Fat Loss / Recomp'
                                  : '+${finalCalories - userTdee} kcal above TDEE ($userTdee kcal) • Muscle Surplus',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: (finalCalories > userTdee)
                                    ? _warningAmber
                                    : _emeraldGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Save Button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _controller.saveMacroTargets(
                          targetCalories: finalCalories,
                          proteinGrams: pGrams,
                          carbsGrams: cGrams,
                          fatGrams: fGrams,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lime,
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(52),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Save Target Macros',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
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

  Widget _buildPresetChip({
    required String label,
    required String subtitle,
    required bool isDark,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.08),
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.greySubtext,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDirectGramInput({
    required String label,
    required int percent,
    required TextEditingController controller,
    required Color color,
    required bool isDark,
    required Color textColor,
    required VoidCallback onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.greySubtext,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => onChanged(),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 4),
              suffixText: 'g',
              suffixStyle: TextStyle(
                fontSize: 12,
                color: AppColors.greySubtext,
              ),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: textColor,
              ),
            ),
            Text(
              '$percent% (${grams}g)',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: color,
              ),
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
            value: percent.toDouble().clamp(10.0, 75.0),
            min: 10,
            max: 75,
            divisions: 65,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  void _showThemeSelectionSheet(
    BuildContext context,
    Color cardColor,
    Color textColor,
    Color borderColor,
  ) {
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        final borderColor =
            isDark ? AppColors.darkBorder : AppColors.lightBorder;

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
                  child: CircularProgressIndicator(
                    color: AppColors.lime,
                    strokeWidth: 2.5,
                  ),
                )
              : ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  children: [
                    // 1. User Profile Tile
                    GestureDetector(
                      onTap: () =>
                          _showEditNameDialog(context, cardColor, textColor),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(22),
                          border:
                              Border.all(color: borderColor.withOpacity(0.5)),
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
                            const Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: AppColors.greySubtext,
                            ),
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
                                onTap: () => _showEditMacrosSheet(
                                  context,
                                  isDark,
                                  cardColor,
                                  textColor,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.lime.withOpacity(0.15)
                                        : Colors.black.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    'Edit',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.lime
                                          : Colors.black,
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
                          Divider(
                            height: 20,
                            color: borderColor.withOpacity(0.6),
                          ),
                          _buildMacroRow(
                            'Carbs',
                            '${_controller.carbsPercent}% (${_controller.carbsGrams.round()}g)',
                            textColor,
                          ),
                          Divider(
                            height: 20,
                            color: borderColor.withOpacity(0.6),
                          ),
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
                                    onSetupCompleted: () =>
                                        Navigator.of(calcCtx).maybePop(),
                                  ),
                                ),
                              );
                            },
                          ),
                          Divider(
                            height: 1,
                            color: borderColor.withOpacity(0.6),
                          ),
                          ListTile(
                            leading: Icon(
                              isDark
                                  ? Icons.dark_mode_outlined
                                  : Icons.light_mode_outlined,
                              color: textColor,
                              size: 22,
                            ),
                            title: Text(
                              'Theme Appearance',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            subtitle: Text(
                              widget.themeController.themeModeTitle,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.greySubtext,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.themeController.themeModeTitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.lime
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: AppColors.greySubtext,
                                ),
                              ],
                            ),
                            onTap: () => _showThemeSelectionSheet(
                              context,
                              cardColor,
                              textColor,
                              borderColor,
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: borderColor.withOpacity(0.6),
                          ),
                          _buildSettingTile(
                            icon: Icons.straighten_outlined,
                            title: 'Units',
                            value: _controller.unitSystem,
                            textColor: textColor,
                            onTap: () {},
                          ),
                          Divider(
                            height: 1,
                            color: borderColor.withOpacity(0.6),
                          ),
                          _buildSettingTile(
                            icon: Icons.notifications_none_outlined,
                            title: 'Notifications',
                            value:
                                _controller.notificationsEnabled ? 'On' : 'Off',
                            textColor: textColor,
                            onTap: () => _controller.toggleNotifications(
                              !_controller.notificationsEnabled,
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: borderColor.withOpacity(0.6),
                          ),
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
                        leading: const Icon(
                          Icons.logout,
                          color: AppColors.fat,
                          size: 22,
                        ),
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
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.greySubtext,
                fontWeight: FontWeight.w500,
              ),
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
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
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
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
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
          const Icon(
            Icons.chevron_right,
            size: 18,
            color: AppColors.greySubtext,
          ),
        ],
      ),
    );
  }
}