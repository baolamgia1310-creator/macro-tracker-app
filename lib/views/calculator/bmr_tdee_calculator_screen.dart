import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  State<BmrTdeeCalculatorScreen> createState() => _BmrTdeeCalculatorScreenState();
}

class _BmrTdeeCalculatorScreenState extends State<BmrTdeeCalculatorScreen> {
  final CalculatorController _controller = CalculatorController();
  final TextEditingController _ageCtrl = TextEditingController(text: '25');
  final TextEditingController _weightCtrl = TextEditingController(text: '68');
  final TextEditingController _heightCtrl = TextEditingController(text: '172');

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
    _controller.calculate();
    if (_controller.errorMessage != null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final success = await _controller.saveProfileAndTargets(user.uid);
      if (success && mounted) {
        widget.onSetupCompleted();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).colorScheme.surface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nutrition Setup', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Text('Calibrate your baseline targets', style: TextStyle(fontSize: 12, color: AppColors.greySubtext)),
          ],
        ),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final bmiColor = _controller.bmiStatusColor;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_controller.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                      ),
                      child: Text(
                        _controller.errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
                    ),

                  // 1. Biological Sex
                  Text('Biological Sex', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildGenderCard('Male', Icons.male, Gender.male, cardColor, textColor),
                      const SizedBox(width: 12),
                      _buildGenderCard('Female', Icons.female, Gender.female, cardColor, textColor),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. Biometric Stats kèm Badge phân nhóm WHO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Biometric Stats', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: bmiColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: bmiColor.withOpacity(0.4)),
                        ),
                        child: Text(
                          'BMI: ${_controller.bmi.toStringAsFixed(1)} • ${_controller.bmiCategoryLabel}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: bmiColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildInputField('Age', 'years', _ageCtrl, Icons.cake_outlined, cardColor, textColor),
                  const SizedBox(height: 10),
                  _buildInputField('Weight', 'kg', _weightCtrl, Icons.scale_outlined, cardColor, textColor),
                  const SizedBox(height: 10),
                  _buildInputField('Height', 'cm', _heightCtrl, Icons.height_outlined, cardColor, textColor),
                  const SizedBox(height: 20),

                  // 3. Activity Level
                  Text('Activity Level', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<ActivityLevel>(
                        isExpanded: true,
                        value: _controller.activityLevel,
                        dropdownColor: cardColor,
                        items: const [
                          DropdownMenuItem(value: ActivityLevel.sedentary, child: Text('Sedentary (Little to no exercise)')),
                          DropdownMenuItem(value: ActivityLevel.lightlyActive, child: Text('Lightly Active (1-3 days/week)')),
                          DropdownMenuItem(value: ActivityLevel.moderatelyActive, child: Text('Moderately Active (3-5 days/week)')),
                          DropdownMenuItem(value: ActivityLevel.veryActive, child: Text('Very Active (6-7 days hard workouts)')),
                        ],
                        onChanged: (val) => val != null ? _controller.setActivityLevel(val) : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4. Primary Goal Header
                  Text('Primary Goal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
                  const SizedBox(height: 6),

                  // DÒNG GỢI Ý ĐỊNH HƯỚNG MỤC TIÊU DỰA TRÊN BMI WHO
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: bmiColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: bmiColor.withOpacity(0.25)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline, color: bmiColor, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _controller.goalRecommendation,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.darkText : AppColors.lightText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3 Thẻ lựa chọn mục tiêu
                  Row(
                    children: [
                      _buildGoalCard(GoalType.weightLoss, 'Weight\nLoss', 'Deficit', Icons.trending_down, cardColor, textColor, isDark),
                      const SizedBox(width: 10),
                      _buildGoalCard(GoalType.maintenance, 'Maintain\nWeight', 'Maintain', Icons.horizontal_rule, cardColor, textColor, isDark),
                      const SizedBox(width: 10),
                      _buildGoalCard(GoalType.muscleGain, 'Muscle\nGain', 'Surplus', Icons.trending_up, cardColor, textColor, isDark),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Submit Action Button
                  ElevatedButton(
                    onPressed: _controller.isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lime,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _controller.isLoading
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black))
                        : const Text('Calculate & Start Tracking', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGenderCard(String label, IconData icon, Gender gender, Color cardColor, Color textColor) {
    final isSelected = _controller.gender == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () => _controller.setGender(gender),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.lime : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? AppColors.lime : AppColors.greySubtext),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: textColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, String unit, TextEditingController ctrl, IconData icon, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.greySubtext),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
          const Spacer(),
          SizedBox(
            width: 70,
            child: TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.lime, fontSize: 16),
              decoration: InputDecoration(
                suffixText: ' $unit',
                suffixStyle: const TextStyle(fontSize: 12, color: AppColors.greySubtext),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(GoalType goal, String title, String subtitle, IconData icon, Color cardColor, Color textColor, bool isDark) {
    final isSelected = _controller.selectedGoal == goal;
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
              color: isSelected ? AppColors.lime : Colors.transparent,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.lime.withOpacity(0.12),
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
                      ? AppColors.lime.withOpacity(0.15)
                      : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: isSelected ? AppColors.lime : AppColors.greySubtext, size: 24),
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
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
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
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? (isDark ? AppColors.lime : Colors.black) : AppColors.greySubtext,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}