import 'package:flutter/material.dart';
import 'package:money_mirror/core/utils/app_colors.dart';

class UiUtils {
  static Widget buildListHeader({required String title}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 16),
          child: Text(
            title,
            textAlign: TextAlign.start,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
              fontSize: 18,
            ),
          ),
        ),
        Divider(color: AppColors.primaryColor),
      ],
    );
  }
}
