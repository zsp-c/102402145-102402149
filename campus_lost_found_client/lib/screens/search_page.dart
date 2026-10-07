import 'package:flutter/material.dart';
import '../data/app_data.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.onBack});

  /// 由 HomePage 注入：作为底部栏 Tab 内嵌时没有可 pop 的路由，
  /// 返回箭头需要切回首页。
  final VoidCallback? onBack;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController(text: '耳机');
  final List<String> _history = List.from(AppData.searchHistory);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFFF7A2E),
        toolbarHeight: 72,
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
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFFFF7A2E), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: '搜索物品 / 地点',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        _controller.clear();
                        setState(() {});
                      },
                      child: const Icon(Icons.close, color: Colors.grey, size: 18),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {},
              child: const Text('搜索',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.local_fire_department, color: Color(0xFFFF7A2E), size: 22),
                SizedBox(width: 6),
                Text('大家都在',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                Spacer(),
                Text('近 7 天热词', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AppData.hotWords.map((h) {
                final active = h.word == '耳机';
                return GestureDetector(
                  onTap: () {
                    _controller.text = h.word;
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFFFFE8DD) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active ? const Color(0xFFFF7A2E) : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Text(
                      '${h.word} ${h.icon}',
                      style: TextStyle(
                        color: active ? const Color(0xFFFF7A2E) : const Color(0xFF374151),
                        fontSize: 14,
                        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                const Icon(Icons.history, color: Color(0xFF2DB8A3), size: 20),
                const SizedBox(width: 6),
                const Text('搜索历',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _history.clear()),
                  child: const Text('清空', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _history
                  .map((k) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Text(k,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF374151))),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: const [
                  Icon(Icons.image_search, color: Color(0xFF2DB8A3), size: 36),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('找不到？换个关键词试试',
                            style: TextStyle(
                                color: Color(0xFF2DB8A3), fontSize: 14, fontWeight: FontWeight.w600)),
                        SizedBox(height: 4),
                        Text('试试搜索「地点 + 物品」组合，例如「体育馆 钥匙」',
                            style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                      ],
                    ),
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