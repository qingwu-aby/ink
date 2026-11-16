import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/palette.dart';
import '../../core/widgets/common.dart';
import '../../data/db/app_database.dart';
import '../../domain/graph/force_layout.dart';
import '../../domain/graph/graph_builder.dart';
import '../../domain/taxonomy.dart';
import '../../providers.dart';
import '../entities/entity_sheet.dart';
import '../relations/bulk_relation_sheet.dart';
import '../relations/relation_editor_sheet.dart';
import 'graph_painter.dart';

class GraphScreen extends ConsumerStatefulWidget {
  const GraphScreen({super.key, required this.projectId});

  final int projectId;

  @override
  ConsumerState<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends ConsumerState<GraphScreen> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _frame = ValueNotifier<int>(0);
  final _labels = LabelCache();

  ForceLayout? _layout;
  final _positions = <int, ({double x, double y, bool pinned})>{};
  List<Relation> _relations = const [];
  final _edgeKinds = <String>[];
  Map<int, Entity> _entities = const {};
  Map<int, int> _mentionCounts = const {};
  Set<String> _kindFilter = {};
  String _signature = '';

  double _scale = 1;
  Offset _offset = Offset.zero;
  double _startScale = 1;
  Offset _worldAnchor = Offset.zero;

  int? _selected;
  int? _focus;
  int? _dragIndex;
  bool _fitted = false;

  /// 多选模式：长按或在控制条里点「多选」进入
  bool _multi = false;
  final _selection = <int>{};

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  void _onTick(Duration _) {
    final layout = _layout;
    if (layout == null) return;
    if (layout.isSettled) {
      if (_ticker.isActive) _ticker.stop();
      return;
    }
    // 每帧推两步：收敛快一倍，肉眼仍是渐进展开
    layout.step();
    layout.step();
    _frame.value++;
  }

  void _restart() {
    if (!_ticker.isActive) _ticker.start();
  }

  /// 数据变化时同步布局；已有节点保留位置，避免每次编辑都整图乱跳。
  void _sync(List<Entity> entities, List<Relation> relations, Map<int, int> mentionCounts) {
    final signature = '${entities.map((e) => '${e.id}:${e.name}').join(',')}|'
        '${relations.map((r) => '${r.id}:${r.fromId}:${r.toId}:${r.kind}:${r.strength}:${r.validFrom}:${r.validTo}').join(',')}';
    if (signature == _signature) return;
    _signature = signature;

    _entities = {for (final e in entities) e.id: e};
    _relations = relations;
    _mentionCounts = mentionCounts;

    final degree = <int, int>{};
    for (final r in relations) {
      degree[r.fromId] = (degree[r.fromId] ?? 0) + 1;
      degree[r.toId] = (degree[r.toId] ?? 0) + 1;
    }

    final nodes = <ForceNode>[];
    final indexOf = <int, int>{};
    for (final entity in entities) {
      final existing = _positions[entity.id];
      final d = degree[entity.id] ?? 0;
      final node = ForceNode(
        id: entity.id,
        x: existing?.x ?? 0,
        y: existing?.y ?? 0,
        radius: graphNodeRadius(d),
        mass: 1 + d * 0.12,
        pinned: existing?.pinned ?? false,
      );
      indexOf[entity.id] = nodes.length;
      nodes.add(node);
    }

    final edges = <ForceEdge>[];
    _edgeKinds.clear();
    for (final relation in relations) {
      final a = indexOf[relation.fromId];
      final b = indexOf[relation.toId];
      if (a == null || b == null || a == b) continue;
      edges.add(ForceEdge(a: a, b: b, strength: relation.strength.toDouble()));
      _edgeKinds.add(relation.kind);
    }

    final layout = ForceLayout(nodes: nodes, edges: edges);
    // 新节点放到已有中心附近，旧节点保留坐标
    final fresh = nodes.where((n) => !_positions.containsKey(n.id)).toList();
    layout.seed(spacing: 42);
    for (var i = 0; i < nodes.length; i++) {
      final existing = _positions[nodes[i].id];
      if (existing != null) {
        nodes[i]
          ..x = existing.x
          ..y = existing.y;
      }
    }
    for (final node in fresh) {
      // 轻微错开，避免所有新节点重合成一点
      node.x += (nodes.indexOf(node) % 7 - 3) * 26;
      node.y += (nodes.indexOf(node) % 5 - 2) * 22;
    }

    _layout = layout;
    layout.kick(1);
    _labels.clear();
    _fitted = false;
    _restart();
    _frame.value++;
  }

  Future<void> _openBulkLink() async {
    final ids = _selection.toList();
    if (ids.length < 2) return;
    if (ids.length == 2) {
      await showRelationEditor(
        context,
        projectId: widget.projectId,
        fromId: ids[0],
        toId: ids[1],
      );
      if (mounted) setState(() => _selection.clear());
      return;
    }
    final created = await showBulkRelationSheet(
      context,
      projectId: widget.projectId,
      entityIds: ids,
      entities: _entities.values.toList(),
    );
    if (created == true && mounted) {
      setState(() => _selection.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已建立 ${ids.length - 1} 条关系')),
      );
    }
  }

  void _rememberPositions() {
    final layout = _layout;
    if (layout == null) return;
    for (final node in layout.nodes) {
      _positions[node.id] = (x: node.x, y: node.y, pinned: node.pinned);
    }
  }

  void _fit(Size size) {
    final layout = _layout;
    if (layout == null || layout.nodes.isEmpty) return;
    final bounds = layout.bounds();
    final padding = 56.0;
    final scaleX = (size.width - padding) / (bounds.width == 0 ? 1 : bounds.width);
    final scaleY = (size.height - padding) / (bounds.height == 0 ? 1 : bounds.height);
    _scale = scaleX < scaleY ? scaleX : scaleY;
    _scale = _scale.clamp(0.25, 1.15);
    _offset = Offset(size.width / 2, size.height / 2) - bounds.center * _scale;
    _fitted = true;
    _frame.value++;
  }

  int? _hitTest(Offset local) {
    final layout = _layout;
    if (layout == null) return null;
    final world = (local - _offset) / _scale;
    for (var i = layout.nodes.length - 1; i >= 0; i--) {
      final node = layout.nodes[i];
      final reach = node.radius + 8 / _scale;
      if ((Offset(node.x, node.y) - world).distance <= reach) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final entities = ref.watch(entitiesProvider(widget.projectId)).value;
    final relations = ref.watch(relationsProvider(widget.projectId)).value;
    final counts = ref.watch(mentionCountsProvider(widget.projectId)).value;

    if (entities != null && relations != null && counts != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _sync(entities, relations, counts);
      });
    }

    if (entities != null && entities.isEmpty) {
      return EmptyState(
        icon: Icons.hub_outlined,
        title: '图谱还是一片空白',
        description: '先去「实体」建几个人物，他们之间的关系会自动长成一张图。',
      );
    }

    final dark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (!_fitted && _layout != null && _layout!.nodes.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_fitted) _fit(size);
          });
        }

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: (details) {
                  _startScale = _scale;
                  _worldAnchor = (details.localFocalPoint - _offset) / _scale;
                  _dragIndex = _hitTest(details.localFocalPoint);
                  if (_dragIndex != null) {
                    _layout!.nodes[_dragIndex!].pinned = true;
                    _focus = _layout!.nodes[_dragIndex!].id;
                    _frame.value++;
                  }
                },
                onScaleUpdate: (details) {
                  final layout = _layout;
                  if (layout == null) return;
                  if (_dragIndex != null && details.pointerCount == 1) {
                    final node = layout.nodes[_dragIndex!];
                    final world = (details.localFocalPoint - _offset) / _scale;
                    node
                      ..x = world.dx
                      ..y = world.dy
                      ..pinned = true;
                    layout.kick(0.4);
                    _restart();
                    _frame.value++;
                    return;
                  }
                  final next = (_startScale * details.scale).clamp(0.25, 3.0);
                  _scale = next;
                  _offset = details.localFocalPoint - _worldAnchor * _scale;
                  _frame.value++;
                },
                onScaleEnd: (_) {
                  if (_dragIndex != null) _rememberPositions();
                  _dragIndex = null;
                },
                onLongPressStart: (details) {
                  final index = _hitTest(details.localPosition);
                  if (index == null) return;
                  final id = _layout!.nodes[index].id;
                  setState(() {
                    _multi = true;
                    _selection.add(id);
                    _selected = id;
                    _focus = null;
                  });
                  HapticFeedback.selectionClick();
                  _frame.value++;
                },
                onTapUp: (details) {
                  final index = _hitTest(details.localPosition);
                  if (index == null) {
                    setState(() {
                      if (_multi) {
                        _selection.clear();
                        _multi = false;
                      }
                      _selected = null;
                      _focus = null;
                    });
                    _frame.value++;
                    return;
                  }
                  final id = _layout!.nodes[index].id;
                  if (_multi) {
                    setState(() {
                      if (!_selection.remove(id)) _selection.add(id);
                    });
                    _frame.value++;
                    return;
                  }
                  setState(() {
                    _selected = id;
                    _focus = id;
                  });
                  _frame.value++;
                  showEntityPeek(context, projectId: widget.projectId, entityId: id);
                },
                child: ValueListenableBuilder<int>(
                  valueListenable: _frame,
                  builder: (context, _, __) {
                    final layout = _layout;
                    if (layout == null) {
                      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                    }
                    return CustomPaint(
                      size: size,
                      painter: GraphPainter(
                        layout: layout,
                        entityById: _entities,
                        relationLabel: (i) => i < _edgeKinds.length ? _edgeKinds[i] : 'other',
                        scale: _scale,
                        offset: _offset,
                        dark: dark,
                        selectedId: _selected,
                        focusId: _focus,
                        mentionCounts: _mentionCounts,
                        highlightKinds: _kindFilter,
                        labelCache: _labels,
                        selection: _selection,
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              top: 10,
              child: _multi
                  ? _SelectionBar(
                      count: _selection.length,
                      names: _selection
                          .map((id) => _entities[id]?.name ?? '?')
                          .toList(),
                      onCancel: () => setState(() {
                        _selection.clear();
                        _multi = false;
                      }),
                      onLink: _selection.length < 2 ? null : _openBulkLink,
                      onClear: _selection.isEmpty
                          ? null
                          : () => setState(() => _selection.clear()),
                    )
                  : _TopBar(
                      entities: _entities.values.toList(),
                      filter: _kindFilter,
                      relationCount: _relations.length,
                      onToggleKind: (kind) {
                        setState(() {
                          if (!_kindFilter.remove(kind)) _kindFilter.add(kind);
                        });
                        _frame.value++;
                      },
                    ),
            ),
            Positioned(
              right: 12,
              bottom: 16,
              child: _Controls(
                onMulti: () {
                  setState(() {
                    _multi = !_multi;
                    if (!_multi) _selection.clear();
                  });
                  _frame.value++;
                },
                onFit: () => _fit(size),
                onRelayout: () {
                  _positions.clear();
                  _signature = '';
                  setState(() {
                    _selected = null;
                    _focus = null;
                    _fitted = false;
                  });
                },
                onClearFocus: _focus == null
                    ? null
                    : () {
                        setState(() {
                          _focus = null;
                          _selected = null;
                        });
                        _frame.value++;
                      },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.entities,
    required this.filter,
    required this.relationCount,
    required this.onToggleKind,
  });

  final List<Entity> entities;
  final Set<String> filter;
  final int relationCount;
  final void Function(String kind) onToggleKind;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final entity in entities) {
      counts[entity.kind] = (counts[entity.kind] ?? 0) + 1;
    }
    final kinds = EntityKind.values.where((k) => (counts[k.key] ?? 0) > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: kinds.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final kind = kinds[index];
              final active = filter.contains(kind.key);
              final color = kind.color(Theme.of(context).brightness);
              return GestureDetector(
                onTap: () => onToggleKind(kind.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: active ? color.withValues(alpha: 0.16) : context.surface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: active ? color.withValues(alpha: 0.5) : context.border),
                  ),
                  child: Row(
                    children: [
                      Icon(kind.icon, size: 13, color: active ? color : context.muted),
                      const SizedBox(width: 5),
                      Text(
                        '${kind.label} ${counts[kind.key]}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: active ? color : context.soft,
                          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            '${entities.length} 个实体 · $relationCount 条关系 · 拖动可钉住节点',
            style: context.texts.labelSmall,
          ),
        ),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.onMulti,
    required this.onFit,
    required this.onRelayout,
    required this.onClearFocus,
  });

  final VoidCallback onMulti;
  final VoidCallback onFit;
  final VoidCallback onRelayout;
  final VoidCallback? onClearFocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: context.border),
      ),
      padding: const EdgeInsets.all(2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: '多选',
            onPressed: onMulti,
            icon: const Icon(Icons.check_circle_outline, size: 20),
          ),
          IconButton(
            tooltip: '适应窗口',
            onPressed: onFit,
            icon: const Icon(Icons.fit_screen_outlined, size: 20),
          ),
          IconButton(
            tooltip: '重新排布',
            onPressed: onRelayout,
            icon: const Icon(Icons.scatter_plot_outlined, size: 20),
          ),
          if (onClearFocus != null)
            IconButton(
              tooltip: '取消聚焦',
              onPressed: onClearFocus,
              icon: const Icon(Icons.blur_off_outlined, size: 20),
            ),
        ],
      ),
    );
  }
}


class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.count,
    required this.names,
    required this.onCancel,
    required this.onLink,
    required this.onClear,
  });

  final int count;
  final List<String> names;
  final VoidCallback onCancel;
  final VoidCallback? onLink;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: context.surface.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('已选 $count', style: context.texts.titleMedium),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  names.isEmpty ? '点节点加入选择' : names.join('、'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.labelSmall,
                ),
              ),
              IconButton(
                onPressed: onCancel,
                icon: const Icon(Icons.close, size: 18),
                visualDensity: VisualDensity.compact,
                tooltip: '退出多选',
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              TextButton(onPressed: onClear, child: const Text('清空')),
              const Spacer(),
              FilledButton(
                onPressed: onLink,
                style: FilledButton.styleFrom(minimumSize: const Size(0, 36)),
                child: Text(count == 2 ? '建立关系' : '批量建边'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
