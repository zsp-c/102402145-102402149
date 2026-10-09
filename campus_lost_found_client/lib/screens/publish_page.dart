import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/app_data.dart';
import '../models/item_model.dart';
import '../services/api_service.dart';
import '../utils/toast_util.dart';

/// 单张图片的上传状态。
/// 选图后立即上传至阿里云 OSS，成功后保存返回的 URL，
/// 发布时只提交已上传成功的 URL 列表。
class _ImageEntry {
  final String localPath;
  String? ossUrl;
  bool uploading;
  String? error;

  _ImageEntry({
    required this.localPath,
    this.uploading = false,
  });

  bool get ready => ossUrl != null && ossUrl!.isNotEmpty;
}

class PublishPage extends StatefulWidget {
  const PublishPage({super.key, this.onBack, this.onPublished});

  /// 由 HomePage 注入：作为底部栏 Tab 内嵌时没有可 pop 的路由，
  /// 返回箭头需要切回首页。
  final VoidCallback? onBack;

  /// 发布成功后的回调：跳回首页。
  final VoidCallback? onPublished;

  @override
  State<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends State<PublishPage> {
  int _mode = 0;
  String? _selectedCategory;
  bool _submitting = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final List<_ImageEntry> _images = [];
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController(text: '图书馆三楼自习区');

  /// 从后端 `/categories` 拉取的分类名称列表。
  List<String> _categories = [];
  bool _categoriesLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  /// 拉取物品分类列表，失败时回退到本地默认分类。
  Future<void> _loadCategories() async {
    try {
      final resp = await ApiService.getCategories();
      if (resp.success && resp.data != null && resp.data!.isNotEmpty) {
        if (mounted) {
          setState(() {
            _categories = resp.data!;
            _categoriesLoading = false;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _categories = AppData.categories.map((c) => c.name).toList();
        _categoriesLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (widget.onBack != null) {
                  widget.onBack!();
                } else {
                  Navigator.of(context).maybePop();
                }
              },
              child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            ),
            const Spacer(),
            const Text('发布信息'),
            const Spacer(),
            // 留白，与左侧返回箭头宽度对称，保证标题居中
            const SizedBox(width: 20),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModeSwitch(),
                const SizedBox(height: 14),
                _buildHint(),
                const SizedBox(height: 18),
                _buildItemInfoCard(),
                const SizedBox(height: 16),
                _buildTimeLocationCard(),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _publish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A2E),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFFFB88A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 4,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('立即发布',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _mode = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _mode == 0 ? const Color(0xFFFF7A2E) : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.help_outline,
                        color: _mode == 0 ? Colors.white : const Color(0xFF6B7280), size: 20),
                    const SizedBox(width: 6),
                    Text('我丢了东西',
                        style: TextStyle(
                            color: _mode == 0 ? Colors.white : const Color(0xFF374151),
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _mode = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _mode == 1 ? const Color(0xFFFF7A2E) : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border,
                        color: _mode == 1 ? Colors.white : const Color(0xFF6B7280), size: 20),
                    const SizedBox(width: 6),
                    Text('我捡到东西',
                        style: TextStyle(
                            color: _mode == 1 ? Colors.white : const Color(0xFF374151),
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHint() {
    final isLost = _mode == 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFFF7A2E), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isLost
                  ? '填写你丢失的物品信息，发布后会出现在「寻物启事」列表，全校同学都能帮你留意。'
                  : '填写你捡到的物品信息，发布后会出现在「失物招领」列表，方便失主核对认领。',
              style: const TextStyle(color: Color(0xFF8A4A1F), fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemInfoCard() {
    return Container(
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
              Icon(Icons.inventory_2_outlined, color: Color(0xFFFF7A2E), size: 22),
              SizedBox(width: 8),
              Text('物品信息',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
            ],
          ),
          const SizedBox(height: 18),
          const Text('物品名称 *',
              style: TextStyle(fontSize: 14, color: Color(0xFF374151), fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              hintText: '例如：黑色 AirPods Pro 充电盒',
              hintStyle: const TextStyle(color: Color(0xFFB0B5BC), fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF7F8FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          const SizedBox(height: 18),
          const Text('物品分类 *',
              style: TextStyle(fontSize: 14, color: Color(0xFF374151), fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          _categoriesLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF7A2E)),
                  ),
                )
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _categories.map((name) {
                    final active = _selectedCategory == name;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = name),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: active ? const Color(0xFFFFE8DD) : const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active ? const Color(0xFFFF7A2E) : Colors.transparent,
                          ),
                        ),
                        child: Text(name,
                            style: TextStyle(
                              color: active ? const Color(0xFFFF7A2E) : const Color(0xFF4B5563),
                              fontSize: 14,
                              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                            )),
                      ),
                    );
                  }).toList(),
                ),
          const SizedBox(height: 18),
          const Text('详细描述 *',
              style: TextStyle(fontSize: 14, color: Color(0xFF374151), fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            maxLines: 4,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: '描述物品颜色、特征、有无贴纸或挂件等，便于失主或拾获人核对',
              hintStyle: const TextStyle(color: Color(0xFFB0B5BC), fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF7F8FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              counterStyle: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const SizedBox(height: 18),
          const Text('物品图片',
              style: TextStyle(fontSize: 14, color: Color(0xFF374151), fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          _buildImagePicker(),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ..._images.map((entry) => _buildImageThumb(entry)),
        if (_images.length < 6)
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Icon(Icons.add_photo_alternate_outlined,
                  color: Color(0xFF9CA3AF), size: 32),
            ),
          ),
      ],
    );
  }

  Widget _buildImageThumb(_ImageEntry entry) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(File(entry.localPath),
              width: 80, height: 80, fit: BoxFit.cover),
        ),
        if (entry.uploading)
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          )
        else if (entry.error != null)
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.error_outline, color: Colors.redAccent, size: 28),
            ),
          ),
        Positioned(
          right: 4,
          top: 4,
          child: GestureDetector(
            onTap: () => setState(() => _images.remove(entry)),
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    final entry = _ImageEntry(localPath: picked.path, uploading: true);
    setState(() => _images.add(entry));

    try {
      final url = await ApiService.uploadImage(picked.path);
      if (!mounted) return;
      setState(() {
        entry.ossUrl = url;
        entry.uploading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        entry.uploading = false;
        entry.error = e.toString();
      });
      _showFeedback('图片上传失败：$e', success: false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
    }
  }

  Widget _buildTimeLocationCard() {
    return Container(
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
              Icon(Icons.access_time_rounded, color: Color(0xFF2DB8A3), size: 22),
              SizedBox(width: 8),
              Text('时间与地点',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
            ],
          ),
          const SizedBox(height: 18),
          const Text('丢失 / 拾取地点 *',
              style: TextStyle(fontSize: 14, color: Color(0xFF374151), fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: _locationCtrl,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.location_on, color: Color(0xFFFF7A2E)),
              filled: true,
              fillColor: const Color(0xFFF7F8FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('日期', style: TextStyle(fontSize: 14, color: Color(0xFF374151), fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    _PlaceholderField(
                      text: _selectedDate == null
                          ? '请选择日期'
                          : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                      onTap: _pickDate,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('时间', style: TextStyle(fontSize: 14, color: Color(0xFF374151), fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    _PlaceholderField(
                      text: _selectedTime == null
                          ? '请选择时间'
                          : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                      onTap: _pickTime,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ 发布

  /// 校验必填项，返回第一条错误提示；全部通过返回 null。
  String? _validate() {
    if (_nameCtrl.text.trim().isEmpty) return '请填写物品名称';
    if (_selectedCategory == null) return '请选择物品分类';
    if (_descCtrl.text.trim().isEmpty) return '请填写详细描述';
    if (_locationCtrl.text.trim().isEmpty) return '请填写丢失 / 拾取地点';
    if (_images.any((e) => e.uploading)) return '图片正在上传，请稍候';
    if (_images.any((e) => e.error != null)) return '有图片上传失败，请重试或删除';
    return null;
  }

  Future<void> _publish() async {
    final error = _validate();
    if (error != null) {
      _showFeedback('发布失败：$error', success: false);
      return;
    }

    final isLost = _mode == 0;
    final type = isLost ? ItemType.lost : ItemType.found;

    setState(() => _submitting = true);
    try {
      if (!mounted) return;

      final now = DateTime.now();
      final dateStr = _selectedDate == null
          ? '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}'
          : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
      final timeStr = _selectedTime == null
          ? '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}'
          : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
      final findOrLostTime = '$dateStr $timeStr';

      final resp = await ApiService.createItem(
        type: type,
        name: _nameCtrl.text.trim(),
        category: _selectedCategory!,
        description: _descCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        findOrLostTime: findOrLostTime,
        images: _images.map((e) => e.ossUrl!).where((u) => u.isNotEmpty).toList(),
      );

      if (!mounted) return;
      if (!resp.success) {
        setState(() => _submitting = false);
        _showFeedback(resp.msg.isEmpty ? '发布失败' : '发布失败：${resp.msg}', success: false);
        return;
      }

      setState(() {
        _submitting = false;
        _mode = 0;
        _selectedCategory = null;
        _selectedDate = null;
        _selectedTime = null;
        _images.clear();
        _nameCtrl.clear();
        _descCtrl.clear();
        _locationCtrl.text = '图书馆三楼自习区';
      });
      // 取消输入框焦点，避免在手势处理阶段重建导致断言
      FocusScope.of(context).unfocus();
      // 更新当前用户累计发布数（延迟到帧结束，避免与 setState 构建冲突）
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final u = AppData.currentUser.value;
        AppData.currentUser.value = u.copyWith(totalPublish: u.totalPublish + 1);
      });
      _showFeedback(isLost ? '发布成功，希望早日找回' : '发布成功，等待失主认领', success: true);
      widget.onPublished?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showFeedback('发布失败：$e', success: false);
    }
  }

  /// 成功 / 失败反馈：顶部浮层，用颜色和图标区分。
  void _showFeedback(String message, {required bool success}) {
    success
        ? ToastUtil.success(context, message)
        : ToastUtil.error(context, message);
  }
}

class _PlaceholderField extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const _PlaceholderField({required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(child: Text(text, style: const TextStyle(color: Color(0xFFB0B5BC), fontSize: 14))),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}