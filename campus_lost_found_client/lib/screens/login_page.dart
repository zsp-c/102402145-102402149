import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../data/app_data.dart';
import 'home_page.dart';
import 'register_page.dart';

/// 登录页，对接后端 `POST /login`。
/// 请求体 LoginDto: {studentId, password}，响应 ApiResponse of LoginVo。
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdCtrl = TextEditingController(text: ApiConfig.defaultStudentId);
  final _passwordCtrl = TextEditingController(text: ApiConfig.defaultPassword);

  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _studentIdCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// 登录：调用 /login，成功后保存 token 与用户信息，跳转首页。
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final resp = await ApiService.login(
        _studentIdCtrl.text.trim(),
        _passwordCtrl.text,
      );
      if (!mounted) return;
      if (resp.success && resp.data != null) {
        ApiConfig.token = resp.data!.token;
        AppData.currentUser = resp.data!.user;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      } else {
        _showError(resp.msg.isEmpty ? '登录失败' : resp.msg);
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 80),
                _buildLogo(),
                const SizedBox(height: 48),
                _buildStudentIdField(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                const SizedBox(height: 32),
                _buildLoginButton(),
                const SizedBox(height: 24),
                _buildRegisterLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFA066), Color(0xFFFF7A2E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF7A2E).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.search, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 16),
        const Text(
          '校园失物招领',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '让每一件失物都能回家',
          style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
        ),
      ],
    );
  }

  Widget _buildStudentIdField() {
    return TextFormField(
      controller: _studentIdCtrl,
      keyboardType: TextInputType.number,
      decoration: _inputDecoration('学号', Icons.badge),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return '请输入学号';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordCtrl,
      obscureText: _obscure,
      decoration: _inputDecoration('密码', Icons.lock).copyWith(
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return '请输入密码';
        return null;
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      prefixIcon: Icon(icon, color: const Color(0xFFFF7A2E)),
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
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _loading ? null : _login,
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
            : const Text('登 录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RegisterPage()),
          );
        },
        child: const Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '还没有账号？', style: TextStyle(color: Color(0xFF9CA3AF))),
              TextSpan(
                text: '去注册',
                style: TextStyle(color: Color(0xFFFF7A2E), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}