import 'package:flutter/material.dart';
import 'package:money_mirror/core/utils/app_colors.dart';
import 'package:money_mirror/core/utils/pref_currency_symbol.dart';

class TransactionCard extends StatefulWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback? onTap;

  const TransactionCard({super.key, required this.transaction, this.onTap});

  @override
  State<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<TransactionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isIncome = widget.transaction['type'] == 'INCOME';
    final isTransfer = widget.transaction['type'] == 'TRANSFER';
    final amount = (widget.transaction['amount'] as num).toDouble();

    // Determine color based on transaction type
    Color typeColor;
    if (isTransfer) {
      typeColor = AppColors.transferColor;
    } else if (isIncome) {
      typeColor = AppColors.incomeColor;
    } else {
      typeColor = AppColors.expenseColor;
    }

    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) {
        _animationController.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _animationController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDark ? theme.cardColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    // Icon - Category for Income/Expense, Transfer icon for Transfer
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          isTransfer
                              ? '🔄' // Transfer icon
                              : (widget.transaction['category_icon'] ?? '💰'),
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title - Category name for Income/Expense, "Transfer" for Transfer
                          Text(
                            isTransfer
                                ? 'Transfer'
                                : (widget.transaction['category_name'] ??
                                      'Unknown'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: theme.textTheme.titleMedium?.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          // Subtitle - Different for transfers
                          isTransfer
                              ? _buildTransferSubtitle(theme)
                              : _buildRegularSubtitle(theme),
                        ],
                      ),
                    ),

                    // Amount
                    Text(
                      '${isIncome
                          ? '+'
                          : isTransfer
                          ? ''
                          : '-'}${PrefCurrencySymbol.rupee}${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: typeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build subtitle for transfers: "Bank → Cash"
  Widget _buildTransferSubtitle(ThemeData theme) {
    final fromAccountIcon = widget.transaction['account_icon'] ?? '🏦';
    final fromAccountName = widget.transaction['account_name'] ?? 'Unknown';
    final toAccountIcon = widget.transaction['to_account_icon'] ?? '🏦';
    final toAccountName = widget.transaction['to_account_name'] ?? 'Unknown';

    return Row(
      children: [
        // From account
        Text(fromAccountIcon, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 2),
        Text(
          fromAccountName,
          style: TextStyle(
            fontSize: 12,
            color: theme.textTheme.bodySmall?.color,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        // Arrow
        Icon(
          Icons.arrow_forward,
          size: 12,
          color: theme.textTheme.bodySmall?.color,
        ),
        const SizedBox(width: 4),
        // To account
        Text(toAccountIcon, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            toAccountName,
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodySmall?.color,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Build subtitle for regular transactions: "🏦 Bank"
  Widget _buildRegularSubtitle(ThemeData theme) {
    return Row(
      children: [
        Text(
          widget.transaction['account_icon'] ?? '🏦',
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            widget.transaction['account_name'] ?? 'Unknown',
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodySmall?.color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
