import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mopu/data/db/app_database.dart';

void main() {
  test('内存库可用', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final pid = await db.createProject(title: 't');
    await db.createEntity(projectId: pid, name: '甲');
    expect((await db.entitiesOf(pid)).length, 1);
    await db.close();
  });
}
