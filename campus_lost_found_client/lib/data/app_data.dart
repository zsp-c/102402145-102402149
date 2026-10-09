import 'package:flutter/material.dart';
import '../models/item_model.dart';

/// 本地 mock 数据，字段结构对齐 apifox_openapi.json。
/// 后续接入后端时，这里替换为 `ApiResponse.data` 的反序列化结果即可。
class AppData {
  /// `GET /categories`
  static final List<CategoryModel> categories = [
    CategoryModel(id: 1, name: '证件卡类', icon: Icons.badge, color: const Color(0xFFE8794F), bgColor: const Color(0xFFFFE8DD)),
    CategoryModel(id: 2, name: '数码电子', icon: Icons.laptop_windows_rounded, color: const Color(0xFF2DB8A3), bgColor: const Color(0xFFD8F3EE)),
    CategoryModel(id: 3, name: '钥匙门卡', icon: Icons.key, color: const Color(0xFFE6A23C), bgColor: const Color(0xFFFFF4DB)),
    CategoryModel(id: 4, name: '箱包', icon: Icons.backpack_rounded, color: const Color(0xFF6B7FE3), bgColor: const Color(0xFFE1E5FB)),
    CategoryModel(id: 5, name: '水杯水壶', icon: Icons.local_cafe_rounded, color: const Color(0xFFE879A8), bgColor: const Color(0xFFFFE1EC)),
    CategoryModel(id: 6, name: '手表饰品', icon: Icons.watch_rounded, color: const Color(0xFF4DA6E8), bgColor: const Color(0xFFDCEEFB)),
    CategoryModel(id: 7, name: '耳机音频', icon: Icons.headphones_rounded, color: const Color(0xFF9B6BE3), bgColor: const Color(0xFFEADFFB)),
    CategoryModel(id: 8, name: '其他物品', icon: Icons.apps_rounded, color: const Color(0xFF8A8F99), bgColor: const Color(0xFFECEEF1)),
  ];

  static CategoryModel categoryByName(String name) =>
      categories.firstWhere((c) => c.name == name, orElse: () => categories.last);

  /// `GET /items` —— 首页「最新信息」列表（ItemListItem 结构）。
  static final List<ItemModel> latestItems = [
    ItemModel(
      id: 1,
      type: ItemType.found,
      title: '黑色 AirPods Pro 充电盒',
      status: ItemStatus.pending,
      categoryName: '数码电子',
      location: '图书馆 3F 自习区',
      summary: '外壳有透明保护套，充电盒左上角有轻微划痕',
      images: ['https://images.unsplash.com/photo-1600294037681-c80b4cb5b434?w=400&q=80'],
      lostOrFoundTime: '今天 09:20',
      createdAt: '今天 09:20',
      viewCount: 268,
    ),
    ItemModel(
      id: 2,
      type: ItemType.lost,
      title: '校园一卡通丢失，姓名信息已打码',
      status: ItemStatus.seeking,
      categoryName: '证件卡类',
      location: '第二食堂 2 号窗口',
      summary: '卡面贴有蓝色小恐龙贴纸，背面写了宿舍号',
      images: ['https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=400&q=80'],
      lostOrFoundTime: '今天 08:05',
      createdAt: '今天 08:05',
      viewCount: 145,
    ),
    ItemModel(
      id: 3,
      type: ItemType.found,
      title: '一串钥匙带蓝色小熊挂件',
      status: ItemStatus.pending,
      categoryName: '钥匙门卡',
      location: '体育馆更衣室 A 区',
      summary: '钥匙共有三把，其中一把是金色铜钥匙',
      images: ['https://images.unsplash.com/photo-1582139329536-e7284fece509?w=400&q=80'],
      lostOrFoundTime: '昨天 21:40',
      createdAt: '昨天 21:40',
      viewCount: 89,
    ),
    ItemModel(
      id: 4,
      type: ItemType.lost,
      title: '银色卡西欧电子表',
      status: ItemStatus.seeking,
      categoryName: '手表饰品',
      location: '田径场东侧看台',
      summary: '表带有使用痕迹，表盘右侧有一小块磕碰',
      images: ['https://images.unsplash.com/photo-1524805444758-089113d48a6d?w=400&q=80'],
      lostOrFoundTime: '前天 19:55',
      createdAt: '前天 19:55',
      viewCount: 112,
    ),
  ];

  /// `GET /items/{id}` —— 详情页（ItemDetail 结构，含多图与发布者）。
  static final ItemModel detailItem = ItemModel(
    id: 1,
    type: ItemType.found,
    title: '黑色 AirPods Pro 充电盒，图书馆三楼捡到',
    status: ItemStatus.pending,
    categoryName: '数码电子',
    location: '图书馆三楼自习区',
    summary: '在靠窗自习区插座旁捡到一个 AirPods Pro 充电盒，已交至图书馆一楼服务台。',
    images: [
      'https://images.unsplash.com/photo-1600294037681-c80b4cb5b434?w=800&q=80',
      'https://images.unsplash.com/photo-1588423771073-b8903fbb85b5?w=800&q=80',
      'https://images.unsplash.com/photo-1572569511254-d8f925fe2cbb?w=800&q=80',
    ],
    lostOrFoundTime: '2026-09-27 09:20',
    createdAt: '2026-09-27 09:20',
    viewCount: 268,
    claimCount: 3,
    description: '今天上午在图书馆三楼靠窗自习区整理桌面时，在靠墙的插座旁发现这个充电盒。'
        '盒子外面套着一层透明硅胶保护套，左上角有一道明显的划痕，盒盖内侧贴了一张很小的卡通贴纸。'
        '目前已经交到图书馆一楼服务台代为保管，失主可凭校园卡前往核对认领。',
    user: UserModel(
      userId: 1,
      studentId: '2024****37',
      nickname: '林小满',
      college: '信电学院',
      grade: '大二',
      phone: '138****6621',
      followed: true,
      totalPublish: 7,
      helpedCount: 5,
    ),
  );

  /// `GET /items/my` —— 我的发布列表。
  static final List<ItemModel> myPublishedItems = [
    ItemModel(
      id: 101,
      type: ItemType.lost,
      title: '黑色 AirPods Pro 充电盒',
      status: ItemStatus.seeking,
      categoryName: '数码电子',
      location: '图书馆三楼自习区',
      summary: '图书馆三楼自习区发布',
      images: ['https://images.unsplash.com/photo-1600294037681-c80b4cb5b434?w=400&q=80'],
      lostOrFoundTime: '今天 09:20',
      createdAt: '今天 09:20',
      viewCount: 26,
      claimCount: 5,
    ),
    ItemModel(
      id: 102,
      type: ItemType.lost,
      title: '银色卡西欧电子表',
      status: ItemStatus.seeking,
      categoryName: '手表饰品',
      location: '田径场东侧看台',
      summary: '田径场东侧看台发布',
      images: ['https://images.unsplash.com/photo-1524805444758-089113d48a6d?w=400&q=80'],
      lostOrFoundTime: '前天 19:55',
      createdAt: '前天 19:55',
      viewCount: 14,
      claimCount: 2,
    ),
    ItemModel(
      id: 103,
      type: ItemType.found,
      title: '一串钥匙带蓝色小熊挂件',
      status: ItemStatus.pending,
      categoryName: '钥匙门卡',
      location: '体育馆更衣室 A 区',
      summary: '体育馆更衣室发布',
      images: ['https://images.unsplash.com/photo-1582139329536-e7284fece509?w=400&q=80'],
      lostOrFoundTime: '昨天 21:40',
      createdAt: '昨天 21:40',
      viewCount: 9,
      claimCount: 1,
    ),
    ItemModel(
      id: 104,
      type: ItemType.lost,
      title: '白色保温杯（已找回）',
      status: ItemStatus.found,
      categoryName: '水杯水壶',
      location: '第一教学楼 302',
      summary: '已在教学楼管理员处找回',
      images: ['https://images.unsplash.com/photo-1517256064527-09c73fc73e38?w=400&q=80'],
      lostOrFoundTime: '3 天前',
      createdAt: '3 天前',
      viewCount: 41,
      claimCount: 0,
    ),
  ];

  /// `GET /search/history`
  static final List<String> searchHistory = ['学生证', '操场', '充电线'];

  /// `GET /users/me` —— 当前登录用户。
  /// 登录成功后由 AuthService 覆盖为后端返回的真实用户。
  /// 使用 ValueNotifier 以便资料修改后各页面自动刷新。
  static final ValueNotifier<UserModel> currentUser = ValueNotifier(UserModel(
    userId: 1,
    studentId: '2024****37',
    nickname: '林小满',
    college: '信电学院',
    grade: '大二',
    phone: '138****6621',
    joinedDays: 213,
    totalPublish: 7,
    totalCompleted: 3,
    helpedCount: 5,
    followed: true,
  ));

  /// `GET /users/{userId}` —— 详情页发布者对应的完整用户资料。
  static final UserModel otherUser = UserModel(
    userId: 2,
    studentId: '2023****18',
    nickname: '陈昊',
    college: '机械学院',
    grade: '大三',
    phone: '159****3308',
    joinedDays: 428,
    totalPublish: 12,
    totalCompleted: 9,
    helpedCount: 21,
    followed: false,
  );

  /// 某用户发布过的信息（学生详情页用）。
  static final List<ItemModel> otherUserItems = [
    ItemModel(
      id: 201,
      type: ItemType.found,
      title: '黑色 AirPods Pro 充电盒',
      status: ItemStatus.pending,
      categoryName: '数码电子',
      location: '图书馆三楼自习区',
      summary: '在靠窗自习区插座旁捡到，已交至一楼服务台',
      images: ['https://images.unsplash.com/photo-1600294037681-c80b4cb5b434?w=400&q=80'],
      lostOrFoundTime: '2 天前',
      createdAt: '2 天前',
      viewCount: 268,
      claimCount: 3,
    ),
    ItemModel(
      id: 202,
      type: ItemType.lost,
      title: '银色卡西欧电子表',
      status: ItemStatus.seeking,
      categoryName: '手表饰品',
      location: '田径场东侧看台',
      summary: '表盘右侧有一小块磕碰，捡到请联系',
      images: ['https://images.unsplash.com/photo-1524805444758-089113d48a6d?w=400&q=80'],
      lostOrFoundTime: '5 天前',
      createdAt: '5 天前',
      viewCount: 112,
    ),
  ];

  /// `GET /stats/home`
  static final HomeStatsModel homeStats = HomeStatsModel(
    totalItems: 1284,
    helpedCount: 83,
    todayNew: 12,
  );

  /// `GET /notifications` —— 消息通知。
  /// 「联系 TA」发送后会往这里追加一条 OUT 记录。
  static final List<NotificationModel> notifications = [
    NotificationModel(
      id: 9001,
      type: NotificationType.contact,
      direction: NotificationDirection.incoming,
      itemId: 101,
      itemTitle: '黑色 AirPods Pro 充电盒',
      peerNickname: '陈昊',
      peerCollege: '机械学院',
      peerGrade: '大三',
      peerStudentId: '2023****18',
      peerPhone: '138****6621',
      message: '同学你好，我上周在图书馆丢过一个同款，方便的话想核对一下划痕位置。',
      createdAt: '今天 10:12',
    ),
    NotificationModel(
      id: 9002,
      type: NotificationType.contact,
      direction: NotificationDirection.incoming,
      itemId: 102,
      itemTitle: '银色卡西欧电子表',
      peerNickname: '周雨桐',
      peerCollege: '外国语学院',
      peerGrade: '大一',
      peerStudentId: '2025****64',
      peerPhone: '159****3308',
      message: '请问表带内侧有没有刻字？我丢的那只有。',
      read: true,
      createdAt: '昨天 19:38',
    ),
    NotificationModel(
      id: 9003,
      type: NotificationType.system,
      direction: NotificationDirection.incoming,
      itemId: 103,
      itemTitle: '一串钥匙带蓝色小熊挂件',
      peerNickname: '系统通知',
      message: '你发布的信息已被 3 位同学浏览，继续保持～',
      read: true,
      createdAt: '前天 09:00',
    ),
  ];

  /// 未读数。
  static int get unreadCount => notifications.where((e) => !e.read).length;
}