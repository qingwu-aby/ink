// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProjectsTable extends Projects with TableInfo<$ProjectsTable, Project> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _syncIdMeta = const VerificationMeta('syncId');
  @override
  late final GeneratedColumn<String> syncId = GeneratedColumn<String>(
      'sync_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 120),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
      'genre', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _synopsisMeta =
      const VerificationMeta('synopsis');
  @override
  late final GeneratedColumn<String> synopsis = GeneratedColumn<String>(
      'synopsis', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _wordGoalMeta =
      const VerificationMeta('wordGoal');
  @override
  late final GeneratedColumn<int> wordGoal = GeneratedColumn<int>(
      'word_goal', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        syncId,
        title,
        genre,
        synopsis,
        wordGoal,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(Insertable<Project> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sync_id')) {
      context.handle(_syncIdMeta,
          syncId.isAcceptableOrUnknown(data['sync_id']!, _syncIdMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('genre')) {
      context.handle(
          _genreMeta, genre.isAcceptableOrUnknown(data['genre']!, _genreMeta));
    }
    if (data.containsKey('synopsis')) {
      context.handle(_synopsisMeta,
          synopsis.isAcceptableOrUnknown(data['synopsis']!, _synopsisMeta));
    }
    if (data.containsKey('word_goal')) {
      context.handle(_wordGoalMeta,
          wordGoal.isAcceptableOrUnknown(data['word_goal']!, _wordGoalMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Project map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Project(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      syncId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_id']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      genre: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}genre'])!,
      synopsis: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}synopsis'])!,
      wordGoal: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}word_goal'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class Project extends DataClass implements Insertable<Project> {
  final int id;

  /// 跨设备稳定标识：同步时用它认「同一个项目」，本地自增 id 不参与同步
  final String? syncId;
  final String title;
  final String genre;
  final String synopsis;
  final int wordGoal;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 回收站标记：非空 = 已删除但还能恢复（30 天后自动清理）
  final DateTime? deletedAt;
  const Project(
      {required this.id,
      this.syncId,
      required this.title,
      required this.genre,
      required this.synopsis,
      required this.wordGoal,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || syncId != null) {
      map['sync_id'] = Variable<String>(syncId);
    }
    map['title'] = Variable<String>(title);
    map['genre'] = Variable<String>(genre);
    map['synopsis'] = Variable<String>(synopsis);
    map['word_goal'] = Variable<int>(wordGoal);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      syncId:
          syncId == null && nullToAbsent ? const Value.absent() : Value(syncId),
      title: Value(title),
      genre: Value(genre),
      synopsis: Value(synopsis),
      wordGoal: Value(wordGoal),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Project.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Project(
      id: serializer.fromJson<int>(json['id']),
      syncId: serializer.fromJson<String?>(json['syncId']),
      title: serializer.fromJson<String>(json['title']),
      genre: serializer.fromJson<String>(json['genre']),
      synopsis: serializer.fromJson<String>(json['synopsis']),
      wordGoal: serializer.fromJson<int>(json['wordGoal']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'syncId': serializer.toJson<String?>(syncId),
      'title': serializer.toJson<String>(title),
      'genre': serializer.toJson<String>(genre),
      'synopsis': serializer.toJson<String>(synopsis),
      'wordGoal': serializer.toJson<int>(wordGoal),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Project copyWith(
          {int? id,
          Value<String?> syncId = const Value.absent(),
          String? title,
          String? genre,
          String? synopsis,
          int? wordGoal,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      Project(
        id: id ?? this.id,
        syncId: syncId.present ? syncId.value : this.syncId,
        title: title ?? this.title,
        genre: genre ?? this.genre,
        synopsis: synopsis ?? this.synopsis,
        wordGoal: wordGoal ?? this.wordGoal,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  Project copyWithCompanion(ProjectsCompanion data) {
    return Project(
      id: data.id.present ? data.id.value : this.id,
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      title: data.title.present ? data.title.value : this.title,
      genre: data.genre.present ? data.genre.value : this.genre,
      synopsis: data.synopsis.present ? data.synopsis.value : this.synopsis,
      wordGoal: data.wordGoal.present ? data.wordGoal.value : this.wordGoal,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('id: $id, ')
          ..write('syncId: $syncId, ')
          ..write('title: $title, ')
          ..write('genre: $genre, ')
          ..write('synopsis: $synopsis, ')
          ..write('wordGoal: $wordGoal, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, syncId, title, genre, synopsis, wordGoal,
      createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project &&
          other.id == this.id &&
          other.syncId == this.syncId &&
          other.title == this.title &&
          other.genre == this.genre &&
          other.synopsis == this.synopsis &&
          other.wordGoal == this.wordGoal &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class ProjectsCompanion extends UpdateCompanion<Project> {
  final Value<int> id;
  final Value<String?> syncId;
  final Value<String> title;
  final Value<String> genre;
  final Value<String> synopsis;
  final Value<int> wordGoal;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.syncId = const Value.absent(),
    this.title = const Value.absent(),
    this.genre = const Value.absent(),
    this.synopsis = const Value.absent(),
    this.wordGoal = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  ProjectsCompanion.insert({
    this.id = const Value.absent(),
    this.syncId = const Value.absent(),
    required String title,
    this.genre = const Value.absent(),
    this.synopsis = const Value.absent(),
    this.wordGoal = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : title = Value(title);
  static Insertable<Project> custom({
    Expression<int>? id,
    Expression<String>? syncId,
    Expression<String>? title,
    Expression<String>? genre,
    Expression<String>? synopsis,
    Expression<int>? wordGoal,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncId != null) 'sync_id': syncId,
      if (title != null) 'title': title,
      if (genre != null) 'genre': genre,
      if (synopsis != null) 'synopsis': synopsis,
      if (wordGoal != null) 'word_goal': wordGoal,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  ProjectsCompanion copyWith(
      {Value<int>? id,
      Value<String?>? syncId,
      Value<String>? title,
      Value<String>? genre,
      Value<String>? synopsis,
      Value<int>? wordGoal,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt}) {
    return ProjectsCompanion(
      id: id ?? this.id,
      syncId: syncId ?? this.syncId,
      title: title ?? this.title,
      genre: genre ?? this.genre,
      synopsis: synopsis ?? this.synopsis,
      wordGoal: wordGoal ?? this.wordGoal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (syncId.present) {
      map['sync_id'] = Variable<String>(syncId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (synopsis.present) {
      map['synopsis'] = Variable<String>(synopsis.value);
    }
    if (wordGoal.present) {
      map['word_goal'] = Variable<int>(wordGoal.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('syncId: $syncId, ')
          ..write('title: $title, ')
          ..write('genre: $genre, ')
          ..write('synopsis: $synopsis, ')
          ..write('wordGoal: $wordGoal, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $ChaptersTable extends Chapters with TableInfo<$ChaptersTable, Chapter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChaptersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<int> projectId = GeneratedColumn<int>(
      'project_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _indexMeta = const VerificationMeta('index');
  @override
  late final GeneratedColumn<int> index = GeneratedColumn<int>(
      'index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('draft'));
  static const VerificationMeta _wordCountMeta =
      const VerificationMeta('wordCount');
  @override
  late final GeneratedColumn<int> wordCount = GeneratedColumn<int>(
      'word_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, projectId, index, title, body, status, wordCount, note, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chapters';
  @override
  VerificationContext validateIntegrity(Insertable<Chapter> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('index')) {
      context.handle(
          _indexMeta, index.isAcceptableOrUnknown(data['index']!, _indexMeta));
    } else if (isInserting) {
      context.missing(_indexMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('word_count')) {
      context.handle(_wordCountMeta,
          wordCount.isAcceptableOrUnknown(data['word_count']!, _wordCountMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Chapter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Chapter(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}project_id'])!,
      index: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}index'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      wordCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}word_count'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ChaptersTable createAlias(String alias) {
    return $ChaptersTable(attachedDatabase, alias);
  }
}

class Chapter extends DataClass implements Insertable<Chapter> {
  final int id;
  final int projectId;
  final int index;
  final String title;
  final String body;
  final String status;
  final int wordCount;
  final String note;
  final DateTime updatedAt;
  const Chapter(
      {required this.id,
      required this.projectId,
      required this.index,
      required this.title,
      required this.body,
      required this.status,
      required this.wordCount,
      required this.note,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['project_id'] = Variable<int>(projectId);
    map['index'] = Variable<int>(index);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['status'] = Variable<String>(status);
    map['word_count'] = Variable<int>(wordCount);
    map['note'] = Variable<String>(note);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ChaptersCompanion toCompanion(bool nullToAbsent) {
    return ChaptersCompanion(
      id: Value(id),
      projectId: Value(projectId),
      index: Value(index),
      title: Value(title),
      body: Value(body),
      status: Value(status),
      wordCount: Value(wordCount),
      note: Value(note),
      updatedAt: Value(updatedAt),
    );
  }

  factory Chapter.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Chapter(
      id: serializer.fromJson<int>(json['id']),
      projectId: serializer.fromJson<int>(json['projectId']),
      index: serializer.fromJson<int>(json['index']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      status: serializer.fromJson<String>(json['status']),
      wordCount: serializer.fromJson<int>(json['wordCount']),
      note: serializer.fromJson<String>(json['note']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'projectId': serializer.toJson<int>(projectId),
      'index': serializer.toJson<int>(index),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'status': serializer.toJson<String>(status),
      'wordCount': serializer.toJson<int>(wordCount),
      'note': serializer.toJson<String>(note),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Chapter copyWith(
          {int? id,
          int? projectId,
          int? index,
          String? title,
          String? body,
          String? status,
          int? wordCount,
          String? note,
          DateTime? updatedAt}) =>
      Chapter(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        index: index ?? this.index,
        title: title ?? this.title,
        body: body ?? this.body,
        status: status ?? this.status,
        wordCount: wordCount ?? this.wordCount,
        note: note ?? this.note,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Chapter copyWithCompanion(ChaptersCompanion data) {
    return Chapter(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      index: data.index.present ? data.index.value : this.index,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      status: data.status.present ? data.status.value : this.status,
      wordCount: data.wordCount.present ? data.wordCount.value : this.wordCount,
      note: data.note.present ? data.note.value : this.note,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Chapter(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('index: $index, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('status: $status, ')
          ..write('wordCount: $wordCount, ')
          ..write('note: $note, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, projectId, index, title, body, status, wordCount, note, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Chapter &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.index == this.index &&
          other.title == this.title &&
          other.body == this.body &&
          other.status == this.status &&
          other.wordCount == this.wordCount &&
          other.note == this.note &&
          other.updatedAt == this.updatedAt);
}

class ChaptersCompanion extends UpdateCompanion<Chapter> {
  final Value<int> id;
  final Value<int> projectId;
  final Value<int> index;
  final Value<String> title;
  final Value<String> body;
  final Value<String> status;
  final Value<int> wordCount;
  final Value<String> note;
  final Value<DateTime> updatedAt;
  const ChaptersCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.index = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.status = const Value.absent(),
    this.wordCount = const Value.absent(),
    this.note = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ChaptersCompanion.insert({
    this.id = const Value.absent(),
    required int projectId,
    required int index,
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.status = const Value.absent(),
    this.wordCount = const Value.absent(),
    this.note = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : projectId = Value(projectId),
        index = Value(index);
  static Insertable<Chapter> custom({
    Expression<int>? id,
    Expression<int>? projectId,
    Expression<int>? index,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? status,
    Expression<int>? wordCount,
    Expression<String>? note,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (index != null) 'index': index,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (status != null) 'status': status,
      if (wordCount != null) 'word_count': wordCount,
      if (note != null) 'note': note,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ChaptersCompanion copyWith(
      {Value<int>? id,
      Value<int>? projectId,
      Value<int>? index,
      Value<String>? title,
      Value<String>? body,
      Value<String>? status,
      Value<int>? wordCount,
      Value<String>? note,
      Value<DateTime>? updatedAt}) {
    return ChaptersCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      index: index ?? this.index,
      title: title ?? this.title,
      body: body ?? this.body,
      status: status ?? this.status,
      wordCount: wordCount ?? this.wordCount,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<int>(projectId.value);
    }
    if (index.present) {
      map['index'] = Variable<int>(index.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (wordCount.present) {
      map['word_count'] = Variable<int>(wordCount.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChaptersCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('index: $index, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('status: $status, ')
          ..write('wordCount: $wordCount, ')
          ..write('note: $note, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $EntitiesTable extends Entities with TableInfo<$EntitiesTable, Entity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<int> projectId = GeneratedColumn<int>(
      'project_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('character'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 60),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _aliasesMeta =
      const VerificationMeta('aliases');
  @override
  late final GeneratedColumn<String> aliases = GeneratedColumn<String>(
      'aliases', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _summaryMeta =
      const VerificationMeta('summary');
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
      'summary', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _importanceMeta =
      const VerificationMeta('importance');
  @override
  late final GeneratedColumn<int> importance = GeneratedColumn<int>(
      'importance', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(3));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('alive'));
  static const VerificationMeta _deathChapterMeta =
      const VerificationMeta('deathChapter');
  @override
  late final GeneratedColumn<int> deathChapter = GeneratedColumn<int>(
      'death_chapter', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        projectId,
        kind,
        name,
        aliases,
        summary,
        importance,
        status,
        deathChapter,
        tags,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entities';
  @override
  VerificationContext validateIntegrity(Insertable<Entity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('aliases')) {
      context.handle(_aliasesMeta,
          aliases.isAcceptableOrUnknown(data['aliases']!, _aliasesMeta));
    }
    if (data.containsKey('summary')) {
      context.handle(_summaryMeta,
          summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta));
    }
    if (data.containsKey('importance')) {
      context.handle(
          _importanceMeta,
          importance.isAcceptableOrUnknown(
              data['importance']!, _importanceMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('death_chapter')) {
      context.handle(
          _deathChapterMeta,
          deathChapter.isAcceptableOrUnknown(
              data['death_chapter']!, _deathChapterMeta));
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Entity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Entity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}project_id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      aliases: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}aliases'])!,
      summary: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}summary'])!,
      importance: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}importance'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      deathChapter: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}death_chapter']),
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $EntitiesTable createAlias(String alias) {
    return $EntitiesTable(attachedDatabase, alias);
  }
}

class Entity extends DataClass implements Insertable<Entity> {
  final int id;
  final int projectId;
  final String kind;
  final String name;

  /// JSON 数组字符串，如 ["小沈","砚之"]
  final String aliases;
  final String summary;
  final int importance;
  final String status;

  /// 该角色在哪一章退场（用于死亡后出场校验）
  final int? deathChapter;
  final String tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Entity(
      {required this.id,
      required this.projectId,
      required this.kind,
      required this.name,
      required this.aliases,
      required this.summary,
      required this.importance,
      required this.status,
      this.deathChapter,
      required this.tags,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['project_id'] = Variable<int>(projectId);
    map['kind'] = Variable<String>(kind);
    map['name'] = Variable<String>(name);
    map['aliases'] = Variable<String>(aliases);
    map['summary'] = Variable<String>(summary);
    map['importance'] = Variable<int>(importance);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || deathChapter != null) {
      map['death_chapter'] = Variable<int>(deathChapter);
    }
    map['tags'] = Variable<String>(tags);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EntitiesCompanion toCompanion(bool nullToAbsent) {
    return EntitiesCompanion(
      id: Value(id),
      projectId: Value(projectId),
      kind: Value(kind),
      name: Value(name),
      aliases: Value(aliases),
      summary: Value(summary),
      importance: Value(importance),
      status: Value(status),
      deathChapter: deathChapter == null && nullToAbsent
          ? const Value.absent()
          : Value(deathChapter),
      tags: Value(tags),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Entity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Entity(
      id: serializer.fromJson<int>(json['id']),
      projectId: serializer.fromJson<int>(json['projectId']),
      kind: serializer.fromJson<String>(json['kind']),
      name: serializer.fromJson<String>(json['name']),
      aliases: serializer.fromJson<String>(json['aliases']),
      summary: serializer.fromJson<String>(json['summary']),
      importance: serializer.fromJson<int>(json['importance']),
      status: serializer.fromJson<String>(json['status']),
      deathChapter: serializer.fromJson<int?>(json['deathChapter']),
      tags: serializer.fromJson<String>(json['tags']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'projectId': serializer.toJson<int>(projectId),
      'kind': serializer.toJson<String>(kind),
      'name': serializer.toJson<String>(name),
      'aliases': serializer.toJson<String>(aliases),
      'summary': serializer.toJson<String>(summary),
      'importance': serializer.toJson<int>(importance),
      'status': serializer.toJson<String>(status),
      'deathChapter': serializer.toJson<int?>(deathChapter),
      'tags': serializer.toJson<String>(tags),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Entity copyWith(
          {int? id,
          int? projectId,
          String? kind,
          String? name,
          String? aliases,
          String? summary,
          int? importance,
          String? status,
          Value<int?> deathChapter = const Value.absent(),
          String? tags,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Entity(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        kind: kind ?? this.kind,
        name: name ?? this.name,
        aliases: aliases ?? this.aliases,
        summary: summary ?? this.summary,
        importance: importance ?? this.importance,
        status: status ?? this.status,
        deathChapter:
            deathChapter.present ? deathChapter.value : this.deathChapter,
        tags: tags ?? this.tags,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Entity copyWithCompanion(EntitiesCompanion data) {
    return Entity(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      kind: data.kind.present ? data.kind.value : this.kind,
      name: data.name.present ? data.name.value : this.name,
      aliases: data.aliases.present ? data.aliases.value : this.aliases,
      summary: data.summary.present ? data.summary.value : this.summary,
      importance:
          data.importance.present ? data.importance.value : this.importance,
      status: data.status.present ? data.status.value : this.status,
      deathChapter: data.deathChapter.present
          ? data.deathChapter.value
          : this.deathChapter,
      tags: data.tags.present ? data.tags.value : this.tags,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Entity(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('aliases: $aliases, ')
          ..write('summary: $summary, ')
          ..write('importance: $importance, ')
          ..write('status: $status, ')
          ..write('deathChapter: $deathChapter, ')
          ..write('tags: $tags, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, projectId, kind, name, aliases, summary,
      importance, status, deathChapter, tags, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Entity &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.kind == this.kind &&
          other.name == this.name &&
          other.aliases == this.aliases &&
          other.summary == this.summary &&
          other.importance == this.importance &&
          other.status == this.status &&
          other.deathChapter == this.deathChapter &&
          other.tags == this.tags &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class EntitiesCompanion extends UpdateCompanion<Entity> {
  final Value<int> id;
  final Value<int> projectId;
  final Value<String> kind;
  final Value<String> name;
  final Value<String> aliases;
  final Value<String> summary;
  final Value<int> importance;
  final Value<String> status;
  final Value<int?> deathChapter;
  final Value<String> tags;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const EntitiesCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.kind = const Value.absent(),
    this.name = const Value.absent(),
    this.aliases = const Value.absent(),
    this.summary = const Value.absent(),
    this.importance = const Value.absent(),
    this.status = const Value.absent(),
    this.deathChapter = const Value.absent(),
    this.tags = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  EntitiesCompanion.insert({
    this.id = const Value.absent(),
    required int projectId,
    this.kind = const Value.absent(),
    required String name,
    this.aliases = const Value.absent(),
    this.summary = const Value.absent(),
    this.importance = const Value.absent(),
    this.status = const Value.absent(),
    this.deathChapter = const Value.absent(),
    this.tags = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : projectId = Value(projectId),
        name = Value(name);
  static Insertable<Entity> custom({
    Expression<int>? id,
    Expression<int>? projectId,
    Expression<String>? kind,
    Expression<String>? name,
    Expression<String>? aliases,
    Expression<String>? summary,
    Expression<int>? importance,
    Expression<String>? status,
    Expression<int>? deathChapter,
    Expression<String>? tags,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (kind != null) 'kind': kind,
      if (name != null) 'name': name,
      if (aliases != null) 'aliases': aliases,
      if (summary != null) 'summary': summary,
      if (importance != null) 'importance': importance,
      if (status != null) 'status': status,
      if (deathChapter != null) 'death_chapter': deathChapter,
      if (tags != null) 'tags': tags,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  EntitiesCompanion copyWith(
      {Value<int>? id,
      Value<int>? projectId,
      Value<String>? kind,
      Value<String>? name,
      Value<String>? aliases,
      Value<String>? summary,
      Value<int>? importance,
      Value<String>? status,
      Value<int?>? deathChapter,
      Value<String>? tags,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return EntitiesCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      aliases: aliases ?? this.aliases,
      summary: summary ?? this.summary,
      importance: importance ?? this.importance,
      status: status ?? this.status,
      deathChapter: deathChapter ?? this.deathChapter,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<int>(projectId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (aliases.present) {
      map['aliases'] = Variable<String>(aliases.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (importance.present) {
      map['importance'] = Variable<int>(importance.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (deathChapter.present) {
      map['death_chapter'] = Variable<int>(deathChapter.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntitiesCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('aliases: $aliases, ')
          ..write('summary: $summary, ')
          ..write('importance: $importance, ')
          ..write('status: $status, ')
          ..write('deathChapter: $deathChapter, ')
          ..write('tags: $tags, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $RelationsTable extends Relations
    with TableInfo<$RelationsTable, Relation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RelationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<int> projectId = GeneratedColumn<int>(
      'project_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _fromIdMeta = const VerificationMeta('fromId');
  @override
  late final GeneratedColumn<int> fromId = GeneratedColumn<int>(
      'from_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _toIdMeta = const VerificationMeta('toId');
  @override
  late final GeneratedColumn<int> toId = GeneratedColumn<int>(
      'to_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('other'));
  static const VerificationMeta _strengthMeta =
      const VerificationMeta('strength');
  @override
  late final GeneratedColumn<int> strength = GeneratedColumn<int>(
      'strength', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(3));
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _validFromMeta =
      const VerificationMeta('validFrom');
  @override
  late final GeneratedColumn<int> validFrom = GeneratedColumn<int>(
      'valid_from', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _validToMeta =
      const VerificationMeta('validTo');
  @override
  late final GeneratedColumn<int> validTo = GeneratedColumn<int>(
      'valid_to', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        projectId,
        fromId,
        toId,
        kind,
        strength,
        note,
        validFrom,
        validTo,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'relations';
  @override
  VerificationContext validateIntegrity(Insertable<Relation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('from_id')) {
      context.handle(_fromIdMeta,
          fromId.isAcceptableOrUnknown(data['from_id']!, _fromIdMeta));
    } else if (isInserting) {
      context.missing(_fromIdMeta);
    }
    if (data.containsKey('to_id')) {
      context.handle(
          _toIdMeta, toId.isAcceptableOrUnknown(data['to_id']!, _toIdMeta));
    } else if (isInserting) {
      context.missing(_toIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    }
    if (data.containsKey('strength')) {
      context.handle(_strengthMeta,
          strength.isAcceptableOrUnknown(data['strength']!, _strengthMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('valid_from')) {
      context.handle(_validFromMeta,
          validFrom.isAcceptableOrUnknown(data['valid_from']!, _validFromMeta));
    }
    if (data.containsKey('valid_to')) {
      context.handle(_validToMeta,
          validTo.isAcceptableOrUnknown(data['valid_to']!, _validToMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Relation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Relation(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}project_id'])!,
      fromId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}from_id'])!,
      toId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}to_id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      strength: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}strength'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      validFrom: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}valid_from'])!,
      validTo: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}valid_to']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $RelationsTable createAlias(String alias) {
    return $RelationsTable(attachedDatabase, alias);
  }
}

class Relation extends DataClass implements Insertable<Relation> {
  final int id;
  final int projectId;
  final int fromId;
  final int toId;
  final String kind;
  final int strength;
  final String note;

  /// 关系生效的章节区间（含首尾）；validTo 为空表示"至今"
  final int validFrom;
  final int? validTo;
  final DateTime updatedAt;
  const Relation(
      {required this.id,
      required this.projectId,
      required this.fromId,
      required this.toId,
      required this.kind,
      required this.strength,
      required this.note,
      required this.validFrom,
      this.validTo,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['project_id'] = Variable<int>(projectId);
    map['from_id'] = Variable<int>(fromId);
    map['to_id'] = Variable<int>(toId);
    map['kind'] = Variable<String>(kind);
    map['strength'] = Variable<int>(strength);
    map['note'] = Variable<String>(note);
    map['valid_from'] = Variable<int>(validFrom);
    if (!nullToAbsent || validTo != null) {
      map['valid_to'] = Variable<int>(validTo);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RelationsCompanion toCompanion(bool nullToAbsent) {
    return RelationsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      fromId: Value(fromId),
      toId: Value(toId),
      kind: Value(kind),
      strength: Value(strength),
      note: Value(note),
      validFrom: Value(validFrom),
      validTo: validTo == null && nullToAbsent
          ? const Value.absent()
          : Value(validTo),
      updatedAt: Value(updatedAt),
    );
  }

  factory Relation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Relation(
      id: serializer.fromJson<int>(json['id']),
      projectId: serializer.fromJson<int>(json['projectId']),
      fromId: serializer.fromJson<int>(json['fromId']),
      toId: serializer.fromJson<int>(json['toId']),
      kind: serializer.fromJson<String>(json['kind']),
      strength: serializer.fromJson<int>(json['strength']),
      note: serializer.fromJson<String>(json['note']),
      validFrom: serializer.fromJson<int>(json['validFrom']),
      validTo: serializer.fromJson<int?>(json['validTo']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'projectId': serializer.toJson<int>(projectId),
      'fromId': serializer.toJson<int>(fromId),
      'toId': serializer.toJson<int>(toId),
      'kind': serializer.toJson<String>(kind),
      'strength': serializer.toJson<int>(strength),
      'note': serializer.toJson<String>(note),
      'validFrom': serializer.toJson<int>(validFrom),
      'validTo': serializer.toJson<int?>(validTo),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Relation copyWith(
          {int? id,
          int? projectId,
          int? fromId,
          int? toId,
          String? kind,
          int? strength,
          String? note,
          int? validFrom,
          Value<int?> validTo = const Value.absent(),
          DateTime? updatedAt}) =>
      Relation(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        fromId: fromId ?? this.fromId,
        toId: toId ?? this.toId,
        kind: kind ?? this.kind,
        strength: strength ?? this.strength,
        note: note ?? this.note,
        validFrom: validFrom ?? this.validFrom,
        validTo: validTo.present ? validTo.value : this.validTo,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Relation copyWithCompanion(RelationsCompanion data) {
    return Relation(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      fromId: data.fromId.present ? data.fromId.value : this.fromId,
      toId: data.toId.present ? data.toId.value : this.toId,
      kind: data.kind.present ? data.kind.value : this.kind,
      strength: data.strength.present ? data.strength.value : this.strength,
      note: data.note.present ? data.note.value : this.note,
      validFrom: data.validFrom.present ? data.validFrom.value : this.validFrom,
      validTo: data.validTo.present ? data.validTo.value : this.validTo,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Relation(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('fromId: $fromId, ')
          ..write('toId: $toId, ')
          ..write('kind: $kind, ')
          ..write('strength: $strength, ')
          ..write('note: $note, ')
          ..write('validFrom: $validFrom, ')
          ..write('validTo: $validTo, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, projectId, fromId, toId, kind, strength,
      note, validFrom, validTo, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Relation &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.fromId == this.fromId &&
          other.toId == this.toId &&
          other.kind == this.kind &&
          other.strength == this.strength &&
          other.note == this.note &&
          other.validFrom == this.validFrom &&
          other.validTo == this.validTo &&
          other.updatedAt == this.updatedAt);
}

class RelationsCompanion extends UpdateCompanion<Relation> {
  final Value<int> id;
  final Value<int> projectId;
  final Value<int> fromId;
  final Value<int> toId;
  final Value<String> kind;
  final Value<int> strength;
  final Value<String> note;
  final Value<int> validFrom;
  final Value<int?> validTo;
  final Value<DateTime> updatedAt;
  const RelationsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.fromId = const Value.absent(),
    this.toId = const Value.absent(),
    this.kind = const Value.absent(),
    this.strength = const Value.absent(),
    this.note = const Value.absent(),
    this.validFrom = const Value.absent(),
    this.validTo = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  RelationsCompanion.insert({
    this.id = const Value.absent(),
    required int projectId,
    required int fromId,
    required int toId,
    this.kind = const Value.absent(),
    this.strength = const Value.absent(),
    this.note = const Value.absent(),
    this.validFrom = const Value.absent(),
    this.validTo = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : projectId = Value(projectId),
        fromId = Value(fromId),
        toId = Value(toId);
  static Insertable<Relation> custom({
    Expression<int>? id,
    Expression<int>? projectId,
    Expression<int>? fromId,
    Expression<int>? toId,
    Expression<String>? kind,
    Expression<int>? strength,
    Expression<String>? note,
    Expression<int>? validFrom,
    Expression<int>? validTo,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (fromId != null) 'from_id': fromId,
      if (toId != null) 'to_id': toId,
      if (kind != null) 'kind': kind,
      if (strength != null) 'strength': strength,
      if (note != null) 'note': note,
      if (validFrom != null) 'valid_from': validFrom,
      if (validTo != null) 'valid_to': validTo,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  RelationsCompanion copyWith(
      {Value<int>? id,
      Value<int>? projectId,
      Value<int>? fromId,
      Value<int>? toId,
      Value<String>? kind,
      Value<int>? strength,
      Value<String>? note,
      Value<int>? validFrom,
      Value<int?>? validTo,
      Value<DateTime>? updatedAt}) {
    return RelationsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      fromId: fromId ?? this.fromId,
      toId: toId ?? this.toId,
      kind: kind ?? this.kind,
      strength: strength ?? this.strength,
      note: note ?? this.note,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<int>(projectId.value);
    }
    if (fromId.present) {
      map['from_id'] = Variable<int>(fromId.value);
    }
    if (toId.present) {
      map['to_id'] = Variable<int>(toId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (strength.present) {
      map['strength'] = Variable<int>(strength.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (validFrom.present) {
      map['valid_from'] = Variable<int>(validFrom.value);
    }
    if (validTo.present) {
      map['valid_to'] = Variable<int>(validTo.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RelationsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('fromId: $fromId, ')
          ..write('toId: $toId, ')
          ..write('kind: $kind, ')
          ..write('strength: $strength, ')
          ..write('note: $note, ')
          ..write('validFrom: $validFrom, ')
          ..write('validTo: $validTo, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MentionsTable extends Mentions with TableInfo<$MentionsTable, Mention> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MentionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _chapterIdMeta =
      const VerificationMeta('chapterId');
  @override
  late final GeneratedColumn<int> chapterId = GeneratedColumn<int>(
      'chapter_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<int> entityId = GeneratedColumn<int>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _startMeta = const VerificationMeta('start');
  @override
  late final GeneratedColumn<int> start = GeneratedColumn<int>(
      'start', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _endMeta = const VerificationMeta('end');
  @override
  late final GeneratedColumn<int> end = GeneratedColumn<int>(
      'end', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _surfaceMeta =
      const VerificationMeta('surface');
  @override
  late final GeneratedColumn<String> surface = GeneratedColumn<String>(
      'surface', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns =>
      [id, chapterId, entityId, start, end, surface];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mentions';
  @override
  VerificationContext validateIntegrity(Insertable<Mention> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('chapter_id')) {
      context.handle(_chapterIdMeta,
          chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta));
    } else if (isInserting) {
      context.missing(_chapterIdMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('start')) {
      context.handle(
          _startMeta, start.isAcceptableOrUnknown(data['start']!, _startMeta));
    } else if (isInserting) {
      context.missing(_startMeta);
    }
    if (data.containsKey('end')) {
      context.handle(
          _endMeta, end.isAcceptableOrUnknown(data['end']!, _endMeta));
    } else if (isInserting) {
      context.missing(_endMeta);
    }
    if (data.containsKey('surface')) {
      context.handle(_surfaceMeta,
          surface.isAcceptableOrUnknown(data['surface']!, _surfaceMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Mention map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Mention(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      chapterId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}chapter_id'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}entity_id'])!,
      start: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start'])!,
      end: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}end'])!,
      surface: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}surface'])!,
    );
  }

  @override
  $MentionsTable createAlias(String alias) {
    return $MentionsTable(attachedDatabase, alias);
  }
}

class Mention extends DataClass implements Insertable<Mention> {
  final int id;
  final int chapterId;
  final int entityId;
  final int start;
  final int end;
  final String surface;
  const Mention(
      {required this.id,
      required this.chapterId,
      required this.entityId,
      required this.start,
      required this.end,
      required this.surface});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['chapter_id'] = Variable<int>(chapterId);
    map['entity_id'] = Variable<int>(entityId);
    map['start'] = Variable<int>(start);
    map['end'] = Variable<int>(end);
    map['surface'] = Variable<String>(surface);
    return map;
  }

  MentionsCompanion toCompanion(bool nullToAbsent) {
    return MentionsCompanion(
      id: Value(id),
      chapterId: Value(chapterId),
      entityId: Value(entityId),
      start: Value(start),
      end: Value(end),
      surface: Value(surface),
    );
  }

  factory Mention.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Mention(
      id: serializer.fromJson<int>(json['id']),
      chapterId: serializer.fromJson<int>(json['chapterId']),
      entityId: serializer.fromJson<int>(json['entityId']),
      start: serializer.fromJson<int>(json['start']),
      end: serializer.fromJson<int>(json['end']),
      surface: serializer.fromJson<String>(json['surface']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'chapterId': serializer.toJson<int>(chapterId),
      'entityId': serializer.toJson<int>(entityId),
      'start': serializer.toJson<int>(start),
      'end': serializer.toJson<int>(end),
      'surface': serializer.toJson<String>(surface),
    };
  }

  Mention copyWith(
          {int? id,
          int? chapterId,
          int? entityId,
          int? start,
          int? end,
          String? surface}) =>
      Mention(
        id: id ?? this.id,
        chapterId: chapterId ?? this.chapterId,
        entityId: entityId ?? this.entityId,
        start: start ?? this.start,
        end: end ?? this.end,
        surface: surface ?? this.surface,
      );
  Mention copyWithCompanion(MentionsCompanion data) {
    return Mention(
      id: data.id.present ? data.id.value : this.id,
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      start: data.start.present ? data.start.value : this.start,
      end: data.end.present ? data.end.value : this.end,
      surface: data.surface.present ? data.surface.value : this.surface,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Mention(')
          ..write('id: $id, ')
          ..write('chapterId: $chapterId, ')
          ..write('entityId: $entityId, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('surface: $surface')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, chapterId, entityId, start, end, surface);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Mention &&
          other.id == this.id &&
          other.chapterId == this.chapterId &&
          other.entityId == this.entityId &&
          other.start == this.start &&
          other.end == this.end &&
          other.surface == this.surface);
}

class MentionsCompanion extends UpdateCompanion<Mention> {
  final Value<int> id;
  final Value<int> chapterId;
  final Value<int> entityId;
  final Value<int> start;
  final Value<int> end;
  final Value<String> surface;
  const MentionsCompanion({
    this.id = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.entityId = const Value.absent(),
    this.start = const Value.absent(),
    this.end = const Value.absent(),
    this.surface = const Value.absent(),
  });
  MentionsCompanion.insert({
    this.id = const Value.absent(),
    required int chapterId,
    required int entityId,
    required int start,
    required int end,
    this.surface = const Value.absent(),
  })  : chapterId = Value(chapterId),
        entityId = Value(entityId),
        start = Value(start),
        end = Value(end);
  static Insertable<Mention> custom({
    Expression<int>? id,
    Expression<int>? chapterId,
    Expression<int>? entityId,
    Expression<int>? start,
    Expression<int>? end,
    Expression<String>? surface,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (chapterId != null) 'chapter_id': chapterId,
      if (entityId != null) 'entity_id': entityId,
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (surface != null) 'surface': surface,
    });
  }

  MentionsCompanion copyWith(
      {Value<int>? id,
      Value<int>? chapterId,
      Value<int>? entityId,
      Value<int>? start,
      Value<int>? end,
      Value<String>? surface}) {
    return MentionsCompanion(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      entityId: entityId ?? this.entityId,
      start: start ?? this.start,
      end: end ?? this.end,
      surface: surface ?? this.surface,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (chapterId.present) {
      map['chapter_id'] = Variable<int>(chapterId.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<int>(entityId.value);
    }
    if (start.present) {
      map['start'] = Variable<int>(start.value);
    }
    if (end.present) {
      map['end'] = Variable<int>(end.value);
    }
    if (surface.present) {
      map['surface'] = Variable<String>(surface.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MentionsCompanion(')
          ..write('id: $id, ')
          ..write('chapterId: $chapterId, ')
          ..write('entityId: $entityId, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('surface: $surface')
          ..write(')'))
        .toString();
  }
}

class $EventsTable extends Events with TableInfo<$EventsTable, StoryEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<int> projectId = GeneratedColumn<int>(
      'project_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _chapterIdMeta =
      const VerificationMeta('chapterId');
  @override
  late final GeneratedColumn<int> chapterId = GeneratedColumn<int>(
      'chapter_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _detailMeta = const VerificationMeta('detail');
  @override
  late final GeneratedColumn<String> detail = GeneratedColumn<String>(
      'detail', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _participantsMeta =
      const VerificationMeta('participants');
  @override
  late final GeneratedColumn<String> participants = GeneratedColumn<String>(
      'participants', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
      'order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, projectId, chapterId, title, detail, participants, order];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'events';
  @override
  VerificationContext validateIntegrity(Insertable<StoryEvent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('chapter_id')) {
      context.handle(_chapterIdMeta,
          chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('detail')) {
      context.handle(_detailMeta,
          detail.isAcceptableOrUnknown(data['detail']!, _detailMeta));
    }
    if (data.containsKey('participants')) {
      context.handle(
          _participantsMeta,
          participants.isAcceptableOrUnknown(
              data['participants']!, _participantsMeta));
    }
    if (data.containsKey('order')) {
      context.handle(
          _orderMeta, order.isAcceptableOrUnknown(data['order']!, _orderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoryEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoryEvent(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}project_id'])!,
      chapterId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}chapter_id']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      detail: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}detail'])!,
      participants: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}participants'])!,
      order: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order'])!,
    );
  }

  @override
  $EventsTable createAlias(String alias) {
    return $EventsTable(attachedDatabase, alias);
  }
}

class StoryEvent extends DataClass implements Insertable<StoryEvent> {
  final int id;
  final int projectId;
  final int? chapterId;
  final String title;
  final String detail;
  final String participants;
  final int order;
  const StoryEvent(
      {required this.id,
      required this.projectId,
      this.chapterId,
      required this.title,
      required this.detail,
      required this.participants,
      required this.order});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['project_id'] = Variable<int>(projectId);
    if (!nullToAbsent || chapterId != null) {
      map['chapter_id'] = Variable<int>(chapterId);
    }
    map['title'] = Variable<String>(title);
    map['detail'] = Variable<String>(detail);
    map['participants'] = Variable<String>(participants);
    map['order'] = Variable<int>(order);
    return map;
  }

  EventsCompanion toCompanion(bool nullToAbsent) {
    return EventsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      chapterId: chapterId == null && nullToAbsent
          ? const Value.absent()
          : Value(chapterId),
      title: Value(title),
      detail: Value(detail),
      participants: Value(participants),
      order: Value(order),
    );
  }

  factory StoryEvent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoryEvent(
      id: serializer.fromJson<int>(json['id']),
      projectId: serializer.fromJson<int>(json['projectId']),
      chapterId: serializer.fromJson<int?>(json['chapterId']),
      title: serializer.fromJson<String>(json['title']),
      detail: serializer.fromJson<String>(json['detail']),
      participants: serializer.fromJson<String>(json['participants']),
      order: serializer.fromJson<int>(json['order']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'projectId': serializer.toJson<int>(projectId),
      'chapterId': serializer.toJson<int?>(chapterId),
      'title': serializer.toJson<String>(title),
      'detail': serializer.toJson<String>(detail),
      'participants': serializer.toJson<String>(participants),
      'order': serializer.toJson<int>(order),
    };
  }

  StoryEvent copyWith(
          {int? id,
          int? projectId,
          Value<int?> chapterId = const Value.absent(),
          String? title,
          String? detail,
          String? participants,
          int? order}) =>
      StoryEvent(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        chapterId: chapterId.present ? chapterId.value : this.chapterId,
        title: title ?? this.title,
        detail: detail ?? this.detail,
        participants: participants ?? this.participants,
        order: order ?? this.order,
      );
  StoryEvent copyWithCompanion(EventsCompanion data) {
    return StoryEvent(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      title: data.title.present ? data.title.value : this.title,
      detail: data.detail.present ? data.detail.value : this.detail,
      participants: data.participants.present
          ? data.participants.value
          : this.participants,
      order: data.order.present ? data.order.value : this.order,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoryEvent(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('chapterId: $chapterId, ')
          ..write('title: $title, ')
          ..write('detail: $detail, ')
          ..write('participants: $participants, ')
          ..write('order: $order')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, projectId, chapterId, title, detail, participants, order);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoryEvent &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.chapterId == this.chapterId &&
          other.title == this.title &&
          other.detail == this.detail &&
          other.participants == this.participants &&
          other.order == this.order);
}

class EventsCompanion extends UpdateCompanion<StoryEvent> {
  final Value<int> id;
  final Value<int> projectId;
  final Value<int?> chapterId;
  final Value<String> title;
  final Value<String> detail;
  final Value<String> participants;
  final Value<int> order;
  const EventsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.title = const Value.absent(),
    this.detail = const Value.absent(),
    this.participants = const Value.absent(),
    this.order = const Value.absent(),
  });
  EventsCompanion.insert({
    this.id = const Value.absent(),
    required int projectId,
    this.chapterId = const Value.absent(),
    required String title,
    this.detail = const Value.absent(),
    this.participants = const Value.absent(),
    this.order = const Value.absent(),
  })  : projectId = Value(projectId),
        title = Value(title);
  static Insertable<StoryEvent> custom({
    Expression<int>? id,
    Expression<int>? projectId,
    Expression<int>? chapterId,
    Expression<String>? title,
    Expression<String>? detail,
    Expression<String>? participants,
    Expression<int>? order,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (chapterId != null) 'chapter_id': chapterId,
      if (title != null) 'title': title,
      if (detail != null) 'detail': detail,
      if (participants != null) 'participants': participants,
      if (order != null) 'order': order,
    });
  }

  EventsCompanion copyWith(
      {Value<int>? id,
      Value<int>? projectId,
      Value<int?>? chapterId,
      Value<String>? title,
      Value<String>? detail,
      Value<String>? participants,
      Value<int>? order}) {
    return EventsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      chapterId: chapterId ?? this.chapterId,
      title: title ?? this.title,
      detail: detail ?? this.detail,
      participants: participants ?? this.participants,
      order: order ?? this.order,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<int>(projectId.value);
    }
    if (chapterId.present) {
      map['chapter_id'] = Variable<int>(chapterId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (detail.present) {
      map['detail'] = Variable<String>(detail.value);
    }
    if (participants.present) {
      map['participants'] = Variable<String>(participants.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('chapterId: $chapterId, ')
          ..write('title: $title, ')
          ..write('detail: $detail, ')
          ..write('participants: $participants, ')
          ..write('order: $order')
          ..write(')'))
        .toString();
  }
}

class $ForeshadowsTable extends Foreshadows
    with TableInfo<$ForeshadowsTable, Foreshadow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ForeshadowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<int> projectId = GeneratedColumn<int>(
      'project_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _hookMeta = const VerificationMeta('hook');
  @override
  late final GeneratedColumn<String> hook = GeneratedColumn<String>(
      'hook', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _plantedChapterMeta =
      const VerificationMeta('plantedChapter');
  @override
  late final GeneratedColumn<int> plantedChapter = GeneratedColumn<int>(
      'planted_chapter', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _resolvedChapterMeta =
      const VerificationMeta('resolvedChapter');
  @override
  late final GeneratedColumn<int> resolvedChapter = GeneratedColumn<int>(
      'resolved_chapter', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns =>
      [id, projectId, hook, plantedChapter, resolvedChapter, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'foreshadows';
  @override
  VerificationContext validateIntegrity(Insertable<Foreshadow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('hook')) {
      context.handle(
          _hookMeta, hook.isAcceptableOrUnknown(data['hook']!, _hookMeta));
    } else if (isInserting) {
      context.missing(_hookMeta);
    }
    if (data.containsKey('planted_chapter')) {
      context.handle(
          _plantedChapterMeta,
          plantedChapter.isAcceptableOrUnknown(
              data['planted_chapter']!, _plantedChapterMeta));
    }
    if (data.containsKey('resolved_chapter')) {
      context.handle(
          _resolvedChapterMeta,
          resolvedChapter.isAcceptableOrUnknown(
              data['resolved_chapter']!, _resolvedChapterMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Foreshadow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Foreshadow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}project_id'])!,
      hook: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hook'])!,
      plantedChapter: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}planted_chapter'])!,
      resolvedChapter: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}resolved_chapter']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
    );
  }

  @override
  $ForeshadowsTable createAlias(String alias) {
    return $ForeshadowsTable(attachedDatabase, alias);
  }
}

class Foreshadow extends DataClass implements Insertable<Foreshadow> {
  final int id;
  final int projectId;
  final String hook;
  final int plantedChapter;
  final int? resolvedChapter;
  final String note;
  const Foreshadow(
      {required this.id,
      required this.projectId,
      required this.hook,
      required this.plantedChapter,
      this.resolvedChapter,
      required this.note});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['project_id'] = Variable<int>(projectId);
    map['hook'] = Variable<String>(hook);
    map['planted_chapter'] = Variable<int>(plantedChapter);
    if (!nullToAbsent || resolvedChapter != null) {
      map['resolved_chapter'] = Variable<int>(resolvedChapter);
    }
    map['note'] = Variable<String>(note);
    return map;
  }

  ForeshadowsCompanion toCompanion(bool nullToAbsent) {
    return ForeshadowsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      hook: Value(hook),
      plantedChapter: Value(plantedChapter),
      resolvedChapter: resolvedChapter == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedChapter),
      note: Value(note),
    );
  }

  factory Foreshadow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Foreshadow(
      id: serializer.fromJson<int>(json['id']),
      projectId: serializer.fromJson<int>(json['projectId']),
      hook: serializer.fromJson<String>(json['hook']),
      plantedChapter: serializer.fromJson<int>(json['plantedChapter']),
      resolvedChapter: serializer.fromJson<int?>(json['resolvedChapter']),
      note: serializer.fromJson<String>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'projectId': serializer.toJson<int>(projectId),
      'hook': serializer.toJson<String>(hook),
      'plantedChapter': serializer.toJson<int>(plantedChapter),
      'resolvedChapter': serializer.toJson<int?>(resolvedChapter),
      'note': serializer.toJson<String>(note),
    };
  }

  Foreshadow copyWith(
          {int? id,
          int? projectId,
          String? hook,
          int? plantedChapter,
          Value<int?> resolvedChapter = const Value.absent(),
          String? note}) =>
      Foreshadow(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        hook: hook ?? this.hook,
        plantedChapter: plantedChapter ?? this.plantedChapter,
        resolvedChapter: resolvedChapter.present
            ? resolvedChapter.value
            : this.resolvedChapter,
        note: note ?? this.note,
      );
  Foreshadow copyWithCompanion(ForeshadowsCompanion data) {
    return Foreshadow(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      hook: data.hook.present ? data.hook.value : this.hook,
      plantedChapter: data.plantedChapter.present
          ? data.plantedChapter.value
          : this.plantedChapter,
      resolvedChapter: data.resolvedChapter.present
          ? data.resolvedChapter.value
          : this.resolvedChapter,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Foreshadow(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('hook: $hook, ')
          ..write('plantedChapter: $plantedChapter, ')
          ..write('resolvedChapter: $resolvedChapter, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, projectId, hook, plantedChapter, resolvedChapter, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Foreshadow &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.hook == this.hook &&
          other.plantedChapter == this.plantedChapter &&
          other.resolvedChapter == this.resolvedChapter &&
          other.note == this.note);
}

class ForeshadowsCompanion extends UpdateCompanion<Foreshadow> {
  final Value<int> id;
  final Value<int> projectId;
  final Value<String> hook;
  final Value<int> plantedChapter;
  final Value<int?> resolvedChapter;
  final Value<String> note;
  const ForeshadowsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.hook = const Value.absent(),
    this.plantedChapter = const Value.absent(),
    this.resolvedChapter = const Value.absent(),
    this.note = const Value.absent(),
  });
  ForeshadowsCompanion.insert({
    this.id = const Value.absent(),
    required int projectId,
    required String hook,
    this.plantedChapter = const Value.absent(),
    this.resolvedChapter = const Value.absent(),
    this.note = const Value.absent(),
  })  : projectId = Value(projectId),
        hook = Value(hook);
  static Insertable<Foreshadow> custom({
    Expression<int>? id,
    Expression<int>? projectId,
    Expression<String>? hook,
    Expression<int>? plantedChapter,
    Expression<int>? resolvedChapter,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (hook != null) 'hook': hook,
      if (plantedChapter != null) 'planted_chapter': plantedChapter,
      if (resolvedChapter != null) 'resolved_chapter': resolvedChapter,
      if (note != null) 'note': note,
    });
  }

  ForeshadowsCompanion copyWith(
      {Value<int>? id,
      Value<int>? projectId,
      Value<String>? hook,
      Value<int>? plantedChapter,
      Value<int?>? resolvedChapter,
      Value<String>? note}) {
    return ForeshadowsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      hook: hook ?? this.hook,
      plantedChapter: plantedChapter ?? this.plantedChapter,
      resolvedChapter: resolvedChapter ?? this.resolvedChapter,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<int>(projectId.value);
    }
    if (hook.present) {
      map['hook'] = Variable<String>(hook.value);
    }
    if (plantedChapter.present) {
      map['planted_chapter'] = Variable<int>(plantedChapter.value);
    }
    if (resolvedChapter.present) {
      map['resolved_chapter'] = Variable<int>(resolvedChapter.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ForeshadowsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('hook: $hook, ')
          ..write('plantedChapter: $plantedChapter, ')
          ..write('resolvedChapter: $resolvedChapter, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $ParagraphsTable extends Paragraphs
    with TableInfo<$ParagraphsTable, Paragraph> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ParagraphsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _chapterIdMeta =
      const VerificationMeta('chapterId');
  @override
  late final GeneratedColumn<int> chapterId = GeneratedColumn<int>(
      'chapter_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<int> projectId = GeneratedColumn<int>(
      'project_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _indexMeta = const VerificationMeta('index');
  @override
  late final GeneratedColumn<int> index = GeneratedColumn<int>(
      'index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _startMeta = const VerificationMeta('start');
  @override
  late final GeneratedColumn<int> start = GeneratedColumn<int>(
      'start', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _endMeta = const VerificationMeta('end');
  @override
  late final GeneratedColumn<int> end = GeneratedColumn<int>(
      'end', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, chapterId, projectId, index, start, end, content];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'paragraphs';
  @override
  VerificationContext validateIntegrity(Insertable<Paragraph> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('chapter_id')) {
      context.handle(_chapterIdMeta,
          chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta));
    } else if (isInserting) {
      context.missing(_chapterIdMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('index')) {
      context.handle(
          _indexMeta, index.isAcceptableOrUnknown(data['index']!, _indexMeta));
    } else if (isInserting) {
      context.missing(_indexMeta);
    }
    if (data.containsKey('start')) {
      context.handle(
          _startMeta, start.isAcceptableOrUnknown(data['start']!, _startMeta));
    } else if (isInserting) {
      context.missing(_startMeta);
    }
    if (data.containsKey('end')) {
      context.handle(
          _endMeta, end.isAcceptableOrUnknown(data['end']!, _endMeta));
    } else if (isInserting) {
      context.missing(_endMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Paragraph map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Paragraph(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      chapterId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}chapter_id'])!,
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}project_id'])!,
      index: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}index'])!,
      start: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start'])!,
      end: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}end'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
    );
  }

  @override
  $ParagraphsTable createAlias(String alias) {
    return $ParagraphsTable(attachedDatabase, alias);
  }
}

class Paragraph extends DataClass implements Insertable<Paragraph> {
  final int id;
  final int chapterId;
  final int projectId;

  /// 章内段落序号（从 0 开始）
  final int index;

  /// 在章节正文中的字符区间，用来回跳和高亮
  final int start;
  final int end;

  /// 段落文本。不能叫 text —— 那是 drift Table 上的方法名，会冲突
  final String content;
  const Paragraph(
      {required this.id,
      required this.chapterId,
      required this.projectId,
      required this.index,
      required this.start,
      required this.end,
      required this.content});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['chapter_id'] = Variable<int>(chapterId);
    map['project_id'] = Variable<int>(projectId);
    map['index'] = Variable<int>(index);
    map['start'] = Variable<int>(start);
    map['end'] = Variable<int>(end);
    map['content'] = Variable<String>(content);
    return map;
  }

  ParagraphsCompanion toCompanion(bool nullToAbsent) {
    return ParagraphsCompanion(
      id: Value(id),
      chapterId: Value(chapterId),
      projectId: Value(projectId),
      index: Value(index),
      start: Value(start),
      end: Value(end),
      content: Value(content),
    );
  }

  factory Paragraph.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Paragraph(
      id: serializer.fromJson<int>(json['id']),
      chapterId: serializer.fromJson<int>(json['chapterId']),
      projectId: serializer.fromJson<int>(json['projectId']),
      index: serializer.fromJson<int>(json['index']),
      start: serializer.fromJson<int>(json['start']),
      end: serializer.fromJson<int>(json['end']),
      content: serializer.fromJson<String>(json['content']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'chapterId': serializer.toJson<int>(chapterId),
      'projectId': serializer.toJson<int>(projectId),
      'index': serializer.toJson<int>(index),
      'start': serializer.toJson<int>(start),
      'end': serializer.toJson<int>(end),
      'content': serializer.toJson<String>(content),
    };
  }

  Paragraph copyWith(
          {int? id,
          int? chapterId,
          int? projectId,
          int? index,
          int? start,
          int? end,
          String? content}) =>
      Paragraph(
        id: id ?? this.id,
        chapterId: chapterId ?? this.chapterId,
        projectId: projectId ?? this.projectId,
        index: index ?? this.index,
        start: start ?? this.start,
        end: end ?? this.end,
        content: content ?? this.content,
      );
  Paragraph copyWithCompanion(ParagraphsCompanion data) {
    return Paragraph(
      id: data.id.present ? data.id.value : this.id,
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      index: data.index.present ? data.index.value : this.index,
      start: data.start.present ? data.start.value : this.start,
      end: data.end.present ? data.end.value : this.end,
      content: data.content.present ? data.content.value : this.content,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Paragraph(')
          ..write('id: $id, ')
          ..write('chapterId: $chapterId, ')
          ..write('projectId: $projectId, ')
          ..write('index: $index, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, chapterId, projectId, index, start, end, content);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Paragraph &&
          other.id == this.id &&
          other.chapterId == this.chapterId &&
          other.projectId == this.projectId &&
          other.index == this.index &&
          other.start == this.start &&
          other.end == this.end &&
          other.content == this.content);
}

class ParagraphsCompanion extends UpdateCompanion<Paragraph> {
  final Value<int> id;
  final Value<int> chapterId;
  final Value<int> projectId;
  final Value<int> index;
  final Value<int> start;
  final Value<int> end;
  final Value<String> content;
  const ParagraphsCompanion({
    this.id = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.projectId = const Value.absent(),
    this.index = const Value.absent(),
    this.start = const Value.absent(),
    this.end = const Value.absent(),
    this.content = const Value.absent(),
  });
  ParagraphsCompanion.insert({
    this.id = const Value.absent(),
    required int chapterId,
    required int projectId,
    required int index,
    required int start,
    required int end,
    required String content,
  })  : chapterId = Value(chapterId),
        projectId = Value(projectId),
        index = Value(index),
        start = Value(start),
        end = Value(end),
        content = Value(content);
  static Insertable<Paragraph> custom({
    Expression<int>? id,
    Expression<int>? chapterId,
    Expression<int>? projectId,
    Expression<int>? index,
    Expression<int>? start,
    Expression<int>? end,
    Expression<String>? content,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (chapterId != null) 'chapter_id': chapterId,
      if (projectId != null) 'project_id': projectId,
      if (index != null) 'index': index,
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (content != null) 'content': content,
    });
  }

  ParagraphsCompanion copyWith(
      {Value<int>? id,
      Value<int>? chapterId,
      Value<int>? projectId,
      Value<int>? index,
      Value<int>? start,
      Value<int>? end,
      Value<String>? content}) {
    return ParagraphsCompanion(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      projectId: projectId ?? this.projectId,
      index: index ?? this.index,
      start: start ?? this.start,
      end: end ?? this.end,
      content: content ?? this.content,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (chapterId.present) {
      map['chapter_id'] = Variable<int>(chapterId.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<int>(projectId.value);
    }
    if (index.present) {
      map['index'] = Variable<int>(index.value);
    }
    if (start.present) {
      map['start'] = Variable<int>(start.value);
    }
    if (end.present) {
      map['end'] = Variable<int>(end.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ParagraphsCompanion(')
          ..write('id: $id, ')
          ..write('chapterId: $chapterId, ')
          ..write('projectId: $projectId, ')
          ..write('index: $index, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }
}

class $ProjectTombstonesTable extends ProjectTombstones
    with TableInfo<$ProjectTombstonesTable, ProjectTombstone> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectTombstonesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _syncIdMeta = const VerificationMeta('syncId');
  @override
  late final GeneratedColumn<String> syncId = GeneratedColumn<String>(
      'sync_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [syncId, title, deviceId, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'project_tombstones';
  @override
  VerificationContext validateIntegrity(Insertable<ProjectTombstone> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sync_id')) {
      context.handle(_syncIdMeta,
          syncId.isAcceptableOrUnknown(data['sync_id']!, _syncIdMeta));
    } else if (isInserting) {
      context.missing(_syncIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    } else if (isInserting) {
      context.missing(_deletedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {syncId};
  @override
  ProjectTombstone map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProjectTombstone(
      syncId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at'])!,
    );
  }

  @override
  $ProjectTombstonesTable createAlias(String alias) {
    return $ProjectTombstonesTable(attachedDatabase, alias);
  }
}

class ProjectTombstone extends DataClass
    implements Insertable<ProjectTombstone> {
  final String syncId;
  final String title;

  /// 哪台设备删的，翻仓库历史时能对上人（设备）
  final String deviceId;
  final DateTime deletedAt;
  const ProjectTombstone(
      {required this.syncId,
      required this.title,
      required this.deviceId,
      required this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['sync_id'] = Variable<String>(syncId);
    map['title'] = Variable<String>(title);
    map['device_id'] = Variable<String>(deviceId);
    map['deleted_at'] = Variable<DateTime>(deletedAt);
    return map;
  }

  ProjectTombstonesCompanion toCompanion(bool nullToAbsent) {
    return ProjectTombstonesCompanion(
      syncId: Value(syncId),
      title: Value(title),
      deviceId: Value(deviceId),
      deletedAt: Value(deletedAt),
    );
  }

  factory ProjectTombstone.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProjectTombstone(
      syncId: serializer.fromJson<String>(json['syncId']),
      title: serializer.fromJson<String>(json['title']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deletedAt: serializer.fromJson<DateTime>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'syncId': serializer.toJson<String>(syncId),
      'title': serializer.toJson<String>(title),
      'deviceId': serializer.toJson<String>(deviceId),
      'deletedAt': serializer.toJson<DateTime>(deletedAt),
    };
  }

  ProjectTombstone copyWith(
          {String? syncId,
          String? title,
          String? deviceId,
          DateTime? deletedAt}) =>
      ProjectTombstone(
        syncId: syncId ?? this.syncId,
        title: title ?? this.title,
        deviceId: deviceId ?? this.deviceId,
        deletedAt: deletedAt ?? this.deletedAt,
      );
  ProjectTombstone copyWithCompanion(ProjectTombstonesCompanion data) {
    return ProjectTombstone(
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      title: data.title.present ? data.title.value : this.title,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProjectTombstone(')
          ..write('syncId: $syncId, ')
          ..write('title: $title, ')
          ..write('deviceId: $deviceId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(syncId, title, deviceId, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProjectTombstone &&
          other.syncId == this.syncId &&
          other.title == this.title &&
          other.deviceId == this.deviceId &&
          other.deletedAt == this.deletedAt);
}

class ProjectTombstonesCompanion extends UpdateCompanion<ProjectTombstone> {
  final Value<String> syncId;
  final Value<String> title;
  final Value<String> deviceId;
  final Value<DateTime> deletedAt;
  final Value<int> rowid;
  const ProjectTombstonesCompanion({
    this.syncId = const Value.absent(),
    this.title = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectTombstonesCompanion.insert({
    required String syncId,
    this.title = const Value.absent(),
    this.deviceId = const Value.absent(),
    required DateTime deletedAt,
    this.rowid = const Value.absent(),
  })  : syncId = Value(syncId),
        deletedAt = Value(deletedAt);
  static Insertable<ProjectTombstone> custom({
    Expression<String>? syncId,
    Expression<String>? title,
    Expression<String>? deviceId,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (syncId != null) 'sync_id': syncId,
      if (title != null) 'title': title,
      if (deviceId != null) 'device_id': deviceId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectTombstonesCompanion copyWith(
      {Value<String>? syncId,
      Value<String>? title,
      Value<String>? deviceId,
      Value<DateTime>? deletedAt,
      Value<int>? rowid}) {
    return ProjectTombstonesCompanion(
      syncId: syncId ?? this.syncId,
      title: title ?? this.title,
      deviceId: deviceId ?? this.deviceId,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (syncId.present) {
      map['sync_id'] = Variable<String>(syncId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectTombstonesCompanion(')
          ..write('syncId: $syncId, ')
          ..write('title: $title, ')
          ..write('deviceId: $deviceId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMarksTable extends SyncMarks
    with TableInfo<$SyncMarksTable, SyncMark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _syncIdMeta = const VerificationMeta('syncId');
  @override
  late final GeneratedColumn<String> syncId = GeneratedColumn<String>(
      'sync_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localUpdatedAtMeta =
      const VerificationMeta('localUpdatedAt');
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>('local_updated_at', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _remoteUpdatedAtMeta =
      const VerificationMeta('remoteUpdatedAt');
  @override
  late final GeneratedColumn<DateTime> remoteUpdatedAt =
      GeneratedColumn<DateTime>('remote_updated_at', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [syncId, localUpdatedAt, remoteUpdatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_marks';
  @override
  VerificationContext validateIntegrity(Insertable<SyncMark> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sync_id')) {
      context.handle(_syncIdMeta,
          syncId.isAcceptableOrUnknown(data['sync_id']!, _syncIdMeta));
    } else if (isInserting) {
      context.missing(_syncIdMeta);
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
          _localUpdatedAtMeta,
          localUpdatedAt.isAcceptableOrUnknown(
              data['local_updated_at']!, _localUpdatedAtMeta));
    } else if (isInserting) {
      context.missing(_localUpdatedAtMeta);
    }
    if (data.containsKey('remote_updated_at')) {
      context.handle(
          _remoteUpdatedAtMeta,
          remoteUpdatedAt.isAcceptableOrUnknown(
              data['remote_updated_at']!, _remoteUpdatedAtMeta));
    } else if (isInserting) {
      context.missing(_remoteUpdatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {syncId};
  @override
  SyncMark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMark(
      syncId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_id'])!,
      localUpdatedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}local_updated_at'])!,
      remoteUpdatedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}remote_updated_at'])!,
    );
  }

  @override
  $SyncMarksTable createAlias(String alias) {
    return $SyncMarksTable(attachedDatabase, alias);
  }
}

class SyncMark extends DataClass implements Insertable<SyncMark> {
  final String syncId;
  final DateTime localUpdatedAt;
  final DateTime remoteUpdatedAt;
  const SyncMark(
      {required this.syncId,
      required this.localUpdatedAt,
      required this.remoteUpdatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['sync_id'] = Variable<String>(syncId);
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    map['remote_updated_at'] = Variable<DateTime>(remoteUpdatedAt);
    return map;
  }

  SyncMarksCompanion toCompanion(bool nullToAbsent) {
    return SyncMarksCompanion(
      syncId: Value(syncId),
      localUpdatedAt: Value(localUpdatedAt),
      remoteUpdatedAt: Value(remoteUpdatedAt),
    );
  }

  factory SyncMark.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMark(
      syncId: serializer.fromJson<String>(json['syncId']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
      remoteUpdatedAt: serializer.fromJson<DateTime>(json['remoteUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'syncId': serializer.toJson<String>(syncId),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
      'remoteUpdatedAt': serializer.toJson<DateTime>(remoteUpdatedAt),
    };
  }

  SyncMark copyWith(
          {String? syncId,
          DateTime? localUpdatedAt,
          DateTime? remoteUpdatedAt}) =>
      SyncMark(
        syncId: syncId ?? this.syncId,
        localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
        remoteUpdatedAt: remoteUpdatedAt ?? this.remoteUpdatedAt,
      );
  SyncMark copyWithCompanion(SyncMarksCompanion data) {
    return SyncMark(
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
      remoteUpdatedAt: data.remoteUpdatedAt.present
          ? data.remoteUpdatedAt.value
          : this.remoteUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMark(')
          ..write('syncId: $syncId, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('remoteUpdatedAt: $remoteUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(syncId, localUpdatedAt, remoteUpdatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMark &&
          other.syncId == this.syncId &&
          other.localUpdatedAt == this.localUpdatedAt &&
          other.remoteUpdatedAt == this.remoteUpdatedAt);
}

class SyncMarksCompanion extends UpdateCompanion<SyncMark> {
  final Value<String> syncId;
  final Value<DateTime> localUpdatedAt;
  final Value<DateTime> remoteUpdatedAt;
  final Value<int> rowid;
  const SyncMarksCompanion({
    this.syncId = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.remoteUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMarksCompanion.insert({
    required String syncId,
    required DateTime localUpdatedAt,
    required DateTime remoteUpdatedAt,
    this.rowid = const Value.absent(),
  })  : syncId = Value(syncId),
        localUpdatedAt = Value(localUpdatedAt),
        remoteUpdatedAt = Value(remoteUpdatedAt);
  static Insertable<SyncMark> custom({
    Expression<String>? syncId,
    Expression<DateTime>? localUpdatedAt,
    Expression<DateTime>? remoteUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (syncId != null) 'sync_id': syncId,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (remoteUpdatedAt != null) 'remote_updated_at': remoteUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMarksCompanion copyWith(
      {Value<String>? syncId,
      Value<DateTime>? localUpdatedAt,
      Value<DateTime>? remoteUpdatedAt,
      Value<int>? rowid}) {
    return SyncMarksCompanion(
      syncId: syncId ?? this.syncId,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      remoteUpdatedAt: remoteUpdatedAt ?? this.remoteUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (syncId.present) {
      map['sync_id'] = Variable<String>(syncId.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (remoteUpdatedAt.present) {
      map['remote_updated_at'] = Variable<DateTime>(remoteUpdatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMarksCompanion(')
          ..write('syncId: $syncId, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('remoteUpdatedAt: $remoteUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<AppSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory AppSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) => AppSetting(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  AppSetting copyWithCompanion(SettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $ChaptersTable chapters = $ChaptersTable(this);
  late final $EntitiesTable entities = $EntitiesTable(this);
  late final $RelationsTable relations = $RelationsTable(this);
  late final $MentionsTable mentions = $MentionsTable(this);
  late final $EventsTable events = $EventsTable(this);
  late final $ForeshadowsTable foreshadows = $ForeshadowsTable(this);
  late final $ParagraphsTable paragraphs = $ParagraphsTable(this);
  late final $ProjectTombstonesTable projectTombstones =
      $ProjectTombstonesTable(this);
  late final $SyncMarksTable syncMarks = $SyncMarksTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        projects,
        chapters,
        entities,
        relations,
        mentions,
        events,
        foreshadows,
        paragraphs,
        projectTombstones,
        syncMarks,
        settings
      ];
}

typedef $$ProjectsTableCreateCompanionBuilder = ProjectsCompanion Function({
  Value<int> id,
  Value<String?> syncId,
  required String title,
  Value<String> genre,
  Value<String> synopsis,
  Value<int> wordGoal,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
});
typedef $$ProjectsTableUpdateCompanionBuilder = ProjectsCompanion Function({
  Value<int> id,
  Value<String?> syncId,
  Value<String> title,
  Value<String> genre,
  Value<String> synopsis,
  Value<int> wordGoal,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
});

class $$ProjectsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncId => $composableBuilder(
      column: $table.syncId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get genre => $composableBuilder(
      column: $table.genre, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get synopsis => $composableBuilder(
      column: $table.synopsis, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get wordGoal => $composableBuilder(
      column: $table.wordGoal, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncId => $composableBuilder(
      column: $table.syncId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get genre => $composableBuilder(
      column: $table.genre, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get synopsis => $composableBuilder(
      column: $table.synopsis, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get wordGoal => $composableBuilder(
      column: $table.wordGoal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$ProjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<String> get synopsis =>
      $composableBuilder(column: $table.synopsis, builder: (column) => column);

  GeneratedColumn<int> get wordGoal =>
      $composableBuilder(column: $table.wordGoal, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$ProjectsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProjectsTable,
    Project,
    $$ProjectsTableFilterComposer,
    $$ProjectsTableOrderingComposer,
    $$ProjectsTableAnnotationComposer,
    $$ProjectsTableCreateCompanionBuilder,
    $$ProjectsTableUpdateCompanionBuilder,
    (Project, BaseReferences<_$AppDatabase, $ProjectsTable, Project>),
    Project,
    PrefetchHooks Function()> {
  $$ProjectsTableTableManager(_$AppDatabase db, $ProjectsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> syncId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> genre = const Value.absent(),
            Value<String> synopsis = const Value.absent(),
            Value<int> wordGoal = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              ProjectsCompanion(
            id: id,
            syncId: syncId,
            title: title,
            genre: genre,
            synopsis: synopsis,
            wordGoal: wordGoal,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> syncId = const Value.absent(),
            required String title,
            Value<String> genre = const Value.absent(),
            Value<String> synopsis = const Value.absent(),
            Value<int> wordGoal = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              ProjectsCompanion.insert(
            id: id,
            syncId: syncId,
            title: title,
            genre: genre,
            synopsis: synopsis,
            wordGoal: wordGoal,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProjectsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProjectsTable,
    Project,
    $$ProjectsTableFilterComposer,
    $$ProjectsTableOrderingComposer,
    $$ProjectsTableAnnotationComposer,
    $$ProjectsTableCreateCompanionBuilder,
    $$ProjectsTableUpdateCompanionBuilder,
    (Project, BaseReferences<_$AppDatabase, $ProjectsTable, Project>),
    Project,
    PrefetchHooks Function()>;
typedef $$ChaptersTableCreateCompanionBuilder = ChaptersCompanion Function({
  Value<int> id,
  required int projectId,
  required int index,
  Value<String> title,
  Value<String> body,
  Value<String> status,
  Value<int> wordCount,
  Value<String> note,
  Value<DateTime> updatedAt,
});
typedef $$ChaptersTableUpdateCompanionBuilder = ChaptersCompanion Function({
  Value<int> id,
  Value<int> projectId,
  Value<int> index,
  Value<String> title,
  Value<String> body,
  Value<String> status,
  Value<int> wordCount,
  Value<String> note,
  Value<DateTime> updatedAt,
});

class $$ChaptersTableFilterComposer
    extends Composer<_$AppDatabase, $ChaptersTable> {
  $$ChaptersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get index => $composableBuilder(
      column: $table.index, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get wordCount => $composableBuilder(
      column: $table.wordCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ChaptersTableOrderingComposer
    extends Composer<_$AppDatabase, $ChaptersTable> {
  $$ChaptersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get index => $composableBuilder(
      column: $table.index, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get wordCount => $composableBuilder(
      column: $table.wordCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ChaptersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChaptersTable> {
  $$ChaptersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<int> get index =>
      $composableBuilder(column: $table.index, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get wordCount =>
      $composableBuilder(column: $table.wordCount, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ChaptersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChaptersTable,
    Chapter,
    $$ChaptersTableFilterComposer,
    $$ChaptersTableOrderingComposer,
    $$ChaptersTableAnnotationComposer,
    $$ChaptersTableCreateCompanionBuilder,
    $$ChaptersTableUpdateCompanionBuilder,
    (Chapter, BaseReferences<_$AppDatabase, $ChaptersTable, Chapter>),
    Chapter,
    PrefetchHooks Function()> {
  $$ChaptersTableTableManager(_$AppDatabase db, $ChaptersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChaptersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChaptersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChaptersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> projectId = const Value.absent(),
            Value<int> index = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> wordCount = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              ChaptersCompanion(
            id: id,
            projectId: projectId,
            index: index,
            title: title,
            body: body,
            status: status,
            wordCount: wordCount,
            note: note,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int projectId,
            required int index,
            Value<String> title = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> wordCount = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              ChaptersCompanion.insert(
            id: id,
            projectId: projectId,
            index: index,
            title: title,
            body: body,
            status: status,
            wordCount: wordCount,
            note: note,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ChaptersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChaptersTable,
    Chapter,
    $$ChaptersTableFilterComposer,
    $$ChaptersTableOrderingComposer,
    $$ChaptersTableAnnotationComposer,
    $$ChaptersTableCreateCompanionBuilder,
    $$ChaptersTableUpdateCompanionBuilder,
    (Chapter, BaseReferences<_$AppDatabase, $ChaptersTable, Chapter>),
    Chapter,
    PrefetchHooks Function()>;
typedef $$EntitiesTableCreateCompanionBuilder = EntitiesCompanion Function({
  Value<int> id,
  required int projectId,
  Value<String> kind,
  required String name,
  Value<String> aliases,
  Value<String> summary,
  Value<int> importance,
  Value<String> status,
  Value<int?> deathChapter,
  Value<String> tags,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$EntitiesTableUpdateCompanionBuilder = EntitiesCompanion Function({
  Value<int> id,
  Value<int> projectId,
  Value<String> kind,
  Value<String> name,
  Value<String> aliases,
  Value<String> summary,
  Value<int> importance,
  Value<String> status,
  Value<int?> deathChapter,
  Value<String> tags,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$EntitiesTableFilterComposer
    extends Composer<_$AppDatabase, $EntitiesTable> {
  $$EntitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get aliases => $composableBuilder(
      column: $table.aliases, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get summary => $composableBuilder(
      column: $table.summary, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get importance => $composableBuilder(
      column: $table.importance, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deathChapter => $composableBuilder(
      column: $table.deathChapter, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$EntitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $EntitiesTable> {
  $$EntitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get aliases => $composableBuilder(
      column: $table.aliases, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get summary => $composableBuilder(
      column: $table.summary, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get importance => $composableBuilder(
      column: $table.importance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deathChapter => $composableBuilder(
      column: $table.deathChapter,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$EntitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntitiesTable> {
  $$EntitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get aliases =>
      $composableBuilder(column: $table.aliases, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<int> get importance => $composableBuilder(
      column: $table.importance, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get deathChapter => $composableBuilder(
      column: $table.deathChapter, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$EntitiesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EntitiesTable,
    Entity,
    $$EntitiesTableFilterComposer,
    $$EntitiesTableOrderingComposer,
    $$EntitiesTableAnnotationComposer,
    $$EntitiesTableCreateCompanionBuilder,
    $$EntitiesTableUpdateCompanionBuilder,
    (Entity, BaseReferences<_$AppDatabase, $EntitiesTable, Entity>),
    Entity,
    PrefetchHooks Function()> {
  $$EntitiesTableTableManager(_$AppDatabase db, $EntitiesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> projectId = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> aliases = const Value.absent(),
            Value<String> summary = const Value.absent(),
            Value<int> importance = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int?> deathChapter = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              EntitiesCompanion(
            id: id,
            projectId: projectId,
            kind: kind,
            name: name,
            aliases: aliases,
            summary: summary,
            importance: importance,
            status: status,
            deathChapter: deathChapter,
            tags: tags,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int projectId,
            Value<String> kind = const Value.absent(),
            required String name,
            Value<String> aliases = const Value.absent(),
            Value<String> summary = const Value.absent(),
            Value<int> importance = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int?> deathChapter = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              EntitiesCompanion.insert(
            id: id,
            projectId: projectId,
            kind: kind,
            name: name,
            aliases: aliases,
            summary: summary,
            importance: importance,
            status: status,
            deathChapter: deathChapter,
            tags: tags,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$EntitiesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EntitiesTable,
    Entity,
    $$EntitiesTableFilterComposer,
    $$EntitiesTableOrderingComposer,
    $$EntitiesTableAnnotationComposer,
    $$EntitiesTableCreateCompanionBuilder,
    $$EntitiesTableUpdateCompanionBuilder,
    (Entity, BaseReferences<_$AppDatabase, $EntitiesTable, Entity>),
    Entity,
    PrefetchHooks Function()>;
typedef $$RelationsTableCreateCompanionBuilder = RelationsCompanion Function({
  Value<int> id,
  required int projectId,
  required int fromId,
  required int toId,
  Value<String> kind,
  Value<int> strength,
  Value<String> note,
  Value<int> validFrom,
  Value<int?> validTo,
  Value<DateTime> updatedAt,
});
typedef $$RelationsTableUpdateCompanionBuilder = RelationsCompanion Function({
  Value<int> id,
  Value<int> projectId,
  Value<int> fromId,
  Value<int> toId,
  Value<String> kind,
  Value<int> strength,
  Value<String> note,
  Value<int> validFrom,
  Value<int?> validTo,
  Value<DateTime> updatedAt,
});

class $$RelationsTableFilterComposer
    extends Composer<_$AppDatabase, $RelationsTable> {
  $$RelationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fromId => $composableBuilder(
      column: $table.fromId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get toId => $composableBuilder(
      column: $table.toId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get strength => $composableBuilder(
      column: $table.strength, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get validFrom => $composableBuilder(
      column: $table.validFrom, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get validTo => $composableBuilder(
      column: $table.validTo, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$RelationsTableOrderingComposer
    extends Composer<_$AppDatabase, $RelationsTable> {
  $$RelationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fromId => $composableBuilder(
      column: $table.fromId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get toId => $composableBuilder(
      column: $table.toId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get strength => $composableBuilder(
      column: $table.strength, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get validFrom => $composableBuilder(
      column: $table.validFrom, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get validTo => $composableBuilder(
      column: $table.validTo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$RelationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RelationsTable> {
  $$RelationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<int> get fromId =>
      $composableBuilder(column: $table.fromId, builder: (column) => column);

  GeneratedColumn<int> get toId =>
      $composableBuilder(column: $table.toId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get strength =>
      $composableBuilder(column: $table.strength, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get validFrom =>
      $composableBuilder(column: $table.validFrom, builder: (column) => column);

  GeneratedColumn<int> get validTo =>
      $composableBuilder(column: $table.validTo, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$RelationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RelationsTable,
    Relation,
    $$RelationsTableFilterComposer,
    $$RelationsTableOrderingComposer,
    $$RelationsTableAnnotationComposer,
    $$RelationsTableCreateCompanionBuilder,
    $$RelationsTableUpdateCompanionBuilder,
    (Relation, BaseReferences<_$AppDatabase, $RelationsTable, Relation>),
    Relation,
    PrefetchHooks Function()> {
  $$RelationsTableTableManager(_$AppDatabase db, $RelationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RelationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RelationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RelationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> projectId = const Value.absent(),
            Value<int> fromId = const Value.absent(),
            Value<int> toId = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<int> strength = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<int> validFrom = const Value.absent(),
            Value<int?> validTo = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              RelationsCompanion(
            id: id,
            projectId: projectId,
            fromId: fromId,
            toId: toId,
            kind: kind,
            strength: strength,
            note: note,
            validFrom: validFrom,
            validTo: validTo,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int projectId,
            required int fromId,
            required int toId,
            Value<String> kind = const Value.absent(),
            Value<int> strength = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<int> validFrom = const Value.absent(),
            Value<int?> validTo = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              RelationsCompanion.insert(
            id: id,
            projectId: projectId,
            fromId: fromId,
            toId: toId,
            kind: kind,
            strength: strength,
            note: note,
            validFrom: validFrom,
            validTo: validTo,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RelationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RelationsTable,
    Relation,
    $$RelationsTableFilterComposer,
    $$RelationsTableOrderingComposer,
    $$RelationsTableAnnotationComposer,
    $$RelationsTableCreateCompanionBuilder,
    $$RelationsTableUpdateCompanionBuilder,
    (Relation, BaseReferences<_$AppDatabase, $RelationsTable, Relation>),
    Relation,
    PrefetchHooks Function()>;
typedef $$MentionsTableCreateCompanionBuilder = MentionsCompanion Function({
  Value<int> id,
  required int chapterId,
  required int entityId,
  required int start,
  required int end,
  Value<String> surface,
});
typedef $$MentionsTableUpdateCompanionBuilder = MentionsCompanion Function({
  Value<int> id,
  Value<int> chapterId,
  Value<int> entityId,
  Value<int> start,
  Value<int> end,
  Value<String> surface,
});

class $$MentionsTableFilterComposer
    extends Composer<_$AppDatabase, $MentionsTable> {
  $$MentionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get chapterId => $composableBuilder(
      column: $table.chapterId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get start => $composableBuilder(
      column: $table.start, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get end => $composableBuilder(
      column: $table.end, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get surface => $composableBuilder(
      column: $table.surface, builder: (column) => ColumnFilters(column));
}

class $$MentionsTableOrderingComposer
    extends Composer<_$AppDatabase, $MentionsTable> {
  $$MentionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get chapterId => $composableBuilder(
      column: $table.chapterId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get start => $composableBuilder(
      column: $table.start, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get end => $composableBuilder(
      column: $table.end, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get surface => $composableBuilder(
      column: $table.surface, builder: (column) => ColumnOrderings(column));
}

class $$MentionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MentionsTable> {
  $$MentionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get chapterId =>
      $composableBuilder(column: $table.chapterId, builder: (column) => column);

  GeneratedColumn<int> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<int> get start =>
      $composableBuilder(column: $table.start, builder: (column) => column);

  GeneratedColumn<int> get end =>
      $composableBuilder(column: $table.end, builder: (column) => column);

  GeneratedColumn<String> get surface =>
      $composableBuilder(column: $table.surface, builder: (column) => column);
}

class $$MentionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MentionsTable,
    Mention,
    $$MentionsTableFilterComposer,
    $$MentionsTableOrderingComposer,
    $$MentionsTableAnnotationComposer,
    $$MentionsTableCreateCompanionBuilder,
    $$MentionsTableUpdateCompanionBuilder,
    (Mention, BaseReferences<_$AppDatabase, $MentionsTable, Mention>),
    Mention,
    PrefetchHooks Function()> {
  $$MentionsTableTableManager(_$AppDatabase db, $MentionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MentionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MentionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MentionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> chapterId = const Value.absent(),
            Value<int> entityId = const Value.absent(),
            Value<int> start = const Value.absent(),
            Value<int> end = const Value.absent(),
            Value<String> surface = const Value.absent(),
          }) =>
              MentionsCompanion(
            id: id,
            chapterId: chapterId,
            entityId: entityId,
            start: start,
            end: end,
            surface: surface,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int chapterId,
            required int entityId,
            required int start,
            required int end,
            Value<String> surface = const Value.absent(),
          }) =>
              MentionsCompanion.insert(
            id: id,
            chapterId: chapterId,
            entityId: entityId,
            start: start,
            end: end,
            surface: surface,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MentionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MentionsTable,
    Mention,
    $$MentionsTableFilterComposer,
    $$MentionsTableOrderingComposer,
    $$MentionsTableAnnotationComposer,
    $$MentionsTableCreateCompanionBuilder,
    $$MentionsTableUpdateCompanionBuilder,
    (Mention, BaseReferences<_$AppDatabase, $MentionsTable, Mention>),
    Mention,
    PrefetchHooks Function()>;
typedef $$EventsTableCreateCompanionBuilder = EventsCompanion Function({
  Value<int> id,
  required int projectId,
  Value<int?> chapterId,
  required String title,
  Value<String> detail,
  Value<String> participants,
  Value<int> order,
});
typedef $$EventsTableUpdateCompanionBuilder = EventsCompanion Function({
  Value<int> id,
  Value<int> projectId,
  Value<int?> chapterId,
  Value<String> title,
  Value<String> detail,
  Value<String> participants,
  Value<int> order,
});

class $$EventsTableFilterComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get chapterId => $composableBuilder(
      column: $table.chapterId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get detail => $composableBuilder(
      column: $table.detail, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get participants => $composableBuilder(
      column: $table.participants, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get order => $composableBuilder(
      column: $table.order, builder: (column) => ColumnFilters(column));
}

class $$EventsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get chapterId => $composableBuilder(
      column: $table.chapterId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get detail => $composableBuilder(
      column: $table.detail, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get participants => $composableBuilder(
      column: $table.participants,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get order => $composableBuilder(
      column: $table.order, builder: (column) => ColumnOrderings(column));
}

class $$EventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<int> get chapterId =>
      $composableBuilder(column: $table.chapterId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get detail =>
      $composableBuilder(column: $table.detail, builder: (column) => column);

  GeneratedColumn<String> get participants => $composableBuilder(
      column: $table.participants, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);
}

class $$EventsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EventsTable,
    StoryEvent,
    $$EventsTableFilterComposer,
    $$EventsTableOrderingComposer,
    $$EventsTableAnnotationComposer,
    $$EventsTableCreateCompanionBuilder,
    $$EventsTableUpdateCompanionBuilder,
    (StoryEvent, BaseReferences<_$AppDatabase, $EventsTable, StoryEvent>),
    StoryEvent,
    PrefetchHooks Function()> {
  $$EventsTableTableManager(_$AppDatabase db, $EventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> projectId = const Value.absent(),
            Value<int?> chapterId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> detail = const Value.absent(),
            Value<String> participants = const Value.absent(),
            Value<int> order = const Value.absent(),
          }) =>
              EventsCompanion(
            id: id,
            projectId: projectId,
            chapterId: chapterId,
            title: title,
            detail: detail,
            participants: participants,
            order: order,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int projectId,
            Value<int?> chapterId = const Value.absent(),
            required String title,
            Value<String> detail = const Value.absent(),
            Value<String> participants = const Value.absent(),
            Value<int> order = const Value.absent(),
          }) =>
              EventsCompanion.insert(
            id: id,
            projectId: projectId,
            chapterId: chapterId,
            title: title,
            detail: detail,
            participants: participants,
            order: order,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$EventsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EventsTable,
    StoryEvent,
    $$EventsTableFilterComposer,
    $$EventsTableOrderingComposer,
    $$EventsTableAnnotationComposer,
    $$EventsTableCreateCompanionBuilder,
    $$EventsTableUpdateCompanionBuilder,
    (StoryEvent, BaseReferences<_$AppDatabase, $EventsTable, StoryEvent>),
    StoryEvent,
    PrefetchHooks Function()>;
typedef $$ForeshadowsTableCreateCompanionBuilder = ForeshadowsCompanion
    Function({
  Value<int> id,
  required int projectId,
  required String hook,
  Value<int> plantedChapter,
  Value<int?> resolvedChapter,
  Value<String> note,
});
typedef $$ForeshadowsTableUpdateCompanionBuilder = ForeshadowsCompanion
    Function({
  Value<int> id,
  Value<int> projectId,
  Value<String> hook,
  Value<int> plantedChapter,
  Value<int?> resolvedChapter,
  Value<String> note,
});

class $$ForeshadowsTableFilterComposer
    extends Composer<_$AppDatabase, $ForeshadowsTable> {
  $$ForeshadowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hook => $composableBuilder(
      column: $table.hook, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get plantedChapter => $composableBuilder(
      column: $table.plantedChapter,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get resolvedChapter => $composableBuilder(
      column: $table.resolvedChapter,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));
}

class $$ForeshadowsTableOrderingComposer
    extends Composer<_$AppDatabase, $ForeshadowsTable> {
  $$ForeshadowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hook => $composableBuilder(
      column: $table.hook, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get plantedChapter => $composableBuilder(
      column: $table.plantedChapter,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get resolvedChapter => $composableBuilder(
      column: $table.resolvedChapter,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));
}

class $$ForeshadowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ForeshadowsTable> {
  $$ForeshadowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get hook =>
      $composableBuilder(column: $table.hook, builder: (column) => column);

  GeneratedColumn<int> get plantedChapter => $composableBuilder(
      column: $table.plantedChapter, builder: (column) => column);

  GeneratedColumn<int> get resolvedChapter => $composableBuilder(
      column: $table.resolvedChapter, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$ForeshadowsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ForeshadowsTable,
    Foreshadow,
    $$ForeshadowsTableFilterComposer,
    $$ForeshadowsTableOrderingComposer,
    $$ForeshadowsTableAnnotationComposer,
    $$ForeshadowsTableCreateCompanionBuilder,
    $$ForeshadowsTableUpdateCompanionBuilder,
    (Foreshadow, BaseReferences<_$AppDatabase, $ForeshadowsTable, Foreshadow>),
    Foreshadow,
    PrefetchHooks Function()> {
  $$ForeshadowsTableTableManager(_$AppDatabase db, $ForeshadowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ForeshadowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ForeshadowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ForeshadowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> projectId = const Value.absent(),
            Value<String> hook = const Value.absent(),
            Value<int> plantedChapter = const Value.absent(),
            Value<int?> resolvedChapter = const Value.absent(),
            Value<String> note = const Value.absent(),
          }) =>
              ForeshadowsCompanion(
            id: id,
            projectId: projectId,
            hook: hook,
            plantedChapter: plantedChapter,
            resolvedChapter: resolvedChapter,
            note: note,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int projectId,
            required String hook,
            Value<int> plantedChapter = const Value.absent(),
            Value<int?> resolvedChapter = const Value.absent(),
            Value<String> note = const Value.absent(),
          }) =>
              ForeshadowsCompanion.insert(
            id: id,
            projectId: projectId,
            hook: hook,
            plantedChapter: plantedChapter,
            resolvedChapter: resolvedChapter,
            note: note,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ForeshadowsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ForeshadowsTable,
    Foreshadow,
    $$ForeshadowsTableFilterComposer,
    $$ForeshadowsTableOrderingComposer,
    $$ForeshadowsTableAnnotationComposer,
    $$ForeshadowsTableCreateCompanionBuilder,
    $$ForeshadowsTableUpdateCompanionBuilder,
    (Foreshadow, BaseReferences<_$AppDatabase, $ForeshadowsTable, Foreshadow>),
    Foreshadow,
    PrefetchHooks Function()>;
typedef $$ParagraphsTableCreateCompanionBuilder = ParagraphsCompanion Function({
  Value<int> id,
  required int chapterId,
  required int projectId,
  required int index,
  required int start,
  required int end,
  required String content,
});
typedef $$ParagraphsTableUpdateCompanionBuilder = ParagraphsCompanion Function({
  Value<int> id,
  Value<int> chapterId,
  Value<int> projectId,
  Value<int> index,
  Value<int> start,
  Value<int> end,
  Value<String> content,
});

class $$ParagraphsTableFilterComposer
    extends Composer<_$AppDatabase, $ParagraphsTable> {
  $$ParagraphsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get chapterId => $composableBuilder(
      column: $table.chapterId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get index => $composableBuilder(
      column: $table.index, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get start => $composableBuilder(
      column: $table.start, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get end => $composableBuilder(
      column: $table.end, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));
}

class $$ParagraphsTableOrderingComposer
    extends Composer<_$AppDatabase, $ParagraphsTable> {
  $$ParagraphsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get chapterId => $composableBuilder(
      column: $table.chapterId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get index => $composableBuilder(
      column: $table.index, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get start => $composableBuilder(
      column: $table.start, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get end => $composableBuilder(
      column: $table.end, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));
}

class $$ParagraphsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ParagraphsTable> {
  $$ParagraphsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get chapterId =>
      $composableBuilder(column: $table.chapterId, builder: (column) => column);

  GeneratedColumn<int> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<int> get index =>
      $composableBuilder(column: $table.index, builder: (column) => column);

  GeneratedColumn<int> get start =>
      $composableBuilder(column: $table.start, builder: (column) => column);

  GeneratedColumn<int> get end =>
      $composableBuilder(column: $table.end, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);
}

class $$ParagraphsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ParagraphsTable,
    Paragraph,
    $$ParagraphsTableFilterComposer,
    $$ParagraphsTableOrderingComposer,
    $$ParagraphsTableAnnotationComposer,
    $$ParagraphsTableCreateCompanionBuilder,
    $$ParagraphsTableUpdateCompanionBuilder,
    (Paragraph, BaseReferences<_$AppDatabase, $ParagraphsTable, Paragraph>),
    Paragraph,
    PrefetchHooks Function()> {
  $$ParagraphsTableTableManager(_$AppDatabase db, $ParagraphsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ParagraphsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ParagraphsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ParagraphsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> chapterId = const Value.absent(),
            Value<int> projectId = const Value.absent(),
            Value<int> index = const Value.absent(),
            Value<int> start = const Value.absent(),
            Value<int> end = const Value.absent(),
            Value<String> content = const Value.absent(),
          }) =>
              ParagraphsCompanion(
            id: id,
            chapterId: chapterId,
            projectId: projectId,
            index: index,
            start: start,
            end: end,
            content: content,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int chapterId,
            required int projectId,
            required int index,
            required int start,
            required int end,
            required String content,
          }) =>
              ParagraphsCompanion.insert(
            id: id,
            chapterId: chapterId,
            projectId: projectId,
            index: index,
            start: start,
            end: end,
            content: content,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ParagraphsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ParagraphsTable,
    Paragraph,
    $$ParagraphsTableFilterComposer,
    $$ParagraphsTableOrderingComposer,
    $$ParagraphsTableAnnotationComposer,
    $$ParagraphsTableCreateCompanionBuilder,
    $$ParagraphsTableUpdateCompanionBuilder,
    (Paragraph, BaseReferences<_$AppDatabase, $ParagraphsTable, Paragraph>),
    Paragraph,
    PrefetchHooks Function()>;
typedef $$ProjectTombstonesTableCreateCompanionBuilder
    = ProjectTombstonesCompanion Function({
  required String syncId,
  Value<String> title,
  Value<String> deviceId,
  required DateTime deletedAt,
  Value<int> rowid,
});
typedef $$ProjectTombstonesTableUpdateCompanionBuilder
    = ProjectTombstonesCompanion Function({
  Value<String> syncId,
  Value<String> title,
  Value<String> deviceId,
  Value<DateTime> deletedAt,
  Value<int> rowid,
});

class $$ProjectTombstonesTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectTombstonesTable> {
  $$ProjectTombstonesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get syncId => $composableBuilder(
      column: $table.syncId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$ProjectTombstonesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectTombstonesTable> {
  $$ProjectTombstonesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get syncId => $composableBuilder(
      column: $table.syncId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$ProjectTombstonesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectTombstonesTable> {
  $$ProjectTombstonesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$ProjectTombstonesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProjectTombstonesTable,
    ProjectTombstone,
    $$ProjectTombstonesTableFilterComposer,
    $$ProjectTombstonesTableOrderingComposer,
    $$ProjectTombstonesTableAnnotationComposer,
    $$ProjectTombstonesTableCreateCompanionBuilder,
    $$ProjectTombstonesTableUpdateCompanionBuilder,
    (
      ProjectTombstone,
      BaseReferences<_$AppDatabase, $ProjectTombstonesTable, ProjectTombstone>
    ),
    ProjectTombstone,
    PrefetchHooks Function()> {
  $$ProjectTombstonesTableTableManager(
      _$AppDatabase db, $ProjectTombstonesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectTombstonesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectTombstonesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectTombstonesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> syncId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
            Value<DateTime> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProjectTombstonesCompanion(
            syncId: syncId,
            title: title,
            deviceId: deviceId,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String syncId,
            Value<String> title = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
            required DateTime deletedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ProjectTombstonesCompanion.insert(
            syncId: syncId,
            title: title,
            deviceId: deviceId,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProjectTombstonesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProjectTombstonesTable,
    ProjectTombstone,
    $$ProjectTombstonesTableFilterComposer,
    $$ProjectTombstonesTableOrderingComposer,
    $$ProjectTombstonesTableAnnotationComposer,
    $$ProjectTombstonesTableCreateCompanionBuilder,
    $$ProjectTombstonesTableUpdateCompanionBuilder,
    (
      ProjectTombstone,
      BaseReferences<_$AppDatabase, $ProjectTombstonesTable, ProjectTombstone>
    ),
    ProjectTombstone,
    PrefetchHooks Function()>;
typedef $$SyncMarksTableCreateCompanionBuilder = SyncMarksCompanion Function({
  required String syncId,
  required DateTime localUpdatedAt,
  required DateTime remoteUpdatedAt,
  Value<int> rowid,
});
typedef $$SyncMarksTableUpdateCompanionBuilder = SyncMarksCompanion Function({
  Value<String> syncId,
  Value<DateTime> localUpdatedAt,
  Value<DateTime> remoteUpdatedAt,
  Value<int> rowid,
});

class $$SyncMarksTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMarksTable> {
  $$SyncMarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get syncId => $composableBuilder(
      column: $table.syncId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
      column: $table.localUpdatedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get remoteUpdatedAt => $composableBuilder(
      column: $table.remoteUpdatedAt,
      builder: (column) => ColumnFilters(column));
}

class $$SyncMarksTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMarksTable> {
  $$SyncMarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get syncId => $composableBuilder(
      column: $table.syncId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
      column: $table.localUpdatedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get remoteUpdatedAt => $composableBuilder(
      column: $table.remoteUpdatedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$SyncMarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMarksTable> {
  $$SyncMarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
      column: $table.localUpdatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get remoteUpdatedAt => $composableBuilder(
      column: $table.remoteUpdatedAt, builder: (column) => column);
}

class $$SyncMarksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncMarksTable,
    SyncMark,
    $$SyncMarksTableFilterComposer,
    $$SyncMarksTableOrderingComposer,
    $$SyncMarksTableAnnotationComposer,
    $$SyncMarksTableCreateCompanionBuilder,
    $$SyncMarksTableUpdateCompanionBuilder,
    (SyncMark, BaseReferences<_$AppDatabase, $SyncMarksTable, SyncMark>),
    SyncMark,
    PrefetchHooks Function()> {
  $$SyncMarksTableTableManager(_$AppDatabase db, $SyncMarksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> syncId = const Value.absent(),
            Value<DateTime> localUpdatedAt = const Value.absent(),
            Value<DateTime> remoteUpdatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncMarksCompanion(
            syncId: syncId,
            localUpdatedAt: localUpdatedAt,
            remoteUpdatedAt: remoteUpdatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String syncId,
            required DateTime localUpdatedAt,
            required DateTime remoteUpdatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncMarksCompanion.insert(
            syncId: syncId,
            localUpdatedAt: localUpdatedAt,
            remoteUpdatedAt: remoteUpdatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncMarksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncMarksTable,
    SyncMark,
    $$SyncMarksTableFilterComposer,
    $$SyncMarksTableOrderingComposer,
    $$SyncMarksTableAnnotationComposer,
    $$SyncMarksTableCreateCompanionBuilder,
    $$SyncMarksTableUpdateCompanionBuilder,
    (SyncMark, BaseReferences<_$AppDatabase, $SyncMarksTable, SyncMark>),
    SyncMark,
    PrefetchHooks Function()>;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  Value<String> value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsTable,
    AppSetting,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$AppDatabase, $SettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()> {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingsTable,
    AppSetting,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$AppDatabase, $SettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$ChaptersTableTableManager get chapters =>
      $$ChaptersTableTableManager(_db, _db.chapters);
  $$EntitiesTableTableManager get entities =>
      $$EntitiesTableTableManager(_db, _db.entities);
  $$RelationsTableTableManager get relations =>
      $$RelationsTableTableManager(_db, _db.relations);
  $$MentionsTableTableManager get mentions =>
      $$MentionsTableTableManager(_db, _db.mentions);
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db, _db.events);
  $$ForeshadowsTableTableManager get foreshadows =>
      $$ForeshadowsTableTableManager(_db, _db.foreshadows);
  $$ParagraphsTableTableManager get paragraphs =>
      $$ParagraphsTableTableManager(_db, _db.paragraphs);
  $$ProjectTombstonesTableTableManager get projectTombstones =>
      $$ProjectTombstonesTableTableManager(_db, _db.projectTombstones);
  $$SyncMarksTableTableManager get syncMarks =>
      $$SyncMarksTableTableManager(_db, _db.syncMarks);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
