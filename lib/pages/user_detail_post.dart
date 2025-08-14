import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:fontend_pro/models/like_post.dart';
import 'package:fontend_pro/models/get_comment.dart';
import 'package:fontend_pro/models/post_detail.dart' as model;

class UserDetailPostPage extends StatefulWidget {
  final int postId;

  const UserDetailPostPage({Key? key, required this.postId}) : super(key: key);

  @override
  State<UserDetailPostPage> createState() => _UserDetailPostPageState();
}

class _UserDetailPostPageState extends State<UserDetailPostPage>
    with TickerProviderStateMixin {
  model.PostDetail? postDetail;
  bool isLoading = true;
  String? errorMessage;
  bool isLiked = false;
  bool isSavingLike = false;
  int loggedInUserId = 0;

  Map<int, bool> savedMap = {};
  Map<int, int> saveCountMap = {};
  bool isSavingSave = false;

  GetStorage gs = GetStorage();

  // สำหรับ animation หัวใจ
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool showHeart = false;

  @override
  void initState() {
    super.initState();
    fetchPostDetail();
    getLoggedInUserId();
    loadSavedPosts();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.4).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 300), () {
          setState(() {
            showHeart = false;
          });
          _animationController.reset();
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void getLoggedInUserId() {
    loggedInUserId = gs.read('user') ?? 0;
    checkIsLiked();
  }

  String _formatTimeAgo(DateTime postDate) {
    final now = DateTime.now();
    final difference = now.difference(postDate);

    if (difference.inSeconds < 60) {
      return 'เมื่อสักครู่';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} วันที่แล้ว';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks สัปดาห์ที่แล้ว';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months เดือนที่แล้ว';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ปีที่แล้ว';
    }
  }

  Future<void> fetchPostDetail() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];
      final uri = '$url/image_post/by-post/${widget.postId}';

      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          postDetail = model.PostDetail.fromJson(jsonData);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> checkIsLiked() async {
    if (loggedInUserId == 0) return;

    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];
      final uri = Uri.parse('$url/image_post/liked-posts/$loggedInUserId');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List likedPostIds = data['likedPostIds'] ?? [];

        setState(() {
          isLiked = likedPostIds.contains(widget.postId);
        });
      } else {
        setState(() {
          isLiked = false;
        });
      }
    } catch (e) {
      setState(() {
        isLiked = false;
      });
    }
  }

  Future<void> toggleLike() async {
    if (isSavingLike || loggedInUserId == 0) return;

    setState(() {
      isSavingLike = true;
    });

    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];
      Uri uri;

      if (!isLiked) {
        // กรณี like
        uri = Uri.parse('$url/image_post/like');
        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            "user_id": loggedInUserId,
            "post_id": widget.postId,
          }),
        );

        if (response.statusCode == 200) {
          setState(() {
            isLiked = true;
            if (postDetail != null) {
              postDetail!.post.amountOfLike += 1;
            }
          });
        }
      } else {
        // กรณี unlike (ยกเลิกไลก์)
        uri = Uri.parse('$url/image_post/unlike');
        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            "user_id": loggedInUserId,
            "post_id": widget.postId,
          }),
        );

        if (response.statusCode == 200) {
          setState(() {
            isLiked = false;
            if (postDetail != null && postDetail!.post.amountOfLike > 0) {
              postDetail!.post.amountOfLike -= 1;
            }
          });
        }
      }
    } catch (e) {
      // handle error
    } finally {
      setState(() {
        isSavingLike = false;
      });
    }
  }

  void savePost(int postId) async {
    if (isSavingSave) return;

    setState(() {
      isSavingSave = true;
    });

    final uid = gs.read('user');
    final isSaved = savedMap[postId] ?? false;

    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      final endpoint = isSaved ? '/image_post/unsave' : '/image_post/save';
      final uri = Uri.parse('$url$endpoint');

      final saveModel = LikePost(userId: uid, postId: postId);
      final bodyJson = likePostToJson(saveModel);

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: bodyJson,
      );

      if (response.statusCode == 200) {
        setState(() {
          savedMap[postId] = !isSaved;
          if (!isSaved) {
            saveCountMap[postId] = (saveCountMap[postId] ?? 0) + 1;
          } else {
            saveCountMap[postId] = (saveCountMap[postId] ?? 1) - 1;
            if (saveCountMap[postId]! < 0) saveCountMap[postId] = 0;
          }
        });
      }
    } catch (e) {
      // handle error
    } finally {
      setState(() {
        isSavingSave = false;
      });
    }
  }

  Future<void> loadSavedPosts() async {
    final uid = gs.read('user');
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];
    final uri = Uri.parse('$url/image_post/saved-posts/$uid');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List savedPostIds = data['savedPostIds'];

        setState(() {
          savedMap = {};
          for (var postId in savedPostIds) {
            savedMap[postId] = true;
          }
        });
      }
    } catch (e) {
      // handle error
    }
  }

  void _showCommentBottomSheet(BuildContext context, int postId) {
    TextEditingController _commentController = TextEditingController();
    FocusNode _focusNode = FocusNode();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return AnimatedPadding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle Bar
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'ความคิดเห็น',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Comments List
                    Expanded(
                      child: FutureBuilder<GetComment>(
                        future: _fetchComments(postId),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Container(
                              color: Colors.white,
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.blue),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'กำลังโหลดความคิดเห็น...',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final comments = snapshot.data!.comments;

                          if (comments.isEmpty) {
                            return Container(
                              color: Colors.white,
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'ยังไม่มีความคิดเห็น',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'เป็นคนแรกที่แสดงความคิดเห็น',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return Container(
                            color: Colors.white,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: comments.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 4),
                              itemBuilder: (context, index) {
                                final c = comments[index];
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Hero(
                                            tag: 'avatar_${c.name}_$index',
                                            child: Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.grey[300]!,
                                                  width: 1,
                                                ),
                                              ),
                                              child: CircleAvatar(
                                                radius: 18,
                                                backgroundImage: c
                                                        .profileImage.isNotEmpty
                                                    ? NetworkImage(
                                                        c.profileImage)
                                                    : const AssetImage(
                                                            'assets/default_avatar.png')
                                                        as ImageProvider,
                                                backgroundColor:
                                                    Colors.grey[200],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  c.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.access_time,
                                                      size: 12,
                                                      color: Colors.grey[500],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      _formatTimeAgo(
                                                          c.createdAt),
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey[500],
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.grey[200]!,
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Text(
                                          c.commentText,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),

                    // Comment Input
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Colors.grey[200]!),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Container(
                                constraints: const BoxConstraints(
                                  minHeight: 48,
                                  maxHeight: 120,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: TextField(
                                  controller: _commentController,
                                  focusNode: _focusNode,
                                  maxLines: null,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'แสดงความคิดเห็น...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _commentController,
                              builder: (context, value, child) {
                                final hasText = value.text.trim().isNotEmpty;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: hasText
                                          ? () async {
                                              final text = _commentController
                                                  .text
                                                  .trim();
                                              if (text.isNotEmpty) {
                                                _commentController.clear();
                                                _focusNode.unfocus();

                                                // Show loading state
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: const Row(
                                                      children: [
                                                        SizedBox(
                                                          width: 16,
                                                          height: 16,
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            valueColor:
                                                                AlwaysStoppedAnimation<
                                                                        Color>(
                                                                    Colors
                                                                        .white),
                                                          ),
                                                        ),
                                                        SizedBox(width: 12),
                                                        Text(
                                                            'กำลังส่งความคิดเห็น...'),
                                                      ],
                                                    ),
                                                    duration: const Duration(
                                                        seconds: 1),
                                                    backgroundColor:
                                                        Colors.blue,
                                                  ),
                                                );

                                                await _submitComment(
                                                    postId, text);
                                                setModalState(
                                                    () {}); // รีโหลด FutureBuilder
                                              }
                                            }
                                          : null,
                                      borderRadius: BorderRadius.circular(24),
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: hasText
                                              ? Colors.blue
                                              : Colors.grey[300],
                                          shape: BoxShape.circle,
                                          boxShadow: hasText
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.blue
                                                        .withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Icon(
                                          Icons.send_rounded,
                                          color: hasText
                                              ? Colors.white
                                              : Colors.grey[500],
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<GetComment> _fetchComments(int postId) async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];
    final res = await http.get(Uri.parse('$url/image_post/comments/$postId'));
    if (res.statusCode == 200) {
      return getCommentFromJson(res.body);
    } else {
      throw Exception('โหลดคอมเมนต์ไม่สำเร็จ');
    }
  }

  Future<void> _submitComment(int postId, String commentText) async {
    final gs = GetStorage();
    final userId = gs.read('user');
    
    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];
      
      final res = await http.post(
        Uri.parse('$url/image_post/comment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'post_id': postId,
          'user_id': userId,
          'comment_text': commentText,
        }),
      );
      
      if (res.statusCode == 200) {
        // แสดงข้อความสำเร็จ
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text('ส่งความคิดเห็นสำเร็จ'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          
          // รีเฟรชหน้าเพื่ออัพเดทจำนวน comments
          setState(() {});
        }
      } else {
        // แสดงข้อความผิดพลาด
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text('ส่งความคิดเห็นไม่สำเร็จ'),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
        debugPrint('ส่งคอมเมนต์ไม่สำเร็จ: ${res.statusCode} - ${res.body}');
      }
    } catch (e) {
      // จัดการ error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('เกิดข้อผิดพลาด กรุณาลองใหม่'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
      debugPrint('Error submitting comment: $e');
    }
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'เมื่อสักครู่';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} วันที่แล้ว';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildCategoriesSection() {
    // เช็คว่า categories ไม่เป็น null และมีข้อมูล
    if (postDetail?.categories == null || postDetail!.categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: postDetail!.categories.map((category) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 214, 214, 214),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color.fromARGB(255, 0, 0, 0)),
            ),
            child: Text(
              category.cname,
              style: const TextStyle(
                fontSize: 14,
                color: Color.fromARGB(255, 0, 0, 0),
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHashtagsSection() {
    // เช็คว่า hashtags ไม่เป็น null และมีข้อมูล
    if (postDetail?.hashtags == null || postDetail!.hashtags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 4,
        children: postDetail!.hashtags.map((hashtag) {
          return GestureDetector(
            onTap: () {
              print('Tapped hashtag: ${hashtag.tagName}');
            },
            child: Text(
              '#${hashtag.tagName}',
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          title: const Text('Post', style: TextStyle(color: Colors.black)),
        ),
        body: const Scaffold(
          backgroundColor: Color(0xFFF8F9FA),
          body: Center(
            child: CircularProgressIndicator(
              color: Colors.black,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          title: const Text('Post', style: TextStyle(color: Colors.black)),
        ),
        body: Center(child: Text(errorMessage!)),
      );
    }

    if (postDetail == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          title: const Text('Post', style: TextStyle(color: Colors.black)),
        ),
        body: const Center(child: Text('No data found')),
      );
    }

    final post = postDetail!.post;
    final user = postDetail!.user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Post',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - User Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: user.profileImage != null && user.profileImage!.isNotEmpty
                        ? NetworkImage(user.profileImage!)
                        : null,
                    child: user.profileImage == null || user.profileImage!.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _timeAgo(post.postDate),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_horiz),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Images Carousel with double-tap heart animation
            if (postDetail!.images.isNotEmpty)
              SizedBox(
                height: 400,
                child: PageView.builder(
                  itemCount: postDetail!.images.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onDoubleTap: () {
                        setState(() {
                          showHeart = true;
                        });
                        _animationController.forward();
                        toggleLike();
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.network(
                            postDetail!.images[index].image,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            // เพิ่ม error handler สำหรับรูปภาพ
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                          if (showHeart)
                            ScaleTransition(
                              scale: _scaleAnimation,
                              child: Icon(
                                Icons.favorite,
                                color: Colors.red.withOpacity(0.8),
                                size: 120,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Like Button
                      IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.black,
                          size: 28,
                        ),
                        onPressed: toggleLike,
                      ),
                      
                      // Comment Button - เชื่อมต่อกับ bottom sheet
                      IconButton(
                        icon: const Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.black,
                          size: 28,
                        ),
                        onPressed: () => _showCommentBottomSheet(context, widget.postId),
                      ),
                      
                      // Share Button
                      IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: Colors.black,
                          size: 28,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  
                  // Save Button
                  IconButton(
                    icon: Icon(
                      savedMap[widget.postId] == true
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      color: Colors.black,
                      size: 28,
                    ),
                    onPressed: () {
                      savePost(widget.postId);
                    },
                  ),
                ],
              ),
            ),

            // Likes and Comments count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Likes count
                  Text(
                    '${post.amountOfLike} likes',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  
                  // Comments count - เพิ่มการแสดงจำนวน comments
                  const SizedBox(height: 2),
                  FutureBuilder<GetComment>(
                    future: _fetchComments(widget.postId),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.comments.isNotEmpty) {
                        final commentCount = snapshot.data!.comments.length;
                        return GestureDetector(
                          onTap: () => _showCommentBottomSheet(context, widget.postId),
                          child: Text(
                            commentCount == 1 
                                ? 'ดูความคิดเห็น 1 รายการ'
                                : 'ดูความคิดเห็นทั้งหมด $commentCount รายการ',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),

            // Caption
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.postTopic.isNotEmpty)
                    Text(
                      post.postTopic,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  // ใช้ null safety สำหรับ postDescription
                  if (post.postDescription != null && post.postDescription!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        post.postDescription!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          height: 1.3,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Categories Section
            _buildCategoriesSection(),

            // Hashtags Section
            _buildHashtagsSection(),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}