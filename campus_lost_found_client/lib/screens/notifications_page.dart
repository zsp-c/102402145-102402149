import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../models/item_model.dart';

/// 消息通知页，对应接口文档 `GET /notifications`。
/// 由首页右上角铃铛进入；「联系 TA」发出的联系申请也会出现在这里。
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<NotificationModel> get _items => AppData.notifications;

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            ),
            const Spacer(),
            const Text('消息通知'),
            const Spacer(),
            GestureDetector(
              onTap: _markAllRead,
              child: const Text('全部已读',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
      body: items.isEmpty
          ? _buildEmpty()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildCard(items[index]),
            ),
    );
  }

  void _markAllRead() {
    setState(() {
      for (final n in _items) {
        n.read = true;
      }
    });
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 12),
          const Text('暂无消息', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildCard(NotificationModel n) {
    final isSystem = n.type == NotificationType.system;
    return GestureDetector(
      onTap: () => setState(() => n.read = true),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // 未读用左侧色条标记。
          border: Border(
            left: BorderSide(
              color: n.read ? Colors.transparent : const Color(0xFFFF7A2E),
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSystem ? const Color(0xFFF3F4F6) : const Color(0xFFFFF1E8),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: isSystem
                      ? const Icon(Icons.campaign_outlined, color: Color(0xFF9CA3AF), size: 20)
                      : Text(n.peerAvatarText,
                          style: const TextStyle(
                              color: Color(0xFFFF7A2E), fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(n.peerNickname,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: isSystem ? const Color(0xFFF3F4F6) : const Color(0xFFE8F8F5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(n.isIncoming ? n.typeLabel : '我发出的',
                                style: TextStyle(
                                  color: isSystem ? const Color(0xFF6B7280) : const Color(0xFF2DB8A3),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                )),
                          ),
                        ],
                      ),
                      if (!isSystem && n.peerCollege.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text('${n.peerCollege} · ${n.peerGrade} · 学号 ${n.peerStudentId}',
                            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                Text(n.createdAt, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
              ],
            ),
            const SizedBox(height: 10),
            Text(n.message,
                style: const TextStyle(color: Color(0xFF374151), fontSize: 13, height: 1.5)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, color: Color(0xFF9CA3AF), size: 14),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(n.itemTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
