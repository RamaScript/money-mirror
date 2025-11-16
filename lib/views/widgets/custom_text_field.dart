import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String placeHolder;
  final bool obscureText;
  final int? maxLength;

  final TextInputType keyboardType;
  final Color? hintTextColor;
  final Color? titleTextColor;
  final Color? inputTextColor;
  final VoidCallback? onInvalidInput;

  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? leadingIconColor;
  final Color? trailingIconColor;
  final Color? backgroundColor;
  final Color? cursorColor;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingIconTap;
  final bool showTitle;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.placeHolder,
    this.onInvalidInput,
    this.inputFormatters,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.hintTextColor,
    this.titleTextColor,
    this.inputTextColor,
    this.borderColor,
    this.focusedBorderColor,
    this.leadingIconColor,
    this.trailingIconColor,
    this.backgroundColor,
    this.cursorColor,
    this.maxLength,
    this.leadingIcon,
    this.trailingIcon,
    this.onTrailingIconTap,
    this.showTitle = true,
  });

  @override
  State<StatefulWidget> createState() {
    return _CustomTextFieldState();
  }
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final defaultBorderColor = widget.borderColor ?? Colors.grey;
    final defaultFocusedBorderColor = widget.focusedBorderColor ?? Colors.blue;
    final defaultHintTextColor = widget.hintTextColor ?? Colors.grey.shade400;
    final defaultTitleTextColor = widget.titleTextColor ?? Colors.grey[800];
    final defaultInputTextColor = widget.inputTextColor ?? Colors.black87;
    final defaultCursorColor = widget.cursorColor ?? Colors.grey.shade700;
    final defaultLeadingIconColor = widget.leadingIconColor ?? Colors.grey;
    final defaultTrailingIconColor =
        widget.trailingIconColor ?? Colors.grey.shade400;
    final defaultBackgroundColor = widget.backgroundColor ?? Colors.white;

    final enabledBorder = OutlineInputBorder(
      borderSide: BorderSide(color: defaultBorderColor, width: 1),
      borderRadius: BorderRadius.circular(12),
    );

    final focusedBorder = OutlineInputBorder(
      borderSide: BorderSide(color: defaultFocusedBorderColor, width: 1.5),
      borderRadius: BorderRadius.circular(12),
    );

    Widget? prefixIcon;
    if (widget.leadingIcon != null) {
      prefixIcon = Icon(widget.leadingIcon, color: defaultLeadingIconColor);
    }

    Widget? suffixIcon;
    if (widget.obscureText) {
      suffixIcon = IconButton(
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: defaultTrailingIconColor,
        ),
      );
    } else if (widget.trailingIcon != null) {
      suffixIcon = IconButton(
        onPressed: widget.onTrailingIconTap,
        icon: Icon(widget.trailingIcon, color: defaultTrailingIconColor),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle)
          Text(widget.label, style: TextStyle(color: defaultTitleTextColor)),
        SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          onChanged: (value) {
            if (widget.maxLength == 1 &&
                widget.inputFormatters != null &&
                !_isEmoji(value)) {
              widget.controller.clear(); // ❌ wrong input → clear
              widget.onInvalidInput?.call(); // 🔔 notify parent
            }
          },
          maxLength: widget.maxLength,
          cursorColor: defaultCursorColor,
          inputFormatters: widget.inputFormatters,
          style: TextStyle(color: defaultInputTextColor),
          decoration: InputDecoration(
            filled: true,
            fillColor: defaultBackgroundColor,
            border: enabledBorder,
            enabledBorder: enabledBorder,
            focusedBorder: focusedBorder,
            hintText: widget.placeHolder,
            hintStyle: TextStyle(color: defaultHintTextColor),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  bool _isEmoji(String input) {
    final emojiRegex = RegExp(
      r'^[\u{1F300}-\u{1F6FF}\u{1F900}-\u{1F9FF}\u{2600}-\u{26FF}]$',
      unicode: true,
    );
    return emojiRegex.hasMatch(input);
  }
}
