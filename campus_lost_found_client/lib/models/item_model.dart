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
  final UserModel? user;

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
    this.user,
  });

  String get typeLabel => ItemType.labelOf(type);
  String get statusLabel => ItemStatus.labelOf(status);
  Color get statusColor => ItemStatus.colorOf(status);
  Color get typeColor => ItemType.colorOf(type);
  Color get typeBgColor => ItemType.bgColorOf(type);
  bool get isFound => type == ItemType.found;

  /// 是否已解决：寻物 FOUND（已找回）/ 招领 CLAIMED（已归还）。
  bool get isResolved => status == ItemStatus.found || status == ItemStatus.claimed;

  /// 列表卡片用的封面图。
  String get coverImage => images.isNotEmpty ? images.first : '';

  /// 详情页正文；详情缺失时回退到摘要。
  String get fullDescription =>
      (description == null || description!.isEmpty) ? summary : description!;

  /// 生成一个部分字段更新的副本，详情页标记解决后用于本地刷新。
  ItemModel copyWith({
    int? id,
    String? type,
    String? title,
    String? status,
    String? categoryName,
    String? location,
    String? summary,
    List<String>? images,
    String? lostOrFoundTime,
    String? createdAt,
    int? viewCount,
    int? claimCount,
    String? description,
    UserModel? user,
  }) {
    return ItemModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      status: status ?? this.status,
      categoryName: categoryName ?? this.categoryName,
      location: location ?? this.location,
      summary: summary ?? this.summary,
      images: images ?? this.images,
      lostOrFoundTime: lostOrFoundTime ?? this.lostOrFoundTime,
      createdAt: createdAt ?? this.createdAt,
      viewCount: viewCount ?? this.viewCount,
      claimCount: claimCount ?? this.claimCount,
      description: description ?? this.description,
      user: user ?? this.user,
    );
  }

  /// 从后端 `Item` / `ItemVo` JSON 反序列化。
  /// 字段映射：itemId→id, name→title, category→categoryName,
  /// description→summary, image(s)→images, findOrLostTime→lostOrFoundTime,
  /// createTime→createdAt, user→user（仅详情接口返回）。
  factory ItemModel.fromJson(Map<String, dynamic> json) {
    List<String> images = [];
    final imgList = json['images'];
    if (imgList is List) {
      images = imgList.map((e) => e.toString()).toList();
    } else {
      final single = json['image'];
      if (single != null && single.toString().isNotEmpty) {
        images = [single.toString()];
      }
    }
    return ItemModel(
      id: (json['itemId'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? ItemType.found,
      title: json['name'] as String? ?? '',
      status: json['status'] as String? ?? ItemStatus.seeking,
      categoryName: json['category'] as String? ?? '',
      location: json['location'] as String? ?? '',
      summary: json['description'] as String? ?? '',
      images: images,
      lostOrFoundTime: json['findOrLostTime'] as String? ?? '',
      createdAt: json['createTime'] as String? ?? '',
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      claimCount: (json['claimCount'] as num?)?.toInt() ?? 0,
      description: json['description'] as String?,
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  /// 序列化为后端 `ItemDto`，用于 `POST /items` 发布信息。
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': title,
      'category': categoryName,
      'description': summary,
      'location': location,
      'findOrLostTime': lostOrFoundTime,
      'images': images,
    };
  }
}

/// 用户信息，对应后端 com.zsp.campus.entity.User。
/// 字段名与后端 JSON 保持一致，由 Jackson 自动序列化/反序列化。
class UserModel {
  final int userId;
  final String studentId;
  final String nickname;
  final String avatar;
  final String college;
  final String grade;
  final String phone;
  final int totalPublish;
  final int totalCompleted;
  final int? status;

  // ---- 以下为前端扩展字段，后端 User 实体未提供，mock 数据使用 ----
  final int joinedDays;
  final int helpedCount;
  final bool followed;

  UserModel({
    required this.userId,
    required this.studentId,
    required this.nickname,
    this.avatar = '',
    required this.college,
    required this.grade,
    this.phone = '',
    this.totalPublish = 0,
    this.totalCompleted = 0,
    this.status,
    this.joinedDays = 0,
    this.helpedCount = 0,
    this.followed = false,
  });

  /// 进行中 = 累计发布 - 已找回。
  int get totalOngoing => totalPublish - totalCompleted;

  /// 头像占位用的首字。
  String get avatarText => nickname.isEmpty ? '?' : nickname[0];

  /// 是否有可用的头像 URL（排除空串、null 字面量等无效值）。
  bool get hasAvatar {
    if (avatar.isEmpty) return false;
    final lower = avatar.trim().toLowerCase();
    if (lower == 'null' || lower == 'none') return false;
    if (!lower.startsWith('http')) return false;
    return true;
  }

  /// 从后端 User JSON 反序列化，字段名一一对应，无需转换。
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      studentId: json['studentId'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      college: json['college'] as String? ?? '',
      grade: json['grade'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      totalPublish: (json['totalPublish'] as num?)?.toInt() ?? 0,
      totalCompleted: (json['totalCompleted'] as num?)?.toInt() ?? 0,
      status: (json['status'] as num?)?.toInt(),
    );
  }

  UserModel copyWith({
    int? userId,
    String? studentId,
    String? nickname,
    String? avatar,
    String? college,
    String? grade,
    String? phone,
    int? totalPublish,
    int? totalCompleted,
    int? status,
    int? joinedDays,
    int? helpedCount,
    bool? followed,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      studentId: studentId ?? this.studentId,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      college: college ?? this.college,
      grade: grade ?? this.grade,
      phone: phone ?? this.phone,
      totalPublish: totalPublish ?? this.totalPublish,
      totalCompleted: totalCompleted ?? this.totalCompleted,
      status: status ?? this.status,
      joinedDays: joinedDays ?? this.joinedDays,
      helpedCount: helpedCount ?? this.helpedCount,
      followed: followed ?? this.followed,
    );
  }
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
  final String peerPhone;

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
    this.peerPhone = '',
    this.message = '',
    this.read = false,
    this.createdAt = '',
  });

  String get typeLabel => NotificationType.labelOf(type);
  bool get isIncoming => direction == NotificationDirection.incoming;
  String get peerAvatarText => peerNickname.isEmpty ? '?' : peerNickname[0];
}