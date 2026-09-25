import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/premium.dart';

/// Location picked from the map.
class PickedLocation {
  final String address;
  final double lat;
  final double lng;
  const PickedLocation({required this.address, required this.lat, required this.lng});
}

/// Full-screen map picker: pan the map under the center pin,
/// or jump to current location. No API key needed (OpenStreetMap).
class MapLocationPicker extends StatefulWidget {
  final String title;
  final PickedLocation? initial;
  const MapLocationPicker({super.key, required this.title, this.initial});

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  final _mapCtrl = MapController();
  LatLng _center = const LatLng(23.0225, 72.5714); // Ahmedabad default
  String _address = 'Location load ho raha hai...';
  bool _loadingAddr = true;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _center = LatLng(widget.initial!.lat, widget.initial!.lng);
      _address = widget.initial!.address;
      _loadingAddr = false;
    } else {
      _goToCurrent(silent: true);
    }
    _reverseGeocode();
  }

  Future<void> _goToCurrent({bool silent = false}) async {
    if (!silent) setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (!silent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Location permission chahiye map ke liye')));
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        _center = LatLng(pos.latitude, pos.longitude);
        _loadingAddr = true;
      });
      _mapCtrl.move(_center, 15);
      _reverseGeocode();
    } catch (_) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Current location nahi mil paya')));
      }
    } finally {
      if (mounted && !silent) setState(() => _locating = false);
    }
  }

  Future<void> _reverseGeocode() async {
    try {
      final marks = await placemarkFromCoordinates(
        _center.latitude,
        _center.longitude,
      ).timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (marks.isNotEmpty) {
        final p = marks.first;
        final parts = [
          p.name,
          p.subLocality,
          p.locality,
          p.administrativeArea,
        ].where((e) => e != null && e.trim().isNotEmpty).toSet().toList();
        setState(() {
          _address = parts.take(4).join(', ');
          _loadingAddr = false;
        });
      } else {
        _fallbackAddr();
      }
    } catch (_) {
      if (mounted) _fallbackAddr();
    }
  }

  void _fallbackAddr() {
    setState(() {
      _address =
          '${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}';
      _loadingAddr = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 14,
              minZoom: 4,
              maxZoom: 18,
              onPositionChanged: (pos, _) {
                final c = pos.center;
                if (c != null &&
                    (c.latitude != _center.latitude ||
                        c.longitude != _center.longitude)) {
                  setState(() {
                    _center = c;
                    _loadingAddr = true;
                  });
                  _reverseGeocode();
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.namasteindia.app',
              ),
            ],
          ),
          // Center pin
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 44),
              child: Icon(Icons.location_pin,
                  size: 52, color: AppTheme.error),
            ),
          ),
          // Current location button
          Positioned(
            right: 16,
            bottom: 190,
            child: FloatingActionButton(
              heroTag: 'curLoc',
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () => _goToCurrent(),
              child: _locating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location, color: AppTheme.primary),
            ),
          ),
          // Bottom confirm card
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.rLg),
                boxShadow: AppTheme.shadowLg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: .1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.rSm),
                        ),
                        child: const Icon(Icons.location_pin,
                            color: AppTheme.error, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _loadingAddr
                            ? const Text('Address dhoondh rahe hain...',
                                style: TextStyle(color: AppTheme.textSecondary))
                            : Text(_address,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  PremiumButton(
                    label: 'Ye Location Select Karo',
                    icon: Icons.check,
                    onPressed: () => Navigator.of(context).pop(
                      PickedLocation(
                        address: _address,
                        lat: _center.latitude,
                        lng: _center.longitude,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
