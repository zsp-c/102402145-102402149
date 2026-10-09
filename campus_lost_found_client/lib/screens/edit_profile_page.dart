import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/app_data.dart';
import '../models/item_model.dart';
import '../services/api_service.dart';

/// 编辑个人资料页。
/// 可修改：头像、昵称、手机号、学院、年级。
/// 学号不可修改。
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.user, this.onSaved});

  final UserModel user;
  final VoidCallback? onSaved;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _nicknameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _collegeCtrl;
  late final TextEditingController _gradeCtrl;

  /// 当前头像 URL，空字符串表示使用默认首字母头像。
  late String _avatarUrl;
  bool _saving = false;
  bool _uploadingAvatar = false;

  final List<String> _gradeOptions = ['大一', '大二', '大三', '大四', '研究生', '其他'];

  @override
  void initState() {
    super.initState();
    _nicknameCtrl = TextEditingController(text: widget.user.nickname);
    _phoneCtrl = TextEditingController(text: widget.user.phone);
    _collegeCtrl = TextEditingController(text: widget.user.college);
    _gradeCtrl = TextEditingController(text: widget.user.grade);
    _avatarUrl = widget.user.avatar;
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _phoneCtrl.dispose();
    _collegeCtrl.dispose();
    _gradeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final nickname = _nicknameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final college = _collegeCtrl.text.trim();
    final grade = _gradeCtrl.text.trim();

    if (nickname.isEmpty) {
      _showToast('请输入昵称');
      return;
    }

    setState(() => _saving = true);
    try {
      final resp = await ApiService.updateUser(
        nickname: nickname,
        avatar: _avatarUrl,
        phone: phone,
        college: college,
        grade: grade,
      );
      if (resp.success && resp.data != null) {
        widget.onSaved?.call();
        if (mounted) {
          Navigator.of(context).pop(true);
        }
        // 延迟到帧结束后更新，避免与路由 pop 同一帧导致
        // InheritedWidget deactivate 时依赖未清理（_dependents.isEmpty 断言）。
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppData.currentUser.value = resp.data!;
        });
      } else {
        _showToast(resp.msg.isEmpty ? '保存失败' : resp.msg);
      }
    } catch (e) {
      _showToast('网络异常，请稍后重试');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// 头像 URL 是否有效（非空、非 null 字面量、以 http 开头）。
  bool get _hasValidAvatar {
    if (_avatarUrl.isEmpty) return false;
    final lower = _avatarUrl.trim().toLowerCase();
    if (lower == 'null' || lower == 'none') return false;
    if (!lower.startsWith('http')) return false;
    return true;
  }

  /// 从相册选择图片并上传到 OSS，成功后更新本地头像 URL。
  Future<void> _pickAvatar() async {
    if (_uploadingAvatar) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    setState(() => _uploadingAvatar = true);
    try {
      final url = await ApiService.uploadImage(picked.path);
      if (!mounted) return;
      setState(() => _avatarUrl = url);
      _showToast('头像上传成功');
    } catch (e) {
      _showToast('头像上传失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
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
            const Text('编辑资料'),
            const Spacer(),
            const SizedBox(width: 20),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAvatarPicker(),
            const SizedBox(height: 16),
            _buildField('学号', widget.user.studentId, enabled: false),
            const SizedBox(height: 12),
            _buildField('昵称', '', controller: _nicknameCtrl, hint: '请输入昵称'),
            const SizedBox(height: 12),
            _buildField('手机号', '', controller: _phoneCtrl, hint: '请输入手机号'),
            const SizedBox(height: 12),
            _buildField('学院', '', controller: _collegeCtrl, hint: '请输入学院'),
            const SizedBox(height: 12),
            _buildGradeField(),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A2E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('保存修改', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    String value, {
    TextEditingController? controller,
    String? hint,
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
          ),
          Expanded(
            child: controller != null
                ? TextField(
                    controller: controller,
                    enabled: enabled,
                    style: const TextStyle(color: Color(0xFF1F2937), fontSize: 15),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: hint,
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                    ),
                  )
                : Text(value, style: const TextStyle(color: Color(0xFF1F2937), fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 70,
            child: Text('年级', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
          ),
          Expanded(
            child: DropdownButton<String>(
              value: _gradeOptions.contains(_gradeCtrl.text) ? _gradeCtrl.text : null,
              hint: const Text('请选择年级', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
              isExpanded: true,
              underline: const SizedBox(),
              items: _gradeOptions
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) {
                if (v != null) _gradeCtrl.text = v;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPicker() {
    return GestureDetector(
      onTap: _pickAvatar,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: !_hasValidAvatar
                        ? const LinearGradient(
                            colors: [Color(0xFFFFA066), Color(0xFFFF7A2E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _hasValidAvatar
                      ? Image.network(
                          _avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(widget.user.avatarText,
                                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
                          ),
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white));
                          },
                        )
                      : Center(
                          child: Text(widget.user.avatarText,
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
                        ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF7A2E),
                      shape: BoxShape.circle,
                    ),
                    child: _uploadingAvatar
                        ? const Padding(
                            padding: EdgeInsets.all(6),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text('点击更换头像', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
          ],
        ),
      ),
    );
  }
}