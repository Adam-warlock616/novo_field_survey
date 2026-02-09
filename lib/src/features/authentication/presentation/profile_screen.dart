import 'package:cloud_firestore/cloud_firestore.dart'; // <--- 1. NEW IMPORT
import 'package:field_pro/src/features/authentication/data/auth_repository.dart';
import 'package:field_pro/src/features/settings/theme_provider.dart';
import 'package:field_pro/src/features/survey/data/survey_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // <--- 2. NEW IMPORT
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // --- STATE VARIABLES ---
  bool _isNotificationsEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  // --- 1. CHECK STATUS ON LOAD ---
  Future<void> _checkNotificationStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();

      if (mounted) {
        setState(() {
          // If 'fcmToken' exists, notifications are considered ON
          _isNotificationsEnabled =
              data != null && data.containsKey('fcmToken');
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error checking notification status: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. TOGGLE LOGIC ---
  Future<void> _toggleNotifications(bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isNotificationsEnabled = value); // UI Update

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    try {
      if (value == true) {
        // TURN ON: Get Token & Save
        String? token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await userRef.set({
            'fcmToken': token,
            'lastActive': DateTime.now(),
          }, SetOptions(merge: true));
          print("🔔 Notifications Enabled");
        }
      } else {
        // TURN OFF: Delete Token Field
        await userRef.update({'fcmToken': FieldValue.delete()});
        print("🔕 Notifications Disabled");
      }
    } catch (e) {
      print("Error toggling notifications: $e");
      // Revert UI if error occurs
      if (mounted) setState(() => _isNotificationsEnabled = !value);
    }
  }

  // --- 3. EDIT PROFILE LOGIC ---
  Future<void> _showEditDialog(User user) async {
    final nameController = TextEditingController(text: user.displayName);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Profile"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: "Full Name",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await user.updateDisplayName(nameController.text.trim());
                await user.reload();
                setState(() {});
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Profile Updated!")),
                  );
                }
              } catch (e) {
                print("Error updating profile: $e");
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // --- 4. PASSWORD RESET LOGIC ---
  Future<void> _changePassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Reset link sent to $email"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final surveysAsync = ref.watch(surveyListProvider);
    final themeMode = ref.watch(themeProvider);

    final name = user?.displayName ?? "Novo Technician";
    final email = user?.email ?? "No Email";
    final letter = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : "T";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Technician Profile"),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                children: [
                  // --- HEADER SECTION ---
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          child: Text(
                            letter,
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          onPressed: () => _showEditDialog(user!),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text("Edit Name"),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surface,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- REAL STATS CARD ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: surveysAsync.when(
                      data: (surveys) {
                        final total = surveys.length;
                        final completed = surveys
                            .where((s) => s.status == 'Completed')
                            .length;
                        final pending = total - completed;

                        return Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(
                                  "Total Jobs",
                                  total.toString(),
                                  Colors.blue,
                                ),
                                _buildContainer(),
                                _buildStatItem(
                                  "Completed",
                                  completed.toString(),
                                  Colors.green,
                                ),
                                _buildContainer(),
                                _buildStatItem(
                                  "Pending",
                                  pending.toString(),
                                  Colors.orange,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, s) => const Text("Stats unavailable"),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- SETTINGS SECTION ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Settings",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // 1. Dark Mode Toggle
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.dark_mode_outlined),
                            title: const Text("Dark Mode"),
                            trailing: Switch(
                              value: themeMode == ThemeMode.dark,
                              onChanged: (value) {
                                ref
                                    .read(themeProvider.notifier)
                                    .toggleTheme(value);
                              },
                            ),
                          ),
                        ),

                        // 2. Change Password
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.lock_reset),
                            title: const Text("Change Password"),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () => _changePassword(email),
                          ),
                        ),

                        // 3. PUSH NOTIFICATIONS (REAL)
                        Card(
                          child: SwitchListTile(
                            secondary: const Icon(
                              Icons.notifications_active_outlined,
                            ),
                            title: const Text("Push Notifications"),
                            activeColor: Colors.green,
                            value: _isNotificationsEnabled,
                            onChanged: (bool value) {
                              _toggleNotifications(value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Sign Out Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ref.read(authRepositoryProvider).signOut();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[50],
                          foregroundColor: Colors.red,
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text("Sign Out"),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildContainer() =>
      Container(height: 30, width: 1, color: Colors.grey[300]);

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
