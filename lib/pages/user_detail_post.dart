import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:fontend_pro/models/get_post_user.dart' as model;

class UserDetailPost extends StatefulWidget {
  final model.GetPostUser postUser;
  const UserDetailPost({Key? key, required this.postUser}) : super(key: key);

  @override
  State<UserDetailPost> createState() => _UserDetailPostState();
}

class _UserDetailPostState extends State<UserDetailPost>
    with TickerProviderStateMixin {
  // ---------------- state ----------------
  int currentImageIndex = 0;
  bool isLiked = false;
  bool isBookmarked = false;
  bool isLoading = false;
  int likeCount = 0;

  // ---------------- animation ----------------
  late final AnimationController _heartCtrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  // ---------------- storage ----------------
  final GetStorage gs = GetStorage();

  // ==================== LIFE CYCLE ====================
  @override
  void initState() {
    super.initState();
    likeCount = widget.postUser.post.amountOfLike ?? 0;
    _initHeartAnimation();
    _checkIfLiked();
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    super.dispose();
  }

  // ==================== ANIMATION SETUP ====================
  void _initHeartAnimation() {
    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scale = Tween<double>(begin: 0.2, end: 1.3).animate(
      CurvedAnimation(parent: _heartCtrl, curve: Curves.elasticOut),
    );
    _opacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _heartCtrl, curve: const Interval(0.4, 1)),
    );

    _heartCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _heartCtrl.reset();
        setState(() => _showCenterHeart = false);
      }
    });
  }

  // ==================== HELPERS ====================
  bool _showCenterHeart = false;

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return 'เมื่อสักครู่';
    if (d.inMinutes < 60) return '${d.inMinutes} นาทีที่แล้ว';
    if (d.inHours < 24) return '${d.inHours} ชั่วโมงที่แล้ว';
    if (d.inDays < 7) return '${d.inDays} วันที่แล้ว';
    if (d.inDays < 30) return '${(d.inDays / 7).floor()} สัปดาห์ที่แล้ว';
    if (d.inDays < 365) return '${(d.inDays / 30).floor()} เดือนที่แล้ว';
    return '${(d.inDays / 365).floor()} ปีที่แล้ว';
  }

  Future<void> _checkIfLiked() async {
    try {
      final uid = gs.read('user');
      if (uid == null) return;
      final cfg = await Configuration.getConfig();
      final res = await http.get(
        Uri.parse('${cfg['apiEndpoint']}/image_post/liked-posts/$uid'),
      );
      if (res.statusCode == 200) {
        final ids = List<int>.from(json.decode(res.body)['likedPostIds']);
        setState(() => isLiked = ids.contains(widget.postUser.post.postId));
      }
    } catch (_) {}
  }

  // ==================== LIKE / UNLIKE ====================
  Future<void> _toggleLike() async {
    if (isLoading) return;
    final previousIsLiked = isLiked;
    final previousLikeCount = likeCount;

    // อัปเดต UI ทันที
    setState(() {
      isLoading = true;
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });

    try {
      final uid = gs.read('user');
      final cfg = await Configuration.getConfig();
      final url = isLiked
          ? '${cfg['apiEndpoint']}/image_post/like'
          : '${cfg['apiEndpoint']}/image_post/unlike';

      final res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': uid,
          'post_id': widget.postUser.post.postId,
        }),
      );

      // หาก API ล้มเหลว ให้ย้อนสถานะกลับ
      if (res.statusCode != 200) {
        setState(() {
          isLiked = previousIsLiked;
          likeCount = previousLikeCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาด, โปรดลองอีกครั้ง')),
        );
      }
    } catch (e) {
      // หากเกิดข้อผิดพลาดในการเชื่อมต่อ ให้ย้อนสถานะกลับ
      setState(() {
        isLiked = previousIsLiked;
        likeCount = previousLikeCount;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _doubleTapLike() {
    if (!isLiked) {
      _toggleLike();
    }
    setState(() => _showCenterHeart = true);
    _heartCtrl.forward();
  }

  // ==================== UI ====================
  @override
  Widget build(BuildContext context) {
    final p = widget.postUser.post;
    final img = widget.postUser.images;

    return Scaffold(
      appBar: AppBar(title: const Text('โพสต์')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------ IMAGE & DOUBLE-TAP ------------
            Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onDoubleTap: _doubleTapLike,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: PageView.builder(
                      itemCount: img.length,
                      onPageChanged: (i) => setState(() => currentImageIndex = i),
                      itemBuilder: (_, i) => Image.network(
                        img[i].image,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, c, lp) =>
                            lp == null ? c : const Center(child: CircularProgressIndicator()),
                        errorBuilder: (_, __, ___) =>
                            const Center(child: Icon(Icons.broken_image, size: 48)),
                      ),
                    ),
                  ),
                ),
                if (_showCenterHeart)
                  AnimatedBuilder(
                    animation: _heartCtrl,
                    builder: (_, __) => Opacity(
                      opacity: _opacity.value,
                      child: Transform.scale(
                        scale: _scale.value,
                        child: const Icon(Icons.favorite, color: Colors.white, size: 100),
                      ),
                    ),
                  ),
                if (img.length > 1)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                      child: Text('${currentImageIndex + 1}/${img.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
              ],
            ),

            // ------------ ACTION BAR ------------
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    GestureDetector(
                      onTap: _toggleLike,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          key: ValueKey(isLiked),
                          size: 28,
                          color: isLiked ? Colors.red : Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.chat_bubble_outline, size: 28),
                    const SizedBox(width: 16),
                    const Icon(Icons.send, size: 28),
                  ]),
                  GestureDetector(
                    onTap: () => setState(() => isBookmarked = !isBookmarked),
                    child: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border, size: 28),
                  ),
                ],
              ),
            ),

            // ------------ LIKE COUNT ------------
            if (likeCount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('$likeCount คนถูกใจ',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),

            // ------------ CAPTION & TIME ------------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p.postTopic != null)
                    Text(p.postTopic!, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (p.postDescription != null) ...[
                    const SizedBox(height: 4),
                    Text(p.postDescription!),
                  ],
                  const SizedBox(height: 8),
                  Text(_timeAgo(p.postDate), style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}