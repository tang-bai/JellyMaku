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
import 'package:fladder/widgets/navigation_scaffold/components/navigation_button.dart';
import 'package:fladder/widgets/syncplay/syncplay_utils.dart';

/// Dashboard actions above the main navigation list.
///
/// Search stays the original compact icon button. SyncPlay uses the same
/// NavigationButton as the rest of the sidebar so it matches 控制台/媒体库.
class DashboardFabs extends ConsumerWidget {
  const DashboardFabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = ref.watch(isSyncPlayActiveProvider);
    final isLargeBar =
        AdaptiveLayout.layoutModeOf(context) != LayoutMode.single;
    final expanded = isLargeBar &&
        ref.watch(
            clientSettingsProvider.select((value) => value.expandSideBar));

    final search = AdaptiveFab(
      context: context,
      title: context.localized.search,
      key: const Key('dashboard_search'),
      onPressed: () => context.router.navigate(LibrarySearchRoute()),
      child: const Icon(IconsaxPlusLinear.search_normal_1),
    ).normal;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Align(alignment: Alignment.center, child: search),
        NavigationButton(
          label: context.localized.syncPlay,
          selected: isActive,
          selectedIcon: const Icon(IconsaxPlusBold.people),
          icon: const Icon(IconsaxPlusLinear.people),
          horizontal: true,
          expanded: expanded,
          onPressed: () => showSyncPlaySheet(context),
        ),
      ],
    );
  }
}
