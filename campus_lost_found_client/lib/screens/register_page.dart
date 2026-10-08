import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_page.dart';

/// 注册页，对接后端 `POST /auth/register`。
/// 请求体 RegisterDto: {studentId, password, nickname, college, grade, phone, avatar?}
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _collegeCtrl = TextEditingController();
  final _gradeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _obscure = true;
  bool _obscure2 = true;
  bool _loading = false;

  @override
  void dispose() {
    _studentIdCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nicknameCtrl.dispose();
    _collegeCtrl.dispose();
    _gradeCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  /// 注册：调用 /auth/register，成功后返回登录页。
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final resp = await ApiService.register(
        studentId: _studentIdCtrl.text.trim(),
        password: _passwordCtrl.text,
        nickname: _nicknameCtrl.text.trim(),
        college: _collegeCtrl.text.trim(),
        grade: _gradeCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );
      if (!mounted) return;
      if (resp.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('注册成功，请登录'), backgroundColor: Color(0xFF2DB8A3)),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      } else {
        _showError(resp.msg.isEmpty ? '注册失败' : resp.msg);
      }
    } catch (e) {
      if (!mounted) return;
      _showError('网络错误：${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('注册账号'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildField('学号', Icons.badge, _studentIdCtrl,
                    keyboard: TextInputType.number,
                    validator: (v) => v == null || v.trim().isEmpty ? '请输入学号' : null),
                const SizedBox(height: 14),
                _buildField('密码', Icons.lock, _passwordCtrl,
                    obscure: _obscure,
                    onToggle: () => setState(() => _obscure = !_obscure),
                    validator: (v) {
                      if (v == null || v.isEmpty) return '请输入密码';
                      if (v.length < 6) return '密码至少 6 位';
                      return null;
                    }),
                const SizedBox(height: 14),
                _buildField('确认密码', Icons.lock_outline, _confirmCtrl,
                    obscure: _obscure2,
                    onToggle: () => setState(() => _obscure2 = !_obscure2),
                    validator: (v) {
                      if (v == null || v.isEmpty) return '请再次输入密码';
                      if (v != _passwordCtrl.text) return '两次密码不一致';
                      return null;
                    }),
                const SizedBox(height: 14),
                _buildField('昵称', Icons.person_outline, _nicknameCtrl,
                    validator: (v) => v == null || v.trim().isEmpty ? '请输入昵称' : null),
                const SizedBox(height: 14),
                _buildField('学院', Icons.school_outlined, _collegeCtrl,
                    validator: (v) => v == null || v.trim().isEmpty ? '请输入学院' : null),
                const SizedBox(height: 14),
                _buildField('年级', Icons.grade_outlined, _gradeCtrl,
                    hint: '如：大二',
                    validator: (v) => v == null || v.trim().isEmpty ? '请输入年级' : null),
                const SizedBox(height: 14),
                _buildField('手机号', Icons.phone_outlined, _phoneCtrl,
                    keyboard: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return '请输入手机号';
                      if (!RegExp(r'^1\d{10}$').hasMatch(v.trim())) return '手机号格式不正确';
                      return null;
                    }),
                const SizedBox(height: 32),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7A2E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text('注 册', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '已有账号？', style: TextStyle(color: Color(0xFF9CA3AF))),
                          TextSpan(
                            text: '去登录',
                            style: TextStyle(color: Color(0xFFFF7A2E), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    IconData icon,
    TextEditingController ctrl, {
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
    String? hint,
    VoidCallback? onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        prefixIcon: Icon(icon, color: const Color(0xFFFF7A2E)),
        suffixIcon: onToggle != null
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                onPressed: onToggle,
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF7A2E), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}