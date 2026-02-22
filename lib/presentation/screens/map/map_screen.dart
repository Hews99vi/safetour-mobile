import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/config/map_config.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe Map'),
      ),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(6.9271, 79.8612),
          initialZoom: 13,
          interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
        ),
        children: [
          TileLayer(
            urlTemplate:
                "https://api.maptiler.com/maps/dataviz-dark/{z}/{x}/{y}.png?key=${MapConfig.mapTilerKey}",
            userAgentPackageName: "com.safetour.app",
          ),
          MarkerLayer(
            markers: const [
              Marker(
                point: LatLng(6.9271, 79.8612),
                width: 40,
                height: 40,
                child: Icon(Icons.location_on, color: Colors.blue),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).maybePop(),
        backgroundColor: AppColors.neonCyan,
        foregroundColor: AppColors.midnight,
        child: const Icon(Icons.close),
      ),
    );
  }
}
