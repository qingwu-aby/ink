import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/db/app_database.dart';
import 'domain/seed/demo_seed.dart';
import 'providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();
  try {
    await DemoSeed.ensure(db);
  } catch (error, stack) {
    debugPrint('示例数据初始化失败：$error\n$stack');
  }

  // 老库补建段落索引（一次性，之后随保存增量维护）
  try {
    await db.backfillParagraphs();
  } catch (error) {
    debugPrint('段落索引补建失败：$error');
  }

  // 回收站到期清理：超过 30 天没人管就真正删掉
  try {
    final deviceId = await db.getSetting('sync.deviceId') ?? '';
    await db.purgeExpiredTrash(deviceId: deviceId);
  } catch (error) {
    debugPrint('回收站清理失败：$error');
  }

  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const MopuApp(),
    ),
  );
}
