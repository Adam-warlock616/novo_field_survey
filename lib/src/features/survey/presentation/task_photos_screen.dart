import 'dart:io';
import 'package:field_pro/src/features/survey/presentation/survey_photos_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class TaskPhotosScreen extends ConsumerWidget {
  final String surveyId;

  const TaskPhotosScreen({super.key, required this.surveyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. WATCH the global provider for photos belonging to THIS survey
    final allPhotosMap = ref.watch(photoManagerProvider);
    final myPhotos = allPhotosMap[surveyId] ?? [];

    final ImagePicker picker = ImagePicker();

    // Function to take photo and save to Provider
    Future<void> takePhoto() async {
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);

      if (photo != null) {
        // SAVE to the Global Provider instead of local list
        ref.read(photoManagerProvider.notifier).addPhoto(surveyId, photo.path);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Site Photos")),
      body: Column(
        children: [
          Expanded(
            child: myPhotos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No photos yet.",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: myPhotos.length,
                    itemBuilder: (context, index) {
                      return Image.file(
                        File(myPhotos[index]), // Load from path
                        fit: BoxFit.cover,
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text("TAKE NEW PHOTO"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
