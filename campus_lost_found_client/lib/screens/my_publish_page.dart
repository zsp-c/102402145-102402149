import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../models/item_model.dart';
import '../services/api_service.dart';
import '../utils/toast_util.dart';
import 'detail_page.dart';

class MyPublishPage extends StatefulWidget {
  const MyPublishPage({
    super.key,
    this.refreshTrigger,
    this.onBack,
    this.onAdd,
    this.onOpenProfile,
  });

  /// 由 HomePage 注入：值变化时触发列表刷新（替代 GlobalKey，避免 element reparenting）。
  final ValueNotifier<int>? refreshTrigger;

  /// 由 HomePage 注入：作为底部栏 Tab 内嵌时没有可 pop 的路由，
  /// 返回箭头需要切回首页。
  final VoidCallback? onBack;

  /// 右上角「+」：跳转到发布页。
  final VoidCallback? onAdd;

  /// 用户卡片 / 「>」：打开学生详情页。
  final VoidCallback? onOpenProfile;

  @override
  State<MyPublishPage> createState() => MyPublishPageState();
}

class MyPublishPageState extends State<MyPublishPage> {
  int _tab = 0;

  /// 「我的发布」的筛选维度：全部 / 寻物中 / 招领中 / 已找回。
  static const List<String> _tabLabels = ['全部', '寻物中', '招领中', '已找回'];

  List<ItemModel> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
    widget.refreshTrigger?.addListener(_onRefreshTriggered);
  }

  @override
  void didUpdateWidget(covariant MyPublishPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      oldWidget.refreshTrigger?.removeListener(_onRefreshTriggered);
      widget.refreshTrigger?.addListener(_onRefreshTriggered);
    }
  }

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_onRefreshTriggered);
    super.dispose();
  }

  /// 外部刷新触发器回调。
  void _onRefreshTriggered() {
    if (mounted) _loadItems();
  }

  /// 从后端拉取我的发布列表（不带筛选，本地按 Tab 过滤以支持计数）。
  Future<void> _loadItems() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await ApiService.getMyItems(pageSize: 50);
      if (!resp.success) {
        setState(() => _error = resp.msg.isEmpty ? '加载失败' : resp.msg);
        return;
      }
      if (mounted) {
        setState(() {
          _items = resp.data?.records ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<ItemModel> _itemsOf(int tab) {
    switch (tab) {
      case 1:
        return _items.where((e) => e.type == ItemType.lost).toList();
      case 2:
        return _items.where((e) => e.type == ItemType.found).toList();
      case 3:
        return _items
            .where((e) => e.status == ItemStatus.found || e.status == ItemStatus.claimed)
            .toList();
      default:
        return _items;
    }
  }

  @override
  Widget build(BuildContext context) {
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
            ValueListenableBuilder<UserModel>(
              valueListenable: AppData.currentUser,
              builder: (context, user, _) => Column(
                children: [
                  _buildUserCard(user),
                  const SizedBox(height: 16),
                  _buildStatRow(user),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildTabs(),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: CircularProgressIndicator(color: Color(0xFFFF7A2E)),
              )
            else if (_error != null)
              _buildErrorView()
            else if (items.isEmpty)
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

  Widget _buildErrorView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 52, color: Color(0xFFFF7A2E)),
          const SizedBox(height: 10),
          Text(_error ?? '加载失败', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _loadItems,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7A2E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('重试',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: !user.hasAvatar
                    ? const LinearGradient(
                        colors: [Color(0xFFFFA066), Color(0xFFFF7A2E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: user.hasAvatar
                  ? Image.network(
                      user.avatar,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(user.avatarText,
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                      ),
                    )
                  : Center(
                      child: Text(user.avatarText,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                    ),
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
        Expanded(child: _buildStatTile('${user.totalPublish}', '累计发布', const Color(0xFFFF7A2E), const Color(0xFFFFF1E8))),
        const SizedBox(width: 10),
        Expanded(child: _buildStatTile('${user.totalOngoing}', '进行中', const Color(0xFF2DB8A3), const Color(0xFFE8F8F5))),
        const SizedBox(width: 10),
        Expanded(child: _buildStatTile('${user.totalCompleted}', '已找回', const Color(0xFF4B5563), const Color(0xFFF3F4F6))),
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
    ToastUtil.info(context, message);
  }

  /// `PUT /items/{id}/resolve` 标记已解决。
  Future<void> _onResolve(ItemModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('标记已解决'),
        content: Text('确认将该${item.isFound ? '招领' : '寻物'}信息标记为已${item.isFound ? '归还' : '找回'}？'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确认', style: TextStyle(color: Color(0xFFFF7A2E), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final resp = await ApiService.resolveItem(item.id);
      if (!mounted) return;
      if (resp.success) {
        _toast('已标记为解决');
        final newStatus = item.isFound ? ItemStatus.claimed : ItemStatus.found;
        setState(() {
          _items = _items.map((e) => e.id == item.id ? e.copyWith(status: newStatus) : e).toList();
        });
        // 已找回/已归还数 +1（延迟到帧结束，避免与 setState 构建冲突）
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final u = AppData.currentUser.value;
          AppData.currentUser.value = u.copyWith(totalCompleted: u.totalCompleted + 1);
        });
      } else {
        _toast(resp.msg.isEmpty ? '操作失败' : resp.msg);
      }
    } catch (e) {
      if (mounted) _toast('网络异常：$e');
    }
  }

  /// `DELETE /items/{id}` 删除信息。
  Future<void> _onDelete(ItemModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除信息'),
        content: const Text('确认删除该信息？删除后不可恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除', style: TextStyle(color: Color(0xFFE74C3C), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final resp = await ApiService.deleteItem(item.id);
      if (!mounted) return;
      if (resp.success) {
        _toast('已删除');
        setState(() => _items = _items.where((e) => e.id != item.id).toList());
        // 累计发布数 -1（延迟到帧结束，避免与 setState 构建冲突）
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final u = AppData.currentUser.value;
          AppData.currentUser.value = u.copyWith(totalPublish: u.totalPublish - 1);
        });
      } else {
        _toast(resp.msg.isEmpty ? '删除失败' : resp.msg);
      }
    } catch (e) {
      if (mounted) _toast('网络异常：$e');
    }
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
                  onTap: item.isResolved ? null : () => _onResolve(item),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: item.isResolved ? const Color(0xFFF3F4F6) : const Color(0xFFE8F8F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item.isResolved
                          ? (item.isFound ? '已归还' : '已找回')
                          : (item.isFound ? '标记已归还' : '标记已找回'),
                      style: TextStyle(
                          color: item.isResolved ? const Color(0xFF9CA3AF) : const Color(0xFF2DB8A3),
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _onDelete(item),
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