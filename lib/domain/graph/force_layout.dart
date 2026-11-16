import 'dart:math' as math;
import 'dart:ui' show Offset;

/// 力导向图中的一个节点。坐标是「世界坐标」，与屏幕无关。
class ForceNode {
  ForceNode({
    required this.id,
    this.x = 0,
    this.y = 0,
    this.radius = 18,
    this.mass = 1,
    this.pinned = false,
  });

  final int id;
  double x;
  double y;
  double vx = 0;
  double vy = 0;
  double radius;
  double mass;
  bool pinned;

  Offset get position => Offset(x, y);
}

class ForceEdge {
  ForceEdge({required this.a, required this.b, this.strength = 1});

  /// nodes 列表中的下标
  final int a;
  final int b;
  final double strength;
}

/// Barnes-Hut 四叉树节点。
class _Quad {
  _Quad(this.x0, this.y0, this.x1, this.y1);

  final double x0;
  final double y0;
  final double x1;
  final double y1;

  double mass = 0;
  double cx = 0;
  double cy = 0;

  /// 叶子节点里唯一的点下标；None 表示空或已分裂
  int? point;
  List<_Quad>? kids;

  bool get isLeaf => kids == null;
  double get size => x1 - x0;

  void insert(int index, List<ForceNode> nodes, int depth) {
    final node = nodes[index];
    final m = node.mass;
    final total = mass + m;
    if (total > 0) {
      cx = (cx * mass + node.x * m) / total;
      cy = (cy * mass + node.y * m) / total;
      mass = total;
    }

    if (!isLeaf) {
      _childFor(node).insert(index, nodes, depth + 1);
      return;
    }

    if (point == null) {
      point = index;
      return;
    }

    // 深度保护：极近或重合的点不再细分，避免退化递归
    if (depth > 24 || size < 0.5) {
      point = index;
      return;
    }

    final existing = point!;
    point = null;
    kids = <_Quad>[
      _Quad(x0, y0, (x0 + x1) / 2, (y0 + y1) / 2),
      _Quad((x0 + x1) / 2, y0, x1, (y0 + y1) / 2),
      _Quad(x0, (y0 + y1) / 2, (x0 + x1) / 2, y1),
      _Quad((x0 + x1) / 2, (y0 + y1) / 2, x1, y1),
    ];
    _childFor(nodes[existing]).insert(existing, nodes, depth + 1);
    _childFor(node).insert(index, nodes, depth + 1);
  }

  _Quad _childFor(ForceNode node) {
    final midX = (x0 + x1) / 2;
    final midY = (y0 + y1) / 2;
    final right = node.x >= midX;
    final bottom = node.y >= midY;
    if (right) return bottom ? kids![3] : kids![1];
    return bottom ? kids![2] : kids![0];
  }
}

/// 力导向布局：斥力用 Barnes-Hut 近似，引力用胡克弹簧，另有向心重力。
class ForceLayout {
  ForceLayout({required this.nodes, required this.edges});

  final List<ForceNode> nodes;
  final List<ForceEdge> edges;

  double alpha = 1;
  double repulsion = 30000;
  double springLength = 110;
  double springK = 0.05;
  double gravity = 0.008;
  double damping = 0.86;
  double theta = 0.85;

  bool get isSettled => alpha < 0.02;

  /// 用黄金角螺旋铺初始位置，比随机撒点稳定得多。
  void seed({Offset center = Offset.zero, double spacing = 100}) {
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      // 被用户钉住的节点保留原位
      if (node.pinned) continue;
      final radius = spacing * math.sqrt(i + 0.6);
      final angle = i * 2.399963229728653;
      node
        ..x = center.dx + radius * math.cos(angle)
        ..y = center.dy + radius * math.sin(angle)
        ..vx = 0
        ..vy = 0;
    }
    alpha = 1;
  }

  void kick([double amount = 0.6]) {
    alpha = math.max(alpha, amount);
  }

  void step() {
    if (nodes.isEmpty) return;
    if (isSettled) return;

    final fx = List<double>.filled(nodes.length, 0);
    final fy = List<double>.filled(nodes.length, 0);

    _applyRepulsion(fx, fy);
    _applySprings(fx, fy);

    // 向心重力，防止整图飘散
    for (var i = 0; i < nodes.length; i++) {
      fx[i] -= nodes[i].x * gravity;
      fy[i] -= nodes[i].y * gravity;
    }

    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      if (node.pinned) {
        node.vx = 0;
        node.vy = 0;
        continue;
      }
      node.vx = (node.vx + fx[i]) * damping;
      node.vy = (node.vy + fy[i]) * damping;
      // 限速，避免弹性爆炸
      final speed = math.sqrt(node.vx * node.vx + node.vy * node.vy);
      const maxSpeed = 28.0;
      if (speed > maxSpeed) {
        node.vx = node.vx / speed * maxSpeed;
        node.vy = node.vy / speed * maxSpeed;
      }
      node.x += node.vx;
      node.y += node.vy;
    }

    _resolveOverlap();
    alpha *= 0.98;
  }

  int _tick = 0;

  void _applyRepulsion(List<double> fx, List<double> fy) {
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final n in nodes) {
      minX = math.min(minX, n.x);
      maxX = math.max(maxX, n.x);
      minY = math.min(minY, n.y);
      maxY = math.max(maxY, n.y);
    }
    final pad = 64.0;
    final root = _Quad(minX - pad, minY - pad, maxX + pad, maxY + pad);
    for (var i = 0; i < nodes.length; i++) {
      root.insert(i, nodes, 0);
    }
    for (var i = 0; i < nodes.length; i++) {
      _accumulate(root, i, fx, fy, 0);
    }
  }

  void _accumulate(_Quad quad, int index, List<double> fx, List<double> fy, int depth) {
    if (quad.mass <= 0) return;

    final node = nodes[index];
    var dx = quad.cx - node.x;
    var dy = quad.cy - node.y;
    var distSq = dx * dx + dy * dy;

    if (distSq < 0.01) {
      // 完全重合时给一个确定的微小扰动，避免除零与对称僵持
      dx = (index.isEven ? 1 : -1) * 0.7;
      dy = (index % 3 - 1) * 0.7;
      distSq = 0.98;
    }

    // 叶子，或该象限足够远 → 整体近似
    if ((quad.isLeaf && quad.point != null) || quad.size / math.sqrt(distSq) < theta) {
      if (quad.isLeaf && quad.point == index) return;
      final dist = math.sqrt(distSq);
      final force = repulsion * quad.mass * alpha / distSq;
      fx[index] -= force * dx / dist;
      fy[index] -= force * dy / dist;
      return;
    }

    if (depth > 28 || quad.kids == null) return;
    for (final kid in quad.kids!) {
      _accumulate(kid, index, fx, fy, depth + 1);
    }
  }

  void _applySprings(List<double> fx, List<double> fy) {
    for (final edge in edges) {
      if (edge.a >= nodes.length || edge.b >= nodes.length) continue;
      final a = nodes[edge.a];
      final b = nodes[edge.b];
      var dx = b.x - a.x;
      var dy = b.y - a.y;
      var dist = math.sqrt(dx * dx + dy * dy);
      if (dist < 0.01) {
        dx = 0.7;
        dy = 0.7;
        dist = 0.99;
      }
      final target = springLength * (1.0 - 0.12 * (edge.strength - 1).clamp(0, 4));
      final force = (dist - target) * springK * alpha;
      final ux = dx / dist;
      final uy = dy / dist;
      fx[edge.a] += force * ux;
      fy[edge.a] += force * uy;
      fx[edge.b] -= force * ux;
      fy[edge.b] -= force * uy;
    }
  }

  void _resolveOverlap() {
    _tick++;
    // 前期靠斥力散开即可，后期才处理挤压，省掉大半的 O(n²)
    if (_tick % 3 != 0 || alpha > 0.45) return;
    for (var i = 0; i < nodes.length; i++) {
      for (var j = i + 1; j < nodes.length; j++) {
        final a = nodes[i];
        final b = nodes[j];
        final dx = b.x - a.x;
        final dy = b.y - a.y;
        final distSq = dx * dx + dy * dy;
        final minDist = (a.radius + b.radius) * 0.92;
        if (distSq > minDist * minDist || distSq < 0.0001) continue;
        final dist = math.sqrt(distSq);
        final push = (minDist - dist) / 2;
        final ux = dx / dist;
        final uy = dy / dist;
        if (!a.pinned) {
          a.x -= ux * push;
          a.y -= uy * push;
        }
        if (!b.pinned) {
          b.x += ux * push;
          b.y += uy * push;
        }
      }
    }
  }

  /// 子图外扩到合适视口所需的缩放。
  RectBounds bounds() {
    if (nodes.isEmpty) {
      return RectBounds(Offset.zero, Offset.zero);
    }
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final n in nodes) {
      minX = math.min(minX, n.x - n.radius);
      maxX = math.max(maxX, n.x + n.radius);
      minY = math.min(minY, n.y - n.radius);
      maxY = math.max(maxY, n.y + n.radius);
    }
    return RectBounds(Offset(minX, minY), Offset(maxX, maxY));
  }
}

class RectBounds {
  const RectBounds(this.topLeft, this.bottomRight);

  final Offset topLeft;
  final Offset bottomRight;

  Offset get center => (topLeft + bottomRight) / 2;
  double get width => bottomRight.dx - topLeft.dx;
  double get height => bottomRight.dy - topLeft.dy;
  double get maxSide => math.max(width, height);
}
