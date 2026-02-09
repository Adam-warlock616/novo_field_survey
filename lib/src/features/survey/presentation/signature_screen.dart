import 'dart:typed_data';
import 'package:field_pro/src/features/survey/data/survey_repository.dart';
import 'package:field_pro/src/features/survey/domain/survey_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart'; // The Signature Package

class SignatureScreen extends ConsumerStatefulWidget {
  final SurveyModel survey;

  const SignatureScreen({super.key, required this.survey});

  @override
  ConsumerState<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends ConsumerState<SignatureScreen> {
  // 1. Setup the Signature Controller
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3, // Thicker, pen-like stroke
    penColor: Colors.black, // Classic ink color
    exportBackgroundColor:
        Colors.transparent, // Export with transparent background
  );

  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 2. Logic to Save the Signature
  Future<void> _handleSave() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please sign above to approve.")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Export signature to PNG bytes
      final Uint8List? signatureBytes = await _controller.toPngBytes();

      if (signatureBytes != null) {
        // --- REAL WORLD APP LOGIC ---
        // 1. Upload 'signatureBytes' to Firebase Storage here.
        // 2. Get the URL back.
        // 3. Save URL to database.

        // For this MVP, we mark the survey as "Signed" in the local database.
        final updatedSurvey = widget.survey.copyWith(
          status: 'Signed',
          // signatureUrl: uploadedUrl, // <--- Add this field to your model later
        );

        // Update Repository
        await ref.read(surveyRepositoryProvider).addSurvey(updatedSurvey);

        if (mounted) {
          // Success Message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Signature Saved! Survey Approved. ✍️"),
              backgroundColor: Colors.green,
            ),
          );

          // Return to previous screen, passing back the image bytes if needed
          Navigator.pop(context, signatureBytes);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Light grey background like a desk
      appBar: AppBar(
        title: const Text(
          "Customer Approval",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // --- 1. LEGAL HEADER ---
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "I, ${widget.survey.customerName}, approve this site survey.",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "By signing below, you acknowledge that the site measurements and photos are accurate and agree to proceed with the project proposal.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "Date: ${DateTime.now().toString().split(' ')[0]}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- 2. SIGNATURE PAD AREA ---
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    children: [
                      // The "Sign Here" Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        color: Colors.grey[200],
                        child: const Center(
                          child: Text(
                            "SIGN HERE",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      // The Actual Signature Pad
                      Expanded(
                        child: Signature(
                          controller: _controller,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // --- 3. BOTTOM ACTIONS ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // CLEAR BUTTON
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _controller.clear(),
                    icon: const Icon(Icons.refresh, color: Colors.red),
                    label: const Text(
                      "Clear",
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // APPROVE BUTTON
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _handleSave,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle),
                    label: Text(_isSaving ? "Saving..." : "Approve & Sign"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
