import 'package:flutter/material.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import 'package:fladder/providers/settings/client_settings_provider.dart';
import 'package:fladder/providers/syncplay/syncplay_provider.dart';
import 'package:fladder/routes/auto_router.gr.dart';
import 'package:fladder/util/adaptive_layout/adaptive_layout.dart';
import 'package:fladder/util/localization_helper.dart';
import 'package:fladder/widgets/navigation_scaffold/components/adaptive_fab.dart';
import 'package:fladder/widgets/syncplay/syncplay_utils.dart';

/// Combined FAB for dashboard with search and SyncPlay actions
class DashboardFabs extends ConsumerWidget {
  const DashboardFabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = ref.watch(isSyncPlayActiveProvider);
    final isDualLayout =
        AdaptiveLayout.of(context).layoutMode == LayoutMode.dual;
    final sideBarExpanded = ref.watch(
      clientSettingsProvider.select((value) => value.expandSideBar),
    );
    final useExtended = sideBarExpanded &&
        AdaptiveLayout.layoutModeOf(context) != LayoutMode.single;

    final searchFab = AdaptiveFab(
      context: context,
      title: context.localized.search,
      key: const Key('dashboard_search'),
      onPressed: () => context.router.navigate(LibrarySearchRoute()),
      child: const Icon(IconsaxPlusLinear.search_normal_1),
    );

    final children = [
      _SyncPlayFabButton(isActive: isActive, extended: useExtended),
      useExtended ? searchFab.extended : searchFab.normal,
    ];

    return isDualLayout || useExtended
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: useExtended
                ? CrossAxisAlignment.stretch
                : CrossAxisAlignment.center,
            spacing: 8,
            children: children,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: children,
          );
  }
}

class _SyncPlayFabButton extends StatelessWidget {
  final bool isActive;
  final bool extended;

  const _SyncPlayFabButton({
    required this.isActive,
    this.extended = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = Padding(
      padding: const EdgeInsets.all(8.0),
      child: Stack(
        children: [
          Icon(
            isActive ? IconsaxPlusBold.people : IconsaxPlusLinear.people,
          ),
          if (isActive)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );

    final button = extended
        ? AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: FilledButton.tonal(
                onPressed: () => showSyncPlaySheet(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: isActive
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                ),
                child: Row(
                  spacing: 16,
                  children: [
                    icon,
                    Flexible(child: Text(context.localized.syncPlay)),
                  ],
                ),
              ),
            ),
          )
        : IconButton.filledTonal(
            iconSize: 26,
            tooltip: context.localized.syncPlay,
            onPressed: () => showSyncPlaySheet(context),
            style: IconButton.styleFrom(
              backgroundColor: isActive
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
            ),
            icon: icon,
          );

    return Hero(tag: 'syncplay_fab', child: button);
  }
}
