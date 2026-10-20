import 'package:flutter/material.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import 'package:fladder/providers/settings/client_settings_provider.dart';
import 'package:fladder/routes/auto_router.gr.dart';
import 'package:fladder/util/adaptive_layout/adaptive_layout.dart';
import 'package:fladder/util/localization_helper.dart';
import 'package:fladder/widgets/navigation_scaffold/components/adaptive_fab.dart';

/// Search action above the main navigation list.
///
/// SyncPlay is rendered globally by [SideNavigationRail] so it stays visible
/// on search and library routes as well.
class DashboardFabs extends ConsumerWidget {
  const DashboardFabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    );

    return expanded
        ? search.extended
        : Align(alignment: Alignment.center, child: search.normal);
  }
}
