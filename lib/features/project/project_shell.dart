import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/palette.dart';
import '../../features/editor/chapters_screen.dart';
import '../../features/entities/entities_screen.dart';
import '../../features/graph/graph_screen.dart';
import '../../features/lint/lint_screen.dart';
import '../../features/project/overview_screen.dart';
import '../../providers.dart';
import '../export/export_sheet.dart';

/// 项目内的标签页序号。用 ValueNotifier 而不是路由，
/// 因为带 :pid 的分支路由不被 go_router 的 StatefulShellRoute 允许。
final projectTabProvider = Provider.family<ValueNotifier<int>, int>((ref, projectId) {
  final notifier = ValueNotifier<int>(0);
  ref.onDispose(notifier.dispose);
  return notifier;
});

const kTabOverview = 0;
const kTabGraph = 1;
const kTabEntities = 2;
const kTabChapters = 3;
const kTabLint = 4;

/// 项目内的外壳：宽屏用 NavigationRail，窄屏用底部导航。
class ProjectShell extends ConsumerWidget {
  const ProjectShell({super.key, required this.projectId});

  final int projectId;

  static const _destinations = <_Dest>[
    _Dest('概览', Icons.dashboard_outlined, Icons.dashboard),
    _Dest('图谱', Icons.hub_outlined, Icons.hub),
    _Dest('实体', Icons.people_outline, Icons.people),
    _Dest('正文', Icons.edit_note_outlined, Icons.edit_note),
    _Dest('校对', Icons.rule_outlined, Icons.rule),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectProvider(projectId)).value;
    final tab = ref.watch(projectTabProvider(projectId));
    final wide = MediaQuery.sizeOf(context).width >= 720;

    void select(int index) => tab.value = index;

    return ValueListenableBuilder<int>(
      valueListenable: tab,
      builder: (context, current, _) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              tooltip: '书架',
              onPressed: () => context.go('/'),
            ),
            title: Text(
              project?.title ?? '…',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: Serif.family,
                fontFamilyFallback: Serif.fallback,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                tooltip: '检索正文',
                onPressed: () => context.push('/p/$projectId/search'),
                icon: const Icon(Icons.search, size: 20),
              ),
              if (wide) ...[
                TextButton.icon(
                  onPressed: () => context.push('/p/$projectId/import'),
                  icon: const Icon(Icons.file_download_outlined, size: 17),
                  label: const Text('导入'),
                ),
                TextButton.icon(
                  onPressed: () => showExportSheet(context, projectId: projectId),
                  icon: const Icon(Icons.ios_share, size: 17),
                  label: const Text('导出'),
                ),
                IconButton(
                  onPressed: () => context.push('/settings'),
                  icon: const Icon(Icons.tune, size: 19),
                  tooltip: '设置',
                ),
                const SizedBox(width: 6),
              ] else
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, size: 22),
                  onSelected: (value) {
                    switch (value) {
                      case 'import':
                        context.push('/p/$projectId/import');
                        break;
                      case 'export':
                        showExportSheet(context, projectId: projectId);
                        break;
                      case 'timeline':
                        context.push('/p/$projectId/timeline');
                        break;
                      case 'settings':
                        context.push('/settings');
                        break;
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'timeline', child: Text('关系演化')),
                    PopupMenuItem(value: 'export', child: Text('导出')),
                    PopupMenuItem(value: 'import', child: Text('导入旧稿')),
                    PopupMenuItem(value: 'settings', child: Text('设置')),
                  ],
                ),
            ],
          ),
          body: wide
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: current,
                      onDestinationSelected: select,
                      labelType: NavigationRailLabelType.all,
                      groupAlignment: -0.85,
                      destinations: [
                        for (final d in _destinations)
                          NavigationRailDestination(
                            icon: Icon(d.icon),
                            selectedIcon: Icon(d.selectedIcon),
                            label: Text(d.label),
                          ),
                      ],
                    ),
                    VerticalDivider(width: 1, thickness: 1, color: context.border),
                    Expanded(child: _Tabs(projectId: projectId, index: current)),
                  ],
                )
              : _Tabs(projectId: projectId, index: current),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: current,
                  onDestinationSelected: select,
                  destinations: [
                    for (final d in _destinations)
                      NavigationDestination(
                        icon: Icon(d.icon, size: 22),
                        selectedIcon: Icon(d.selectedIcon, size: 22),
                        label: d.label,
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.projectId, required this.index});

  final int projectId;
  final int index;

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: index,
      children: [
        OverviewScreen(projectId: projectId),
        GraphScreen(projectId: projectId),
        EntitiesScreen(projectId: projectId),
        ChaptersScreen(projectId: projectId),
        LintScreen(projectId: projectId),
      ],
    );
  }
}

class _Dest {
  const _Dest(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
