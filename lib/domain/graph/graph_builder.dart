import '../../data/db/app_database.dart';
import 'force_layout.dart';

/// 图谱节点的视觉半径：连接越多越大，但收得比较紧，免得挤掉标签。
double graphNodeRadius(int degree) => 12 + (degree == 0 ? 0 : (degree * 1.8).clamp(0, 11));

/// 把实体和关系摊成一张可供力导向与绘制使用的场景。
class GraphScene {
  GraphScene({required this.layout, required this.edgeRelations, required this.entityById});

  final ForceLayout layout;

  /// 与 layout.edges 一一对应的关系（可能因过滤而少于 relations）
  final List<Relation> edgeRelations;
  final Map<int, Entity> entityById;

  List<String> get edgeKinds => [for (final relation in edgeRelations) relation.kind];
}

GraphScene buildGraphScene(List<Entity> entities, List<Relation> relations) {
  final degree = <int, int>{};
  for (final relation in relations) {
    degree[relation.fromId] = (degree[relation.fromId] ?? 0) + 1;
    degree[relation.toId] = (degree[relation.toId] ?? 0) + 1;
  }

  final nodes = <ForceNode>[];
  final indexOf = <int, int>{};
  for (final entity in entities) {
    final d = degree[entity.id] ?? 0;
    indexOf[entity.id] = nodes.length;
    nodes.add(ForceNode(
      id: entity.id,
      radius: graphNodeRadius(d),
      mass: 1 + d * 0.12,
    ));
  }

  final edges = <ForceEdge>[];
  final edgeRelations = <Relation>[];
  for (final relation in relations) {
    final a = indexOf[relation.fromId];
    final b = indexOf[relation.toId];
    if (a == null || b == null || a == b) continue;
    edges.add(ForceEdge(a: a, b: b, strength: relation.strength.toDouble()));
    edgeRelations.add(relation);
  }

  return GraphScene(
    layout: ForceLayout(nodes: nodes, edges: edges),
    edgeRelations: edgeRelations,
    entityById: {for (final entity in entities) entity.id: entity},
  );
}
