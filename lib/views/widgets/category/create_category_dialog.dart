import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:money_mirror/core/utils/app_strings.dart';
import 'package:money_mirror/core/utils/snack_utils.dart';
import 'package:money_mirror/database/dao/category_dao.dart';
import 'package:money_mirror/models/category_model.dart';

import '../custom_text_field.dart';

class CreateCategoryDialog extends StatefulWidget {
  final VoidCallback onAdded;

  const CreateCategoryDialog({super.key, required this.onAdded});

  @override
  State<CreateCategoryDialog> createState() => CreateCategoryDialogState();
}

class CreateCategoryDialogState extends State<CreateCategoryDialog> {
  String selectedType = AppStrings.EXPENSE;
  final nameCtrl = TextEditingController();
  final iconCtrl = TextEditingController();
  String? nameError;
  String? iconError;

  @override
  void dispose() {
    nameCtrl.dispose();
    iconCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Reset errors
    setState(() {
      nameError = null;
      iconError = null;
    });

    final name = nameCtrl.text.trim();
    final icon = iconCtrl.text.trim();

    // Validation
    if (name.isEmpty) {
      setState(() => nameError = "Category name cannot be empty");
      return;
    }

    if (icon.isEmpty) {
      setState(() => iconError = "Please select an emoji");
      SnackUtils.error(context, "Please select an emoji for the category");
      return;
    }

    // Check for duplicate names
    final allCategories = await CategoryDao.getCategories();
    final duplicateName = allCategories.any(
      (cat) =>
          cat['name'].toString().toLowerCase() == name.toLowerCase() &&
          cat['type'] == selectedType,
    );

    if (duplicateName) {
      setState(() => nameError = "A category with this name already exists");
      SnackUtils.error(context, "A category with this name already exists");
      return;
    }

    // Check for duplicate emojis
    final duplicateEmoji = allCategories.any(
      (cat) => cat['icon'] == icon && cat['type'] == selectedType,
    );

    if (duplicateEmoji) {
      setState(() => iconError = "This emoji is already used");
      SnackUtils.error(
        context,
        "This emoji is already used for another category",
      );
      return;
    }

    try {
      final category = CategoryModel(
        name: name,
        icon: icon,
        type: selectedType,
      );

      await CategoryDao.insertCategory(category.toMap());
      widget.onAdded();
      if (mounted) {
        Navigator.pop(context);
        SnackUtils.success(context, "Category created successfully");
      }
    } catch (e) {
      if (mounted) {
        SnackUtils.error(context, "Failed to create category: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? theme.cardColor : Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Text(
                  "Add new category",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: theme.colorScheme.primary),
              const SizedBox(height: 20),

              // Category Type
              Text(
                "Category Type",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 10),
              buildIconToggle(theme),

              const SizedBox(height: 20),

              // Category Details
              Text(
                "Category Details",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 10),

              // Name Field
              CustomTextField(
                controller: nameCtrl,
                label: "Name",
                showTitle: false,
                titleTextColor: theme.textTheme.bodyMedium?.color,
                backgroundColor: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.shade100,
                inputTextColor: theme.textTheme.bodyLarge?.color,
                borderColor: nameError != null
                    ? Colors.red
                    : theme.colorScheme.primary,
                focusedBorderColor: theme.colorScheme.secondary,
                placeHolder: "Enter Category Name",
              ),
              if (nameError != null) ...[
                const SizedBox(height: 4),
                Text(
                  nameError!,
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ],

              const SizedBox(height: 16),

              // Icon Field
              CustomTextField(
                controller: iconCtrl,
                label: "Icon",
                onInvalidInput: () {
                  setState(() => iconError = "Only 1 emoji is allowed");
                  SnackUtils.info(context, "Only 1 emoji is allowed");
                },
                showTitle: false,
                titleTextColor: theme.textTheme.bodyMedium?.color,
                backgroundColor: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.shade100,
                inputTextColor: theme.textTheme.bodyLarge?.color,
                borderColor: iconError != null
                    ? Colors.red
                    : theme.colorScheme.primary,
                focusedBorderColor: theme.colorScheme.secondary,
                placeHolder: "Enter Icon (Emoji only)",
                maxLength: 1,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(
                      r'[\u{1F300}-\u{1F6FF}\u{1F900}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
                      unicode: true,
                    ),
                  ),
                ],
              ),
              if (iconError != null) ...[
                const SizedBox(height: 4),
                Text(
                  iconError!,
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ],

              const SizedBox(height: 12),

              // Quick Emoji Picker
              Text(
                "Quick Select:",
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var e in [
                    "🍔",
                    "🛒",
                    "💵",
                    "🎉",
                    "🚗",
                    "📚",
                    "🏠",
                    "💊",
                  ])
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          iconCtrl.text = e;
                          iconError = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: theme.colorScheme.primary,
                      elevation: 4,
                    ),
                    onPressed: _save,
                    child: const Text(
                      "Save",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildIconToggle(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _iconPill(theme, "💰 Income", AppStrings.INCOME),
        const SizedBox(width: 16),
        _iconPill(theme, "💸 Expense", AppStrings.EXPENSE),
      ],
    );
  }

  Widget _iconPill(ThemeData theme, String label, String value) {
    final isSelected = selectedType == value;

    return InkWell(
      onTap: () => setState(() => selectedType = value),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.primary,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.secondary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }
}
