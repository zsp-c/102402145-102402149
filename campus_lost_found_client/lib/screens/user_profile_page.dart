import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../models/item_model.dart';
import '../services/api_service.dart';
import 'login_page.dart';
import 'edit_profile_page.dart';

/// 学生详情页，展示学生基本信息。
/// - 他人页面：保留关注按钮；
/// - 本人页面（isSelf）：展示「修改资料」「退出登录」按钮。
class UserProfilePage extends StatefulWidget {
  const UserProfilePage({
    super.key,
    required this.user,
    this.isSelf = false,
  });

  final UserModel user;

  /// 是否查看自己的资料。
  final bool isSelf;

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late bool _followed = widget.user.followed;
  late UserModel _user = widget.user;

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
            Text(widget.isSelf ? '个人资料' : '学生详情'),
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
            _buildProfileCard(_user),
            const SizedBox(height: 16),
            _buildStatGrid(_user),
            const SizedBox(height: 16),
            _buildInfoCard(_user),
            if (widget.isSelf) ...[
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
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
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
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
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(user.avatarText,
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
                    ),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white));
                    },
                  )
                : Center(
                    child: Text(user.avatarText,
                        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
                  ),
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
          _buildStatCell('${user.totalPublish}', '累计发布', const Color(0xFFFF7A2E)),
          _divider(),
          _buildStatCell('${user.totalOngoing}', '进行中', const Color(0xFF2DB8A3)),
          _divider(),
          _buildStatCell('${user.totalCompleted}', '已找回', const Color(0xFF4B5563)),
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

  Widget _buildInfoCard(UserModel user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.badge_outlined, '学号', user.studentId),
          _buildDivider(),
          _buildInfoRow(Icons.person_outline, '昵称', user.nickname),
          _buildDivider(),
          _buildInfoRow(Icons.school_outlined, '学院', user.college),
          _buildDivider(),
          _buildInfoRow(Icons.grade_outlined, '年级', user.grade),
          _buildDivider(),
          _buildInfoRow(Icons.phone_outlined, '手机号', user.phone),
          _buildDivider(),
          _buildInfoRow(Icons.event_available_outlined, '加入天数', '${user.joinedDays} 天'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF7A2E), size: 18),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => Container(height: 1, color: const Color(0xFFF0F0F2), margin: const EdgeInsets.only(left: 44));

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => EditProfilePage(
                    user: _user,
                    onSaved: () {
                      if (mounted) {
                        setState(() => _user = AppData.currentUser.value);
                      }
                    },
                  ),
                ),
              );
              if (result == true && mounted) {
                setState(() => _user = AppData.currentUser.value);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7A2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
            label: const Text('修改资料', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _confirmLogout,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFEF4444)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            icon: const Icon(Icons.logout, color: Color(0xFFEF4444), size: 18),
            label: const Text('退出登录', style: TextStyle(color: Color(0xFFEF4444), fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _doLogout();
            },
            child: const Text('确定', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  void _doLogout() {
    ApiConfig.token = '';
    // 先清空用户信息再换路由：此刻首页还在树上，监听 currentUser 的
    // ValueListenableBuilder 会在这一帧正常重建一次（不涉及路由搬迁），
    // 之后才切路由栈，避免 element 树搬迁途中被通知。
    AppData.currentUser.value = UserModel(
      userId: 0,
      studentId: '',
      nickname: '',
      college: '',
      grade: '',
      phone: '',
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}