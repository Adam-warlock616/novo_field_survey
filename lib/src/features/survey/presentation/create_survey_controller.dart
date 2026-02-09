import 'package:field_pro/src/features/survey/data/survey_repository.dart';
import 'package:field_pro/src/features/survey/domain/survey_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

class CreateSurveyController extends StateNotifier<AsyncValue<void>> {
  final SurveyRepository _repository;

  CreateSurveyController(this._repository) : super(const AsyncValue.data(null));

  // --- UPDATED: Now accepts technicianId ---
  Future<void> createSurvey({
    required String name,
    required String address,
    required String technicianId, // <--- 1. NEW PARAMETER
    double latitude = 0.0,
    double longitude = 0.0,
  }) async {
    // 1. Set state to loading
    state = const AsyncValue.loading();

    // 2. Create the Survey Object
    final newSurvey = SurveyModel(
      id: const Uuid().v4(),
      technicianId: technicianId, // <--- 2. STAMP IT HERE
      customerName: name,
      address: address,
      dateCreated: DateTime.now(),
      status: 'Draft',
      latitude: latitude,
      longitude: longitude,
    );

    // 3. Save to Firebase via Repository
    state = await AsyncValue.guard(() => _repository.addSurvey(newSurvey));
  }
}

// --- PROVIDER ---
final createSurveyControllerProvider =
    StateNotifierProvider<CreateSurveyController, AsyncValue<void>>((ref) {
      final repository = ref.watch(surveyRepositoryProvider);
      return CreateSurveyController(repository);
    });
