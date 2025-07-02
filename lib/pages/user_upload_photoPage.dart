import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:fontend_pro/pages/%E0%B8%B5user_all_uploadPage.dart';

class UserUploadPhotopage extends StatefulWidget {
  const UserUploadPhotopage({super.key});

  @override
  State<UserUploadPhotopage> createState() => _UserUploadPhotopageState();
}

class _UserUploadPhotopageState extends State<UserUploadPhotopage> {
  List<AssetEntity> images = [];
  Set<AssetEntity> selectedImages = {};
  bool isLoading = false;
  final int maxSelection = 5;

  final Map<AssetEntity, Uint8List?> thumbnailCache = {};
  final GetStorage gs = GetStorage();

  @override
  void initState() {
    super.initState();
    _loadImages();
    var user = gs.read('user');
    log('user id: ${user.toString()}');
  }

  Future<void> _loadImages() async {
    setState(() {
      isLoading = true;
    });

    final PermissionState ps = await PhotoManager.requestPermissionExtend();

    if (!ps.hasAccess) {
      await PhotoManager.openSetting();
      setState(() {
        isLoading = false;
      });
      return;
    }

    List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );

    if (albums.isNotEmpty) {
      List<AssetEntity> media = await albums[0].getAssetListPaged(
        page: 0,
        size: 100,
      );

      for (final asset in media) {
        final thumbData =
            await asset.thumbnailDataWithSize(const ThumbnailSize(200, 200));
        thumbnailCache[asset] = thumbData;
      }

      setState(() {
        images = media;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onImageTap(AssetEntity image) {
    setState(() {
      if (selectedImages.contains(image)) {
        selectedImages.remove(image);
      } else {
        if (selectedImages.length < maxSelection) {
          selectedImages.add(image);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เลือกได้สูงสุด $maxSelection รูปเท่านั้น')),
          );
        }
      }
    });
  }

  Future<void> _onNextPressed() async {
    if (selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('โปรดเลือกภาพก่อนกดถัดไป')),
      );
      return;
    }

    // เก็บ id ของรูปที่เลือกใน GetStorage
    final List<String> selectedIds =
        selectedImages.map((e) => e.id).toList(growable: false);
    await gs.write('selected_image_ids', selectedIds);

    // ไปหน้า UserAllUploadPage
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserAllUploadPage()),
    );
  }

  Widget _buildGridItem(AssetEntity image) {
    final bool isSelected = selectedImages.contains(image);
    final Uint8List? thumbData = thumbnailCache[image];

    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: isSelected ? 10 : 3,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isSelected
            ? BorderSide(color: Colors.blueGrey.shade300, width: 3)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _onImageTap(image),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumbData != null)
              Image.memory(
                thumbData,
                fit: BoxFit.cover,
              )
            else
              Container(color: Colors.grey[900]),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: isSelected
                  ? Colors.blueGrey.withOpacity(0.4)
                  : Colors.transparent,
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade700.withOpacity(0.85),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueGrey.shade900.withOpacity(0.7),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white70,
                    size: 28,
                  ),
                  padding: const EdgeInsets.all(5),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        elevation: 6,
        centerTitle: true,
        title: Text(
          'เลือกภาพ (${selectedImages.length}/$maxSelection)',
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueGrey))
          : images.isEmpty
              ? const Center(
                  child: Text(
                    'ไม่พบรูปภาพในเครื่อง',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: GridView.builder(
                    itemCount: images.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) =>
                        _buildGridItem(images[index]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onNextPressed,
        icon: const Icon(Icons.arrow_forward),
        label: const Text('ถัดไป'),
        backgroundColor: Colors.blueGrey.shade700,
        foregroundColor: Colors.white70,
        elevation: 8,
      ),
    );
  }
}
