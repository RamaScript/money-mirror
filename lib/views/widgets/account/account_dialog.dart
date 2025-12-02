import 'package:flutter/material.dart';
import 'package:money_mirror/core/utils/app_colors.dart';
import 'package:money_mirror/core/utils/app_strings.dart';
import 'package:money_mirror/core/utils/snack_utils.dart';
import 'package:money_mirror/database/dao/account_dao.dart';
import 'package:money_mirror/models/account_model.dart';

import '../custom_text_field.dart';

class AccountDialog extends StatefulWidget {
  final VoidCallback onSaved;
  final AccountModel? account; // null = create mode, non-null = edit mode

  const AccountDialog({super.key, required this.onSaved, this.account});

  @override
  State<AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<AccountDialog> {
  late TextEditingController nameCtrl;
  late TextEditingController iconCtrl;
  late TextEditingController initialAmountCtrl;
  bool isSaving = false;

  bool get isEditMode => widget.account != null;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.account?.name ?? '');
    iconCtrl = TextEditingController(text: widget.account?.icon ?? '');
    initialAmountCtrl = TextEditingController(
      text: widget.account?.initialAmount.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    iconCtrl.dispose();
    initialAmountCtrl.dispose();
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
    // Prevent multiple saves
    if (isSaving) return;

    // Validate name
    if (nameCtrl.text.trim().isEmpty) {
      SnackUtils.warning(context, "Name is required");
      return;
    }

    // Validate icon
    if (iconCtrl.text.trim().isEmpty) {
      SnackUtils.warning(context, "Icon is required");
      return;
    }

    setState(() => isSaving = true);

    try {
      if (isEditMode) {
        // Update existing account
        final data = {
          'name': nameCtrl.text.trim(),
          'icon': iconCtrl.text.trim(),
          'initial_amount': double.tryParse(initialAmountCtrl.text.trim()) ?? 0,
        };
        await AccountDao.updateAccount(id: widget.account!.id!, data: data);

        if (mounted) {
          widget.onSaved();
          Navigator.pop(context);
          SnackUtils.success(context, "Account updated successfully");
        }
      } else {
        // Create new account
        final account = AccountModel(
          name: nameCtrl.text.trim(),
          icon: iconCtrl.text.trim(),
          initialAmount: double.tryParse(initialAmountCtrl.text.trim()) ?? 0,
        );
        await AccountDao.insertAccount(account.toMap());

        if (mounted) {
          widget.onSaved();
          Navigator.pop(context);
          SnackUtils.success(context, "Account created successfully");
        }
      }
    } catch (e) {
      setState(() => isSaving = false);
      if (mounted) {
        SnackUtils.error(
          context,
          "Error ${isEditMode ? 'updating' : 'saving'} account: $e",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? theme.cardColor : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Center(
                child: Text(
                  isEditMode ? AppStrings.EDIT_ACCOUNT : AppStrings.ADD_ACCOUNT,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
              ),
              Divider(color: AppColors.primaryColor),
              const SizedBox(height: 8),

              // NAME
              CustomTextField(
                controller: nameCtrl,
                label: AppStrings.NAME,
                showTitle: true,
                titleTextColor: theme.textTheme.bodyMedium?.color,
                backgroundColor: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.shade100,
                inputTextColor: theme.textTheme.bodyLarge?.color,
                borderColor: AppColors.primaryColor,
                focusedBorderColor: AppColors.secondryColor,
                placeHolder: "Enter Account Name",
              ),

              const SizedBox(height: 18),

              // INITIAL AMOUNT
              CustomTextField(
                controller: initialAmountCtrl,
                label: AppStrings.INITIAL_AMOUNT,
                showTitle: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                titleTextColor: theme.textTheme.bodyMedium?.color,
                backgroundColor: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.shade100,
                inputTextColor: theme.textTheme.bodyLarge?.color,
                borderColor: AppColors.primaryColor,
                focusedBorderColor: AppColors.secondryColor,
                placeHolder: "Enter Initial Amount",
              ),

              const SizedBox(height: 18),

              // ICON SECTION TITLE
              Text(
                AppStrings.ICON,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 8),

              // ICON INPUT FIELD
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryColor),
                ),
                child: TextField(
                  controller: iconCtrl,
                  style: TextStyle(
                    fontSize: 24,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  decoration: InputDecoration(
                    hintText: "Select an emoji",
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    // Limit to 1 emoji
                    if (_countEmojis(value) > 1) {
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
                      SnackUtils.warning(context, "Only 1 emoji allowed");
                    }
                  },
                ),
              ),

              const SizedBox(height: 12),

              // QUICK SELECT LABEL
              Text(
                "Quick Select:",
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 8),

              // HORIZONTAL EMOJI SCROLL
              SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (var e in [
                      "💰",
                      "🏦",
                      "💳",
                      "📦",
                      "👜",
                      "💵",
                      "💎",
                      "🏪",
                      "🏛️",
                      "💸",
                      "🪙",
                      "💴",
                      "💶",
                      "💷",
                      "🎯",
                      "📊",
                      "💼",
                      "🔐",
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => iconCtrl.text = e),
                          child: Container(
                            width: 56,
                            height: 56,
                            padding: const EdgeInsets.all(8),
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

              // BUTTONS
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isSaving ? null : () => Navigator.pop(context),
                    child: Text(
                      AppStrings.CANCEL,
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: isSaving ? null : _save,
                    child: isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            isEditMode ? "Update" : AppStrings.SAVE,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
}
