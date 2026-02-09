import 'package:field_pro/src/features/survey/data/survey_repository.dart';
import 'package:field_pro/src/features/survey/domain/survey_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoofMeasurementsScreen extends ConsumerStatefulWidget {
  final SurveyModel survey;

  const RoofMeasurementsScreen({super.key, required this.survey});

  @override
  ConsumerState<RoofMeasurementsScreen> createState() =>
      _RoofMeasurementsScreenState();
}

class _RoofMeasurementsScreenState
    extends ConsumerState<RoofMeasurementsScreen> {
  // Controllers for the form
  final _pitchController = TextEditingController();
  final _azimuthController = TextEditingController();
  double _shadingValue = 0.0;

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing data
    _pitchController.text = widget.survey.roofPitch;
    _azimuthController.text = widget.survey.azimuth;
    _shadingValue = widget.survey.shading;
  }

  @override
  void dispose() {
    _pitchController.dispose();
    _azimuthController.dispose();
    super.dispose();
  }

  void _saveMeasurements() async {
    // 1. Create a new copy of the survey with updated data
    final updatedSurvey = widget.survey.copyWith(
      roofPitch: _pitchController.text,
      azimuth: _azimuthController.text,
      shading: _shadingValue,
      status: 'In Progress', // Update status too!
    );

    // 2. Save to Firebase
    await ref.read(surveyRepositoryProvider).addSurvey(updatedSurvey);

    // 3. Go back
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Measurements Saved!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Roof Measurements")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. Roof Pitch Input
            TextField(
              controller: _pitchController,
              decoration: const InputDecoration(
                labelText: "Roof Pitch (e.g., 30 degrees)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.change_history),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Azimuth Input
            TextField(
              controller: _azimuthController,
              decoration: const InputDecoration(
                labelText: "Azimuth (Orientation)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.compass_calibration),
              ),
            ),
            const SizedBox(height: 24),

            // 3. Shading Slider
            Text("Shading: ${(_shadingValue * 100).round()}%"),
            Slider(
              value: _shadingValue,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: "${(_shadingValue * 100).round()}%",
              onChanged: (value) {
                setState(() {
                  _shadingValue = value;
                });
              },
            ),

            const Spacer(),

            // 4. Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saveMeasurements,
                icon: const Icon(Icons.save),
                label: const Text("SAVE DATA"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
