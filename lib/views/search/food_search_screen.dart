import 'package:flutter/material.dart';
import '../../controllers/food_search_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../models/food_item.dart';

class FoodSearchScreen extends StatefulWidget {
  final Function(FoodItem food, double grams)? onFoodAdded;
  final String? mealType;

  const FoodSearchScreen({
    super.key,
    this.onFoodAdded,
    this.mealType,
  });

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final FoodSearchController _controller = FoodSearchController();
  final TextEditingController _searchTextController = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _searchTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.colorScheme.surface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Container(
          height: 42,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(22),
          ),
          child: TextField(
            controller: _searchTextController,
            onChanged: _controller.setSearchQuery,
            style: TextStyle(fontSize: 14, color: textColor),
            decoration: const InputDecoration(
              hintText: 'Search foods...',
              hintStyle: TextStyle(color: AppColors.greySubtext, fontSize: 13),
              prefixIcon: Icon(Icons.search, size: 20, color: AppColors.greySubtext),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 9),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Thanh Categories phẳng chuẩn thiết kế gốc
              _buildCategoryBar(context: context, isDark: isDark),
              const SizedBox(height: 6),

              // 2. Danh sách thực phẩm cuộn mượt 120Hz
              // Thay thế đoạn Expanded danh sách trong build() của lib/views/search/food_search_screen.dart:
              Expanded(
                child: _controller.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.lime,
                          strokeWidth: 2.5,
                        ),
                      )
                    : _controller.filteredFoods.isEmpty
                        ? Center(
                            child: Text(
                              'No foods found. Try "egg", "beef", "rice"...',
                              style: TextStyle(
                                color: textColor.withOpacity(0.5),
                                fontSize: 14,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                            itemCount: _controller.filteredFoods.length,
                            itemBuilder: (context, index) {
                              final food = _controller.filteredFoods[index];
                              final isCurrentFood = _controller.selectedFood?.id == food.id;

                              return _buildFoodItemCard(
                                context: context,
                                food: food,
                                isSelected: isCurrentFood,
                                onTap: () => _controller.selectFood(food),
                              );
                            },
                          ),
              ),
              // 3. Khối định lượng Select Amount chân trang (Cô lập render 120Hz bằng RepaintBoundary)
              RepaintBoundary(
                child: _buildSelectAmountBottomSection(
                  context: context,
                  isDark: isDark,
                  cardColor: cardColor,
                  textColor: textColor,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryBar({
    required BuildContext context,
    required bool isDark,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: _controller.categories.map((cat) {
          final isSelected = _controller.selectedCategory == cat;

          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: GestureDetector(
              onTap: () => _controller.setCategory(cat),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.lime
                      : (isDark ? AppColors.darkCard : Colors.white),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.lime
                        : (isDark
                            ? Colors.white.withOpacity(0.15)
                            : Colors.black.withOpacity(0.12)),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected
                        ? Colors.black
                        : (isDark ? Colors.grey[400] : Colors.grey[700]),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFoodItemCard({
    required BuildContext context,
    required FoodItem food,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.lime : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.restaurant_outlined,
              size: 22,
              color: AppColors.lime,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '${food.caloriesPer100g.toInt()} kcal',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.lime : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• P ${food.proteinPer100g}g  C ${food.carbsPer100g}g  F ${food.fatPer100g}g',
                      style: const TextStyle(fontSize: 11, color: AppColors.greySubtext),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.lime : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.lime : AppColors.greySubtext.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.add,
                size: 18,
                color: isSelected ? Colors.black : AppColors.greySubtext,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectAmountBottomSection({
    required BuildContext context,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
  }) {
    final foodName = _controller.selectedFood?.name ?? 'Select a food';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Amount',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Food: $foodName',
              style: const TextStyle(fontSize: 12, color: AppColors.greySubtext),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildGramCircleButton(
                  icon: Icons.remove,
                  onTap: _controller.decrementGrams,
                  isDark: isDark,
                ),
                const SizedBox(width: 32),
                Column(
                  children: [
                    Text(
                      '${_controller.selectedGrams.toInt()}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Text(
                      'grams',
                      style: TextStyle(fontSize: 12, color: AppColors.greySubtext),
                    ),
                  ],
                ),
                const SizedBox(width: 32),
                _buildGramCircleButton(
                  icon: Icons.add,
                  onTap: _controller.incrementGrams,
                  isDark: isDark,
                  isPrimary: true,
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_controller.selectedFood == null) return;

                if (widget.onFoodAdded != null) {
                  widget.onFoodAdded!(
                    _controller.selectedFood!,
                    _controller.selectedGrams,
                  );
                  Navigator.of(context).maybePop();
                } else if (widget.mealType != null) {
                  final success = await _controller.logFood(mealType: widget.mealType!);
                  if (success && mounted) {
                    Navigator.of(context).maybePop();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lime,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(54),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Add Food',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGramCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.lime
              : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isPrimary ? Colors.black : (isDark ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}