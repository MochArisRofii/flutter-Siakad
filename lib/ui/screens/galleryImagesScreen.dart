import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool/data/models/galleryFile.dart';
import 'package:eschool/ui/widgets/customAppbar.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class GalleryImagesScreen extends StatefulWidget {
  final List<GalleryFile> images;
  final int currentImageIndex;
  GalleryImagesScreen(
      {Key? key, required this.currentImageIndex, required this.images})
      : super(key: key);

  static Route route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => GalleryImagesScreen(
        currentImageIndex: arguments['currentImageIndex'],
        images: arguments['images'],
      ),
    );
  }

  @override
  State<GalleryImagesScreen> createState() => _GalleryImagesScreenState();
}

class _GalleryImagesScreenState extends State<GalleryImagesScreen> {
  late final PageController _pageController =
      PageController(initialPage: widget.currentImageIndex);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height *
                      (Utils.appBarSmallerHeightPercentage)),
              child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.images.length,
                  itemBuilder: (context, index) {
                    final galleryImage = widget.images[index];
                    return galleryImage.isSvgImage()
                        ? SvgPicture.network(galleryImage.fileUrl ?? "")
                        : CachedNetworkImage(
                            imageUrl: galleryImage.fileUrl ?? "");
                  }),
            ),
          ),
          CustomAppBar(title: ""),
        ],
      ),
    );
  }
}
