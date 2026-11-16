/// 图上的轻量算法：连通分量、度数统计。都不依赖 Flutter。
class GraphAlgorithms {
  /// 返回每个节点所属连通分量的编号（从 0 开始，按大小降序）。
  /// [neighbours] 是邻接表：节点下标 → 相邻节点下标列表。
  static List<int> components(List<List<int>> neighbours) {
    final n = neighbours.length;
    final label = List<int>.filled(n, -1);
    final groups = <List<int>>[];

    for (var start = 0; start < n; start++) {
      if (label[start] != -1) continue;
      final group = <int>[];
      final stack = <int>[start];
      label[start] = groups.length;
      while (stack.isNotEmpty) {
        final current = stack.removeLast();
        group.add(current);
        for (final next in neighbours[current]) {
          if (label[next] == -1) {
            label[next] = groups.length;
            stack.add(next);
          }
        }
      }
      groups.add(group);
    }

    // 把大分量排在前面，配色优先级更高
    final order = List<int>.generate(groups.length, (i) => i)
      ..sort((a, b) => groups[b].length.compareTo(groups[a].length));
    final remap = List<int>.filled(groups.length, 0);
    for (var i = 0; i < order.length; i++) {
      remap[order[i]] = i;
    }
    return [for (var i = 0; i < n; i++) remap[label[i]]];
  }

  static List<int> degrees(int nodeCount, List<List<int>> edges) {
    final degree = List<int>.filled(nodeCount, 0);
    for (final e in edges) {
      if (e[0] < nodeCount) degree[e[0]]++;
      if (e[1] < nodeCount) degree[e[1]]++;
    }
    return degree;
  }
}
