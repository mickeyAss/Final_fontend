import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fontend_pro/config/config.dart';
import 'package:fontend_pro/pages/user_detail_post.dart';

class SearchPostHashtagsPage extends StatefulWidget {
  final int tagId;
  final String? tagName;

  const SearchPostHashtagsPage({
    super.key,
    required this.tagId,
    this.tagName,
  });

  @override
  State<SearchPostHashtagsPage> createState() => _SearchPostHashtagsPageState();
}

class _SearchPostHashtagsPageState extends State<SearchPostHashtagsPage> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  Map<String, dynamic>? _hashtag;
  List<dynamic> _posts = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPostsByHashtag();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPostsByHashtag() async {
    if (!_isRefreshing) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final config = await Configuration.getConfig();
      final url = config['apiEndpoint'];

      final response = await http.get(
        Uri.parse("$url/hashtags/hashtag-posts?tag_id=${widget.tagId}"),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _hashtag = body['hashtag'];
            _posts = body['posts'];
            _errorMessage = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'เกิดข้อผิดพลาดในการโหลดโพสต์';
          });
        }
      }
    } catch (e) {
      log('Error loading posts: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'เกิดข้อผิดพลาดในการโหลดโพสต์';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _isRefreshing = true;
    });
    await _loadPostsByHashtag();
  }

  double _getRandomHeight() {
    return 150 + math.Random().nextDouble() * 150;
  }

  Widget _buildPinterestPostItem(dynamic post, double itemHeight) {
    final images = (post['images'] as List<dynamic>?) ?? [];
    final hasImages = images.isNotEmpty;
    final mainImage = hasImages ? images[0] : null;

    return Container(
      height: itemHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // เปลี่ยนตรงนี้ให้ไปหน้า UserDetailPostPage
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserDetailPostPage(postId: post['post_id']),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImages)
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        mainImage,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    if (images.length > 1)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.collections,
                                  color: Colors.white, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                '${images.length}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Center(
                    child:
                        Icon(Icons.article, size: 32, color: Colors.grey[400]),
                  ),
                ),
              ),
            Expanded(
              flex: hasImages ? 2 : 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (post['post_topic'] != null) ...[
                      Text(
                        post['post_topic'],
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (post['post_description'] != null) ...[
                      Expanded(
                        child: Text(
                          post['post_description'],
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                          maxLines: hasImages ? 3 : 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ] else
                      const Spacer(),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: post['user'] != null &&
                                  post['user']['profile_image'] != null &&
                                  post['user']['profile_image']
                                      .toString()
                                      .isNotEmpty
                              ? NetworkImage(post['user']['profile_image'])
                              : null,
                          child: post['user'] == null ||
                                  post['user']['profile_image'] == null ||
                                  post['user']['profile_image']
                                      .toString()
                                      .isEmpty
                              ? Icon(Icons.person,
                                  size: 12, color: Colors.grey[600])
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post['user']?['name'] ?? 'Unknown',
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (post['post_date'] != null)
                                Text(
                                  _formatDate(post['post_date']),
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey[500]),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 7) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} วันที่แล้ว';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ชม.';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} นาที';
      } else {
        return 'เมื่อสักครู่';
      }
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildStaggeredGrid() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final post = _posts[index];
                final itemHeight = _getRandomHeight();
                return _buildPinterestPostItem(post, itemHeight);
              },
              childCount: _posts.length,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _hashtag != null
                  ? '#${_hashtag!['tag_name']}'
                  : widget.tagName != null
                      ? '#${widget.tagName}'
                      : 'โพสต์แฮชแท็ก',
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            if (_posts.isNotEmpty)
              Text('${_posts.length} โพสต์',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _refreshPosts,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Colors.black, strokeWidth: 2))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(_errorMessage!,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPostsByHashtag,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white),
                        child: const Text('ลองใหม่'),
                      ),
                    ],
                  ),
                )
              : _posts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.content_paste_off,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text('ยังไม่มีโพสต์สำหรับแฮชแท็กนี้',
                              style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshPosts,
                      child: _buildStaggeredGrid(),
                    ),
    );
  }
}
