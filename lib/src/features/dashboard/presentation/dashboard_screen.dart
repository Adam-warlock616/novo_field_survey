import 'package:field_pro/src/features/authentication/data/auth_repository.dart';
import 'package:field_pro/src/features/authentication/presentation/profile_screen.dart';
import 'package:field_pro/src/features/survey/data/survey_repository.dart';
import 'package:field_pro/src/features/survey/domain/survey_model.dart';
import 'package:field_pro/src/features/survey/presentation/create_survey_screen.dart';
import 'package:field_pro/src/features/survey/presentation/map_view.dart';
import 'package:field_pro/src/features/survey/presentation/survey_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0; // 0 = List, 1 = Map
  bool _isCheckingPermissions = false;

  @override
  void initState() {
    super.initState();
    // Trigger permission check on start
    _checkPermissions();
  }

  // Improved permission logic with user feedback
  Future<void> _checkPermissions() async {
    if (_isCheckingPermissions) return;

    setState(() {
      _isCheckingPermissions = true;
    });

    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        // Show dialog to enable location services
        if (mounted) {
          await _showEnableLocationDialog();
        }
        debugPrint("❌ Location services are disabled.");
        return;
      }

      // Check current permission status
      permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // Request permission - THIS SHOWS THE SYSTEM PERMISSION DIALOG
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Location permissions are required for map features',
                ),
                duration: Duration(seconds: 3),
              ),
            );
          }
          debugPrint("❌ Location permissions are denied");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Show dialog to open app settings
        if (mounted) {
          await _showPermissionDeniedForeverDialog();
        }
        debugPrint("❌ Location permissions are permanently denied");
        return;
      }

      debugPrint("✅ Location Permission Granted!");

      if (mounted && permission == LocationPermission.whileInUse) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location access enabled for app usage'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error checking permissions: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingPermissions = false;
        });
      }
    }
  }

  Future<void> _showEnableLocationDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Location Services'),
        content: const Text(
          'Location services are disabled. Please enable them to use map features and capture GPS coordinates for surveys.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPermissionDeniedForeverDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'Location permissions are permanently denied. Please enable them in app settings to use map features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // Function to manually refresh permissions if needed
  Future<void> _refreshPermissions() async {
    await _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the list of surveys
    final surveyListAsync = ref.watch(surveyListProvider);

    // Get Current User info
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? "Technician";
    final letter = email.isNotEmpty ? email.substring(0, 1).toUpperCase() : "T";

    // Access the current Theme (Light/Dark)
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Novo Field Pro"),
        centerTitle: true,
        actions: [
          // Add a refresh button for permissions when in map view
          if (_selectedIndex == 1)
            IconButton(
              icon: _isCheckingPermissions
                  ? const CircularProgressIndicator.adaptive()
                  : const Icon(Icons.refresh),
              onPressed: _isCheckingPermissions ? null : _refreshPermissions,
              tooltip: 'Refresh Location Permissions',
            ),
        ],
      ),

      // --- 1. SIDE DRAWER (PROFILE MENU) ---
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: theme.colorScheme.primary),
              accountName: const Text("Novo Technician"),
              accountEmail: Text(email),
              currentAccountPicture: CircleAvatar(
                backgroundColor: theme.colorScheme.surface,
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: 24,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("My Profile"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text("Location Settings"),
              subtitle: _isCheckingPermissions
                  ? const Text("Checking...")
                  : const Text("Manage location permissions"),
              onTap: _refreshPermissions,
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Log Out", style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                ref.read(authRepositoryProvider).signOut();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),

      // --- 2. BODY (SWITCHES BETWEEN LIST AND MAP) ---
      body: surveyListAsync.when(
        data: (surveys) {
          // Explicitly cast to List<SurveyModel> to be safe
          final List<SurveyModel> surveyList = surveys.cast<SurveyModel>();

          if (surveyList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 80,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No surveys yet.",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tap + to create your first survey",
                    style: TextStyle(
                      color: Colors.grey.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          // SWITCH VIEW BASED ON SELECTION
          if (_selectedIndex == 0) {
            // --- LIST VIEW ---
            return RefreshIndicator(
              onRefresh: () async {
                // Refresh survey data
                ref.invalidate(surveyListProvider);
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: surveyList.length,
                itemBuilder: (context, index) {
                  final survey = surveyList[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: survey.status == 'Completed'
                            ? Colors.green[100]
                            : survey.status == 'Signed'
                            ? Colors.teal[100]
                            : Colors.orange[100],
                        child: Icon(
                          survey.status == 'Completed'
                              ? Icons.check_circle
                              : survey.status == 'Signed'
                              ? Icons.verified
                              : Icons.work_outline,
                          color: survey.status == 'Completed'
                              ? Colors.green[700]
                              : survey.status == 'Signed'
                              ? Colors.teal[700]
                              : Colors.orange[700],
                          size: 24,
                        ),
                      ),
                      title: Text(
                        survey.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            survey.address,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 12,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat.yMMMd().format(survey.dateCreated),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Chip(
                                label: Text(
                                  survey.status,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                backgroundColor: survey.status == 'Completed'
                                    ? Colors.green[50]
                                    : survey.status == 'Signed'
                                    ? Colors.teal[50]
                                    : Colors.orange[50],
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 0,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: Colors.grey[500],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SurveyDetailsScreen(survey: survey),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          } else {
            // --- MAP VIEW ---
            return DashboardMapView(surveys: surveyList);
          }
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading surveys...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error loading surveys',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(surveyListProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),

      // --- 3. FLOATING ACTION BUTTON ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateSurveyScreen()),
          );
        },
        label: const Text("New Survey"),
        icon: const Icon(Icons.add),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 4,
      ),

      // --- 4. BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_outlined),
            selectedIcon: Icon(Icons.list),
            label: 'List',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
        ],
      ),
    );
  }
}
