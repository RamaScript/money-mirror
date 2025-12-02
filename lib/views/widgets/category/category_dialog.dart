import 'package:flutter/material.dart';
import 'package:money_mirror/core/utils/app_strings.dart';
import 'package:money_mirror/core/utils/snack_utils.dart';
import 'package:money_mirror/database/dao/category_dao.dart';
import 'package:money_mirror/models/category_model.dart';

import '../custom_text_field.dart';

class CategoryDialog extends StatefulWidget {
  final VoidCallback onSaved;
  final CategoryModel? category; // null = create mode, non-null = edit mode

  const CategoryDialog({super.key, required this.onSaved, this.category});

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  late TextEditingController nameCtrl;
  late TextEditingController iconCtrl;
  late String selectedType;
  String? nameError;
  String? iconError;

  bool get isEditMode => widget.category != null;

  @override
  void initState() {
    super.initState();

    // Initialize with existing data if edit mode, otherwise empty
    nameCtrl = TextEditingController(text: widget.category?.name ?? '');
    iconCtrl = TextEditingController(text: widget.category?.icon ?? '');
    selectedType = widget.category?.type ?? AppStrings.EXPENSE;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    iconCtrl.dispose();
    super.dispose();
  }

  // Helper function to count emojis properly
  int _countEmojis(String text) {
    if (text.isEmpty) return 0;

    final runes = text.runes.toList();
    int count = 0;
    int i = 0;

    while (i < runes.length) {
      count++;
      i++;

      // Skip zero-width joiners and variation selectors
      while (i < runes.length &&
          (runes[i] == 0x200D || // Zero-width joiner
              (runes[i] >= 0xFE00 &&
                  runes[i] <= 0xFE0F) || // Variation selectors
              (runes[i] >= 0x1F3FB && runes[i] <= 0x1F3FF))) {
        // Skin tones
        i++;
      }
    }

    return count;
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

    // Check for duplicates (skip if editing the same category)
    final allCategories = await CategoryDao.getCategories();

    // Check for duplicate names
    final duplicateName = allCategories.any(
      (cat) =>
          cat['name'].toString().toLowerCase() == name.toLowerCase() &&
          cat['type'] == selectedType &&
          cat['id'] !=
              widget.category?.id, // Skip current category in edit mode
    );

    if (duplicateName) {
      setState(() => nameError = "A category with this name already exists");
      SnackUtils.error(context, "A category with this name already exists");
      return;
    }

    // Check for duplicate emojis
    final duplicateEmoji = allCategories.any(
      (cat) =>
          cat['icon'] == icon &&
          cat['type'] == selectedType &&
          cat['id'] !=
              widget.category?.id, // Skip current category in edit mode
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
      if (isEditMode) {
        // Update existing category
        await CategoryDao.updateCategory(
          id: widget.category!.id!,
          data: {'name': name, 'icon': icon, 'type': selectedType},
        );
        if (mounted) {
          widget.onSaved();
          Navigator.pop(context);
          SnackUtils.success(context, "Category updated successfully");
        }
      } else {
        // Create new category
        final category = CategoryModel(
          name: name,
          icon: icon,
          type: selectedType,
        );
        await CategoryDao.insertCategory(category.toMap());
        if (mounted) {
          widget.onSaved();
          Navigator.pop(context);
          SnackUtils.success(context, "Category created successfully");
        }
      }
    } catch (e) {
      if (mounted) {
        SnackUtils.error(
          context,
          "Failed to ${isEditMode ? 'update' : 'create'} category: $e",
        );
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
                  isEditMode ? "Edit category" : "Add new category",
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
              if (!isEditMode) ...[
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
                _buildIconToggle(theme),
              ],
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
              TextField(
                controller: iconCtrl,
                style: TextStyle(
                  fontSize: 24,
                  color: theme.textTheme.bodyLarge?.color,
                ),
                decoration: InputDecoration(
                  hintText: "Enter Icon (Emoji only)",
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: iconError != null
                          ? Colors.red
                          : theme.colorScheme.primary,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: iconError != null
                          ? Colors.red
                          : theme.colorScheme.primary,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.secondary,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) {
                  // Limit to 1 emoji
                  if (_countEmojis(value) > 1) {
                    // Get first emoji only
                    final runes = value.runes.toList();
                    int endIndex = 1;

                    // Include modifiers if present
                    while (endIndex < runes.length &&
                        (runes[endIndex] == 0x200D ||
                            (runes[endIndex] >= 0xFE00 &&
                                runes[endIndex] <= 0xFE0F) ||
                            (runes[endIndex] >= 0x1F3FB &&
                                runes[endIndex] <= 0x1F3FF))) {
                      endIndex++;
                    }

                    final firstEmoji = String.fromCharCodes(
                      runes.sublist(0, endIndex),
                    );
                    iconCtrl.value = TextEditingValue(
                      text: firstEmoji,
                      selection: TextSelection.collapsed(
                        offset: firstEmoji.length,
                      ),
                    );

                    setState(() => iconError = "Only 1 emoji is allowed");
                    SnackUtils.info(context, "Only 1 emoji is allowed");
                  } else {
                    setState(() => iconError = null);
                  }
                },
              ),
              if (iconError != null) ...[
                const SizedBox(height: 4),
                Text(
                  iconError!,
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ],

              const SizedBox(height: 12),

              // Quick Emoji Picker with Horizontal Scroll
              Text(
                "Quick Select:",
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
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
                      "✈️",
                      "🎮",
                      "☕",
                      "👕",
                      "🍕",
                      "🎬",
                      "💻",
                      "📱",
                      "⚡",
                      "🎵",
                      "🏋️",
                      "🍷",
                      "🎨",
                      "📷",
                      "🚴",
                      "🏊",
                      "⚽",
                      "🎯",
                      "💡",
                      "🔧",
                      "🌟",
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              iconCtrl.text = e;
                              iconError = null;
                            });
                          },
                          child: Container(
                            width: 56,
                            height: 56,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.3,
                                ),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                e,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
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
                    child: Text(
                      isEditMode ? "Update" : "Save",
                      style: const TextStyle(
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

  Widget _buildIconToggle(ThemeData theme) {
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

    return Expanded(
      child: InkWell(
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
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : theme.textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ),
    );
  }
}
