import 'package:flutter/material.dart';
import 'package:money_mirror/core/utils/image_paths.dart';

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
            _buildListItemsDivider(),
            _buildListItemsHeader(title: "Management"),
            _buildDrawerItem(title: "Export Records", icon: Icons.settings),
            _buildDrawerItem(title: "Backup & Restore", icon: Icons.settings),
            _buildDrawerItem(title: "Delete and Reset", icon: Icons.settings),
            _buildListItemsDivider(),
            _buildListItemsHeader(title: "Application"),

            _buildDrawerItem(title: "Pro Version", icon: Icons.settings),
            _buildDrawerItem(title: "Like Money Mirror", icon: Icons.settings),
            _buildDrawerItem(title: "Help", icon: Icons.settings),
            _buildDrawerItem(title: "Feedback", icon: Icons.settings),
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
}
