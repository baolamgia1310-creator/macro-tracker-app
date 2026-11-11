import 'package:flutter/material.dart';
import '../../controllers/food_search_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../models/food_item.dart';

class FoodSearchScreen extends StatefulWidget {
  final Function(FoodItem food, double amount)? onFoodAdded;
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
  late final FoodSearchController _controller;
  final TextEditingController _searchTextController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = FoodSearchController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (currentScroll >= maxScroll - 80) {
      _controller.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _controller.dispose();
    _searchTextController.dispose();
    super.dispose();
  }

  // Bảng chọn bữa ăn khi người dùng bấm Add Food trực tiếp từ tab Food dưới Bottom Bar
  void _showMealPickerSheet(BuildContext context, bool isDark) {
    final cardColor = Theme.of(context).colorScheme.surface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    const meals = [
      {'title': 'Breakfast', 'icon': Icons.free_breakfast_outlined},
      {'title': 'Lunch', 'icon': Icons.lunch_dining_outlined},
      {'title': 'Dinner', 'icon': Icons.dinner_dining_outlined},
      {'title': 'Snacks', 'icon': Icons.cookie_outlined},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Select Meal to Log',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...meals.map((m) {
                  final mealName = m['title'] as String;
                  final mealIcon = m['icon'] as IconData;
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(mealIcon, color: AppColors.lime, size: 20),
                    ),
                    title: Text(
                      mealName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textColor,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.add_circle_outline,
                      color: AppColors.lime,
                    ),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      await _controller.logFood(mealType: mealName);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateCustomFoodSheet(BuildContext context, bool isDark) {
    final nameCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    final proCtrl = TextEditingController();
    final carbCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
    String selectedType = 'serving';
    bool isSaving = false;

    final cardColor = Theme.of(context).colorScheme.surface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

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
                          'Create Custom Food',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.greySubtext),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildModalInputField(
                      controller: nameCtrl,
                      label: 'Food Name (e.g., Grilled Chicken Salad)',
                      icon: Icons.restaurant_menu,
                      isDark: isDark,
                      textColor: textColor,
                      isNumber: false,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Serving Unit Type',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => selectedType = 'serving'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selectedType == 'serving'
                                    ? AppColors.lime
                                    : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Per 1 Serving',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: selectedType == 'serving' ? Colors.black : textColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => selectedType = 'g'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selectedType == 'g'
                                    ? AppColors.lime
                                    : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Per 100 Grams',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: selectedType == 'g' ? Colors.black : textColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildModalInputField(
                      controller: calCtrl,
                      label: 'Calories (kcal)',
                      icon: Icons.local_fire_department_outlined,
                      isDark: isDark,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildModalInputField(
                            controller: proCtrl,
                            label: 'Protein (g)',
                            isDark: isDark,
                            textColor: textColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildModalInputField(
                            controller: carbCtrl,
                            label: 'Carbs (g)',
                            isDark: isDark,
                            textColor: textColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildModalInputField(
                            controller: fatCtrl,
                            label: 'Fat (g)',
                            isDark: isDark,
                            textColor: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              final cal = double.tryParse(calCtrl.text.trim()) ?? 0.0;
                              final pro = double.tryParse(proCtrl.text.trim()) ?? 0.0;
                              final carb = double.tryParse(carbCtrl.text.trim()) ?? 0.0;
                              final fat = double.tryParse(fatCtrl.text.trim()) ?? 0.0;

                              if (name.isEmpty || cal <= 0) return;

                              setModalState(() => isSaving = true);
                              await _controller.addCustomFood(
                                name: name,
                                servingType: selectedType,
                                calories: cal,
                                protein: pro,
                                carbs: carb,
                                fat: fat,
                              );

                              if (ctx.mounted) {
                                Navigator.of(ctx).pop();
                              }
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
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              'Save to My Foods',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
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

  Widget _buildModalInputField({
    required TextEditingController controller,
    required String label,
    required bool isDark,
    required Color textColor,
    IconData? icon,
    bool isNumber = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          icon: icon != null ? Icon(icon, size: 18, color: AppColors.lime) : null,
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12, color: AppColors.greySubtext),
          border: InputBorder.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.colorScheme.surface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: Container(
          height: 42,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(22),
          ),
          child: TextField(
            controller: _searchTextController,
            onChanged: (val) {
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(0);
              }
              _controller.setSearchQuery(val);
            },
            style: TextStyle(fontSize: 14, color: textColor),
            decoration: const InputDecoration(
              hintText: 'Search foods, chicken, rice...',
              hintStyle: TextStyle(color: AppColors.greySubtext, fontSize: 13),
              prefixIcon: Icon(Icons.search, size: 20, color: AppColors.greySubtext),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 9),
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Create Custom Food',
            icon: const Icon(Icons.add_circle_outline, color: AppColors.lime, size: 26),
            onPressed: () => _showCreateCustomFoodSheet(context, isDark),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final items = _controller.filteredFoods;
          final showBottomLoader = _controller.isLoadingMore || _controller.hasMore;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategoryBar(context: context, isDark: isDark),
              const SizedBox(height: 6),
              Expanded(
                child: _controller.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.lime,
                          strokeWidth: 2.5,
                        ),
                      )
                    : items.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'No matching foods found.',
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.5),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: () => _showCreateCustomFoodSheet(context, isDark),
                                  icon: const Icon(Icons.add, color: AppColors.lime),
                                  label: const Text(
                                    'Create Custom Food',
                                    style: TextStyle(
                                      color: AppColors.lime,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                            itemCount: items.length + (showBottomLoader ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == items.length) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: _controller.isLoadingMore
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              color: AppColors.lime,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                );
                              }

                              final food = items[index];
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
              onTap: () {
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(0);
                }
                _controller.setCategory(cat);
              },
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
    final unitSubtext = food.servingType == 'serving' ? '1 serving' : '100g';
    final isCustomFood = food.id.startsWith('custom_') || food.category == 'My Foods';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.lime : Colors.transparent,
            width: 1.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.lime.withOpacity(0.18)
                    : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
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
                        '${food.calories.round()} kcal',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.lime : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '/$unitSubtext',
                        style: const TextStyle(fontSize: 11, color: AppColors.greySubtext),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '• P ${food.protein}g  C ${food.carbs}g  F ${food.fat}g',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: AppColors.greySubtext),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isCustomFood)
              IconButton(
                tooltip: 'Delete custom food',
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                onPressed: () => _controller.removeCustomFood(food.id),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectAmountBottomSection({
    required BuildContext context,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
  }) {
    final foodName = _controller.selectedFood?.name ?? 'Select a food item';
    final caloValue = _controller.calculatedCalories.round();

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
              'Selected: $foodName • $caloValue kcal',
              style: const TextStyle(fontSize: 12, color: AppColors.greySubtext),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAmountCircleButton(
                  icon: Icons.remove,
                  onTap: _controller.decrementAmount,
                  isDark: isDark,
                ),
                const SizedBox(width: 32),
                Column(
                  children: [
                    Text(
                      _controller.amountLabel,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      _controller.unitLabel,
                      style: const TextStyle(fontSize: 12, color: AppColors.greySubtext),
                    ),
                  ],
                ),
                const SizedBox(width: 32),
                _buildAmountCircleButton(
                  icon: Icons.add,
                  onTap: _controller.incrementAmount,
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
                    _controller.selectedAmount,
                  );
                  Navigator.of(context).maybePop();
                } else if (widget.mealType != null) {
                  final success = await _controller.logFood(mealType: widget.mealType!);
                  if (success && mounted) {
                    Navigator.of(context).maybePop();
                  }
                } else {
                  // Mở từ tab Food dưới thanh Navigation Bar -> Hiện bảng chọn bữa ăn
                  _showMealPickerSheet(context, isDark);
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
              child: Text(
                widget.mealType != null ? 'Add to ${widget.mealType}' : 'Add Food',
                style: const TextStyle(
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

  Widget _buildAmountCircleButton({
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