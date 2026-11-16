import 'package:drift/drift.dart';

@DataClassName('Project')
class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 跨设备稳定标识：同步时用它认「同一个项目」，本地自增 id 不参与同步
  TextColumn get syncId => text().nullable().unique()();
  TextColumn get title => text().withLength(min: 1, max: 120)();
  TextColumn get genre => text().withDefault(const Constant(''))();
  TextColumn get synopsis => text().withDefault(const Constant(''))();
  IntColumn get wordGoal => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// 回收站标记：非空 = 已删除但还能恢复（30 天后自动清理）
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

@DataClassName('Chapter')
class Chapters extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get projectId =>
      integer().references(Projects, #id, onDelete: KeyAction.cascade)();
  IntColumn get index => integer()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get body => text().withDefault(const Constant(''))();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  IntColumn get wordCount => integer().withDefault(const Constant(0))();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('Entity')
class Entities extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get projectId =>
      integer().references(Projects, #id, onDelete: KeyAction.cascade)();
  TextColumn get kind => text().withDefault(const Constant('character'))();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  /// JSON 数组字符串，如 ["小沈","砚之"]
  TextColumn get aliases => text().withDefault(const Constant('[]'))();
  TextColumn get summary => text().withDefault(const Constant(''))();
  IntColumn get importance => integer().withDefault(const Constant(3))();
  TextColumn get status => text().withDefault(const Constant('alive'))();
  /// 该角色在哪一章退场（用于死亡后出场校验）
  IntColumn get deathChapter => integer().nullable()();
  TextColumn get tags => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('Relation')
class Relations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get projectId =>
      integer().references(Projects, #id, onDelete: KeyAction.cascade)();
  IntColumn get fromId =>
      integer().references(Entities, #id, onDelete: KeyAction.cascade)();
  IntColumn get toId =>
      integer().references(Entities, #id, onDelete: KeyAction.cascade)();
  TextColumn get kind => text().withDefault(const Constant('other'))();
  IntColumn get strength => integer().withDefault(const Constant(3))();
  TextColumn get note => text().withDefault(const Constant(''))();
  /// 关系生效的章节区间（含首尾）；validTo 为空表示"至今"
  IntColumn get validFrom => integer().withDefault(const Constant(1))();
  IntColumn get validTo => integer().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('Mention')
class Mentions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get chapterId =>
      integer().references(Chapters, #id, onDelete: KeyAction.cascade)();
  IntColumn get entityId =>
      integer().references(Entities, #id, onDelete: KeyAction.cascade)();
  IntColumn get start => integer()();
  IntColumn get end => integer()();
  TextColumn get surface => text().withDefault(const Constant(''))();
}

/// 段落索引：正文按段落切开存一份，用来做全文检索和"某角色出现过的所有段落"。
///
/// 不引入 FTS5：段落是最小检索单位，`LIKE` 扫几十万字的段落表在手机上仍是毫秒级，
/// 而中文分词器对自造名字的召回率远不如"实体词典 + 原文扫描"。
@DataClassName('Paragraph')
class Paragraphs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get chapterId =>
      integer().references(Chapters, #id, onDelete: KeyAction.cascade)();
  IntColumn get projectId =>
      integer().references(Projects, #id, onDelete: KeyAction.cascade)();

  /// 章内段落序号（从 0 开始）
  IntColumn get index => integer()();

  /// 在章节正文中的字符区间，用来回跳和高亮
  IntColumn get start => integer()();
  IntColumn get end => integer()();

  /// 段落文本。不能叫 text —— 那是 drift Table 上的方法名，会冲突
  TextColumn get content => text()();
}

@DataClassName('StoryEvent')
class Events extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get projectId =>
      integer().references(Projects, #id, onDelete: KeyAction.cascade)();
  IntColumn get chapterId => integer().nullable()();
  TextColumn get title => text()();
  TextColumn get detail => text().withDefault(const Constant(''))();
  TextColumn get participants => text().withDefault(const Constant('[]'))();
  IntColumn get order => integer().withDefault(const Constant(0))();
}

@DataClassName('Foreshadow')
class Foreshadows extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get projectId =>
      integer().references(Projects, #id, onDelete: KeyAction.cascade)();
  TextColumn get hook => text()();
  IntColumn get plantedChapter => integer().withDefault(const Constant(1))();
  IntColumn get resolvedChapter => integer().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
}

/// 已删除项目的墓碑。
///
/// 不同步删除会出两种事故：A 删了 B 还留着，然后 B 又把它推回仓库（复活）；
/// 或者两边各自留一份幽灵。墓碑就是"这个 syncId 在某个时刻被删了"的公开告示，
/// 谁的更新时间早于这个时刻，就跟着删。
@DataClassName('ProjectTombstone')
class ProjectTombstones extends Table {
  TextColumn get syncId => text()();
  TextColumn get title => text().withDefault(const Constant(''))();

  /// 哪台设备删的，翻仓库历史时能对上人（设备）
  TextColumn get deviceId => text().withDefault(const Constant(''))();
  DateTimeColumn get deletedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {syncId};
}

/// 上次同步时，每个项目在本地/远端的 updatedAt 水位。
///
/// 没有它就分不清"我改了"和"他改了"：只能比谁的时间更新（LWW），
/// 而两边都改过时，较新的那份会静默吃掉另一份。
@DataClassName('SyncMark')
class SyncMarks extends Table {
  TextColumn get syncId => text()();
  DateTimeColumn get localUpdatedAt => dateTime()();
  DateTimeColumn get remoteUpdatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {syncId};
}

@DataClassName('AppSetting')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {key};
}
