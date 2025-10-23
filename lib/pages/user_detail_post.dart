import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:fontend_pro/models/like_post.dart';
import 'package:fontend_pro/models/get_comment.dart';
import 'package:fontend_pro/models/get_hashtags.dart';
import 'package:fontend_pro/models/get_all_category.dart';
import 'package:fontend_pro/models/post_detail.dart' as model;
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import 'dart:developer';

String getStatusText(String status) {
  final s = status.trim().toLowerCase();
  switch (s) {
    case 'public':
      return 'สาธารณะ';
    case 'friends':
      return 'เฉพาะเพื่อน';
    default:
      return 'สาธารณะ';
  }
}

IconData getStatusIcon(String status) {
  final s = status.trim().toLowerCase();
  switch (s) {
    case 'public':
      return Icons.public;
    case 'friends':
      return Icons.people;
    default:
      return Icons.public;
  }
}

Color getStatusColor(String status) {
  final s = status.trim().toLowerCase();
  switch (s) {
    case 'public':
      return Colors.green;
    case 'friends':
      return Colors.blue;
    default:
      return Colors.green;
  }
}

Color getStatusDarkColor(String status) {
  final s = status.trim().toLowerCase();
  switch (s) {
    case 'public':
      return Colors.green.shade700;
    case 'friends':
      return Colors.blue.shade700;
    default:
      return Colors.green.shade700;
  }
}

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

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool showHeart = false;

  Map<int, bool> commentLikedMap = {};
  Map<int, int> commentLikeCountMap = {};
  bool isTogglingCommentLike = false;

  List<Comment> comments = [];

  @override
void initState() {
  super.initState();

  fetchPostDetail(); // โหลด post ก่อน
  getLoggedInUserId();
  loadSavedPosts();

  fetchCommentsLater(); // โหลด comment แยกทีหลัง

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

// โหลด comment แยกทีหลัง
Future<void> fetchCommentsLater() async {
  if (widget.postId == null) return;

  try {
    final commentData = await _fetchComments(widget.postId);
    if (mounted) {
      setState(() {
        comments = commentData.comments;
      });
    }
  } catch (e) {
    debugPrint('Error loading comments: $e');
  }
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
      log('Raw JSON: ${response.body}');

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

  // ฟังก์ชันลบโพสต์
  Future<bool> _deletePost(BuildContext context, int postId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบโพสต์'),
        content: const Text(
            'คุณแน่ใจหรือไม่ว่าต้องการลบโพสต์นี้? การดำเนินการนี้ไม่สามารถย้อนกลับได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return false;

    // แสดง SnackBar Loading
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('กำลังลบโพสต์...'),
            ],
          ),
          duration: Duration(seconds: 30),
          backgroundColor: Colors.orange,
        ),
      );
    }

    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      final response = await http.delete(
        Uri.parse('$url/image_post/delete-post/$postId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (response.statusCode == 200) {
          // ลบสำเร็จ
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text('ลบโพสต์สำเร็จ'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          return true; // ส่งผลลัพธ์กลับไปให้ parent
        } else {
          final errorData = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(errorData['message'] ?? 'ลบโพสต์ไม่สำเร็จ'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          return false;
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('เกิดข้อผิดพลาด: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      debugPrint('Error deleting post: $e');
      return false;
    }

    return false;
  }

  // เพิ่มฟังก์ชันสำหรับตรวจสอบว่าผู้ใช้ไลค์คอมเมนต์หรือไม่
  Future<void> checkCommentLikes(List<int> commentIds) async {
  if (loggedInUserId == 0 || commentIds.isEmpty) return;

  try {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    // สร้าง list ของ Future สำหรับแต่ละ comment
    List<Future> futures = commentIds.map((commentId) async {
      // ตรวจสอบว่าไลค์หรือไม่
      final likeUri = Uri.parse(
          '$url/image_post/is-comment-liked?user_id=$loggedInUserId&comment_id=$commentId');
      final likeRes = await http.get(likeUri);
      if (likeRes.statusCode == 200) {
        final data = json.decode(likeRes.body);
        setState(() {
          commentLikedMap[commentId] = data['liked'] ?? false;
        });
      }

      // ดึงจำนวนไลค์
      final countUri =
          Uri.parse('$url/image_post/comment-like-count/$commentId');
      final countRes = await http.get(countUri);
      if (countRes.statusCode == 200) {
        final countData = json.decode(countRes.body);
        setState(() {
          commentLikeCountMap[commentId] = countData['like_count'] ?? 0;
        });
      }
    }).toList();

    // รันทุก request พร้อมกัน
    await Future.wait(futures);

  } catch (e) {
    debugPrint('Error checking comment likes: $e');
  }
}

// ฟังก์ชันสำหรับกดไลค์/ยกเลิกไลค์คอมเมนต์
  Future<void> toggleCommentLike(int commentId) async {
    if (isTogglingCommentLike || loggedInUserId == 0) return;

    setState(() {
      isTogglingCommentLike = true;
    });

    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      final isLiked = commentLikedMap[commentId] ?? false;
      final endpoint =
          isLiked ? '/image_post/unlike-comment' : '/image_post/like-comment';
      final uri = Uri.parse('$url$endpoint');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "user_id": loggedInUserId,
          "comment_id": commentId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          commentLikedMap[commentId] = data['liked'] ?? false;
          commentLikeCountMap[commentId] = data['like_count'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error toggling comment like: $e');
    } finally {
      setState(() {
        isTogglingCommentLike = false;
      });
    }
  }

  Future<bool> _deleteComment(
    BuildContext context,
    int commentId,
    int userId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red[400]),
            const SizedBox(width: 8),
            const Text('ลบความคิดเห็น'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('คุณแน่ใจหรือไม่ว่าต้องการลบความคิดเห็นนี้?'),
            const SizedBox(height: 8),
            if (postDetail != null &&
                userId == postDetail!.post.postFkUid &&
                userId != commentId)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'คุณกำลังลบความคิดเห็นของผู้อื่นในฐานะเจ้าของโพสต์',
                        style:
                            TextStyle(fontSize: 12, color: Colors.orange[700]),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed != true) return false;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('กำลังลบความคิดเห็น...'),
            ],
          ),
          duration: Duration(seconds: 30),
          backgroundColor: Colors.orange,
        ),
      );
    }

    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      final response = await http.post(
        Uri.parse('$url/image_post/delete-comment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'comment_id': commentId,
          'user_id': userId,
          'post_id': widget.postId,
        }),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final deletedBy = responseData['deletedBy'] ?? 'ผู้ใช้';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('ลบความคิดเห็นสำเร็จ (โดย: $deletedBy)'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          setState(() {}); // รีเฟรช state หลัก
          return true; // ✅ คืนค่า true เมื่อสำเร็จ
        } else {
          final errorData = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(errorData['error'] ?? 'ลบความคิดเห็นไม่สำเร็จ'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          return false;
        }
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('เกิดข้อผิดพลาด: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }

  // State variables
  List<GetAllCategory> selectedCategories = []; // หมวดหมู่ที่เลือกแล้ว

// ฟังก์ชันโหลดหมวดหมู่จาก API
  Future<List<GetAllCategory>> fetchAllCategories() async {
    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      final response = await http.get(Uri.parse('$url/category/get'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => GetAllCategory.fromJson(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return [];
    }
  }

  Future<void> _addNewHashtag(
    String hashtagName,
    TextEditingController hashtagController,
    StateSetter setModalState,
    List<GetHashtags> selectedHashtags,
  ) async {
    final trimmedName = hashtagName.trim();

    if (trimmedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาใส่ชื่อแฮชแท็ก'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final hashtagNameWithoutHash = trimmedName.replaceFirst('#', '');

    // ตรวจสอบว่าเลือกแล้วหรือไม่
    final alreadySelected = selectedHashtags.expand((gh) => gh.data).any(
        (tag) =>
            tag.tagName.toLowerCase() == hashtagNameWithoutHash.toLowerCase());

    if (alreadySelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('แฮชแท็กนี้ถูกเลือกแล้ว'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('กำลังเพิ่มแฮชแท็ก...'),
          ],
        ),
        duration: Duration(seconds: 30),
        backgroundColor: Colors.blue,
      ),
    );

    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      final response = await http.post(
        Uri.parse('$url/hashtags/insert'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tag_name': hashtagNameWithoutHash}),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final isNew = responseData['isNew'] ?? false;
          final data = responseData['data'] ?? [];

          int tagId = 0;
          if (data.isNotEmpty) {
            tagId = data[0]['tag_id'] ?? 0;
          }

          if (isNew) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.add_circle, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                        child:
                            Text('เพิ่มแฮชแท็กใหม่: #$hashtagNameWithoutHash')),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                            'ใช้แฮชแท็กที่มีอยู่: #$hashtagNameWithoutHash')),
                  ],
                ),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 2),
              ),
            );
          }

          setModalState(() {
            if (selectedHashtags.isEmpty) {
              selectedHashtags.add(
                GetHashtags(isNew: isNew, data: [
                  Datum(tagId: tagId, tagName: hashtagNameWithoutHash)
                ]),
              );
            } else {
              selectedHashtags[0]
                  .data
                  .add(Datum(tagId: tagId, tagName: hashtagNameWithoutHash));
            }
            hashtagController.clear();
          });
        } else {
          final errorData = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                      child:
                          Text(errorData['error'] ?? 'เพิ่มแฮชแท็กไม่สำเร็จ')),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('เกิดข้อผิดพลาด: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      debugPrint('Error adding hashtag: $e');
    }
  }

  Future<void> _loadHashtagsForSelection(
    TextEditingController hashtagController,
    StateSetter setModalState,
    List<GetHashtags> selectedHashtags,
  ) async {
    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      final response = await http.get(Uri.parse('$url/hashtags/get'));

      if (response.statusCode == 200) {
        final List<dynamic> allHashtags = jsonDecode(response.body);

        if (context.mounted) {
          // แสดง Bottom Sheet เพื่อเลือกแฮชแท็ก
          _showHashtagSelectionSheet(
            allHashtags,
            hashtagController,
            setModalState,
            selectedHashtags,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('โหลดแฮชแท็กไม่สำเร็จ'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading hashtags: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showHashtagSelectionSheet(
    List<dynamic> allHashtags,
    TextEditingController hashtagController,
    StateSetter setModalState,
    List<GetHashtags> selectedHashtags,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'เลือกแฮชแท็ก',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: allHashtags.length,
                  itemBuilder: (context, index) {
                    final hashtag = allHashtags[index];
                    final tagName =
                        hashtag['tag_name'] ?? hashtag['tagName'] ?? '';
                    final tagId = hashtag['tag_id'] ?? hashtag['tagId'] ?? 0;

                    // ตรวจสอบว่าเลือกแล้วหรือไม่
                    final isSelected = selectedHashtags
                        .expand((gh) => gh.data)
                        .any((tag) =>
                            tag.tagName.toLowerCase() == tagName.toLowerCase());

                    return ListTile(
                      leading: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? Colors.blue : Colors.grey,
                      ),
                      title: Text('#$tagName'),
                      enabled: !isSelected,
                      onTap: isSelected
                          ? null
                          : () {
                              // เพิ่มแฮชแท็กที่เลือก
                              setModalState(() {
                                if (selectedHashtags.isEmpty) {
                                  selectedHashtags.add(
                                    GetHashtags(
                                      isNew: false,
                                      data: [
                                        Datum(tagId: tagId, tagName: tagName)
                                      ],
                                    ),
                                  );
                                } else {
                                  selectedHashtags[0].data.add(
                                        Datum(tagId: tagId, tagName: tagName),
                                      );
                                }
                              });

                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle,
                                          color: Colors.white, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child:
                                            Text('เพิ่ม #$tagName เรียบร้อย'),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editPost(BuildContext context) async {
    if (postDetail == null) return;

    final topicController =
        TextEditingController(text: postDetail!.post.postTopic);
    final descController =
        TextEditingController(text: postDetail!.post.postDescription ?? '');
    final hashtagController = TextEditingController();

    // State ของหมวดหมู่และแฮชแท็ก
    List<GetAllCategory> selectedCategories = postDetail!.categories
        .map((cat) => GetAllCategory(
              cid: cat.cid,
              cname: cat.cname,
              cimage: '',
              ctype: Ctype.F,
              cdescription: '',
            ))
        .toList();

    List<GetHashtags> selectedHashtags = postDetail!.hashtags
        .map((h) => GetHashtags(
              isNew: false,
              data: [Datum(tagId: h.tagId, tagName: h.tagName)],
            ))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext modalContext, StateSetter setModalState) {
            return AnimatedPadding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              duration: const Duration(milliseconds: 300),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: Colors.grey[200]!)),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(modalContext),
                          ),
                          const Expanded(
                            child: Text(
                              'แก้ไขโพสต์',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final categoryIds =
                                  selectedCategories.map((c) => c.cid).toList();
                              final hashtagIdsOrNames = <Object>[];
                              for (var gh in selectedHashtags) {
                                for (var tag in gh.data) {
                                  if (tag.tagId != 0) {
                                    hashtagIdsOrNames.add(tag.tagId);
                                  } else {
                                    hashtagIdsOrNames.add(tag.tagName);
                                  }
                                }
                              }

                              await _saveEditedPost(
                                context,
                                topicController.text,
                                descController.text,
                                hashtagIdsOrNames,
                                categoryIds,
                              );
                            },
                            child: const Text(
                              'บันทึก',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Body
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // รูปภาพ
                            if (postDetail!.images.isNotEmpty) ...[
                              const Text('รูปภาพ (ไม่สามารถแก้ไขได้)',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey)),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: postDetail!.images.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      width: 100,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.grey[300]!),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                            postDetail!.images[index].image,
                                            fit: BoxFit.cover),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // หัวข้อ
                            const Text('หัวข้อ',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: topicController,
                              decoration: InputDecoration(
                                hintText: 'หัวข้อโพสต์',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // คำอธิบาย
                            const Text('คำอธิบาย',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: descController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'เขียนคำอธิบาย...',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // หมวดหมู่
                            const Text('หมวดหมู่',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),

                            // ✅ แสดง Selected Categories พร้อม Chip
                            Wrap(
                              spacing: 8,
                              children: selectedCategories.map((cat) {
                                return Chip(
                                  label: Text(cat.cname),
                                  deleteIcon: const Icon(Icons.close),
                                  onDeleted: () {
                                    // ✅ ใช้ setModalState เพื่ออัปเดต UI ทันที
                                    setModalState(() {
                                      selectedCategories
                                          .removeWhere((c) => c.cid == cat.cid);
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 8),

                            // ✅ Dropdown เพื่อเลือกหมวดหมู่ใหม่
                            FutureBuilder<List<GetAllCategory>>(
                              future: fetchAllCategories(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                if (snapshot.hasError) {
                                  return Text(
                                      'โหลดหมวดหมู่ไม่สำเร็จ: ${snapshot.error}');
                                }
                                if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return const Text('ไม่มีหมวดหมู่ให้เลือก');
                                }

                                final allCategories = snapshot.data!;
                                final remainingCategories = allCategories
                                    .where((c) => !selectedCategories
                                        .any((sc) => sc.cid == c.cid))
                                    .toList();

                                if (remainingCategories.isEmpty) {
                                  return const Text('เลือกหมวดหมู่ครบแล้ว');
                                }

                                return DropdownButton<GetAllCategory>(
                                  hint: const Text('เพิ่มหมวดหมู่'),
                                  value: null,
                                  items: remainingCategories
                                      .map((cat) => DropdownMenuItem(
                                          value: cat, child: Text(cat.cname)))
                                      .toList(),
                                  onChanged: (cat) {
                                    if (cat != null) {
                                      // ✅ ใช้ setModalState เพื่ออัปเดต UI ทันที
                                      setModalState(() {
                                        selectedCategories.add(cat);
                                      });
                                    }
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            // แฮชแท็ก
                            const Text('แฮชแท็ก',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),

                            // ✅ แสดง Selected Hashtags พร้อม Chip
                            Wrap(
                              spacing: 8,
                              children: selectedHashtags
                                  .expand((gh) => gh.data)
                                  .map((tag) {
                                return Chip(
                                  label: Text('#${tag.tagName}'),
                                  deleteIcon: const Icon(Icons.close),
                                  onDeleted: () {
                                    // ✅ ใช้ setModalState เพื่ออัปเดต UI ทันที
                                    setModalState(() {
                                      final parent =
                                          selectedHashtags.firstWhere(
                                        (gh) => gh.data.contains(tag),
                                        orElse: () =>
                                            GetHashtags(isNew: true, data: []),
                                      );
                                      parent.data.remove(tag);
                                      if (parent.data.isEmpty) {
                                        selectedHashtags.remove(parent);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 8),

                            // ✅ เพิ่มแฮชแท็กใหม่
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: hashtagController,
                                          decoration: InputDecoration(
                                            hintText:
                                                'พิมพ์ # เพื่อเลือก หรือพิมพ์ชื่อแฮชแท็กใหม่',
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12),
                                          ),
                                          onChanged: (value) {
                                            // ถ้าพิมพ์ # ให้เรียก GET
                                            if (value == '#') {
                                              _loadHashtagsForSelection(
                                                  hashtagController,
                                                  setModalState,
                                                  selectedHashtags);
                                              hashtagController.clear();
                                            }
                                          },
                                          onSubmitted: (value) {
                                            if (value.trim().isNotEmpty &&
                                                value != '#') {
                                              _addNewHashtag(
                                                  value,
                                                  hashtagController,
                                                  setModalState,
                                                  selectedHashtags);
                                            }
                                          },
                                        ),
                                      ),
                                      // ✅ แก้ไขปุ่มบวก - ลบ IconButton ที่ซ้อนกัน
                                      IconButton(
                                        icon: const Icon(Icons.add,
                                            color: Colors.blue),
                                        onPressed: () {
                                          final value =
                                              hashtagController.text.trim();
                                          if (value.isNotEmpty &&
                                              value != '#') {
                                            _addNewHashtag(
                                                value,
                                                hashtagController,
                                                setModalState,
                                                selectedHashtags);
                                          }
                                        },
                                      )
                                    ],
                                  ),
                                )
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
          },
        );
      },
    );
  }

// ฟังก์ชันโหลดหมวดหมู่
  Future<List<GetAllCategory>> _loadAllCategories() async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];
    final response = await http.get(Uri.parse('$url/category/get'));
    if (response.statusCode == 200) {
      return getAllCategoryFromJson(response.body);
    } else {
      return [];
    }
  }

// ฟังก์ชันบันทึกโพสต์
  Future<void> _saveEditedPost(
    BuildContext context,
    String topic,
    String description,
    List<Object> hashtags,
    List<int> categoryIds,
  ) async {
    // ✅ ลบ SnackBar ที่แสดง "กำลังบันทึก..."

    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      final response = await http.put(
        Uri.parse('$url/image_post/post/edit/${widget.postId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': loggedInUserId,
          'post_topic': topic,
          'post_description': description,
          'hashtags': hashtags,
          'categories': categoryIds,
        }),
      );

      if (context.mounted) {
        // ✅ ไม่มี hideCurrentSnackBar() เพราะไม่มี loading snackbar
        if (response.statusCode == 200) {
          // ✅ แสดง Success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('แก้ไขโพสต์สำเร็จ'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context);
          await fetchPostDetail();
        } else {
          final errorData = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorData['error'] ?? 'แก้ไขโพสต์ไม่สำเร็จ'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      debugPrint('Error editing post: $e');
    }
  }

  void _showCommentBottomSheet(BuildContext context, int postId) {
    TextEditingController commentController = TextEditingController();
    FocusNode focusNode = FocusNode();

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
                            color: Color.fromARGB(255, 0, 0, 0),
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
                                          Color.fromARGB(255, 0, 0, 0)),
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
                                final isCommentOwner = loggedInUserId == c.uid;
                                final isLiked =
                                    commentLikedMap[c.commentId] ?? false;
                                final likeCount =
                                    commentLikeCountMap[c.commentId] ?? 0;

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
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.access_time,
                                                          size: 12,
                                                          color:
                                                              Colors.grey[500],
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          _formatTimeAgo(
                                                              c.createdAt),
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: Colors
                                                                .grey[500],
                                                            fontWeight:
                                                                FontWeight.w400,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          // 🎯 เพิ่มส่วน Like Button
                                          Row(
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  toggleCommentLike(
                                                      c.commentId);
                                                  setModalState(
                                                      () {}); // รีเฟรช UI ใน modal
                                                },
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      isLiked
                                                          ? Icons.favorite
                                                          : Icons
                                                              .favorite_border,
                                                      size: 18,
                                                      color: isLiked
                                                          ? Colors.red
                                                          : Colors.grey[600],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      likeCount > 0
                                                          ? '$likeCount'
                                                          : '',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          // แสดงปุ่มลบถ้าเป็นเจ้าของคอมเมนต์ หรือเจ้าของโพสต์
                                          // แสดงปุ่มลบถ้าเป็นเจ้าของคอมเมนต์ หรือเจ้าของโพสต์
                                          if (isCommentOwner ||
                                              loggedInUserId ==
                                                  postDetail!.post.postFkUid)
                                            PopupMenuButton<String>(
                                              onSelected: (value) async {
                                                if (value == 'edit') {
                                                  final success =
                                                      await _editComment(
                                                    context,
                                                    c.commentId,
                                                    c.commentText,
                                                  );
                                                  if (success && mounted) {
                                                    setModalState(
                                                        () {}); // รีเฟรช UI ทันที
                                                  }
                                                } else if (value == 'delete') {
                                                  final success =
                                                      await _deleteComment(
                                                    context,
                                                    c.commentId,
                                                    loggedInUserId,
                                                  );
                                                  if (success && mounted) {
                                                    setModalState(
                                                        () {}); // รีเฟรช UI ทันที
                                                  }
                                                }
                                              },
                                              itemBuilder:
                                                  (BuildContext context) => [
                                                // แสดงปุ่มแก้ไขเฉพาะเจ้าของคอมเมนต์
                                                if (isCommentOwner)
                                                  const PopupMenuItem<String>(
                                                    value: 'edit',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.edit,
                                                            color:
                                                                Color.fromARGB(
                                                                    255,
                                                                    0,
                                                                    0,
                                                                    0),
                                                            size: 18),
                                                        SizedBox(width: 8),
                                                        Text('แก้ไข',
                                                            style: TextStyle(
                                                                color: Color
                                                                    .fromARGB(
                                                                        255,
                                                                        0,
                                                                        0,
                                                                        0))),
                                                      ],
                                                    ),
                                                  ),
                                                const PopupMenuItem<String>(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.delete,
                                                          color: Colors.red,
                                                          size: 18),
                                                      SizedBox(width: 8),
                                                      Text('ลบ',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.red)),
                                                    ],
                                                  ),
                                                ),
                                              ],
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
                                  controller: commentController,
                                  focusNode: focusNode,
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
                              valueListenable: commentController,
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
                                              final text =
                                                  commentController.text.trim();
                                              if (text.isNotEmpty) {
                                                commentController.clear();
                                                focusNode.unfocus();

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
                                                setModalState(() {});
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
    final commentData = getCommentFromJson(res.body);

    // ดึง commentId แล้วเรียก checkCommentLikes แต่ไม่ต้อง await
    final commentIds = commentData.comments.map((c) => c.commentId).toList();
    checkCommentLikes(commentIds); // 🔥 เรียก background

    return commentData; // คืนค่าคอมเมนต์ทันที
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

          setState(() {});
        }
      } else {
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
    log('postStatus: ${post.postStatus}');

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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: user.profileImage != null &&
                            user.profileImage!.isNotEmpty
                        ? NetworkImage(user.profileImage!)
                        : null,
                    child:
                        user.profileImage == null || user.profileImage!.isEmpty
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: getStatusColor(post.postStatus)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: getStatusColor(post.postStatus),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  getStatusIcon(post.postStatus),
                                  size: 8,
                                  color: getStatusDarkColor(post.postStatus),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  getStatusText(post.postStatus),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    color: getStatusDarkColor(post.postStatus),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _timeAgo(post.postDate),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )),
                  IconButton(
                    icon: const Icon(Icons.more_horiz),
                    onPressed: () {
                      final isOwner = loggedInUserId == user.uid;

                      showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isOwner)
                                ListTile(
                                  leading: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  title: const Text("แก้ไขโพสต์"),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _editPost(context);
                                  },
                                ),
                              if (isOwner)
                                ListTile(
                                  leading: const Icon(Icons.delete,
                                      color: Colors.red),
                                  title: const Text(
                                    "ลบโพสต์",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _deletePost(context, widget.postId);
                                  },
                                ),
                              if (!isOwner)
                                ListTile(
                                  leading: const Icon(Icons.report,
                                      color: Colors.red),
                                  title: const Text("รายงานโพสต์"),
                                  onTap: () {
                                    Navigator.pop(context);
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (context) {
                                        final reasons = [
                                          "สแปม",
                                          "เนื้อหาไม่เหมาะสม",
                                          "ละเมิดลิขสิทธิ์",
                                          "อื่น ๆ",
                                        ];

                                        return ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: reasons.length,
                                          itemBuilder: (context, index) {
                                            return ListTile(
                                              title: Text(reasons[index]),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _reportPost(
                                                  context,
                                                  post.postId,
                                                  reasons[index],
                                                  gs.read('user'),
                                                );
                                              },
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            if (postDetail!.images.isNotEmpty)
              SizedBox(
                height: 400,
                child: PageView.builder(
                  itemCount: postDetail!.images.length,
                  itemBuilder: (context, index) {
                    final imageUrl = postDetail!.images[index].image;

                    return GestureDetector(
                      onDoubleTap: () {
                        setState(() {
                          showHeart = true;
                        });

                        Future.delayed(const Duration(milliseconds: 800), () {
                          if (mounted) {
                            setState(() {
                              showHeart = false;
                            });
                          }
                        });

                        toggleLike();
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
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
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                          if (showHeart)
                            Center(
                              child: AnimatedScale(
                                scale: showHeart ? 1.2 : 0.0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.elasticOut,
                                child: AnimatedOpacity(
                                  opacity: showHeart ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          const Color.fromARGB(255, 247, 32, 32)
                                              .withOpacity(0.8),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color.fromARGB(
                                                  255, 247, 32, 32)
                                              .withOpacity(0.3),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.favorite,
                                      color: Colors.white,
                                      size: 36,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.black,
                          size: 28,
                        ),
                        onPressed: toggleLike,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.chat,
                          color: Colors.black,
                          size: 28,
                        ),
                        onPressed: () =>
                            _showCommentBottomSheet(context, widget.postId),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      savedMap[widget.postId] == true
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      color: savedMap[widget.postId] == true
                          ? Color.fromARGB(255, 255, 200, 0)
                          : Colors.black,
                      size: 24,
                    ),
                    onPressed: () {
                      savePost(widget.postId);
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${post.amountOfLike} likes',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FutureBuilder<GetComment>(
                    future: _fetchComments(widget.postId),
                    builder: (context, snapshot) {
                      if (snapshot.hasData &&
                          snapshot.data!.comments.isNotEmpty) {
                        final commentCount = snapshot.data!.comments.length;
                        return GestureDetector(
                          onTap: () =>
                              _showCommentBottomSheet(context, widget.postId),
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
                  if (post.postDescription != null &&
                      post.postDescription!.isNotEmpty)
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
            _buildCategoriesSection(),
            _buildHashtagsSection(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _reportPost(
      BuildContext context, int postId, String reason, int reporterId) async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    try {
      final response = await http.post(
        Uri.parse("$url/image_post/report-posts"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "post_id": postId,
          "reporter_id": reporterId,
          "reason": reason,
        }),
      );

      final resBody = jsonDecode(response.body);
      final message = resBody['message'] ?? "รายงานโพสต์สำเร็จ";
      final isAlreadyReported = message.contains("รายงานไปแล้ว");

      Get.snackbar(
        "สถานะ",
        message,
        backgroundColor: isAlreadyReported ? Colors.orange : Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        "เกิดข้อผิดพลาด",
        "$e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<bool> _editComment(
    BuildContext context,
    int commentId,
    String currentText,
  ) async {
    final TextEditingController editController =
        TextEditingController(text: currentText);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.edit, color: Colors.blue[400]),
            const SizedBox(width: 8),
            const Text('แก้ไขความคิดเห็น'),
          ],
        ),
        content: TextField(
          controller: editController,
          maxLines: 5,
          maxLength: 1000,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'แก้ไขความคิดเห็นของคุณ...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              if (editController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กรุณาใส่ความคิดเห็น'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 0, 0, 0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    if (confirmed != true) return false;

    final newText = editController.text.trim();
    if (newText.isEmpty) return false;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('กำลังแก้ไขความคิดเห็น...'),
            ],
          ),
          duration: Duration(seconds: 30),
          backgroundColor: Colors.blue,
        ),
      );
    }

    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      final response = await http.put(
        Uri.parse('$url/image_post/edit-comment/$commentId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': loggedInUserId,
          'post_id': widget.postId,
          'comment_text': newText,
        }),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final editedBy = data['editedBy'] ?? 'ผู้ใช้';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('แก้ไขความคิดเห็นสำเร็จ (โดย: $editedBy)'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          setState(() {}); // รีเฟรช state หลัก
          return true; // ✅ คืนค่า true เมื่อสำเร็จ
        } else {
          final errorData = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child:
                        Text(errorData['error'] ?? 'แก้ไขความคิดเห็นไม่สำเร็จ'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          return false;
        }
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('เกิดข้อผิดพลาด: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }
}
