import 'package:field_pro/src/features/survey/presentation/create_survey_controller.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <--- 1. NEW IMPORT
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class CreateSurveyScreen extends ConsumerStatefulWidget {
  const CreateSurveyScreen({super.key});

  @override
  ConsumerState<CreateSurveyScreen> createState() => _CreateSurveyScreenState();
}

class _CreateSurveyScreenState extends ConsumerState<CreateSurveyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isFetchingLocation = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      // 2. GET CURRENT USER (Safety Check)
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: No technician logged in!")),
        );
        return;
      }

      setState(() => _isFetchingLocation = true);

      try {
        // --- PERMISSION CHECKS (Keep your existing logic) ---
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.deniedForever) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Location permission is needed for the map."),
              ),
            );
          }
          setState(() => _isFetchingLocation = false);
          return;
        }

        // --- GET LOCATION ---
        double lat = 0.0;
        double long = 0.0;
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          lat = position.latitude;
          long = position.longitude;
        }

        // 3. CALL CONTROLLER (PASS THE ID)
        await ref
            .read(createSurveyControllerProvider.notifier)
            .createSurvey(
              name: _nameController.text.trim(),
              address: _addressController.text.trim(),
              latitude: lat,
              longitude: long,
              technicianId: user.uid, // <--- PASS ID HERE
            );

        if (mounted && !ref.read(createSurveyControllerProvider).hasError) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error getting location: $e")));
        }
      } finally {
        if (mounted) setState(() => _isFetchingLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (Keep your existing build method exactly as it is) ...
    // Just for brevity, I am hiding the UI part since it doesn't change.
    final controllerState = ref.watch(createSurveyControllerProvider);
    final isLoading = _isFetchingLocation || controllerState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text("New Site Survey")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Customer Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Please enter a name" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: "Site Address",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Please enter an address" : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _submit,
                  icon: isLoading
                      ? const SizedBox.shrink()
                      : const Icon(Icons.my_location),
                  label: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("START SURVEY (WITH GPS)"),
                ),
              ),
              if (controllerState.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    "Error: ${controllerState.error}",
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
