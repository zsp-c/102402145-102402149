import 'package:flutter/material.dart';
import '../models/item_model.dart';
import 'detail_page.dart';

/// 学生详情页，对应接口文档 `GET /users/{userId}`（本人资料即 `GET /users/me`）。
/// 由「我的发布」用户卡片或物品详情页的发布者卡片进入。
class UserProfilePage extends StatefulWidget {
  const UserProfilePage({
    super.key,
    required this.user,
    this.items = const [],
    this.isSelf = false,
  });

  final UserModel user;

  /// TA 发布过的信息列表。
  final List<ItemModel> items;

  /// 是否查看自己的资料（自己的话不显示关注按钮）。
  final bool isSelf;

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late bool _followed = widget.user.followed;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
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
            const Text('学生详情'),
            const Spacer(),
            const SizedBox(width: 20),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(user),
            const SizedBox(height: 16),
            _buildStatGrid(user),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('TA 的发布',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                const Spacer(),
                Text('共 ${widget.items.length} 条',
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.items.isEmpty)
              _buildEmpty()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _buildItemCard(widget.items[index]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFA066), Color(0xFFFF7A2E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(user.avatarText,
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.nickname,
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F8F5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${user.college} · ${user.grade}',
                              style: const TextStyle(
                                  color: Color(0xFF2DB8A3), fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        Text('加入 ${user.joinedDays} 天',
                            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              if (!widget.isSelf)
                GestureDetector(
                  onTap: () => setState(() => _followed = !_followed),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _followed ? const Color(0xFFFFF1E8) : const Color(0xFFFF7A2E),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFF7A2E)),
                    ),
                    child: Text(_followed ? '已关注' : '+ 关注',
                        style: TextStyle(
                          color: _followed ? const Color(0xFFFF7A2E) : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: const Color(0xFFF0F0F2)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.badge_outlined, color: Color(0xFF9CA3AF), size: 16),
              const SizedBox(width: 6),
              Text('学号 ${user.studentId}',
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(UserModel user) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildStatCell('${user.totalPublished}', '累计发布', const Color(0xFFFF7A2E)),
          _divider(),
          _buildStatCell('${user.totalOngoing}', '进行中', const Color(0xFF2DB8A3)),
          _divider(),
          _buildStatCell('${user.totalResolved}', '已找回', const Color(0xFF4B5563)),
          _divider(),
          _buildStatCell('${user.helpedCount}', '已帮助', const Color(0xFF6B7FE3)),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 28, color: const Color(0xFFF0F0F2));

  Widget _buildStatCell(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 52, color: Colors.grey[400]),
          const SizedBox(height: 10),
          const Text('TA 还没有发布过信息',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildItemCard(ItemModel item) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DetailPage(item: item)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                item.coverImage,
                width: 76,
                height: 76,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 76,
                  height: 76,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.typeBgColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(item.typeLabel,
                            style: TextStyle(
                                color: item.typeColor, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      Text(item.statusLabel,
                          style: TextStyle(color: item.statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                  const SizedBox(height: 4),
                  Text(item.summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFFFF7A2E), size: 14),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text('${item.location}  |  ${item.createdAt}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                      ),
                    ],
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
