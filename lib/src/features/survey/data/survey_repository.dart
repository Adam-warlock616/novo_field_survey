import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:field_pro/src/features/survey/domain/survey_model.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <--- 1. Need Auth
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SurveyRepository {
  final FirebaseFirestore _firestore;

  SurveyRepository(this._firestore);

  // 1. CREATE / UPDATE
  Future<void> addSurvey(SurveyModel survey) async {
    await _firestore.collection('surveys').doc(survey.id).set(survey.toMap());
  }

  // 2. READ: Stream list of surveys (FILTERED BY TECHNICIAN)
  Stream<List<SurveyModel>> getSurveys(String technicianId) {
    // <--- 2. Accept ID
    return _firestore
        .collection('surveys')
        .where('technicianId', isEqualTo: technicianId) // <--- 3. THE FILTER
        .orderBy('dateCreated', descending: true) // <--- 4. SORT NEWEST FIRST
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return SurveyModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // 3. DELETE
  Future<void> deleteSurvey(String surveyId) async {
    await _firestore.collection('surveys').doc(surveyId).delete();
  }
}

// --- RIVERPOD PROVIDERS ---

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final surveyRepositoryProvider = Provider<SurveyRepository>((ref) {
  return SurveyRepository(ref.watch(firestoreProvider));
});

// 4. THE STREAM PROVIDER (Now with Auth Logic)
final surveyListProvider = StreamProvider<List<SurveyModel>>((ref) {
  final repository = ref.watch(surveyRepositoryProvider);

  // Get the Current User
  final user = FirebaseAuth.instance.currentUser;

  // Security Check: If no user, return empty list
  if (user == null) {
    return Stream.value([]);
  }

  // Pass the UID to the repository
  return repository.getSurveys(user.uid);
});
