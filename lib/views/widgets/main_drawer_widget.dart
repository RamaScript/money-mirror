import 'package:flutter/material.dart';
import 'package:money_mirror/core/utils/app_colors.dart';
import 'package:money_mirror/core/utils/image_paths.dart';
import 'package:money_mirror/main.dart';

class MainDrawerWidget extends StatelessWidget {
  const MainDrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDrawerHeader(theme),
            Divider(color: theme.dividerColor),
            _buildDrawerItem(title: "Settings", icon: Icons.settings, theme: theme),
            _buildThemeSection(context),
            _buildListItemsDivider(theme),
            _buildListItemsHeader(title: "Management", theme: theme),
            _buildDrawerItem(
              title: "Export Records ",
              icon: Icons.file_download,
              theme: theme,
            ),
            _buildDrawerItem(title: "Backup & Restore ", icon: Icons.backup, theme: theme),
            _buildDrawerItem(
              title: "Delete and Reset ",
              icon: Icons.delete_forever,
              theme: theme,
            ),
            _buildListItemsDivider(theme),
            _buildListItemsHeader(title: "Application", theme: theme),

            _buildDrawerItem(title: "Pro Version ", icon: Icons.star, theme: theme),
            _buildDrawerItem(title: "Like Money Mirror ", icon: Icons.favorite, theme: theme),
            _buildDrawerItem(title: "Help ", icon: Icons.help, theme: theme),
            _buildDrawerItem(title: "Feedback ", icon: Icons.feedback, theme: theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(ImagePaths.Logo, height: 64),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Money Mirror",
                style: TextStyle(
                  fontSize: 22,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              Text(
                "1.0.0",
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required String title,
    required IconData icon,
    required ThemeData theme,
  }) {
    return ListTile(
      leading: Icon(icon, color: theme.iconTheme.color),
      title: Text(
        title,
        style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      ),
    );
  }

  Widget _buildListItemsHeader({
    required String title,
    required ThemeData theme,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          color: theme.textTheme.bodySmall?.color,
        ),
      ),
    );
  }

  Widget _buildListItemsDivider(ThemeData theme) {
    return Divider(color: theme.dividerColor);
  }

  Widget _buildThemeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 12, top: 8, bottom: 8),
          child: Text("Theme ", style: TextStyle(fontSize: 12)),
        ),
        ListTile(
          leading: Icon(Icons.brightness_6),
          title: Text("Appearance "),
          subtitle: Text(themeManager.currentThemeName),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showThemeDialog(context),
        ),
      ],
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Choose Theme "),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: Text("Light "),
              value: ThemeMode.light,
              groupValue: themeManager.themeMode,
              activeColor: AppColors.primaryColor,
              onChanged: (value) {
                if (value != null) {
                  themeManager.setTheme(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text("Dark "),
              value: ThemeMode.dark,
              groupValue: themeManager.themeMode,
              activeColor: AppColors.primaryColor,
              onChanged: (value) {
                if (value != null) {
                  themeManager.setTheme(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text("System Default "),
              value: ThemeMode.system,
              groupValue: themeManager.themeMode,
              activeColor: AppColors.primaryColor,
              onChanged: (value) {
                if (value != null) {
                  themeManager.setTheme(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
