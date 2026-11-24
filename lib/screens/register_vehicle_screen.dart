import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class CountryDialInfo {
  final String name;
  final String dialCode;
  final String flag;

  const CountryDialInfo({
    required this.name,
    required this.dialCode,
    required this.flag,
  });
}

class AdditionalDriverInput {
  final TextEditingController nameController;
  final TextEditingController documentController;
  final TextEditingController phoneController;

  AdditionalDriverInput({
    String name = '',
    String document = '',
    String phone = '',
  })  : nameController = TextEditingController(text: name),
        documentController = TextEditingController(text: document),
        phoneController = TextEditingController(text: phone);

  void dispose() {
    nameController.dispose();
    documentController.dispose();
    phoneController.dispose();
  }
}

class RegisterVehicleScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const RegisterVehicleScreen({
    super.key,
    this.initialData,
  });

  @override
  State<RegisterVehicleScreen> createState() => _RegisterVehicleScreenState();
}

class _RegisterVehicleScreenState extends State<RegisterVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  static const String _storageKey = 'sos_auto_registered_vehicle_v1';

  static const List<CountryDialInfo> _americanCountries = [
    CountryDialInfo(name: 'Colombia', dialCode: '+57', flag: '🇨🇴'),
    CountryDialInfo(name: 'Argentina', dialCode: '+54', flag: '🇦🇷'),
    CountryDialInfo(name: 'Bolivia', dialCode: '+591', flag: '🇧🇴'),
    CountryDialInfo(name: 'Brasil', dialCode: '+55', flag: '🇧🇷'),
    CountryDialInfo(name: 'Canadá', dialCode: '+1', flag: '🇨🇦'),
    CountryDialInfo(name: 'Chile', dialCode: '+56', flag: '🇨🇱'),
    CountryDialInfo(name: 'Costa Rica', dialCode: '+506', flag: '🇨🇷'),
    CountryDialInfo(name: 'Cuba', dialCode: '+53', flag: '🇨🇺'),
    CountryDialInfo(name: 'Ecuador', dialCode: '+593', flag: '🇪🇨'),
    CountryDialInfo(name: 'El Salvador', dialCode: '+503', flag: '🇸🇻'),
    CountryDialInfo(name: 'Estados Unidos', dialCode: '+1', flag: '🇺🇸'),
    CountryDialInfo(name: 'Guatemala', dialCode: '+502', flag: '🇬🇹'),
    CountryDialInfo(name: 'Honduras', dialCode: '+504', flag: '🇭🇳'),
    CountryDialInfo(name: 'México', dialCode: '+52', flag: '🇲🇽'),
    CountryDialInfo(name: 'Nicaragua', dialCode: '+505', flag: '🇳🇮'),
    CountryDialInfo(name: 'Panamá', dialCode: '+507', flag: '🇵🇦'),
    CountryDialInfo(name: 'Paraguay', dialCode: '+595', flag: '🇵🇾'),
    CountryDialInfo(name: 'Perú', dialCode: '+51', flag: '🇵🇪'),
    CountryDialInfo(name: 'Puerto Rico', dialCode: '+1', flag: '🇵🇷'),
    CountryDialInfo(name: 'República Dominicana', dialCode: '+1', flag: '🇩🇴'),
    CountryDialInfo(name: 'Uruguay', dialCode: '+598', flag: '🇺🇾'),
    CountryDialInfo(name: 'Venezuela', dialCode: '+58', flag: '🇻🇪'),
  ];

  static const List<String> _vehicleTypes = [
    'Automóvil',
    'Motocicleta',
    'Camioneta / SUV',
    'Camión',
    'Bus / Microbús',
  ];

  final _plateController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _colorController = TextEditingController();
  final _cityController = TextEditingController();

  final _ownerNameController = TextEditingController();
  final _ownerDocumentController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _ownerEmailController = TextEditingController();

  final _emergency1NameController = TextEditingController();
  final _emergency1PhoneController = TextEditingController();
  final _emergency2NameController = TextEditingController();
  final _emergency2PhoneController = TextEditingController();

  CountryDialInfo _selectedCountry = _americanCountries.first;
  String _selectedVehicleType = _vehicleTypes.first;
  final List<AdditionalDriverInput> _additionalDrivers = [];

  bool _isLoading = true;
  bool _isSaving = false;

  List> get validAdditionalDrivers {
    final result = >[];
    for (final driver in _additionalDrivers) {
      final name = driver.nameController.text.trim();
      final doc = driver.documentController.text.trim();
      final phone = driver.phoneController.text.trim();
      if (name.isNotEmpty || doc.isNotEmpty || phone.isNotEmpty) {
        result.add({
          'name': name,
          'document': doc,
          'phone': phone.isNotEmpty ? '${_selectedCountry.dialCode}$phone' : '',
          'rawPhone': phone,
        });
      }
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    Map<String, dynamic>? sourceData = widget.initialData;

    if (sourceData == null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final rawJson = prefs.getString(_storageKey);
        if (rawJson != null && rawJson.isNotEmpty) {
          final decoded = jsonDecode(rawJson);
          if (decoded is Map<String, dynamic>) {
            sourceData = decoded;
          }
        }
      } catch (_) {}
    }

    if (sourceData != null) {
      _applyDataToControllers(sourceData);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyDataToControllers(Map<String, dynamic> data) {
    final savedCountry = (data['country'] ?? '').toString();
    if (savedCountry.isNotEmpty) {
      final match = _americanCountries.where((c) => c.name == savedCountry);
      if (match.isNotEmpty) {
        _selectedCountry = match.first;
      }
    }

    final savedType = (data['vehicleType'] ?? '').toString();
    if (_vehicleTypes.contains(savedType)) {
      _selectedVehicleType = savedType;
    }

    _plateController.text = (data['plate'] ?? '').toString();
    _brandController.text = (data['brand'] ?? '').toString();
    _modelController.text = (data['model'] ?? '').toString();
    _colorController.text = (data['color'] ?? '').toString();
    _cityController.text = (data['city'] ?? '').toString();

    _ownerNameController.text = (data['ownerName'] ?? '').toString();
    _ownerDocumentController.text = (data['ownerDocument'] ?? '').toString();
    _ownerPhoneController.text = (data['ownerRawPhone'] ?? '').toString();
    _ownerEmailController.text = (data['ownerEmail'] ?? '').toString();

    final contacts = data['emergencyContacts'];
    if (contacts is List) {
      if (contacts.isNotEmpty && contacts[0] is Map) {
        _emergency1NameController.text = (contacts[0]['name'] ?? '').toString();
        _emergency1PhoneController.text =
            (contacts[0]['rawPhone'] ?? '').toString();
      }
      if (contacts.length > 1 && contacts[1] is Map) {
        _emergency2NameController.text = (contacts[1]['name'] ?? '').toString();
        _emergency2PhoneController.text =
            (contacts[1]['rawPhone'] ?? '').toString();
      }
    }

    for (final d in _additionalDrivers) {
      d.dispose();
    }
    _additionalDrivers.clear();

    final drivers = data['additionalDrivers'];
    if (drivers is List) {
      for (final item in drivers) {
        if (item is Map) {
          _additionalDrivers.add(
            AdditionalDriverInput(
              name: (item['name'] ?? '').toString(),
              document: (item['document'] ?? '').toString(),
              phone: (item['rawPhone'] ?? '').toString(),
            ),
          );
        }
      }
    }
  }

  void _addDriverField() {
    setState(() {
      _additionalDrivers.add(AdditionalDriverInput());
    });
  }

  void _removeDriverField(int index) {
    setState(() {
      final removed = _additionalDrivers.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _saveRegistration() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa los campos obligatorios marcados.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final normalizedPlate =
        _plateController.text.trim().toUpperCase().replaceAll(' ', '');
    final ownerRawPhone = _ownerPhoneController.text.trim();
    final e1RawPhone = _emergency1PhoneController.text.trim();
    final e2RawPhone = _emergency2PhoneController.text.trim();

    final emergencyContacts = >[
      {
        'name': _emergency1NameController.text.trim(),
        'phone': '${_selectedCountry.dialCode}$e1RawPhone',
        'rawPhone': e1RawPhone,
      },
      if (_emergency2NameController.text.trim().isNotEmpty ||
          e2RawPhone.isNotEmpty)
        {
          'name': _emergency2NameController.text.trim(),
          'phone': '${_selectedCountry.dialCode}$e2RawPhone',
          'rawPhone': e2RawPhone,
        },
    ];

    final registrationData = <String, dynamic>{
      'vehicleType': _selectedVehicleType,
      'plate': normalizedPlate,
      'brand': _brandController.text.trim(),
      'model': _modelController.text.trim(),
      'color': _colorController.text.trim(),
      'country': _selectedCountry.name,
      'dialCode': _selectedCountry.dialCode,
      'city': _cityController.text.trim(),
      'ownerName': _ownerNameController.text.trim(),
      'ownerDocument': _ownerDocumentController.text.trim(),
      'ownerPhone': '${_selectedCountry.dialCode}$ownerRawPhone',
      'ownerRawPhone': ownerRawPhone,
      'ownerEmail': _ownerEmailController.text.trim(),
      'additionalDrivers': validAdditionalDrivers,
      'emergencyContacts': emergencyContacts,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(registrationData));

      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(normalizedPlate)
            .set(
              {
                ...registrationData,
                'serverUpdatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            )
            .timeout(const Duration(seconds: 6));
      }

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vehículo $normalizedPlate registrado y guardado correctamente.',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );

      Navigator.of(context).pop(registrationData);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Guardado localmente en el teléfono. Sincronización en nube pendiente ($e).',
          ),
          backgroundColor: Colors.orange.shade800,
        ),
      );

      Navigator.of(context).pop(registrationData);
    }
  }

  @override
  void dispose() {
    _plateController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _cityController.dispose();
    _ownerNameController.dispose();
    _ownerDocumentController.dispose();
    _ownerPhoneController.dispose();
    _ownerEmailController.dispose();
    _emergency1NameController.dispose();
    _emergency1PhoneController.dispose();
    _emergency2NameController.dispose();
    _emergency2PhoneController.dispose();
    for (final driver in _additionalDrivers) {
      driver.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Vehículo y Conductores'),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSectionHeader(
                      icon: Icons.public,
                      title: '1. Ubicación (Continente Americano)',
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<CountryDialInfo>(
                      value: _selectedCountry,
                      decoration: const InputDecoration(
                        labelText: 'País *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flag),
                      ),
                      items: _americanCountries.map((country) {
                        return DropdownMenuItem<CountryDialInfo>(
                          value: country,
                          child: Text(
                            '${country.flag} ${country.name} (${country.dialCode})',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCountry = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cityController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Ciudad / Municipio *',
                        hintText: 'Ej. Medellín, Sincelejo, Bogotá',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Ingresa tu ciudad'
                          : null,
                    ),
                    const SizedBox(height: 22),
                    _build
