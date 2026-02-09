import 'dart:typed_data';
import 'package:field_pro/src/features/survey/data/pdf_generator.dart';
import 'package:field_pro/src/features/survey/data/survey_repository.dart';
import 'package:field_pro/src/features/survey/domain/survey_model.dart';
import 'package:field_pro/src/features/survey/presentation/electrical_screen.dart';
import 'package:field_pro/src/features/survey/presentation/roof_measurements_screen.dart';
import 'package:field_pro/src/features/survey/presentation/signature_screen.dart';
import 'package:field_pro/src/features/survey/presentation/task_photos_screen.dart';
import 'package:field_pro/src/features/survey/presentation/survey_photos_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart'; // Add this import for Clipboard

// Signature State Provider
final currentSignatureProvider = StateProvider<Uint8List?>((ref) => null);

class SurveyDetailsScreen extends ConsumerWidget {
  final SurveyModel survey;

  const SurveyDetailsScreen({super.key, required this.survey});

  // --- 1. NAVIGATION (Google Maps) - CORRECTED ---
  Future<void> _openMaps(BuildContext context, SurveyModel survey) async {
    final hasGps = survey.latitude != 0.0 && survey.longitude != 0.0;
    final Uri mapsUrl;

    if (hasGps) {
      // Correct format for GPS coordinates
      mapsUrl = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=${survey.latitude},${survey.longitude}",
      );
    } else {
      // Fallback to address search
      final query = Uri.encodeComponent(survey.address);
      mapsUrl = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=$query",
      );
    }

    try {
      // Try to launch Google Maps directly (app)
      final Uri directUrl = hasGps
          ? Uri.parse(
              "comgooglemaps://?q=${survey.latitude},${survey.longitude}&center=${survey.latitude},${survey.longitude}&zoom=15",
            )
          : Uri.parse(
              "comgooglemaps://?q=${Uri.encodeComponent(survey.address)}",
            );

      // First try to open in Google Maps app
      try {
        if (await canLaunchUrl(directUrl)) {
          await launchUrl(directUrl, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {
        // If Google Maps app isn't installed, continue to web version
      }

      // Open in browser
      await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      print("Could not open maps: $e");
      // Fallback: show a dialog with options
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Open Location"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Address: ${survey.address}"),
                if (hasGps)
                  Text(
                    "Latitude: ${survey.latitude}\nLongitude: ${survey.longitude}",
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              if (hasGps)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Copy coordinates to clipboard
                    Clipboard.setData(
                      ClipboardData(
                        text: "${survey.latitude}, ${survey.longitude}",
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Coordinates copied to clipboard"),
                      ),
                    );
                  },
                  child: const Text("Copy Coordinates"),
                ),
            ],
          ),
        );
      }
    }
  }

  // --- 2. SHARE - CORRECTED ---
  void _shareSurvey(SurveyModel survey) {
    final hasGps = survey.latitude != 0.0 && survey.longitude != 0.0;
    final mapLink = hasGps
        ? "https://www.google.com/maps/search/?api=1&query=${survey.latitude},${survey.longitude}"
        : "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(survey.address)}";

    final text =
        "📋 *New Survey Job*\n👤 Customer: ${survey.customerName}\n📍 Address: ${survey.address}\n🔗 Map: $mapLink\n📅 Created: ${DateFormat.yMMMd().format(survey.dateCreated)}\n📊 Status: ${survey.status}";
    Share.share(text);
  }

  // --- 3. PRINT ---
  void _printReport(
    BuildContext context,
    WidgetRef ref,
    SurveyModel survey,
  ) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Generating PDF..."),
          duration: Duration(seconds: 1),
        ),
      );
      final allPhotos = ref.read(photoManagerProvider);
      final myPhotos = allPhotos[survey.id] ?? [];
      final signature = ref.read(currentSignatureProvider);
      final pdfBytes = await PdfGenerator().generateSurveyReport(
        survey,
        myPhotos,
        signature,
      );
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Survey_${survey.customerName}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- 4. DELETE ---
  void _deleteSurvey(
    BuildContext context,
    WidgetRef ref,
    SurveyModel survey,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Survey?"),
        content: const Text("Are you sure? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(surveyRepositoryProvider).deleteSurvey(survey.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Survey Deleted"),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  // --- 5. COMPLETE ---
  void _completeSurvey(
    BuildContext context,
    WidgetRef ref,
    SurveyModel survey,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Complete Survey?"),
        content: const Text("This will mark the job as finished."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Complete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    final updatedSurvey = survey.copyWith(status: 'Completed');
    await ref.read(surveyRepositoryProvider).addSurvey(updatedSurvey);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Survey Completed!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  // --- 6. EDIT ---
  void _editSurveyDetails(
    BuildContext context,
    WidgetRef ref,
    SurveyModel survey,
  ) {
    final nameController = TextEditingController(text: survey.customerName);
    final addressController = TextEditingController(text: survey.address);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Survey Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Customer Name"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: "Address"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedSurvey = survey.copyWith(
                customerName: nameController.text,
                address: addressController.text,
              );
              await ref.read(surveyRepositoryProvider).addSurvey(updatedSurvey);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'Completed') return Colors.green;
    if (status == 'Signed') return Colors.teal;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surveysAsync = ref.watch(surveyListProvider);

    final liveSurvey = surveysAsync.maybeWhen(
      data: (surveys) {
        try {
          return surveys.firstWhere((s) => s.id == survey.id);
        } catch (e) {
          return survey;
        }
      },
      orElse: () => survey,
    );

    final allPhotos = ref.watch(photoManagerProvider);
    final myPhotos = allPhotos[liveSurvey.id] ?? [];
    final photoCount = myPhotos.length;

    final storedSignature = ref.watch(currentSignatureProvider);
    final isSigned =
        liveSurvey.status == 'Signed' ||
        liveSurvey.status == 'Completed' ||
        storedSignature != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(liveSurvey.customerName),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _deleteSurvey(context, ref, liveSurvey),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareSurvey(liveSurvey),
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printReport(context, ref, liveSurvey),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editSurveyDetails(context, ref, liveSurvey),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Row(
              children: [
                Chip(
                  label: Text(liveSurvey.status.toUpperCase()),
                  backgroundColor: _getStatusColor(liveSurvey.status),
                  labelStyle: const TextStyle(color: Colors.white),
                ),
                const Spacer(),
                Text(
                  "Created: ${DateFormat.MMMd().format(liveSurvey.dateCreated)}",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Address Card with Map Button
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on, color: Colors.blue),
                title: const Text("Site Address"),
                subtitle: Text(liveSurvey.address),
                trailing: IconButton(
                  icon: const Icon(Icons.directions, color: Colors.blue),
                  onPressed: () => _openMaps(
                    context,
                    liveSurvey,
                  ), // Fixed: added context parameter
                ),
              ),
            ),

            // GPS Coordinates (if available)
            if (liveSurvey.latitude != 0.0 && liveSurvey.longitude != 0.0)
              Card(
                margin: const EdgeInsets.only(top: 8),
                child: ListTile(
                  leading: const Icon(Icons.gps_fixed, color: Colors.green),
                  title: const Text("GPS Coordinates"),
                  subtitle: Text(
                    "${liveSurvey.latitude.toStringAsFixed(6)}, ${liveSurvey.longitude.toStringAsFixed(6)}",
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy, color: Colors.grey),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(
                          text:
                              "${liveSurvey.latitude}, ${liveSurvey.longitude}",
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Coordinates copied to clipboard"),
                        ),
                      );
                    },
                  ),
                ),
              ),

            const Divider(height: 32),
            const Text(
              "Survey Tasks",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            // Tasks List
            _buildTaskTile(
              context,
              Icons.photo_camera,
              "Site Photos",
              "$photoCount photos",
              liveSurvey,
            ),
            _buildTaskTile(
              context,
              Icons.straighten,
              "Roof Measurements",
              "${liveSurvey.roofPitch != 'Unknown' ? 'Pitch: ${liveSurvey.roofPitch}' : 'Not measured'}",
              liveSurvey,
            ),
            _buildTaskTile(
              context,
              Icons.electrical_services,
              "Electrical Panel",
              "${liveSurvey.mainBreakerAmps > 0 ? '${liveSurvey.mainBreakerAmps}A' : 'Not inspected'}",
              liveSurvey,
            ),

            const SizedBox(height: 40),

            // Signature Section
            if (isSigned)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified, color: Colors.teal),
                    SizedBox(width: 8),
                    Text(
                      "Customer Signed",
                      style: TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            if (!isSigned)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SignatureScreen(survey: liveSurvey),
                      ),
                    );
                    if (result != null && result is Uint8List) {
                      ref.read(currentSignatureProvider.notifier).state =
                          result;
                    }
                  },
                  icon: const Icon(Icons.draw, color: Colors.blue),
                  label: const Text(
                    "CUSTOMER SIGNATURE",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
              ),

            if (liveSurvey.status != 'Completed')
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () => _completeSurvey(context, ref, liveSurvey),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check_circle),
                  label: const Text("COMPLETE SURVEY"),
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Helper Widget for Tasks
  Widget _buildTaskTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    SurveyModel survey,
  ) {
    final isLocked = survey.status == 'Completed';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isLocked ? Colors.grey[100] : Colors.white,
      child: ListTile(
        leading: Icon(icon, color: isLocked ? Colors.grey : Colors.grey[700]),
        title: Text(
          title,
          style: TextStyle(color: isLocked ? Colors.grey : Colors.black),
        ),
        subtitle: Text(subtitle),
        trailing: isLocked
            ? null
            : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: isLocked
            ? null
            : () {
                if (title == "Site Photos") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TaskPhotosScreen(surveyId: survey.id),
                    ),
                  );
                } else if (title == "Roof Measurements") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          RoofMeasurementsScreen(survey: survey),
                    ),
                  );
                } else if (title == "Electrical Panel") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ElectricalScreen(survey: survey),
                    ),
                  );
                }
              },
      ),
    );
  }
}
