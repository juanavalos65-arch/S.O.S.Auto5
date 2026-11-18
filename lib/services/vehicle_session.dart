import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleSession {
  static String driverName = '';
  static String phone = '';
  static String country = 'Colombia';
  static String city = 'Medellín';
  static String vehicleType = 'Automóvil';
  static String plate = '';
  static String brand = '';
  static String model = '';
  static String color = '';
  static String emergencyContactName = '';
  static String emergencyContactPhone = '';

  static bool get hasVehicle => plate.trim().isNotEmpty;

  static String get summary {
    if (!hasVehicle) return 'Sin vehículo registrado aún';
    final String desc = '$vehicleType $brand $model $color'.trim();
    return '$desc — Placa ${plate.toUpperCase()}';
  }

  static Future load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      driverName = prefs.getString('sos_driver_name') ?? '';
      phone = prefs.getString('sos_phone') ?? '';
      country = prefs.getString('sos_country') ?? 'Colombia';
      city = prefs.getString('sos_city') ?? 'Medellín';
      vehicleType = prefs.getString('sos_vehicle_type') ?? 'Automóvil';
      plate = prefs.getString('sos_plate') ?? '';
      brand = prefs.getString('sos_brand') ?? '';
      model = prefs.getString('sos_model') ?? '';
      color = prefs.getString('sos_color') ?? '';
      emergencyContactName = prefs.getString('sos_ec_name') ?? '';
      emergencyContactPhone = prefs.getString('sos_ec_phone') ?? '';
    } catch (_) {}
  }

  static Future save({
    required String newDriverName,
    required String newPhone,
    required String newCountry,
    required String newCity,
    required String newVehicleType,
    required String newPlate,
    required String newBrand,
    required String newModel,
    required String newColor,
    required String newEcName,
    required String newEcPhone,
  }) async {
    driverName = newDriverName.trim();
    phone = newPhone.trim();
    country = newCountry.trim();
    city = newCity.trim();
    vehicleType = newVehicleType.trim();
    plate = newPlate.trim().toUpperCase();
    brand = newBrand.trim();
    model = newModel.trim();
    color = newColor.trim();
    emergencyContactName = newEcName.trim();
    emergencyContactPhone = newEcPhone.trim();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sos_driver_name', driverName);
    await prefs.setString('sos_phone', phone);
    await prefs.setString('sos_country', country);
    await prefs.setString('sos_city', city);
    await prefs.setString('sos_vehicle_type', vehicleType);
    await prefs.setString('sos_plate', plate);
    await prefs.setString('sos_brand', brand);
    await prefs.setString('sos_model', model);
    await prefs.setString('sos_color', color);
    await prefs.setString('sos_ec_name', emergencyContactName);
    await prefs.setString('sos_ec_phone', emergencyContactPhone);

    // Sincronización en la nube (Firebase Firestore) por placa (soporta múltiples conductores)
    try {
      await FirebaseFirestore.instance.collection('vehicles').doc(plate).set({
        'plate': plate,
        'vehicleType': vehicleType,
        'brand': brand,
        'model': model,
        'color': color,
        'country': country,
        'city': city,
        'updatedAt': FieldValue.serverTimestamp(),
        'drivers': FieldValue.arrayUnion([
          {
            'name': driverName,
            'phone': phone,
            'emergencyContactName': emergencyContactName,
            'emergencyContactPhone': emergencyContactPhone,
          }
        ]),
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}
