import 'package:flutter/material.dart';

/// 物品分类，对应接口文档 `Category`。
class CategoryModel {
  final int id;
  final String name;
  final IconData icon;
  final Color color;
  final Color bgColor;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}

/// 信息类型，对应接口文档 `type` 字段（LOST-寻物 / FOUND-招领）。
class ItemType {
  const ItemType._();

  static const String lost = 'LOST';
  static const String found = 'FOUND';

  static String labelOf(String type) => type == found ? '招领' : '寻物';

  /// 招领用橙色、寻物用青色，与全局主色保持一致。
  static Color colorOf(String type) =>
      type == found ? const Color(0xFFFF7A2E) : const Color(0xFF2DB8A3);

  static Color bgColorOf(String type) =>
      type == found ? const Color(0xFFFFE8DD) : const Color(0xFFE8F8F5);
}

/// 信息状态，对应接口文档 `status` 字段。
/// SEEKING-寻找中 / FOUND-已找回 / PENDING-待认领 / CLAIMED-已归还
class ItemStatus {
  const ItemStatus._();

  static const String seeking = 'SEEKING';
  static const String found = 'FOUND';
  static const String pending = 'PENDING';
  static const String claimed = 'CLAIMED';

  static String labelOf(String status) {
    switch (status) {
      case seeking:
        return '寻找中';
      case found:
        return '已找回';
      case pending:
        return '待认领';
      case claimed:
        return '已归还';
      default:
        return status;
    }
  }

  static Color colorOf(String status) {
    switch (status) {
      case seeking:
        return const Color(0xFF2DB8A3);
      case pending:
        return const Color(0xFFFF8A5C);
      case found:
      case claimed:
        return const Color(0xFF4B5563);
      default:
        return const Color(0xFF9CA3AF);
    }
  }
}

/// 发布者公开信息，对应接口文档 `PublisherInfo`。
class PublisherModel {
  final int id;
  final String nickname;
  final String avatar;
  final String college;
  final String grade;
  final bool followed;
  final int totalPublished;
  final int helpedCount;

  PublisherModel({
    required this.id,
    required this.nickname,
    this.avatar = '',
    required this.college,
    required this.grade,
    this.followed = false,
    this.totalPublished = 0,
    this.helpedCount = 0,
  });
}

/// 信息条目，覆盖接口文档的 `ItemListItem`（列表）与 `ItemDetail`（详情）。
class ItemModel {
  final int id;
  final String type; // LOST / FOUND
  final String title;
  final String status; // SEEKING / FOUND / PENDING / CLAIMED
  final String categoryName;
  final String location;

  /// 描述摘要（列表接口返回 `summary`）。
  final String summary;
  final List<String> images;
  final String lostOrFoundTime;
  final String createdAt;
  final int viewCount;

  /// 认领线索数（「我的发布」列表返回 `claimCount`）。
  final int claimCount;

  // ---- 以下仅详情接口 `ItemDetail` 返回 ----
  final String? description;
  final PublisherModel? publisher;

  ItemModel({
    required this.id,
    required this.type,
    required this.title,
    required this.status,
    required this.categoryName,
    required this.location,
    this.summary = '',
    this.images = const [],
    this.lostOrFoundTime = '',
    this.createdAt = '',
    this.viewCount = 0,
    this.claimCount = 0,
    this.description,
    this.publisher,
  });

  String get typeLabel => ItemType.labelOf(type);
  String get statusLabel => ItemStatus.labelOf(status);
  Color get statusColor => ItemStatus.colorOf(status);
  Color get typeColor => ItemType.colorOf(type);
  Color get typeBgColor => ItemType.bgColorOf(type);
  bool get isFound => type == ItemType.found;

  /// 列表卡片用的封面图。
  String get coverImage => images.isNotEmpty ? images.first : '';

  /// 详情页正文；详情缺失时回退到摘要。
  String get fullDescription =>
      (description == null || description!.isEmpty) ? summary : description!;
}

/// 用户信息，对应接口文档 `UserInfo`。
class UserModel {
  final int id;
  final String studentId; // 脱敏学号
  final String nickname;
  final String avatar;
  final String college;
  final String grade;
  final int joinedDays;
  final int totalPublished;
  final int totalOngoing;
  final int totalResolved;
  final int helpedCount; // 已帮助人数
  final bool followed; // 当前用户是否已关注

  UserModel({
    required this.id,
    required this.studentId,
    required this.nickname,
    this.avatar = '',
    required this.college,
    required this.grade,
    this.joinedDays = 0,
    this.totalPublished = 0,
    this.totalOngoing = 0,
    this.totalResolved = 0,
    this.helpedCount = 0,
    this.followed = false,
  });

  /// 头像占位用的首字。
  String get avatarText => nickname.isEmpty ? '?' : nickname[0];
}

/// 首页顶部统计，对应接口文档 `HomeStats`。
class HomeStatsModel {
  final int totalItems;
  final int helpedCount;
  final int todayNew;

  HomeStatsModel({
    required this.totalItems,
    required this.helpedCount,
    required this.todayNew,
  });
}

/// 热门搜索词，对应接口文档 `HotWord`。
class HotWordModel {
  final String word;
  final int heat;
  final String icon;

  HotWordModel({
    required this.word,
    this.heat = 0,
    this.icon = '',
  });
}

/// 消息类型，对应接口文档 `Notification.type`。
class NotificationType {
  const NotificationType._();

  static const String contact = 'CONTACT'; // 认领 / 线索联系
  static const String system = 'SYSTEM'; // 系统通知

  static String labelOf(String type) => type == system ? '系统通知' : '认领联系';
}

/// 消息方向：IN-收到 / OUT-发出。
class NotificationDirection {
  const NotificationDirection._();

  static const String incoming = 'IN';
  static const String outgoing = 'OUT';
}

/// 消息通知，对应接口文档 `Notification`。
///
/// 「联系 TA」会把当前用户的资料发给信息发布者，双方各产生一条记录：
/// 发布者侧为 IN，发送者侧为 OUT。
class NotificationModel {
  final int id;
  final String type; // CONTACT / SYSTEM
  final String direction; // IN / OUT
  final int itemId;
  final String itemTitle;

  /// 对方（IN 时是发送者，OUT 时是接收者）。
  final String peerNickname;
  final String peerCollege;
  final String peerGrade;
  final String peerStudentId;

  /// 附言。
  final String message;

  bool read;
  final String createdAt;

  NotificationModel({
    required this.id,
    this.type = NotificationType.contact,
    this.direction = NotificationDirection.incoming,
    required this.itemId,
    required this.itemTitle,
    required this.peerNickname,
    this.peerCollege = '',
    this.peerGrade = '',
    this.peerStudentId = '',
    this.message = '',
    this.read = false,
    this.createdAt = '',
  });

  String get typeLabel => NotificationType.labelOf(type);
  bool get isIncoming => direction == NotificationDirection.incoming;
  String get peerAvatarText => peerNickname.isEmpty ? '?' : peerNickname[0];
}
