import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:money_mirror/app_routes.dart';
import 'package:money_mirror/core/utils/app_colors.dart';
import 'package:money_mirror/core/utils/image_paths.dart';
import 'package:money_mirror/database/db_handler.dart';
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
            // Divider(color: theme.dividerColor),
            // _buildDrawerItem(
            //   title: "Settings",
            //   icon: Icons.settings,
            //   theme: theme,
            //   onTap: () => {
            //     Navigator.pushNamed(context, AppRoutes.settingsScreen),
            //   },
            // ),
            _buildThemeSection(context, theme),
            _buildListItemsDivider(theme),
            _buildListItemsHeader(
              title: "Management",
              theme: theme,
              context: context,
            ),
            _buildDrawerItem(
              context: context,

              title: "Import Records ",
              icon: ImagePaths.icImport,
              theme: theme,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.importCsvScreen),
            ),
            // _buildDrawerItem(
            //   title: "Export Records ",
            //   icon: Icons.file_download,
            //   theme: theme,
            //   onTap: () => {},
            // ),
            // _buildDrawerItem(
            //   title: "Backup & Restore ",
            //   icon: Icons.backup,
            //   theme: theme,
            //   onTap: () => {},
            // ),
            _buildDrawerItem(
              context: context,

              title: "Delete and Reset ",
              icon: ImagePaths.icBin,
              theme: theme,
              onTap: () => _showDeleteConfirmationDialog(context),
            ),
            _buildListItemsDivider(theme),
            _buildListItemsHeader(
              title: "Application",
              theme: theme,
              context: context,
            ),

            // _buildDrawerItem(
            //   title: "Pro Version ",
            //   icon: Icons.star,
            //   theme: theme,
            //   onTap: () => {},
            // ),
            // _buildDrawerItem(
            //   title: "Like Money Mirror ",
            //   icon: Icons.favorite,
            //   theme: theme,
            //   onTap: () => {},
            // ),
            _buildDrawerItem(
              context: context,

              title: "Demo ",
              icon: ImagePaths.icDemo,
              theme: theme,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.onboarding);
              },
            ),
            // _buildDrawerItem(
            //   title: "Help ",
            //   icon: Icons.help,
            //   theme: theme,
            //   onTap: () => {},
            // ),
            // _buildDrawerItem(
            //   title: "Feedback ",
            //   icon: Icons.feedback,
            //   theme: theme,
            //   onTap: () => {},
            // ),
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
                  fontFamily: "Pacifico",
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              Text(
                "1.0.0",
                style: TextStyle(color: theme.textTheme.bodySmall?.color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required String title,
    required String icon,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: ListTile(
        leading: SvgPicture.asset(
          icon,
          color: Theme.of(context).colorScheme.primary,
          height: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: theme.textTheme.bodySmall?.color,
            fontSize: 14,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }

  Widget _buildListItemsHeader({
    required BuildContext context,
    required String title,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 6, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildListItemsDivider(ThemeData theme) {
    return Divider(color: theme.dividerColor);
  }

  Widget _buildThemeSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildListItemsDivider(theme),

        _buildListItemsHeader(context: context, title: "Theme", theme: theme),
        ListTile(
          leading: SvgPicture.asset(
            ImagePaths.icApperance,
            color: Theme.of(context).colorScheme.primary,
            height: 32,
          ),
          title: Text("Appearance "),
          subtitle: Text(
            themeManager.currentThemeName,

            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          onTap: () => _showThemeDialog(context),
        ),
      ],
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text(
            'Are you sure you want to delete all data? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();

                final dbHandler = DBHandler();
                await dbHandler.deleteAndReset();

                runApp(const MyApp());
              },
            ),
          ],
        );
      },
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
