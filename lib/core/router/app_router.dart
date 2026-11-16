import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/editor/editor_screen.dart';
import '../../features/entities/entity_editor_screen.dart';
import '../../features/import/import_screen.dart';
import '../../features/library/library_screen.dart';
import '../../features/library/trash_screen.dart';
import '../../features/project/project_shell.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/sync_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/snapshot/snapshot_screen.dart';
import '../../features/timeline/timeline_screen.dart';

int _intParam(GoRouterState state, String name) =>
    int.tryParse(state.pathParameters[name] ?? '') ?? 0;

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LibraryScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/trash',
        builder: (context, state) => const TrashScreen(),
      ),
      GoRoute(
        path: '/settings/sync',
        builder: (context, state) => const SyncScreen(),
      ),
      GoRoute(
        path: '/p/:pid',
        builder: (context, state) => ProjectShell(projectId: _intParam(state, 'pid')),
      ),
      GoRoute(
        path: '/p/:pid/entity/:eid',
        builder: (context, state) => EntityEditorScreen(
          projectId: _intParam(state, 'pid'),
          entityId: _intParam(state, 'eid'),
        ),
      ),
      GoRoute(
        path: '/p/:pid/chapter/:cid',
        builder: (context, state) => EditorScreen(
          projectId: _intParam(state, 'pid'),
          chapterId: _intParam(state, 'cid'),
          initialOffset: int.tryParse(state.uri.queryParameters['at'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/p/:pid/search',
        builder: (context, state) => SearchScreen(
          projectId: _intParam(state, 'pid'),
          entityId: int.tryParse(state.uri.queryParameters['eid'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/p/:pid/snapshot',
        builder: (context, state) => SnapshotScreen(
          projectId: _intParam(state, 'pid'),
          initialChapter: int.tryParse(state.uri.queryParameters['c'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/p/:pid/timeline',
        builder: (context, state) => TimelineScreen(projectId: _intParam(state, 'pid')),
      ),
      GoRoute(
        path: '/p/:pid/import',
        builder: (context, state) => ImportScreen(projectId: _intParam(state, 'pid')),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('走错路了')),
      body: Center(
        child: TextButton(
          onPressed: () => context.go('/'),
          child: const Text('回书架'),
        ),
      ),
    ),
  );
});
