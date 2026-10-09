import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../models/item_model.dart';
import '../services/api_service.dart';
import '../services/notification_api.dart';
import '../utils/toast_util.dart';
import 'edit_item_page.dart';
import 'user_profile_page.dart';

/// 物品详情页，对应接口文档 `GET /items/{id}`（ItemVo）。
class DetailPage extends StatefulWidget {
  const DetailPage({super.key, required this.item, this.isMine = false});

  /// 列表传入的物品信息（可能不含 user / 完整描述），页面加载后会用 id 拉取完整详情。
  final ItemModel item;

  /// 是否是当前用户自己发布的（决定是否显示「修改」入口）。
  final bool isMine;

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  int _imageIndex = 0;

  /// 用可变副本持有，编辑保存后可刷新显示。
  late ItemModel _item;

  bool _loading = true;
  String? _error;

  ItemModel get item => _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _loadDetail();
  }

  /// 用 item.id 拉取完整详情（含发布者 user、完整描述等列表接口不返回的字段）。
  Future<void> _loadDetail() async {
    try {
      final resp = await ApiService.getItemDetail(widget.item.id);
      if (!resp.success) {
        if (mounted) setState(() => _error = resp.msg.isEmpty ? '加载失败' : resp.msg);
        return;
      }
      if (resp.data != null && mounted) {
        setState(() {
          _item = resp.data!;
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
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

  @override
  Widget build(BuildContext context) {
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
            const Text('信息详情'),
            const Spacer(),
            const SizedBox(width: 20),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A2E)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 52, color: Color(0xFFFF7A2E)),
                      const SizedBox(height: 10),
                      Text(_error!, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _loading = true;
                            _error = null;
                          });
                          _loadDetail();
                        },
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
                )
              : Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildImageSection(),
                          const SizedBox(height: 12),
                          _buildTitleCard(),
                          const SizedBox(height: 12),
                          _buildPublisherCard(),
                          const SizedBox(height: 12),
                          _buildItemInfoCard(),
                          const SizedBox(height: 12),
                          _buildDescriptionCard(),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _buildBottomBar(),
                    ),
                  ],
                ),
    );
  }

  // ---------------------------------------------------------------- 图片区

  Widget _buildImageSection() {
    final images = item.images;
    return Stack(
      children: [
        if (images.isEmpty)
          Container(
            height: 300,
            width: double.infinity,
            color: Colors.grey[300],
            child: const Icon(Icons.image, size: 80, color: Colors.grey),
          )
        else
          SizedBox(
            height: 300,
            child: PageView.builder(
              onPageChanged: (i) => setState(() => _imageIndex = i),
              itemCount: images.length,
              itemBuilder: (_, i) => Image.network(
                images[i],
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 300,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, size: 80, color: Colors.grey),
                ),
              ),
            ),
          ),
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: item.typeColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.isFound ? Icons.favorite_border : Icons.help_outline,
                    color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text('${item.typeLabel}信息',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        if (images.length > 1)
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.image_outlined, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text('${_imageIndex + 1} / ${images.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------------------ 标题信息卡

  Widget _buildTitleCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1F2937), height: 1.4)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip(
                icon: Icons.schedule,
                text: item.statusLabel,
                color: item.statusColor,
                bg: item.statusColor.withOpacity(0.15),
              ),
              _buildChip(
                text: item.categoryName,
                color: const Color(0xFF2DB8A3),
                bg: const Color(0xFFE8F8F5),
              ),
              _buildChip(
                text: item.location,
                color: const Color(0xFF6B7280),
                bg: const Color(0xFFF3F4F6),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFF0F0F2)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.visibility, color: Color(0xFF9CA3AF), size: 16),
              const SizedBox(width: 4),
              Text('浏览量 ${item.viewCount}',
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
              const Spacer(),
              const Icon(Icons.access_time, color: Color(0xFF9CA3AF), size: 16),
              const SizedBox(width: 4),
              Text('发布于 ${item.createdAt}',
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip({IconData? icon, required String text, required Color color, required Color bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 3),
          ],
          Text(text,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- 发布者卡

  Widget _buildPublisherCard() {
    final user = item.user;
    if (user == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => _openPublisherProfile(user),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
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
                        child: Text(user.nickname.isEmpty ? '?' : user.nickname[0],
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                      ),
                    )
                  : Center(
                      child: Text(user.nickname.isEmpty ? '?' : user.nickname[0],
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
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
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
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
                  Text('累计发布 ${user.totalPublish} 条 · 已帮助 ${user.helpedCount} 位同学',
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

  void _openPublisherProfile(UserModel user) {
    // 发布者是本人的话，展示自己的完整资料。
    final isSelf = user.userId == AppData.currentUser.value.userId;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfilePage(
          user: isSelf ? AppData.currentUser.value : AppData.otherUser,
          isSelf: isSelf,
        ),
      ),
    );
  }

  // ------------------------------------------------------------ 物品信息卡

  Widget _buildItemInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, color: Color(0xFFFF7A2E), size: 22),
              const SizedBox(width: 8),
              const Text('物品信息',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
              const Spacer(),
              if (widget.isMine) _buildEditButton(),
            ],
          ),
          const SizedBox(height: 18),
          _buildInfoRow(
            icon: Icons.location_on,
            iconColor: const Color(0xFFFF7A2E),
            label: '${item.isFound ? '拾取' : '丢失'}地点',
            value: item.location,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.access_time,
            iconColor: const Color(0xFF2DB8A3),
            label: '${item.isFound ? '拾取' : '丢失'}时间',
            value: item.lostOrFoundTime,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.category,
            iconColor: const Color(0xFF4DA6E8),
            label: '物品类别',
            value: item.categoryName,
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    return GestureDetector(
      onTap: _onEdit,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1E8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFF7A2E)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_outlined, color: Color(0xFFFF7A2E), size: 15),
            SizedBox(width: 4),
            Text('修改',
                style: TextStyle(color: Color(0xFFFF7A2E), fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
              const SizedBox(height: 3),
              Text(value,
                  style: const TextStyle(color: Color(0xFF1F2937), fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------ 详细描述卡

  Widget _buildDescriptionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.menu_book_rounded, color: Color(0xFF4DA6E8), size: 22),
              SizedBox(width: 8),
              Text('详细描述',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
            ],
          ),
          const SizedBox(height: 14),
          Text(item.fullDescription,
              style: const TextStyle(color: Color(0xFF374151), fontSize: 14, height: 1.7)),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- 底部操作

  Widget _buildBottomBar() {
    if (widget.isMine) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.98),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: item.isResolved ? null : _onResolve,
                    icon: Icon(item.isResolved ? Icons.check_circle : Icons.check_circle_outline,
                        color: item.isResolved ? Colors.grey : const Color(0xFFFF7A2E), size: 20),
                    label: Text(item.isResolved ? '已解决' : '标记已解决',
                        style: TextStyle(
                            color: item.isResolved ? Colors.grey : const Color(0xFFFF7A2E),
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: item.isResolved ? Colors.grey : const Color(0xFFFF7A2E)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _onDelete,
                    icon: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                    label: const Text('删除',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE74C3C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      elevation: 4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.98),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _onContact,
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
            label: Text(item.isFound ? '联系 TA 认领' : '我有线索',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7A2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 4,
            ),
          ),
        ),
      ),
    );
  }

  /// `PUT /items/{id}/resolve` 标记已解决。
  Future<void> _onResolve() async {
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
        setState(() => _item = _item.copyWith(status: newStatus));
      } else {
        _toast(resp.msg.isEmpty ? '操作失败' : resp.msg);
      }
    } catch (e) {
      if (mounted) _toast('网络异常：$e');
    }
  }

  /// `DELETE /items/{id}` 删除信息。
  Future<void> _onDelete() async {
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
        Navigator.of(context).pop(true);
      } else {
        _toast(resp.msg.isEmpty ? '删除失败' : resp.msg);
      }
    } catch (e) {
      if (mounted) _toast('网络异常：$e');
    }
  }

  void _toast(String message) {
    ToastUtil.info(context, message);
  }

  Future<void> _onEdit() async {
    final updated = await Navigator.of(context).push<ItemModel>(
      MaterialPageRoute(
        builder: (_) => EditItemPage(item: _item),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _item = updated);
    }
  }

  /// 对应接口文档「消息模块 · 发送认领联系」`POST /claims`：
  /// 请求体只带物品 id 与附言；发送者身份由服务端从 token 取，
  /// 接收者由服务端按物品发布者推导——前端两边都传不了，避免伪造身份 / 收件人。
  Future<void> _onContact() async {
    final peer = item.user;
    final me = AppData.currentUser.value;
    final messageCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('发送认领联系', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('将把你的资料发送给 ${peer?.nickname ?? '发布者'}：',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${me.nickname} · ${me.college} · ${me.grade}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                    const SizedBox(height: 2),
                    Text('学号 ${me.studentId}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageCtrl,
                maxLines: 3,
                maxLength: 100,
                decoration: InputDecoration(
                  hintText: item.isFound ? '说明物品特征，方便对方核对' : '补充线索，方便对方核对',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFB0B5BC)),
                  filled: true,
                  fillColor: const Color(0xFFF7F8FA),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  counterStyle: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7A2E),
              foregroundColor: Colors.white,
            ),
            child: const Text('发送'),
          ),
        ],
      ),
    );

    final message = messageCtrl.text.trim();
    messageCtrl.dispose();
    if (confirmed != true) return;

    // 走后端 `POST /claims`：消息落库后出现在双方的消息页里（对方未读、红点亮起）。
    // 之前这里只往本地 AppData 塞了一条假记录，消息页拉取时自然看不到。
    try {
      final resp = await NotificationApi.sendClaim(
        itemId: item.id,
        currentUserId: me.userId,
        content: message.isEmpty ? '想和你核对一下这件物品的信息。' : message,
      );
      if (!mounted) return;
      if (resp.success) {
        _toast('已把你的资料发送给 ${peer?.nickname ?? '发布者'}');
      } else {
        _toast(resp.msg.isEmpty ? '发送失败' : resp.msg);
      }
    } catch (e) {
      if (mounted) _toast('网络异常：$e');
    }
  }
}