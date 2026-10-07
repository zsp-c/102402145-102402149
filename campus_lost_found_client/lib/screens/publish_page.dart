import 'package:flutter/material.dart';
import '../data/app_data.dart';

class PublishPage extends StatefulWidget {
  const PublishPage({super.key, this.onBack, this.onOpenMyPublish});

  /// 由 HomePage 注入：作为底部栏 Tab 内嵌时没有可 pop 的路由，
  /// 返回箭头需要切回首页。
  final VoidCallback? onBack;

  /// 右上角「我的发布」：切到「我的发布」页。
  final VoidCallback? onOpenMyPublish;

  @override
  State<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends State<PublishPage> {
  int _mode = 0;
  String? _selectedCategory;
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController(text: '图书馆三楼自习区');

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
            GestureDetector(
              onTap: widget.onOpenMyPublish,
              child: const Text('我的发布',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
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
                const SizedBox(height: 16),
                _buildContactCard(),
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
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A2E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 4,
                  ),
                  child: const Text('立即发布',
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.info_outline, color: Color(0xFFFF7A2E), size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '填写你丢失的物品信息，发布后会出现在「寻物启事」列表，全校同学都能帮你留意。',
              style: TextStyle(color: Color(0xFF8A4A1F), fontSize: 13, height: 1.5),
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
        ],
      ),
    );
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
              suffix: GestureDetector(
                onTap: () {},
                child: const Text('选择常用地',
                    style: TextStyle(color: Color(0xFFFF7A2E), fontSize: 13, fontWeight: FontWeight.w600)),
              ),
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
                  children: const [
                    Text('日期', style: TextStyle(fontSize: 14, color: Color(0xFF374151), fontWeight: FontWeight.w500)),
                    SizedBox(height: 8),
                    _PlaceholderField(text: '请选择日期'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('时间', style: TextStyle(fontSize: 14, color: Color(0xFF374151), fontWeight: FontWeight.w500)),
                    SizedBox(height: 8),
                    _PlaceholderField(text: '请选择时间'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
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
              Icon(Icons.contact_phone_outlined, color: Color(0xFF4DA6E8), size: 22),
              SizedBox(width: 8),
              Text('联系方式',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
            ],
          ),
          const SizedBox(height: 18),
          const Text('联系人 *',
              style: TextStyle(fontSize: 14, color: Color(0xFF374151), fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const _PlaceholderField(text: '请输入联系人姓名'),
          const SizedBox(height: 14),
          const Text('联系电话 *',
              style: TextStyle(fontSize: 14, color: Color(0xFF374151), fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const _PlaceholderField(text: '请输入手机号'),
        ],
      ),
    );
  }
}

class _PlaceholderField extends StatelessWidget {
  final String text;
  const _PlaceholderField({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}