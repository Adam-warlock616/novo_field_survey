import 'package:field_pro/src/features/survey/data/survey_repository.dart';
import 'package:field_pro/src/features/survey/domain/survey_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ElectricalScreen extends ConsumerStatefulWidget {
  final SurveyModel survey;

  const ElectricalScreen({super.key, required this.survey});

  @override
  ConsumerState<ElectricalScreen> createState() => _ElectricalScreenState();
}

class _ElectricalScreenState extends ConsumerState<ElectricalScreen> {
  // Controllers for text input
  final _locationController = TextEditingController();
  final _ampsController = TextEditingController();

  // State for the switch
  bool _isUpgradable = true;

  @override
  void initState() {
    super.initState();
    // Pre-fill data if it exists
    _locationController.text = widget.survey.panelLocation == 'Unknown'
        ? ''
        : widget.survey.panelLocation;

    _ampsController.text = widget.survey.mainBreakerAmps == 0
        ? ""
        : widget.survey.mainBreakerAmps.toString();

    _isUpgradable = widget.survey.isPanelUpgradable;
  }

  // --- CRITICAL FIX: Dispose controllers to prevent memory leaks ---
  @override
  void dispose() {
    _locationController.dispose();
    _ampsController.dispose();
    super.dispose();
  }

  void _saveData() async {
    // 1. Update the model
    final updatedSurvey = widget.survey.copyWith(
      panelLocation: _locationController.text,
      mainBreakerAmps: int.tryParse(_ampsController.text) ?? 0,
      isPanelUpgradable: _isUpgradable,
      status: 'In Progress',
    );

    // 2. Save to Firebase via Repository
    await ref.read(surveyRepositoryProvider).addSurvey(updatedSurvey);

    // 3. Handle UI Feedback
    if (mounted) {
      Navigator.pop(context); // Close screen
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Electrical Data Saved!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Electrical Panel")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. Location Input
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: "Panel Location (e.g. Garage)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.map),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Amperage Input
            TextField(
              controller: _ampsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Main Breaker (Amps)",
                hintText: "e.g. 200",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flash_on),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Upgradable Switch
            SwitchListTile(
              title: const Text("Space for new breakers?"),
              subtitle: Text(_isUpgradable ? "Yes" : "No, panel is full"),
              value: _isUpgradable,
              onChanged: (val) {
                setState(() => _isUpgradable = val);
              },
            ),

            const Spacer(),

            // 4. Save Button (Styled)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saveData,
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
