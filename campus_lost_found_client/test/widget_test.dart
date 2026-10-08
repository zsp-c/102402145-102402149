import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_lost_found_client/data/app_data.dart';
import 'package:campus_lost_found_client/main.dart';
import 'package:campus_lost_found_client/models/item_model.dart';
import 'package:campus_lost_found_client/screens/detail_page.dart';
import 'package:campus_lost_found_client/screens/my_publish_page.dart';
import 'package:campus_lost_found_client/screens/notifications_page.dart';
import 'package:campus_lost_found_client/screens/publish_page.dart';
import 'package:campus_lost_found_client/screens/search_page.dart';
import 'package:campus_lost_found_client/screens/user_profile_page.dart';
import 'package:campus_lost_found_client/services/api_service.dart';

void main() {
  // 测试环境下模拟已登录，使 CampusLostFoundApp 直接进入首页。
  ApiConfig.token = 'test-token';

  /// 底部栏上的文字（页面标题可能同名，需限定在 BottomAppBar 内查找）。
  Finder navLabel(String text) =>
      find.descendant(of: find.byType(BottomAppBar), matching: find.text(text));

  /// 主页面「最新信息」的筛选 Tab。卡片上也有「招领 / 寻物」标签，
  /// 故先由唯一的「全部」定位到 Tab 所在的那一行。
  Finder latestTab(String label) {
    final row = find.ancestor(of: find.text('全部'), matching: find.byType(Row)).first;
    return find.descendant(of: row, matching: find.text(label));
  }

  IndexedStack stack(WidgetTester tester) =>
      tester.widget<IndexedStack>(find.byType(IndexedStack));

  /// 中间的发布按钮（MyPublishPage 的 AppBar 里也有一个 +，故按类型定位）。
  final fab = find.byType(FloatingActionButton);

  group('底部栏与主页面', () {
    testWidgets('底部栏只保留 首页 / 我的发布，中间是 + 按钮', (WidgetTester tester) async {
      await tester.pumpWidget(const CampusLostFoundApp());
      await tester.pump();

      expect(navLabel('首页'), findsOneWidget);
      expect(navLabel('我的发布'), findsOneWidget);
      expect(navLabel('搜索'), findsNothing);
      expect(navLabel('最新信息'), findsNothing);
      expect(fab, findsOneWidget);
    });

    testWidgets('主页面直接展示「最新信息」，且两个旧模块已移除', (WidgetTester tester) async {
      await tester.pumpWidget(const CampusLostFoundApp());
      await tester.pump();

      expect(stack(tester).index, 0);
      expect(find.text('最新信息'), findsOneWidget);
      expect(latestTab('全部'), findsOneWidget);
      expect(latestTab('招领'), findsOneWidget);
      expect(latestTab('寻物'), findsOneWidget);

      expect(find.textContaining('你班同学已发布'), findsNothing);
      expect(find.text('物品分类'), findsNothing);
      expect(find.text('证件卡类'), findsNothing);
    });

    testWidgets('筛选「寻物」后只剩寻物条目', (WidgetTester tester) async {
      await tester.pumpWidget(const CampusLostFoundApp());
      await tester.pump();

      const zhaolingSummary = '外壳有透明保护套，充电盒左上角有轻微划痕'; // 招领
      const xunwuSummary = '表带有使用痕迹，表盘右侧有一小块磕碰'; // 寻物

      expect(find.text(zhaolingSummary), findsOneWidget);
      expect(find.text(xunwuSummary), findsOneWidget);

      await tester.tap(latestTab('寻物'));
      await tester.pump();

      expect(find.text(zhaolingSummary), findsNothing);
      expect(find.text(xunwuSummary), findsOneWidget);
    });
  });

  group('返回逻辑', () {
    testWidgets('发布页（+）的返回箭头切回首页', (WidgetTester tester) async {
      await tester.pumpWidget(const CampusLostFoundApp());
      await tester.pump();

      await tester.tap(fab);
      await tester.pump();
      expect(stack(tester).index, 2);

      await tester.tap(find.descendant(
        of: find.byType(PublishPage),
        matching: find.byIcon(Icons.arrow_back_ios),
      ));
      await tester.pump();
      expect(stack(tester).index, 0);
    });

    testWidgets('「我的发布」页的返回箭头切回首页', (WidgetTester tester) async {
      await tester.pumpWidget(const CampusLostFoundApp());
      await tester.pump();

      await tester.tap(navLabel('我的发布'));
      await tester.pump();
      expect(stack(tester).index, 3);

      await tester.tap(find.descendant(
        of: find.byType(MyPublishPage),
        matching: find.byIcon(Icons.arrow_back_ios),
      ));
      await tester.pump();
      expect(stack(tester).index, 0);
    });

    testWidgets('搜索页（首页搜索框进入）的返回箭头切回首页', (WidgetTester tester) async {
      await tester.pumpWidget(const CampusLostFoundApp());
      await tester.pump();

      await tester.tap(find.text('搜索物品名称 / 地点 / 描述...'));
      await tester.pump();
      expect(stack(tester).index, 1);

      await tester.tap(find.descendant(
        of: find.byType(SearchPage),
        matching: find.byIcon(Icons.arrow_back_ios),
      ));
      await tester.pump();
      expect(stack(tester).index, 0);
    });
  });

  group('「我的发布」页跳转', () {
    testWidgets('右上角 + 跳到发布页', (WidgetTester tester) async {
      await tester.pumpWidget(const CampusLostFoundApp());
      await tester.pump();

      await tester.tap(navLabel('我的发布'));
      await tester.pump();
      expect(stack(tester).index, 3);

      await tester.tap(find.descendant(
        of: find.byType(MyPublishPage),
        matching: find.byIcon(Icons.add),
      ));
      await tester.pump();
      expect(stack(tester).index, 2);
    });

    testWidgets('点击用户卡片打开学生详情页', (WidgetTester tester) async {
      await tester.pumpWidget(const CampusLostFoundApp());
      await tester.pump();

      await tester.tap(navLabel('我的发布'));
      await tester.pump();

      await tester.tap(find.text(AppData.currentUser.nickname));
      await tester.pumpAndSettle();

      expect(find.byType(UserProfilePage), findsOneWidget);
      expect(find.text('学生详情'), findsOneWidget);
    });
  });

  group('物品详情页', () {
    Widget wrap(Widget child) => MaterialApp(home: child);

    testWidgets('按 ItemDetail 渲染：多图、状态、分类、保管地点、发布者', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(DetailPage(item: AppData.detailItem, isMine: true)));
      await tester.pump();

      final item = AppData.detailItem;
      expect(find.text(item.title), findsOneWidget);
      expect(find.text(item.statusLabel), findsOneWidget);
      // 分类同时出现在标题卡的标签和「物品信息」行里。
      expect(find.text(item.categoryName), findsNWidgets(2));
      // 多图角标按真实图片数量显示。
      expect(find.text('1 / ${item.images.length}'), findsOneWidget);
      expect(find.text(item.user!.nickname), findsOneWidget);
      // 自己发布的信息才有「修改」。
      expect(find.text('修改'), findsOneWidget);

      // 按要求已移除：收藏、分享、「当前保管」「认领线索」条目。
      expect(find.text('收藏'), findsNothing);
      expect(find.byIcon(Icons.share_outlined), findsNothing);
      expect(find.text('当前保管'), findsNothing);
      expect(find.text('认领线索'), findsNothing);
    });

    testWidgets('别人的信息不显示「修改」，且寻物不显示保管地点', (WidgetTester tester) async {
      final othersLost = AppData.latestItems.firstWhere((e) => e.type == 'LOST');
      await tester.pumpWidget(wrap(DetailPage(item: othersLost)));
      await tester.pump();

      expect(find.text('修改'), findsNothing);
      expect(find.text('丢失地点'), findsOneWidget);
    });
  });

  group('消息通知', () {
    testWidgets('点击首页铃铛打开消息通知页', (WidgetTester tester) async {
      await tester.pumpWidget(const CampusLostFoundApp());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.notifications_none));
      await tester.pumpAndSettle();

      expect(find.byType(NotificationsPage), findsOneWidget);
      expect(find.text('消息通知'), findsOneWidget);
      // 种子数据里的联系人应能列出。
      expect(find.text('周雨桐'), findsOneWidget);
    });

    testWidgets('「联系 TA」把自身资料发给对方并记入消息', (WidgetTester tester) async {
      final before = AppData.notifications.length;
      await tester.pumpWidget(MaterialApp(home: DetailPage(item: AppData.detailItem)));
      await tester.pump();

      await tester.tap(find.text('联系 TA 认领'));
      await tester.pumpAndSettle();

      // 弹窗中应展示即将发送的自身资料。
      expect(find.textContaining(AppData.currentUser.nickname), findsWidgets);
      expect(find.textContaining(AppData.currentUser.studentId), findsWidgets);

      await tester.tap(find.text('发送'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3)); // 让 SnackBar 自行退场

      expect(AppData.notifications.length, before + 1);
      final sent = AppData.notifications.first;
      expect(sent.direction, NotificationDirection.outgoing);
      expect(sent.itemId, AppData.detailItem.id);
      expect(sent.peerNickname, AppData.detailItem.user!.nickname);
    });
  });

  group('发布页', () {
    /// 从底部栏中间的 + 进入发布页。
    Future<void> openPublish(WidgetTester tester) async {
      await tester.pumpWidget(const CampusLostFoundApp());
      await tester.pump();
      await tester.tap(fab);
      await tester.pump();
    }

    /// 限定在发布页内查找（IndexedStack 会同时构建其它 Tab）。
    Finder inPublish(Finder matching) =>
        find.descendant(of: find.byType(PublishPage), matching: matching);

    testWidgets('已移除的控件都不存在：我的发布 / 联系方式 / 选择常用地', (WidgetTester tester) async {
      await openPublish(tester);

      // 右上角的「我的发布」入口
      expect(inPublish(find.text('我的发布')), findsNothing);
      // 「联系方式」整张卡片
      expect(inPublish(find.text('联系方式')), findsNothing);
      expect(inPublish(find.text('联系人 *')), findsNothing);
      expect(inPublish(find.text('联系电话 *')), findsNothing);
      // 地点输入框右侧的「选择常用地」
      expect(inPublish(find.text('选择常用地')), findsNothing);
    });

    testWidgets('必填项没填全时给出失败反馈', (WidgetTester tester) async {
      await openPublish(tester);

      await tester.tap(inPublish(find.text('立即发布')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('发布失败：请填写物品名称'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4)); // 让 SnackBar 退场
    });

    testWidgets('填完整后发布成功：给出反馈并跳回首页', (WidgetTester tester) async {
      await openPublish(tester);

      final fields = inPublish(find.byType(TextField));
      await tester.enterText(fields.at(0), '黑色雨伞'); // 物品名称
      await tester.enterText(fields.at(1), '伞面蓝色格子，伞柄缠了胶带'); // 详细描述

      // 分类 chips 在测试视口里可能在折叠线以下，先滚动到可见再点
      final categoryChip = inPublish(find.text('数码电子'));
      await tester.ensureVisible(categoryChip);
      await tester.pumpAndSettle();
      await tester.tap(categoryChip);
      await tester.pump();

      await tester.tap(inPublish(find.text('立即发布')));
      await tester.pump(); // 进入加载态
      await tester.pump(const Duration(milliseconds: 900)); // 等模拟请求返回
      await tester.pump(const Duration(milliseconds: 300));

      // 默认是「我丢了东西」，提示语应说「希望早日找回」而非「等待认领」
      expect(find.text('发布成功，希望早日找回'), findsOneWidget);
      // 发布成功后自动跳回首页（切 Tab 不会把提示一起带走）
      expect(stack(tester).index, 0);
      await tester.pump(const Duration(seconds: 4)); // 让 SnackBar 退场
    });

    testWidgets('「我捡到东西」发布成功后提示等待失主认领', (WidgetTester tester) async {
      await openPublish(tester);

      // 切到招领模式，提示文案应跟着变
      await tester.tap(inPublish(find.text('我捡到东西')));
      await tester.pump();
      expect(inPublish(find.textContaining('填写你捡到的物品信息')), findsOneWidget);

      final fields = inPublish(find.byType(TextField));
      await tester.enterText(fields.at(0), '黑色雨伞');
      await tester.enterText(fields.at(1), '伞面蓝色格子，伞柄缠了胶带');

      final categoryChip = inPublish(find.text('数码电子'));
      await tester.ensureVisible(categoryChip);
      await tester.pumpAndSettle();
      await tester.tap(categoryChip);
      await tester.pump();

      await tester.tap(inPublish(find.text('立即发布')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('发布成功，等待失主认领'), findsOneWidget);
      expect(stack(tester).index, 0);
      await tester.pump(const Duration(seconds: 4)); // 让 SnackBar 退场
    });
  });
}