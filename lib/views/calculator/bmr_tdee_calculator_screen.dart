import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../controllers/calculator_controller.dart';
import '../../models/user_profile.dart';

class BmrTdeeCalculatorScreen extends StatefulWidget {
  final VoidCallback onSetupCompleted;

  const BmrTdeeCalculatorScreen({
    super.key,
    required this.onSetupCompleted,
  });

  @override
  State<BmrTdeeCalculatorScreen> createState() =>
      _BmrTdeeCalculatorScreenState();
}

class _BmrTdeeCalculatorScreenState extends State<BmrTdeeCalculatorScreen> {
  final CalculatorController _controller = CalculatorController();
  final TextEditingController _ageCtrl = TextEditingController(text: '25');
  final TextEditingController _weightCtrl = TextEditingController(text: '68');
  final TextEditingController _heightCtrl = TextEditingController(text: '172');

  static const Color _lightModeLimeText = Color(0xFF365314);
  static const Color _lightModeLimeBorder = Color(0xFF84CC16);

  @override
  void initState() {
    super.initState();
    _weightCtrl.addListener(() {
      final w = double.tryParse(_weightCtrl.text);
      if (w != null) _controller.setWeight(w);
    });
    _heightCtrl.addListener(() {
      final h = double.tryParse(_heightCtrl.text);
      if (h != null) _controller.setHeight(h);
    });
    _ageCtrl.addListener(() {
      final a = int.tryParse(_ageCtrl.text);
      if (a != null) _controller.setAge(a);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final success = await _controller.saveProfileAndTargets();
    if (success && mounted) {
      widget.onSetupCompleted();
    }
  }

  Color _resolveReadableBmiColor(Color rawColor, bool isDark) {
    if (!isDark && rawColor == AppColors.lime) {
      return _lightModeLimeText;
    }
    return rawColor;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).colorScheme.surface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nutrition Setup',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: textColor,
              ),
            ),
            const Text(
              'Calibrate your baseline targets',
              style: TextStyle(fontSize: 12, color: AppColors.greySubtext),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final rawBmiColor = _controller.bmiStatusColor;
            final readableBmiColor =
                _resolveReadableBmiColor(rawBmiColor, isDark);
            final badgeBgColor = (!isDark && rawBmiColor == AppColors.lime)
                ? AppColors.lime.withOpacity(0.32)
                : rawBmiColor.withOpacity(0.12);
            final badgeBorderColor = (!isDark && rawBmiColor == AppColors.lime)
                ? _lightModeLimeBorder
                : rawBmiColor.withOpacity(0.4);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_controller.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 14,
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.redAccent.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _controller.errorMessage!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                        ),
                      ),
                    ),

                  // 1. Biological Sex
                  Text(
                    'Biological Sex',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildGenderCard(
                        'Male',
                        Icons.male,
                        Gender.male,
                        cardColor,
                        textColor,
                        isDark,
                      ),
                      const SizedBox(width: 12),
                      _buildGenderCard(
                        'Female',
                        Icons.female,
                        Gender.female,
                        cardColor,
                        textColor,
                        isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. Biometric Stats kèm Badge WHO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Biometric Stats',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBgColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: badgeBorderColor),
                        ),
                        child: Text(
                          'BMI: ${_controller.bmi.toStringAsFixed(1)} • ${_controller.bmiCategoryLabel}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: readableBmiColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildInputField(
                    'Age',
                    'years',
                    _ageCtrl,
                    Icons.cake_outlined,
                    cardColor,
                    textColor,
                    isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildInputField(
                    'Weight',
                    'kg',
                    _weightCtrl,
                    Icons.scale_outlined,
                    cardColor,
                    textColor,
                    isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildInputField(
                    'Height',
                    'cm',
                    _heightCtrl,
                    Icons.height_outlined,
                    cardColor,
                    textColor,
                    isDark,
                  ),
                  const SizedBox(height: 20),

                  // 3. Activity Level
                  Text(
                    'Activity Level',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.06),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<ActivityLevel>(
                        isExpanded: true,
                        value: _controller.activityLevel,
                        dropdownColor: cardColor,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: ActivityLevel.sedentary,
                            child: Text('Sedentary (Office job, little exercise)'),
                          ),
                          DropdownMenuItem(
                            value: ActivityLevel.lightlyActive,
                            child: Text('Lightly Active (1-3 workouts/week)'),
                          ),
                          DropdownMenuItem(
                            value: ActivityLevel.moderatelyActive,
                            child: Text('Moderately Active (3-5 workouts/week)'),
                          ),
                          DropdownMenuItem(
                            value: ActivityLevel.veryActive,
                            child: Text('Very Active (6-7 intense workouts/week)'),
                          ),
                        ],
                        onChanged: (val) =>
                            val != null ? _controller.setActivityLevel(val) : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4. Primary Goal kèm chỉ dẫn lâm sàng
                  Text(
                    'Primary Goal',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: badgeBorderColor),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: readableBmiColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _controller.goalRecommendation,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Row(
                    children: [
                      _buildGoalCard(
                        GoalType.weightLoss,
                        'Weight\nLoss',
                        '-20% Deficit',
                        Icons.trending_down,
                        cardColor,
                        textColor,
                        isDark,
                      ),
                      const SizedBox(width: 10),
                      _buildGoalCard(
                        GoalType.maintenance,
                        'Maintain\nWeight',
                        'Recomp',
                        Icons.horizontal_rule,
                        cardColor,
                        textColor,
                        isDark,
                      ),
                      const SizedBox(width: 10),
                      _buildGoalCard(
                        GoalType.muscleGain,
                        'Muscle\nGain',
                        'Lean Bulk',
                        Icons.trending_up,
                        cardColor,
                        textColor,
                        isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 5. Thẻ Xem trước Kế hoạch Dinh dưỡng (Live Preview Card)
                  _buildLivePlanPreviewCard(cardColor, textColor, isDark),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _controller.isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lime,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _controller.isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Calculate & Start Tracking',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLivePlanPreviewCard(
    Color cardColor,
    Color textColor,
    bool isDark,
  ) {
    final accentColor = isDark ? AppColors.lime : _lightModeLimeText;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estimated Daily Target',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              Text(
                '${_controller.previewTargetCalories} kcal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'BMR: ${_controller.previewBmr} kcal  •  Maintenance (TDEE): ${_controller.previewTdee} kcal',
            style: const TextStyle(fontSize: 11.5, color: AppColors.greySubtext),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildMacroPreviewPill(
                'Protein',
                '${_controller.previewProteinGrams}g',
                AppColors.protein,
                textColor,
                isDark,
              ),
              const SizedBox(width: 8),
              _buildMacroPreviewPill(
                'Carbs',
                '${_controller.previewCarbsGrams}g',
                AppColors.carbs,
                textColor,
                isDark,
              ),
              const SizedBox(width: 8),
              _buildMacroPreviewPill(
                'Fat',
                '${_controller.previewFatGrams}g',
                AppColors.fat,
                textColor,
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroPreviewPill(
    String label,
    String value,
    Color color,
    Color textColor,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.14 : 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.greySubtext,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderCard(
    String label,
    IconData icon,
    Gender gender,
    Color cardColor,
    Color textColor,
    bool isDark,
  ) {
    final isSelected = _controller.gender == gender;
    final activeBorderColor = isDark ? AppColors.lime : _lightModeLimeBorder;

    return Expanded(
      child: GestureDetector(
        onTap: () => _controller.setGender(gender),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? activeBorderColor
                  : (isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.06)),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.lime
                      : (isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.04)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.black : AppColors.greySubtext,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    String unit,
    TextEditingController ctrl,
    IconData icon,
    Color cardColor,
    Color textColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.greySubtext),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
          ),
          const Spacer(),
          SizedBox(
            width: 80,
            child: TextField(
              controller: ctrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isDark ? AppColors.lime : textColor,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                suffixText: ' $unit',
                suffixStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.greySubtext,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(
    GoalType goal,
    String title,
    String subtitle,
    IconData icon,
    Color cardColor,
    Color textColor,
    bool isDark,
  ) {
    final isSelected = _controller.selectedGoal == goal;
    final activeBorderColor = isDark ? AppColors.lime : _lightModeLimeBorder;

    return Expanded(
      child: GestureDetector(
        onTap: () => _controller.setGoal(goal),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 138,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? activeBorderColor
                  : (isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.06)),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.lime.withOpacity(isDark ? 0.12 : 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.lime
                      : (isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.04)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.black : AppColors.greySubtext,
                  size: 22,
                ),
              ),
              SizedBox(
                height: 32,
                child: Center(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: textColor,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? AppColors.lime : _lightModeLimeText)
                      : AppColors.greySubtext,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}