import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../models/item_model.dart';
import '../services/api_service.dart';
import 'search_page.dart';
import 'publish_page.dart';
import 'my_publish_page.dart';
import 'detail_page.dart';
import 'user_profile_page.dart';
import 'notifications_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  int _latestTab = 0;

  static const List<String> _latestTabLabels = ['全部', '招领', '寻物'];
  static const List<String?> _latestTabTypes = [null, ItemType.found, ItemType.lost];

  List<ItemModel> _items = [];
  bool _loading = true;
  String? _error;

  final GlobalKey<MyPublishPageState> _myPublishKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  /// 从后端拉取最新信息列表，根据当前 Tab 筛选 type。
  Future<void> _loadItems() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final type = _latestTabTypes[_latestTab];
      final resp = await ApiService.getItems(type: type, pageSize: 20);
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

  /// 底部栏返回首页。
  void _goHome() => setState(() => _currentIndex = 0);

  /// 切换底部 Tab，切到「我的发布」时刷新数据。
  void _switchTab(int index) {
    setState(() => _currentIndex = index);
    if (index == 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _myPublishKey.currentState?.refresh();
      });
    }
  }

  /// 发布成功后刷新「我的发布」并切回首页。
  void _onPublished() {
    _myPublishKey.currentState?.refresh();
    _goHome();
  }

  /// 打开消息通知页；返回后刷新未读红点。
  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
    if (mounted) setState(() {});
  }

  /// 打开自己的学生详情页。
  void _openMyProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfilePage(
          user: AppData.currentUser.value,
          isSelf: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          SearchPage(onBack: _goHome),
          PublishPage(onBack: _goHome, onPublished: _onPublished),
          MyPublishPage(
            key: _myPublishKey,
            onBack: _goHome,
            onAdd: () => setState(() => _currentIndex = 2),
            onOpenProfile: _openMyProfile,
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _currentIndex == 2
          ? null
          : FloatingActionButton(
              heroTag: 'fab',
              onPressed: () {
                setState(() => _currentIndex = 2);
              },
              backgroundColor: const Color(0xFFFF7A2E),
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white, size: 32),
            ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 8,
        // 栏身收窄，中间 + 按钮随之整体下移。
        height: 58,
        padding: EdgeInsets.zero,
        notchMargin: 8,
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_rounded, '首页'),
            const SizedBox(width: 56),
            _buildNavItem(3, Icons.article_rounded, '我的发布'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final active = _currentIndex == index;
    return InkWell(
      onTap: () => _switchTab(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? const Color(0xFFFF7A2E) : Colors.grey, size: 28),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                color: active ? const Color(0xFFFF7A2E) : Colors.grey,
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              )),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildLatestSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF7A2E), Color(0xFFFF9A55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('阳光大学 · 失物招领平台',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Text('校园失物招领',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700)),
                      SizedBox(width: 6),
                      Text('💛', style: TextStyle(fontSize: 20)),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: _openNotifications,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.notifications_none, color: Colors.white, size: 22),
                      // 未读红点。
                      if (AppData.unreadCount > 0)
                        Positioned(
                          top: 7,
                          right: 7,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF4D4F),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => setState(() => _currentIndex = 1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFFFF7A2E), size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      '搜索物品名称 / 地点 / 描述...',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7A2E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('去搜索',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestSection() {
    final items = _items;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('最新信息',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    _buildLatestTab(0, '全部'),
                    _buildLatestTab(1, '招领'),
                    _buildLatestTab(2, '寻物'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: CircularProgressIndicator(color: Color(0xFFFF7A2E)),
            )
          else if (_error != null)
            _buildErrorView()
          else if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 52, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  Text('暂无「${_latestTabLabels[_latestTab]}」信息',
                      style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildItemCard(items[index]),
            ),
        ],
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
          Text(_error ?? '加载失败',
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _loadItems,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7A2E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('重试', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestTab(int index, String label) {
    final active = _latestTab == index;
    return GestureDetector(
      onTap: () {
        if (_latestTab == index) return;
        setState(() => _latestTab = index);
        _loadItems();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFF7A2E) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label,
            style: TextStyle(
              color: active ? Colors.white : Colors.grey,
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            )),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                item.coverImage,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 96,
                  height: 96,
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
                                color: item.typeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFFFF7A2E), size: 14),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text('${item.location}  |  ${item.createdAt}',
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