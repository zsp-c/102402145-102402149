import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/app_data.dart';
import '../models/item_model.dart';
import '../services/api_service.dart';
import '../utils/toast_util.dart';

/// 单张新增图片的上传状态（已有图片直接是 OSS URL，不需要此结构）。
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

/// 编辑已发布物品。
///
/// 视觉风格与 `PublishPage` 保持一致，区别在于：
/// - 表单字段用原物品数据预填充；
/// - 已有图片直接展示 OSS URL，可删除；
/// - 新增图片走 OSS 上传，成功后才计入保存；
/// - 保存时用新字段替换 `AppData` 中对应 id 的条目（保留 id / 浏览量 / 发布者等不可编辑字段）。
class EditItemPage extends StatefulWidget {
  final ItemModel item;

  /// 保存成功后的回调（用于刷新详情页 / 列表页）。
  final VoidCallback? onSaved;

  const EditItemPage({super.key, required this.item, this.onSaved});

  @override
  State<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> {
  late int _mode;
  late String? _selectedCategory;
  bool _submitting = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  /// 原物品已有的图片（OSS URL），可删除。
  late List<String> _existingImages;

  /// 本次新增、待上传 / 已上传的图片。
  final List<_ImageEntry> _newImages = [];

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _mode = item.type == ItemType.lost ? 0 : 1;
    _selectedCategory = item.categoryName;
    _nameCtrl.text = item.title;
    _descCtrl.text = item.fullDescription;
    _locationCtrl.text = item.location;
    _existingImages = List<String>.from(item.images);
    _parseLostOrFoundTime(item.lostOrFoundTime);
  }

  /// 解析 `lostOrFoundTime`，兼容 `yyyy-MM-dd HH:mm` 与「今天/昨天/前天 HH:mm」两种常见格式。
  void _parseLostOrFoundTime(String raw) {
    if (raw.isEmpty) return;
    try {
      final match = RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})\s+(\d{1,2}):(\d{2})').firstMatch(raw);
      if (match != null) {
        _selectedDate = DateTime(
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
        );
        _selectedTime = TimeOfDay(
          hour: int.parse(match.group(4)!),
          minute: int.parse(match.group(5)!),
        );
        return;
      }
      final now = DateTime.now();
      int offsetDays = 0;
      if (raw.contains('今天')) {
        offsetDays = 0;
      } else if (raw.contains('昨天')) {
        offsetDays = -1;
      } else if (raw.contains('前天')) {
        offsetDays = -2;
      } else {
        return;
      }
      final timeMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(raw);
      if (timeMatch == null) return;
      final d = now.add(Duration(days: offsetDays));
      _selectedDate = DateTime(d.year, d.month, d.day);
      _selectedTime = TimeOfDay(
        hour: int.parse(timeMatch.group(1)!),
        minute: int.parse(timeMatch.group(2)!),
      );
    } catch (_) {
      // 解析失败就让用户重新选
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  int get _totalImages => _existingImages.length + _newImages.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            ),
            const Spacer(),
            const Text('修改信息'),
            const Spacer(),
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
                  onPressed: _submitting ? null : _save,
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
                      : const Text('保存修改',
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
                    Text('寻物启事',
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
                    Text('失物招领',
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
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AppData.categories.map((c) {
              final active = _selectedCategory == c.name;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = c.name),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFFFFE8DD) : const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active ? const Color(0xFFFF7A2E) : Colors.transparent,
                    ),
                  ),
                  child: Text(c.name,
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
        ..._existingImages.map((url) => _buildExistingImageThumb(url)),
        ..._newImages.map((entry) => _buildNewImageThumb(entry)),
        if (_totalImages < 6)
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

  /// 已有图片：展示 OSS 网络图，点击右上角删除。
  Widget _buildExistingImageThumb(String url) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 80,
              height: 80,
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: GestureDetector(
            onTap: () => setState(() => _existingImages.remove(url)),
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

  /// 新增图片：本地预览 + 上传状态遮罩。
  Widget _buildNewImageThumb(_ImageEntry entry) {
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
            onTap: () => setState(() => _newImages.remove(entry)),
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
    setState(() => _newImages.add(entry));

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

  // ------------------------------------------------------------ 保存

  String? _validate() {
    if (_nameCtrl.text.trim().isEmpty) return '请填写物品名称';
    if (_selectedCategory == null) return '请选择物品分类';
    if (_descCtrl.text.trim().isEmpty) return '请填写详细描述';
    if (_locationCtrl.text.trim().isEmpty) return '请填写丢失 / 拾取地点';
    if (_newImages.any((e) => e.uploading)) return '图片正在上传，请稍候';
    if (_newImages.any((e) => e.error != null)) return '有图片上传失败，请重试或删除';
    return null;
  }

  Future<void> _save() async {
    final error = _validate();
    if (error != null) {
      _showFeedback('保存失败：$error', success: false);
      return;
    }

    final isLost = _mode == 0;
    final type = isLost ? ItemType.lost : ItemType.found;

    setState(() => _submitting = true);
    try {
      final now = DateTime.now();
      final dateStr = _selectedDate == null
          ? '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}'
          : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
      final timeStr = _selectedTime == null
          ? '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}'
          : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
      final findOrLostTime = '$dateStr $timeStr';

      final allImages = <String>[
        ..._existingImages,
        ..._newImages.map((e) => e.ossUrl!).where((u) => u.isNotEmpty),
      ];

      final resp = await ApiService.updateItem(
        id: widget.item.id,
        type: type,
        name: _nameCtrl.text.trim(),
        category: _selectedCategory!,
        description: _descCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        findOrLostTime: findOrLostTime,
        images: allImages,
      );

      if (!mounted) return;

      if (!resp.success) {
        setState(() => _submitting = false);
        _showFeedback(resp.msg.isEmpty ? '保存失败' : resp.msg, success: false);
        return;
      }

      final updated = resp.data ?? widget.item;

      // 同步更新本地缓存中对应 id 的条目。
      _replaceInList(AppData.latestItems, updated);
      _replaceInList(AppData.myPublishedItems, updated);

      setState(() => _submitting = false);
      _showFeedback('修改成功', success: true);
      widget.onSaved?.call();
      if (mounted) Navigator.of(context).pop(updated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showFeedback('保存失败：$e', success: false);
    }
  }

  /// 按 id 替换列表中的条目，找不到则不处理。
  void _replaceInList(List<ItemModel> list, ItemModel updated) {
    final index = list.indexWhere((e) => e.id == updated.id);
    if (index != -1) {
      list[index] = updated;
    }
  }

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