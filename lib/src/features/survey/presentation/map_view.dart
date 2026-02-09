import 'package:field_pro/src/features/survey/domain/survey_model.dart';
import 'package:field_pro/src/features/survey/presentation/survey_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DashboardMapView extends StatefulWidget {
  final List<SurveyModel> surveys;

  const DashboardMapView({super.key, required this.surveys});

  @override
  State<DashboardMapView> createState() => _DashboardMapViewState();
}

class _DashboardMapViewState extends State<DashboardMapView> {
  late final MapController _mapController;
  LatLng? _currentCenter;
  double _currentZoom = 10.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _calculateMapCenter();
  }

  void _calculateMapCenter() {
    final validSurveys = widget.surveys
        .where((s) => s.latitude != 0.0 && s.longitude != 0.0)
        .toList();

    if (validSurveys.isEmpty) {
      _currentCenter = const LatLng(9.9312, 76.2673); // Cochin, Kerala
      return;
    }

    // Calculate average of all coordinates
    double avgLat = 0.0;
    double avgLng = 0.0;

    for (final survey in validSurveys) {
      avgLat += survey.latitude;
      avgLng += survey.longitude;
    }

    avgLat /= validSurveys.length;
    avgLng /= validSurveys.length;

    _currentCenter = LatLng(avgLat, avgLng);
  }

  void _zoomToSurvey(SurveyModel survey) {
    _mapController.move(
      LatLng(survey.latitude, survey.longitude),
      15.0, // Zoom level
    );
  }

  void _showAllSurveys() {
    final validSurveys = widget.surveys
        .where((s) => s.latitude != 0.0 && s.longitude != 0.0)
        .toList();

    if (validSurveys.isEmpty) return;

    // Calculate bounds
    double minLat = validSurveys.first.latitude;
    double maxLat = validSurveys.first.latitude;
    double minLng = validSurveys.first.longitude;
    double maxLng = validSurveys.first.longitude;

    for (final survey in validSurveys) {
      if (survey.latitude < minLat) minLat = survey.latitude;
      if (survey.latitude > maxLat) maxLat = survey.latitude;
      if (survey.longitude < minLng) minLng = survey.longitude;
      if (survey.longitude > maxLng) maxLng = survey.longitude;
    }

    // Calculate center point
    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    // Calculate zoom level based on bounds (simplified calculation)
    double latDiff = maxLat - minLat;
    double lngDiff = maxLng - minLng;
    double maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

    // Adjust zoom based on the spread (lower number = more zoomed out)
    double zoomLevel = 10.0;
    if (maxDiff < 0.01) {
      zoomLevel = 15.0; // Very close together
    } else if (maxDiff < 0.1) {
      zoomLevel = 12.0; // Close together
    } else if (maxDiff < 0.5) {
      zoomLevel = 10.0; // Medium distance
    } else if (maxDiff < 1.0) {
      zoomLevel = 8.0; // Far apart
    } else {
      zoomLevel = 6.0; // Very far apart
    }

    _mapController.move(LatLng(centerLat, centerLng), zoomLevel);
  }

  void _resetToDefault() {
    _mapController.move(const LatLng(9.9312, 76.2673), 10.0);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Signed':
        return Colors.teal;
      case 'Draft':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Completed':
        return Icons.check_circle;
      case 'Signed':
        return Icons.verified;
      case 'Draft':
        return Icons.edit;
      default:
        return Icons.location_on;
    }
  }

  @override
  Widget build(BuildContext context) {
    final validSurveys = widget.surveys
        .where((s) => s.latitude != 0.0 && s.longitude != 0.0)
        .toList();

    final invalidSurveys = widget.surveys
        .where((s) => s.latitude == 0.0 || s.longitude == 0.0)
        .toList();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentCenter ?? const LatLng(9.9312, 76.2673),
            initialZoom: _currentZoom,
            onPositionChanged: (position, hasGesture) {
              setState(() {
                _currentCenter = position.center;
                _currentZoom = position.zoom;
              });
            },
          ),
          children: [
            // 1. MAP TILES
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.novo.field_pro',
              tileProvider: NetworkTileProvider(),
              retinaMode: MediaQuery.of(context).devicePixelRatio > 1.0,
            ),

            // 2. MARKERS
            MarkerLayer(
              markers: [
                // Default center marker (only shown when no surveys)
                if (validSurveys.isEmpty)
                  Marker(
                    point: const LatLng(9.9312, 76.2673),
                    width: 100,
                    height: 100,
                    child: Column(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.blue.withOpacity(0.7),
                          size: 60,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            "Cochin, Kerala",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Survey markers
                ...validSurveys.map((survey) {
                  return Marker(
                    point: LatLng(survey.latitude, survey.longitude),
                    width: 80,
                    height: 80,
                    child: GestureDetector(
                      onTap: () {
                        // Show bottom sheet with options
                        showModalBottomSheet(
                          context: context,
                          builder: (context) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: Icon(
                                      _getStatusIcon(survey.status),
                                      color: _getStatusColor(survey.status),
                                    ),
                                    title: Text(
                                      survey.customerName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(survey.address),
                                        const SizedBox(height: 4),
                                        Chip(
                                          label: Text(survey.status),
                                          backgroundColor: _getStatusColor(
                                            survey.status,
                                          ).withOpacity(0.2),
                                          labelStyle: TextStyle(
                                            color: _getStatusColor(
                                              survey.status,
                                            ),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(),
                                  ListTile(
                                    leading: const Icon(Icons.zoom_in),
                                    title: const Text('Zoom to Location'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _zoomToSurvey(survey);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.open_in_full),
                                    title: const Text('View Survey Details'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              SurveyDetailsScreen(
                                                survey: survey,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              _getStatusIcon(survey.status),
                              color: _getStatusColor(survey.status),
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              survey.customerName.split(' ').first,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),

        // 3. CONTROLS OVERLAY
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show all surveys button
              if (validSurveys.length > 1)
                FloatingActionButton.small(
                  heroTag: 'show_all',
                  onPressed: _showAllSurveys,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.fit_screen,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              if (validSurveys.length > 1) const SizedBox(height: 8),

              // Reset button
              FloatingActionButton.small(
                heroTag: 'reset',
                onPressed: _resetToDefault,
                backgroundColor: Colors.white,
                child: Icon(Icons.home, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(height: 8),

              // Zoom in
              FloatingActionButton.small(
                heroTag: 'zoom_in',
                onPressed: () {
                  _mapController.move(
                    _currentCenter ??
                        const LatLng(9.9312, 76.2673), // Fallback center
                    _currentZoom + 1,
                  );
                },
                backgroundColor: Colors.white,
                child: Icon(Icons.add, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(height: 8),

              // Zoom out
              FloatingActionButton.small(
                heroTag: 'zoom_out',
                onPressed: () {
                  if (_currentZoom > 1) {
                    // Minimum zoom level
                    _mapController.move(
                      _currentCenter ??
                          const LatLng(9.9312, 76.2673), // Fallback center
                      _currentZoom - 1,
                    );
                  }
                },
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.remove,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),

        // 4. INFO BANNER
        if (invalidSurveys.isNotEmpty)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${invalidSurveys.length} survey(s) without GPS location',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 5. LEGEND
        Positioned(
          top: invalidSurveys.isNotEmpty ? 80 : 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Status Legend',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                _buildLegendItem('Completed', Colors.green, Icons.check_circle),
                _buildLegendItem('Signed', Colors.teal, Icons.verified),
                _buildLegendItem('Draft', Colors.orange, Icons.edit),
                _buildLegendItem('Other', Colors.blue, Icons.location_on),
              ],
            ),
          ),
        ),

        // 6. ZOOM LEVEL INDICATOR (Optional)
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'Zoom: ${_currentZoom.toStringAsFixed(1)}x',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
