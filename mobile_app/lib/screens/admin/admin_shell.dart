import 'package:flutter/material.dart';
import 'package:sentinel/l10n/app_localizations.dart';
import 'package:sentinel/services/auth_service.dart';

class AdminShell extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  const AdminShell({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  bool _isSigningOut = false;

  Future<void> _signOut() async {
    if (_isSigningOut) return;

    setState(() => _isSigningOut = true);

    try {
      await AuthService.signOut();
    } catch (error) {
      debugPrint('Çıkış yapılamadı: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.signOutFailed)),
      );
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  Widget _buildSignOutButton({required bool extended}) {
    final l10n = AppLocalizations.of(context)!;

    final icon = _isSigningOut
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.logout_rounded);

    if (!extended) {
      return IconButton(
        tooltip: l10n.signOutButton,
        onPressed: _isSigningOut ? null : _signOut,
        icon: icon,
      );
    }

    return TextButton.icon(
      onPressed: _isSigningOut ? null : _signOut,
      icon: icon,
      label: Text(l10n.signOutButton),
      style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    final labels = [l10n.adminOverview, l10n.adminDevices, l10n.anomalyHistory];

    const icons = [
      Icons.dashboard_outlined,
      Icons.devices_other_outlined,
      Icons.warning_amber_outlined,
    ];

    const selectedIcons = [
      Icons.dashboard,
      Icons.devices_other,
      Icons.warning_rounded,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return Scaffold(
            body: widget.child,
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildSignOutButton(extended: true),
                  ),
                ),
                NavigationBar(
                  indicatorColor: colors.primary.withValues(alpha: 0.2),
                  selectedIndex: widget.selectedIndex,
                  onDestinationSelected: widget.onDestinationSelected,
                  destinations: [
                    for (var i = 0; i < labels.length; i++)
                      NavigationDestination(
                        icon: Icon(icons[i]),
                        selectedIcon: Icon(
                          selectedIcons[i],
                          color: colors.primary,
                        ),
                        label: labels[i],
                      ),
                  ],
                ),
              ],
            ),
          );
        }

        final extended = constraints.maxWidth >= 1100;

        return Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: extended ? 240 : 80,
                child: ColoredBox(
                  color: colors.surface,
                  child: SafeArea(
                    child: Column(
                      children: [
                        Expanded(
                          child: NavigationRail(
                            extended: extended,
                            minWidth: 80,
                            minExtendedWidth: 240,
                            backgroundColor: colors.surface,
                            indicatorColor: colors.primary.withValues(
                              alpha: 0.18,
                            ),
                            selectedIconTheme: IconThemeData(
                              color: colors.primary,
                            ),
                            selectedLabelTextStyle: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            selectedIndex: widget.selectedIndex,
                            onDestinationSelected: widget.onDestinationSelected,
                            leading: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Icon(
                                Icons.sensors_rounded,
                                color: colors.primary,
                                size: 36,
                              ),
                            ),
                            destinations: [
                              for (var i = 0; i < labels.length; i++)
                                NavigationRailDestination(
                                  icon: Icon(icons[i]),
                                  selectedIcon: Icon(selectedIcons[i]),
                                  label: Text(labels[i]),
                                ),
                            ],
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: colors.outline.withValues(alpha: 0.15),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: _buildSignOutButton(extended: extended),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              VerticalDivider(
                width: 1,
                color: colors.outline.withValues(alpha: 0.15),
              ),
              Expanded(child: widget.child),
            ],
          ),
        );
      },
    );
  }
}
