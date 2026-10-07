import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../models/item_model.dart';
import 'detail_page.dart';

class MyPublishPage extends StatefulWidget {
  const MyPublishPage({
    super.key,
    this.onBack,
    this.onAdd,
    this.onOpenProfile,
  });

  /// 由 HomePage 注入：作为底部栏 Tab 内嵌时没有可 pop 的路由，
  /// 返回箭头需要切回首页。
  final VoidCallback? onBack;

  /// 右上角「+」：跳转到发布页。
  final VoidCallback? onAdd;

  /// 用户卡片 / 「>」：打开学生详情页。
  final VoidCallback? onOpenProfile;

  @override
  State<MyPublishPage> createState() => _MyPublishPageState();
}

class _MyPublishPageState extends State<MyPublishPage> {
  int _tab = 0;

  /// 「我的发布」的筛选维度：全部 / 寻物中 / 招领中 / 已找回。
  static const List<String> _tabLabels = ['全部', '寻物中', '招领中', '已找回'];

  List<ItemModel> _itemsOf(int tab) {
    switch (tab) {
      case 1:
        return AppData.myPublishedItems.where((e) => e.type == ItemType.lost).toList();
      case 2:
        return AppData.myPublishedItems.where((e) => e.type == ItemType.found).toList();
      case 3:
        return AppData.myPublishedItems
            .where((e) => e.status == ItemStatus.found || e.status == ItemStatus.claimed)
            .toList();
      default:
        return AppData.myPublishedItems;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AppData.currentUser;
    final items = _itemsOf(_tab);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => widget.onBack != null
                  ? widget.onBack!()
                  : Navigator.of(context).maybePop(),
              child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            ),
            const Spacer(),
            const Text('我的发布'),
            const Spacer(),
            GestureDetector(
              onTap: widget.onAdd,
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildUserCard(user),
            const SizedBox(height: 16),
            _buildStatRow(user),
            const SizedBox(height: 16),
            _buildTabs(),
            const SizedBox(height: 12),
            if (items.isEmpty)
              _buildEmpty()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _buildPublishCard(items[index]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return GestureDetector(
      onTap: widget.onOpenProfile,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
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
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(user.nickname,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F8F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${user.college} · ${user.grade}',
                            style: const TextStyle(color: Color(0xFF2DB8A3), fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('学号 ${user.studentId} · 加入 ${user.joinedDays} 天',
                      style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(UserModel user) {
    return Row(
      children: [
        Expanded(child: _buildStatTile('${user.totalPublished}', '累计发布', const Color(0xFFFF7A2E), const Color(0xFFFFF1E8))),
        const SizedBox(width: 10),
        Expanded(child: _buildStatTile('${user.totalOngoing}', '进行中', const Color(0xFF2DB8A3), const Color(0xFFE8F8F5))),
        const SizedBox(width: 10),
        Expanded(child: _buildStatTile('${user.totalResolved}', '已找回', const Color(0xFF4B5563), const Color(0xFFF3F4F6))),
      ],
    );
  }

  Widget _buildStatTile(String value, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _tabLabels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final active = _tab == index;
          return GestureDetector(
            onTap: () => setState(() => _tab = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: active ? const Color(0xFFFF7A2E) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: active ? const Color(0xFFFF7A2E) : const Color(0xFFE5E7EB),
                ),
              ),
              alignment: Alignment.center,
              child: Text('${_tabLabels[index]} ${_itemsOf(index).length}',
                  style: TextStyle(
                    color: active ? Colors.white : const Color(0xFF374151),
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  )),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 52, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text('暂无「${_tabLabels[_tab]}」的信息',
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
        ],
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Widget _buildPublishCard(ItemModel item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  item.coverImage,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: item.statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(item.statusLabel,
                              style: TextStyle(color: item.statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('${item.location} · ${item.createdAt}',
                        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.visibility, color: Color(0xFF9CA3AF), size: 14),
                        const SizedBox(width: 3),
                        Text('${item.viewCount}', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                        const SizedBox(width: 14),
                        const Icon(Icons.chat_bubble_outline, color: Color(0xFF9CA3AF), size: 14),
                        const SizedBox(width: 3),
                        Text('${item.claimCount} 条线索',
                            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => DetailPage(item: item, isMine: true)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: const Text('查看详情',
                        style: TextStyle(color: Color(0xFF4B5563), fontSize: 14)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () => _toast(item.isFound ? '已标记为「已归还」' : '已标记为「已找回」'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item.isFound ? '标记已归还' : '标记已找回',
                      style: const TextStyle(color: Color(0xFF2DB8A3), fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _toast('已删除该条信息'),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.delete_outline, color: Color(0xFF9CA3AF), size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
