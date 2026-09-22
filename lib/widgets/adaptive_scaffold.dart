import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/employee.dart';
import '../theme/adaptive.dart';
import '../theme/colors.dart';

class AdaptiveNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final WidgetBuilder builder;

  const AdaptiveNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.builder,
  });
}

/// Persistent sidebar on web/desktop, bottom tab bar on iOS/Android — the
/// one navigation shell every role/screen shares, built once.
class AdaptiveScaffold extends StatefulWidget {
  final List<AdaptiveNavItem> items;
  final Employee user;
  final VoidCallback onSignOut;
  final String brandLabel;
  final Widget Function(BuildContext, VoidCallback openAddProject)? sidebarTrailingAction;

  const AdaptiveScaffold({
    super.key,
    required this.items,
    required this.user,
    required this.onSignOut,
    this.brandLabel = 'Contento',
    this.sidebarTrailingAction,
  });

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    if (Adaptive.isIOSNative) return _cupertinoShell();
    if (Adaptive.isAndroidNative) return _materialTabShell();
    return _webShell();
  }

  // ---------------------------------------------------------------- iOS --
  Widget _cupertinoShell() {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: AppColors.surface,
        activeColor: AppColors.primary,
        inactiveColor: AppColors.textMuted,
        items: [
          for (final item in widget.items)
            BottomNavigationBarItem(icon: Icon(item.icon), activeIcon: Icon(item.activeIcon ?? item.icon), label: item.label),
        ],
      ),
      tabBuilder: (context, i) {
        return CupertinoTabView(
          builder: (context) => widget.items[i].builder(context),
        );
      },
    );
  }

  // ------------------------------------------------------------ Android --
  Widget _materialTabShell() {
    return Scaffold(
      body: SafeArea(child: widget.items[_index].builder(context)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        backgroundColor: AppColors.surface,
        destinations: [
          for (final item in widget.items)
            NavigationDestination(icon: Icon(item.icon), selectedIcon: Icon(item.activeIcon ?? item.icon), label: item.label),
        ],
      ),
    );
  }

  // ----------------------------------------------------------- Web/desk --
  Widget _webShell() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= Adaptive.mobileBreakpoint;
        if (wide) return _wideSidebarLayout();
        return _narrowWebLayout();
      },
    );
  }

  Widget _wideSidebarLayout() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          Container(
            width: 232,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(right: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primary, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.circle, size: 12, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Text(widget.brandLabel,
                          style: const TextStyle(
                              fontFamily: 'Space Grotesk', fontWeight: FontWeight.w700, fontSize: 18)),
                    ],
                  ),
                ),
                for (int i = 0; i < widget.items.length; i++) _sidebarTile(i),
                const Spacer(),
                const Divider(height: 1, color: AppColors.border),
                _userFooter(),
              ],
            ),
          ),
          Expanded(child: widget.items[_index].builder(context)),
        ],
      ),
    );
  }

  Widget _sidebarTile(int i) {
    final item = widget.items[i];
    final selected = i == _index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: () => setState(() => _index = i),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(item.icon, size: 19, color: selected ? AppColors.primary : AppColors.textMuted),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? AppColors.primary : AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _userFooter() {
    return InkWell(
      onTap: () => _showAccountSheet(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Text(widget.user.initials,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.user.name,
                      style: const TextStyle(fontFamily: 'IBM Plex Sans', fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(widget.user.roleLabel, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.logout_rounded, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _narrowWebLayout() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            const Icon(Icons.circle_outlined, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(widget.brandLabel,
                style: const TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.textDark)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => _showAccountSheet(context),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                child: Text(widget.user.initials,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
      body: widget.items[_index].builder(context),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        destinations: [
          for (final item in widget.items)
            NavigationDestination(icon: Icon(item.icon), selectedIcon: Icon(item.activeIcon ?? item.icon), label: item.label),
        ],
      ),
    );
  }

  void _showAccountSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.user.name, style: Theme.of(context).textTheme.titleLarge),
              Text(widget.user.email, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onSignOut();
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Sign out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
