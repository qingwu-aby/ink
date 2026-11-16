import 'dart:math';

/// 生成 v4 UUID。同步要靠它认「同一个项目」，不需要引入 uuid 依赖。
String newSyncId() {
  final rng = Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}'
      '-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// 稳定的设备标识：写进同步文件，出问题时能看出是哪台机器推的。
String newDeviceId() => 'dev-${newSyncId().substring(0, 8)}';
