import 'package:flutter_riverpod/legacy.dart';

// This class manages the photos for ALL surveys in memory
class PhotoManager extends StateNotifier<Map<String, List<String>>> {
  PhotoManager() : super({});

  // 1. Add a photo path to a specific survey
  void addPhoto(String surveyId, String photoPath) {
    final currentPhotos = state[surveyId] ?? [];
    // We create a new map to trigger a state update
    state = {
      ...state,
      surveyId: [...currentPhotos, photoPath],
    };
  }

  // 2. Get photos for a specific survey
  List<String> getPhotos(String surveyId) {
    return state[surveyId] ?? [];
  }
}

// THE PROVIDER (The Global Variable)
final photoManagerProvider =
    StateNotifierProvider<PhotoManager, Map<String, List<String>>>((ref) {
      return PhotoManager();
    });
