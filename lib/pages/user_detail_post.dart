import 'package:flutter/material.dart';
import 'package:fontend_pro/models/get_post_user.dart' as model;

class UserDetailPost extends StatefulWidget {
  final model.GetPostUser postUser;

  const UserDetailPost({super.key, required this.postUser});

  @override
  State<UserDetailPost> createState() => _UserDetailPostState();
}

class _UserDetailPostState extends State<UserDetailPost>
    with TickerProviderStateMixin {
  int _currentImageIndex = 0;
  bool _isLiked = false;
  bool _isSaved = false;

  late AnimationController _likeAnimationController;
  late AnimationController _saveAnimationController;
  late Animation<double> _likeAnimation;
  late Animation<double> _saveAnimation;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _saveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _likeAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _likeAnimationController, curve: Curves.elasticOut),
    );
    _saveAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _saveAnimationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    _saveAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.postUser.post;
    final images = widget.postUser.images;
    final categories = widget.postUser.categories;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'โพสต์',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.black),
                onPressed: () {},
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(),

                _buildImageCarousel(images),

                _buildInstagramActions(),

                _buildCaptionSection(post),

                if (categories.isNotEmpty) _buildHashtagSection(categories),

                // เอาส่วน comments ออกตามคำขอ

                Container(
                  height: 1,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.symmetric(vertical: 20),
                ),

                _buildRelatedSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF404040), Color(0xFF808080), Color(0xFF404040)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(2),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(
                  'https://via.placeholder.com/150',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'ผู้ใช้งาน',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'ประเทศไทย',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(List<dynamic> images) {
    if (images.isEmpty) {
      return Container(
        height: 400,
        color: Colors.grey[100],
        child: const Center(
          child: Icon(
            Icons.image_not_supported,
            size: 80,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Stack(
      children: [
        SizedBox(
          height: 400,
          child: PageView.builder(
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Image.network(
                images[index].image,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.grey[100],
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[100],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 80, color: Colors.grey),
                    ),
                  );
                },
              );
            },
          ),
        ),

        if (images.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: index == _currentImageIndex ? 8 : 6,
                  height: index == _currentImageIndex ? 8 : 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentImageIndex
                        ? Colors.grey[800]
                        : Colors.grey.withOpacity(0.4),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildInstagramActions() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isLiked = !_isLiked;
              });
              if (_isLiked) {
                _likeAnimationController.forward().then((_) {
                  _likeAnimationController.reverse();
                });
              }
            },
            child: AnimatedBuilder(
              animation: _likeAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _likeAnimation.value,
                  child: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 28,
                    color: _isLiked ? Colors.red : Colors.black,
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 20),

          GestureDetector(
            onTap: () {},
            child: const Icon(
              Icons.mode_comment_outlined,
              size: 28,
              color: Colors.black,
            ),
          ),

          const SizedBox(width: 20),

          GestureDetector(
            onTap: () {},
            child: const Icon(
              Icons.send_outlined,
              size: 28,
              color: Colors.black,
            ),
          ),

          const Spacer(),

          GestureDetector(
            onTap: () {
              setState(() {
                _isSaved = !_isSaved;
              });
              if (_isSaved) {
                _saveAnimationController.forward().then((_) {
                  _saveAnimationController.reverse();
                });
              }
            },
            child: AnimatedBuilder(
              animation: _saveAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _saveAnimation.value,
                  child: Icon(
                    _isSaved ? Icons.bookmark : Icons.bookmark_border,
                    size: 28,
                    color: _isSaved ? Colors.amber : Colors.black,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptionSection(dynamic post) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.postTopic != null)
            Text(
              post.postTopic!,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),

          const SizedBox(height: 8),

          RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'ผู้ใช้งาน ',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                TextSpan(
                  text: post.postDescription ?? 'ไม่มีรายละเอียด',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHashtagSection(List<dynamic> categories) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: categories.map((cat) {
          return GestureDetector(
            onTap: () {},
            child: Text(
              '#${cat.cname}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRelatedSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'โพสต์ที่เกี่ยวข้อง',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      'https://via.placeholder.com/120',
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
