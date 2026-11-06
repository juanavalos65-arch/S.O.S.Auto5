import 'package:location/location.dart';

Location location = new Location();

bool _serviceEnabled;
PermissionStatus _permissionGranted;
LocationData _locationData;

Future<void> obtenerUbicacion() async {
  _serviceEnabled = await location.serviceEnabled();
  if (!_serviceEnabled) {
    _serviceEnabled = await location.requestService();
    if (!_serviceEnabled) {
      return;
    }
  }

  _permissionGranted = await location.hasPermission();
  if (_permissionGranted == PermissionStatus.denied) {
    _permissionGranted = await location.requestPermission();
    if (_permissionGranted != PermissionStatus.denied) {
      return;
    }
  }

  _locationData = await location.getLocation();
  print("Latitud: ${_locationData.latitude}, Longitud: ${_locationData.longitude}");
}
