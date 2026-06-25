import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Keeps [GoogleMap] alive and avoids blank maps inside scrollable parents.
class CarWashMapView extends StatefulWidget {
  const CarWashMapView({
    required this.cameraTarget,
    required this.markers,
    this.polylines = const {},
    this.height = 260,
    this.zoom = 12,
    this.borderRadius = 20,
    this.myLocationEnabled = true,
    this.onMapCreated,
    this.onTap,
    super.key,
  });

  final LatLng cameraTarget;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final double height;
  final double zoom;
  final double borderRadius;
  final bool myLocationEnabled;
  final ValueChanged<GoogleMapController>? onMapCreated;
  final ArgumentCallback<LatLng>? onTap;

  @override
  State<CarWashMapView> createState() => CarWashMapViewState();
}

class CarWashMapViewState extends State<CarWashMapView> {
  GoogleMapController? _controller;
  LatLng? _lastCameraTarget;

  @override
  void didUpdateWidget(covariant CarWashMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _moveCameraIfNeeded();
  }

  Future<void> moveCamera(LatLng target, {double? zoom}) async {
    _lastCameraTarget = target;
    await _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(target, zoom ?? widget.zoom),
    );
  }

  Future<void> _moveCameraIfNeeded() async {
    if (_controller == null) {
      return;
    }
    if (_lastCameraTarget == widget.cameraTarget) {
      return;
    }
    _lastCameraTarget = widget.cameraTarget;
    await _controller!.animateCamera(
      CameraUpdate.newLatLngZoom(widget.cameraTarget, widget.zoom),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: GoogleMap(
          key: const ValueKey('car_wash_google_map'),
          initialCameraPosition: CameraPosition(
            target: widget.cameraTarget,
            zoom: widget.zoom,
          ),
          markers: widget.markers,
          polylines: widget.polylines,
          myLocationEnabled: widget.myLocationEnabled,
          myLocationButtonEnabled: widget.myLocationEnabled,
          compassEnabled: true,
          mapToolbarEnabled: false,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(
              () => EagerGestureRecognizer(),
            ),
          },
          onMapCreated: (controller) {
            _controller = controller;
            _lastCameraTarget = widget.cameraTarget;
            widget.onMapCreated?.call(controller);
          },
          onTap: widget.onTap,
        ),
      ),
    );
  }
}

class MapSetupHintBanner extends StatelessWidget {
  const MapSetupHintBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          '地图未加载？请确认：\n'
          '1. 已在 android/secrets.properties 填写 google.maps.api.key\n'
          '2. Google Cloud 已启用 Maps SDK for Android 并开启计费\n'
          '3. 修改密钥后执行 flutter clean && flutter run\n'
          '4. 中国大陆需可访问 Google 服务的网络环境',
          style: TextStyle(fontSize: 12, height: 1.45),
        ),
      ),
    );
  }
}
