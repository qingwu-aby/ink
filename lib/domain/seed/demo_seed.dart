import '../../data/db/app_database.dart';
import '../text/entity_matcher.dart';

/// 首次启动时铺一个可玩的示例项目：有图谱、有正文、也故意留了一处矛盾。
abstract final class DemoSeed {
  static const projectTitle = '听雨录';

  static Future<bool> ensure(AppDatabase db) async {
    if (await db.getSetting('demo.seeded') == '1') return false;
    await _build(db);
    await db.setSetting('demo.seeded', '1');
    return true;
  }

  static Future<void> _build(AppDatabase db) async {
    final pid = await db.createProject(
      title: projectTitle,
      genre: '武侠 · 悬疑',
      synopsis: '前朝史官之子沈砚之流落洛水城，靠替人记话谋生。'
          '一册账、半页旧诏、一个不该活着的人，把他和听雨楼、玄机阁、铁衣卫一起卷进了十年前的那场火。',
      wordGoal: 120000,
    );

    Future<int> person(
      String name, {
      List<String> aliases = const [],
      String summary = '',
      int importance = 3,
      String kind = 'character',
      String status = 'alive',
      int? deathChapter,
    }) =>
        db.createEntity(
          projectId: pid,
          name: name,
          kind: kind,
          aliases: aliases,
          summary: summary,
          importance: importance,
          status: status,
          deathChapter: deathChapter,
        );

    final shen = await person('沈砚之',
        aliases: ['砚之', '沈记话'],
        summary: '前朝史官沈仲之子，靠替人记口供为生。能记住听过的每一句话，却记不清父亲死那晚的事。',
        importance: 5);
    final su = await person('苏鸢',
        aliases: ['阿鸢'],
        summary: '听雨楼账房，算账极快。实为玄机阁埋了六年的暗桩，腕上有一道自己划的旧疤。',
        importance: 5);
    final pei = await person('裴无咎',
        aliases: ['裴指挥'],
        summary: '铁衣卫指挥使。十年前那场火的点火人，也是唯一一个还想把案子翻过来的人。',
        importance: 5);
    final bai = await person('白芷',
        aliases: ['白师姐'],
        summary: '城南药铺的主人，沈砚之的师姐。用毒比用药更准，从不解释自己在等什么。',
        importance: 4);
    final gu = await person('顾长风',
        aliases: ['顾楼主'],
        summary: '听雨楼主。看似只卖酒听雨，实则替玄机阁养着一整城的耳目。',
        importance: 4);
    final liu = await person('柳三娘',
        aliases: ['三娘'],
        summary: '玄机阁阁主。知道所有人的把柄，唯独不知道自己的名字是谁给的。',
        importance: 4);
    final zhou = await person('老周',
        summary: '听雨楼跑堂。话多，记性差，可偏偏记得十年前那个雨夜有几个人上楼。',
        importance: 2,
        status: 'dead',
        deathChapter: 2);

    final luoshui = await person('洛水城', kind: 'location', summary: '三面环水，一条长街。城里所有的雨最后都落在听雨楼的瓦上。', importance: 4);
    final tingyu = await person('听雨楼', kind: 'location', aliases: ['听雨'], summary: '城中最高的酒楼，也是玄机阁的耳朵。', importance: 4);
    final xuanji = await person('玄机阁', kind: 'faction', summary: '不出面、只出手。专收别人不敢收的旧账。', importance: 4);
    final tieyi = await person('铁衣卫', kind: 'faction', aliases: ['铁衣'], summary: '先帝亲军，如今替新朝查旧案，也替新朝埋旧人。', importance: 4);
    final zhaoyu = await person('诏狱', kind: 'location', summary: '铁衣卫的地字一号。进去的人不审，只等。', importance: 2);
    final qingnang = await person('青囊书', kind: 'item', summary: '白芷的医书，夹层里藏着一页名录。', importance: 3);
    final duanshui = await person('断水刀', kind: 'item', summary: '裴无咎的佩刀。刀背刻着一个不该出现在铁衣卫刀上的字。', importance: 3);
    final tinghua = await person('听语', kind: 'concept', summary: '沈家祖传的本事：听过的话不会忘。代价是忘不掉的话会自己找上门。', importance: 3);

    Future<void> link(int from, int to, String kind, {int strength = 3, String note = '', int validFrom = 1, int? validTo}) =>
        db.upsertRelation(
          projectId: pid,
          fromId: from,
          toId: to,
          kind: kind,
          strength: strength,
          note: note,
          validFrom: validFrom,
          validTo: validTo,
        );

    await link(shen, bai, 'peer', strength: 4, note: '同门师兄妹，白芷代师授艺');
    await link(bai, shen, 'mentor', strength: 3, note: '教他辨药，也教他辨人');
    await link(shen, su, 'crush', strength: 4, note: '第一眼就记住了她算盘拨错的那一声', validFrom: 3);
    await link(su, liu, 'liege', strength: 5, note: '六年暗桩，尚未暴露');
    await link(gu, su, 'parent', strength: 4, note: '义父女，顾长风不知她的底细');
    await link(gu, liu, 'ally', strength: 4, note: '听雨楼是玄机阁的眼');
    await link(liu, pei, 'enemy', strength: 5, note: '十年前那场火的两端');
    await link(pei, shen, 'enemy', strength: 3, note: '一个要翻案，一个要被灭口', validFrom: 3);
    await link(zhou, gu, 'liege', strength: 2, note: '跑堂二十年');
    await link(pei, duanshui, 'other', strength: 4, note: '佩刀');
    await link(bai, qingnang, 'other', strength: 4, note: '托付之物');
    await link(shen, tinghua, 'other', strength: 5, note: '血脉');
    await link(shen, luoshui, 'other', strength: 2, note: '客居');
    await link(tingyu, luoshui, 'other', strength: 3, note: '城中制高点');
    await link(pei, zhaoyu, 'liege', strength: 4, note: '主事');
    await link(pei, tieyi, 'liege', strength: 5, note: '指挥使');
    await link(liu, xuanji, 'liege', strength: 5, note: '阁主');
    await link(xuanji, tingyu, 'other', strength: 3, note: '以酒楼为耳目');
    await link(tieyi, zhaoyu, 'other', strength: 4, note: '所辖');

    final ch1 = await db.createChapter(
      projectId: pid,
      title: '第一章 洛水夜雨',
      body: '洛水城的雨下了三日。\n\n'
          '沈砚之坐在听雨楼二楼靠窗的位置，面前的茶早就凉透了。他不喝茶，只记人说话。这是他父亲教他的本事：听来的话，比写在纸上的真。\n\n'
          '楼下跑堂的老周正跟人争一枚铜钱，嗓门大得整条街都听得见。沈砚之听着，忽然在袖中摸到半页纸——那是他父亲留下的旧诏，只剩半页，边角焦黑。\n\n'
          '楼梯响了一声。苏鸢抱着账册上来，算盘珠子撞在一起，清脆得像雨点砸在瓦上。她在他斜对面坐下，翻开账册，第一笔就拨错了。\n'
          '「沈先生，」她头也不抬，「顾楼主让你今夜别回住处。」\n\n'
          '沈砚之抬眼看她。雨光从窗棂漏进来，照见她腕上一道旧疤。',
    );

    final ch2 = await db.createChapter(
      projectId: pid,
      title: '第二章 城南药铺',
      body: '白芷在城南的药铺里等他，桌上摊着那本青囊书。\n\n'
          '「你袖子里那半页东西，」她说，「最好烧了。」\n\n'
          '沈砚之没答。他记得父亲死那晚也下着雨，火光把半座城照成白天。他记得所有人说的话，唯独那一夜，什么都听不见。\n\n'
          '天快亮时，老周死在听雨楼后巷，死得很安静，手里还攥着那枚铜钱。\n\n'
          '裴无咎来的时候没带随从，只带了断水刀。他站在后巷口看了一会儿，说：「让沈先生来认认，这人昨晚上楼时说了什么。」',
    );

    final ch3 = await db.createChapter(
      projectId: pid,
      title: '第三章 断水',
      body: '铁衣卫的人把后巷围了三层。\n\n'
          '老周端着一壶热酒走过来，笑着说沈先生你总算回来了——沈砚之的后背瞬间凉透。他分明记得这个人已经死了，可眼前的手是热的，酒气是真的。\n\n'
          '苏鸢不知何时站在他身侧，把那壶酒接了过去，腕上旧疤在灯下泛白。她低声说：「别问，先记。」\n\n'
          '裴无咎拔刀时，刀背上的那个字晃了一下。沈砚之听见自己心里有个声音在念，念的是那半页旧诏上残存的三个字。\n\n'
          '那一刻他忽然明白，苏鸢一直在等他把这三个字听全。',
    );

    await db.createForeshadow(
      projectId: pid,
      hook: '沈砚之袖中那半页烧焦的旧诏',
      plantedChapter: 1,
      note: '残存三个字，可能指向那位"不该活着的人"',
    );
    await db.createForeshadow(
      projectId: pid,
      hook: '苏鸢腕上的旧疤是怎么来的',
      plantedChapter: 1,
      resolvedChapter: 3,
      note: '是她自己划的，为了记住暗桩编号',
    );
    await db.createForeshadow(
      projectId: pid,
      hook: '断水刀背上刻的那个字',
      plantedChapter: 2,
      note: '铁衣卫的刀不该有的字',
    );

    // 正文索引：把实体提及写进库，图谱的「出现次数」才有数据
    final entities = await db.entitiesOf(pid);
    final matcher = EntityMatcher(entities);
    for (final chapter in [ch1, ch2, ch3]) {
      final row = await db.getChapter(chapter);
      if (row == null) continue;
      await db.replaceMentions(chapter, matcher.scan(row.body));
      await db.reindexParagraphs(chapterId: chapter, projectId: pid, body: row.body);
    }
  }
}
