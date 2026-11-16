# 可道 MoPu — 小说写作知识图谱

> 写作时，正文与图谱双向绑定。

## 一、定位

面向**长篇**小说作者（10 万字以上、多人物、多线索）的移动端写作工作台。
不是"AI 帮你写"，而是**帮你在 40 万字时还记得住**。

三个必须回答的问题：

1. 这两个人**现在**是什么关系？
2. 这个设定我**前面写过没**？
3. 这条线 / 这个伏笔**收了没**？

## 二、与竞品的差异

| 产品 | 图谱能力 | 短板 |
| --- | --- | --- |
| Novelcrafter Codex | 卡片 + Relations | 关系只用于 AI 上下文注入，不是给作者看的语义图谱；Web |
| World Anvil / Campfire | 世界观最全 | 重型桌面 Web，移动端不可用 |
| 墨者 / 彩云小梦 | 基本没有 | 编辑器为主，人物关系靠卷管理 |
| writeGOD | Neo4j + D3 力导向 | 需部署服务，纯 Web |
| graphify-novel / narra | AI 自动抽取 | CLI / MCP，没有图形界面 |

**空位**：移动端 + 本地优先 + 图谱是一等公民（不是侧栏附属）。

## 三、核心闭环

```
       ┌────────────────────────────────────────────┐
       │                                            │
   ┌───▼────┐   提及/建边    ┌──────────┐   规则扫描  ┌──────┐
   │  图谱  │ ─────────────► │  正文    │ ─────────► │ 校验 │
   │ 档案   │ ◄───────────── │  编辑器  │            │ 报告 │
   └────────┘   高亮/抽屉    └──────────┘            └──────┘
```

- **建图**：实体档案 + 有向关系（带类型、强度、**有效章节区间**）
- **写作**：正文中实体别名自动高亮 → 点开抽屉看档案而不离开正文
- **校验**：确定性规则引擎（不依赖 AI），输出可定位的问题列表

关键设计：`Relation` 带 `validFrom / validTo` 章节号 —— 关系是有**时间维度**的。
"第 12 章反目"不是修改关系，而是让旧关系失效、新关系生效。这是竞品普遍缺失的，
也是长篇最常见的错误来源（作者自己忘了这两个人已经翻脸）。

## 四、数据模型

```
Project  id, title, genre, synopsis, createdAt
Chapter  id, projectId, index, title, body, status(draft/revise/done), wordCount

Entity   id, projectId, type, name, aliases(json), summary, avatarColor,
         importance(1..5), status(dead/alive/unknown), deathChapter, tags(json)

Relation id, projectId, fromId, toId, type, strength(1..5), note,
         validFrom, validTo(null=至今)

Mention  id, chapterId, entityId, start, end, surface   -- 正文中的实体出现
Event    id, projectId, chapterId, timelineOrder, title, participants(json), place
Foreshadow id, projectId, hook, plantedChapter, resolvedChapter(null=未回收), note
```

实体类型：`character / location / item / faction / event / concept`
关系类型（内置，可扩展）：`亲属·父 / 亲属·子 / 夫妻 / 兄弟 / 师徒 / 主从 / 敌对 /
盟友 / 暗恋 / 前任 / 同事 / 仇人 / 同门 / 其他`

## 五、图谱视图规格

| 视图 | 说明 |
| --- | --- |
| 全局力导向图 | Barnes-Hut 四叉树近似斥力，节点半径 ∝ √degree，颜色 = 实体类型 |
| 焦点子图 | 以某实体为心取 N 跳邻居（SQLite 递归 CTE），其余淡出 |
| 关系矩阵 | 实体 × 实体 热力矩阵，快速发现"这两个人从没同框" |
| 时间轴 | 章节 × 实体出现频次，找人物断档 |
| 阵营聚类 | 弱连通分量着色，识别孤立子群 |

交互（移动端）：单指拖动 = 平移，双指 = 缩放，点节点 = 底部抽屉，
长按节点 = 进入多选，拖节点 = 手动钉住（`pinned`）。

多选批量建边：选中 N 个实体 → 指定一个中心 + 关系类型 + 方向 → 一次生成 N-1 条星型关系。
选两个时退化成普通的关系编辑器。

## 六、关系演化（时间带）

把 `validFrom / validTo` 摊到章节轴上：

- 一行一条关系，色带从 `validFrom` 画到 `validTo`（空 = 延伸到最新章，标「至今」）
- 颜色按关系类型分组：敌对朱砂 / 同盟·同门石绿 / 师徒·效忠·亲子靛青 / 倾心藕荷 / 其他赤金
- 顶部可按实体筛选（只看某个人的所有连线）
- 伏笔单独一条轨：埋点实心圆，已回收画实线 + 勾，未回收画虚线到最新章
- 点任意一行直接打开关系编辑器

章节少时可读性最好；上百章时仍能看出"哪段关系长期存在、哪段集中在中段"。

## 七、章节快照

图谱回答"现在"，时间带回答"从哪到哪"，快照回答"第 N 章那一刻"。

- **布局只算一次**：整图跑一遍力导向，坐标定死；拖动章节只做过滤，节点不会乱跳。
- **可见性**：实体在 `firstSeen(实体)` 之后才出现（正文没提过的按第 1 章算在场）；
  关系要求 `validFrom ≤ N ≤ validTo` 且两端都在场。
- **生死按章节算**：`statusAt(entity, N) = deathChapter == null ? 状态 : (deathChapter ≤ N ? 已故 : 在世)`，
  所以第 1 章的快照里，第 3 章才死的人还是活的。
- **本章变化**：登场 / 关系开始 / 关系结束 / 退场，四类各列一行。

## 八、三端同步（GitHub 私有仓库）

不做服务器，数据仍然只在本地 SQLite。仓库是搬运通道，也是版本历史。

```
SQLite ──exportLibrary──► LibraryBundle(JSON) ──Git Data API──► mopu/library.json
   ▲                                                                  │
   └──────────────── importLibrary(按 syncId + updatedAt 合并) ◄───────┘
```

- **身份**：`Projects.syncId`（v2 引入的 UUID）。本地自增 id 不跨设备，也不参与同步。
- **单位**：项目。合并规则是项目级 LWW，简单、可解释、不会半本书半本地。
- **格式**：关系用实体**名字**引用，文件在 GitHub 上可读；章节正文原文携带，
  正文提及导入时用 `EntityMatcher` 重扫，同步文件里不存位置。
- **传输**：Git Data API（blob → tree → commit → ref）而不是 Contents API——
  后者单文件 1MB 上限，一本 40 万字的书就超了。
- **并发（git 层）**：PATCH ref 带 `force: false`；冲突抛 `SyncConflictException`，
  服务层重新拉取、合并、重试一次，绝不覆盖别人的提交。
- **并发（人层）**：项目级 LWW 只在"一方动过"时安全。两边都改过同一本书，静默 LWW 会吃掉一份。
  所以引入 `SyncMarks(syncId, localUpdatedAt, remoteUpdatedAt)`——每次同步成功后记下两边水位。
  下次同步时若本地与远端都偏离水位，就**不写数据**，先把冲突报上去：
  - 用我的：抬本地 `updatedAt`，合并时自然胜出；
  - 用远端的：跳过时间戳检查，强制用远端覆盖本地；
  - 两个都留：远端那份换一个新 `syncId` 存成"（远端副本）"，本地保留并抬时间戳，两份都会推上去。
  没有水位（首次同步 / 老版本升级）时退回 LWW，不制造惊喜。
- **删除两段式**：
  - 软删除：`Projects.deletedAt` 非空。项目仍完整存在，只是书架不展示；该字段随同步走，
    所以所有设备都进各自回收站，30 天内可恢复。
  - 彻底删除：`purgeProject` 删行并写墓碑 `ProjectTombstones(syncId, title, deviceId, deletedAt)`。
    超过 30 天的回收站条目在启动时自动走到这一步（`purgeExpiredTrash`）。
  墓碑决定跨设备一致性，合并规则与项目合并同构，都是比时间：
  - 本地 `updatedAt ≤ deletedAt` → 跟着删
  - 本地 `updatedAt > deletedAt` → 保留并清墓碑（编辑晚于删除即复活）
  - 远端项目 `updatedAt ≤ deletedAt` → 不导入，避免复活
  - 墓碑本身随同步文件传播，导出时只带一年内的。
- **触发**：手动按钮 + 「打开 App / 回到前台时检查，满 24 小时才连网」，
  失败节流一小时。不引入 WorkManager/BGTaskScheduler：三端各一套，且系统不保证执行。
- **密钥**：Token 进系统钥匙串，读不到时退回本地设置表；仓库地址与分支存普通设置。

## 九、正文检索

写到四十万字时，作者真正要的不是"再给我一个视图"，而是"那句话我在哪儿写过"。

- **段落表**：`Paragraphs(chapterId, projectId, index, start, end, content)`。
  保存正文时增量重建（和提及索引同一时机），老库在启动时一次性补建。
- **为什么不引入 FTS5**：段落就是最小检索单位，几十万字的段落表用 `LIKE` 扫仍是毫秒级；
  而中文分词对自造姓名、门派名的召回率远不如"实体词典 + 原文扫描"。
  `%` / `_` 会被转义，用户搜 "50%" 不会被当成通配符。
- **按实体聚合**：`paragraphs JOIN mentions ON m.start >= p.start AND m.end <= p.end`。
  段落区间存的是章节内偏移，所以能精确接上提及。
- **点结果回原文**：结果带回 `start`，编辑器用 `?at=` 接住，聚焦并把光标放到命中段，
  `EditableText` 会自动把光标滚进视野。
- **结果即线索**：每条结果都用提及的区间归属算出「这一段里有谁」，
  再筛出「该章仍然生效」的关系（`validFrom ≤ N ≤ validTo` 且沾到本段任一人）。
  一批结果一次算完存进 state，不在每帧 build 里重算。
  这样检索不只是找字，而是直接把读者拉回图谱上下文——这是别的工具做不到的。

## 十、写作提示

校对找的是**矛盾**，写作提示找的是**空档**——两类问题混在一起，作者会疲。

| 规则 | 判据 | 为什么值得提 |
| --- | --- | --- |
| 关系没写出来 | 关系 `strength ≥ 3` 且已生效，但两人从未在同一章出现 | 档案里写着敌对，正文里却没打过照面 |
| 角色长期缺席 | `importance ≥ 4`、露过面、距最新章 ≥ 5 章、且还没写死 | 重要的人消失太久，读者会忘了他为什么重要 |
| 档案没派上用场 | `importance ≥ 3` 但零提及 | 建了档却没用，要么用起来要么删掉 |
| 同场多次却没连线 | 同一章同时出现 ≥ 2 次，且两者之间没有任何关系 | 反复同框却不认识，多半是漏了关系 |

全部是确定性计算，不做语义猜测；结果按"值得先动"排序（关系强度 / 缺席章数 / 重要度 / 同场次数）。

## 十一、导出

| 格式 | 内容 | 备注 |
| --- | --- | --- |
| TXT | 书名 + 章节标题 + 正文 | 标题已带「第X章」时不重复编号 |
| Markdown | 书名、简介、`##` 章节 | 可直接进 Obsidian / 笔记软件 |
| 实体表 CSV | 类型、别称、状态、关系数、出现次数 | 带 BOM，Excel 不乱码 |
| 关系表 CSV | 从、关系、到、亲疏、起始章、结束章、备注 | 类型翻成中文 |
| 伏笔表 CSV | 伏笔、埋于、回收于、状态 | |
| 图谱 PNG | 1400×1000 @2x，带书名与统计 | 独立布局实例，不干扰屏幕状态 |

保存走 `FilePicker.saveFile`（系统「另存为」）；拿不到 SAF 时退回应用文档目录，不静默失败。

## 十二、校验规则（确定性，可单测）

| ID | 规则 | 级别 |
| --- | --- | --- |
| R1 | 死亡后出场：`status=dead` 且 mention 出现在 `deathChapter` 之后 | 错误 |
| R2 | 关系倒挂：`validFrom > validTo` | 错误 |
| R3 | 别名冲突：两个实体共享 name/alias | 错误 |
| R4 | 关系未立先同场：首次同场章节 < 关系 `validFrom` | 警告 |
| R5 | 伏笔超期未收：`plantedChapter < 最新章 - 3` 且未回收 | 警告 |
| R6 | 孤儿实体：既无关系也无提及 | 提示 |
| R7 | 首次登场倒挂：`mention` 早于实体建档章节 | 提示 |

健康度 = 100 - Σ(错误×8 + 警告×3 + 提示×1)，下限 0。

## 十三、技术架构

```
lib/
  main.dart
  app.dart                     # MaterialApp.router + 主题
  core/
    theme/                     # 墨色主题、类型色板、字体
    router/                    # go_router
    widgets/                   # 通用组件
  data/
    db/app_database.dart       # Drift 表定义 + 迁移
    db/*_dao.dart              # 查询（含递归 CTE）
    repositories/              # 数据层门面（可替换）
  domain/
    models/                    # 领域模型
    graph/                     # 力导向布局、四叉树、连通分量
    lint/                      # 规则引擎
    llm/                       # LLM 抽取与一致性检查（可关）
    import/                    # txt/md 分章
  features/
    library/  entities/  relations/  graph/  editor/  lint/  settings/  import/
```

- **Flutter 3.50 / Dart 3.10**，Material 3，`flutter_riverpod ^3.5`，`go_router ^18`
- **Drift + SQLite**：递归 CTE 做 N 跳子图；正文检索用 LIKE（实体词典本身已足够精确，暂不引入分词/FTS5）
- 图谱渲染：`CustomPainter` 自研力导向（四叉树斥力 + 弹簧引力 + 冷却）
- 正文高亮：自定义 `TextEditingController.buildTextSpan`，别名正则一次性扫描
- 三端布局：`< 720dp` 底部导航 + 抽屉；`>= 720dp` NavigationRail + 双栏；`>= 1200dp` 三栏

## 十四、性能预算

| 场景 | 目标 |
| --- | --- |
| 500 节点图布局 | 每帧 < 8ms（四叉树），静止后停 ticker |
| 1 万字章节输入 | 每次击键重算高亮 < 3ms |
| 冷启动到书架 | < 800ms |

## 十五、明确的取舍

- **不做**云同步、账号、协作（第一版）
- **不做**富文本（Markdown 语法即可），长文性能优先
- **不做** docx / epub 排版导出：作者最终会去专门的排版工具，这里只保证"东西带得走"
- **不做**实时协作同步：GitHub 仓库是文件级同步，够一个人三台设备用，不做多端光标级协同
- **不做**章级冲突合并：冲突时较新的项目整体胜出，并明确告知
- 回收站不做"每章回收"：颗粒度是整本书，章级删除仍要重新写
- **AI 抽取是实验特性**，默认关闭，失败不影响主流程
- 中文分词不做，用**别名全量匹配**（自带词典 = 实体表），命中率高且完全可控
