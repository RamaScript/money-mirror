import 'package:flutter/material.dart';
import 'package:money_mirror/core/utils/app_colors.dart';
import 'package:money_mirror/core/utils/image_paths.dart';
import 'package:money_mirror/main.dart';

class MainDrawerWidget extends StatelessWidget {
  const MainDrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDrawerHeader(),
            Divider(color: Colors.white70),
            _buildDrawerItem(title: "Settings", icon: Icons.settings),
            _buildThemeSection(context),
            _buildListItemsDivider(),
            _buildListItemsHeader(title: "Management"),
            _buildDrawerItem(
              title: "Export Records ",
              icon: Icons.file_download,
            ),
            _buildDrawerItem(title: "Backup & Restore ", icon: Icons.backup),
            _buildDrawerItem(
              title: "Delete and Reset ",
              icon: Icons.delete_forever,
            ),
            _buildListItemsDivider(),
            _buildListItemsHeader(title: "Application"),

            _buildDrawerItem(title: "Pro Version ", icon: Icons.star),
            _buildDrawerItem(title: "Like Money Mirror ", icon: Icons.favorite),
            _buildDrawerItem(title: "Help ", icon: Icons.help),
            _buildDrawerItem(title: "Feedback ", icon: Icons.feedback),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
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
              Text("Money Mirror", style: TextStyle(fontSize: 22)),
              Text("1.0.0"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({required String title, required IconData icon}) {
    return ListTile(leading: Icon(icon), title: Text(title));
  }

  Widget _buildListItemsHeader({required String title}) {
    return Padding(
      padding: EdgeInsets.only(left: 12),
      child: Text(title, style: TextStyle(fontSize: 12)),
    );
  }

  Widget _buildListItemsDivider() {
    return Divider(color: Colors.white30);
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
