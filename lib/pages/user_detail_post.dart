import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:fontend_pro/models/like_post.dart';
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
  bool isSavingLike = false; // ป้องกันกดซ้ำขณะกำลังส่ง
  int loggedInUserId = 0;

  Map<int, bool> savedMap = {};
  Map<int, int> saveCountMap = {};
  bool isSavingSave = false; // ป้องกันกดซ้ำ

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

    final uid = gs.read('user'); // อ่าน user id จาก GetStorage
    final isSaved = savedMap[postId] ?? false; // สถานะปัจจุบัน

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
      } else {
        // handle error
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
    final uid = gs.read('user'); // user id จาก GetStorage
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
      } else {
        // handle error
      }
    } catch (e) {
      // handle error
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
    if (postDetail?.categories.isEmpty ?? true) return const SizedBox.shrink();

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
              border: Border.all(color: Color.fromARGB(255, 0, 0, 0)),
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
    if (postDetail?.hashtags.isEmpty ?? true) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 4,
        children: postDetail!.hashtags.map((hashtag) {
          return GestureDetector(
            onTap: () {
              // TODO: Navigate to hashtag search page
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
        body: Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: const Center(
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
                    backgroundImage: user.profileImage.isNotEmpty
                        ? NetworkImage(user.profileImage)
                        : null,
                    child: user.profileImage.isEmpty
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
                          Icons.chat_bubble_outline,
                          color: Colors.black,
                          size: 28,
                        ),
                        onPressed: () {},
                      ),
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

            // Likes count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                '${post.amountOfLike} likes',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
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
                  if (post.postDescription.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        post.postDescription,
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