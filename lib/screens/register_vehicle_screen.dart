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
  const CountryDialInfo({required this.name, required this.dialCode, required this.flag});
}

class AdditionalDriverInput {
  final TextEditingController nameController;
  final TextEditingController documentController;
  final TextEditingController phoneController;

  AdditionalDriverInput({String name = '', String document = '', String phone = ''})
      : nameController = TextEditingController(text: name),
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
  const RegisterVehicleScreen({super.key, this.initialData});

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
          'phone': phone.isNotEmpty ? '${_selectedCountry.dialCode} $phone' : '',
          'rawPhone': phone,
        });
      }
    }
    return result;
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFB71C1C)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF212121)),
          ),
        ),
      ],
    );
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
          if (decoded is Map<String, dynamic>) sourceData = decoded;
        }
      } catch (_) {}
    }
    if (sourceData != null) _applyDataToControllers(sourceData);
    if (mounted) setState(() => _isLoading = false);
  }

  void _applyDataToControllers(Map<String, dynamic> data) {
    final savedCountry = (data['country'] ?? '').toString();
    if (savedCountry.isNotEmpty) {
      final match = _americanCountries.where((c) => c.name == savedCountry);
      if (match.isNotEmpty) _selectedCountry = match.first;
    }
    final savedType = (data['vehicleType'] ?? '').toString();
    if (_vehicleTypes.contains(savedType)) _selectedVehicleType = savedType;

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
        _emergency1PhoneController.text = (contacts[0]['rawPhone'] ?? '').toString();
      }
      if (contacts.length > 1 && contacts[1] is Map) {
        _emergency2NameController.text = (contacts[1]['name'] ?? '').toString();
        _emergency2PhoneController.text = (contacts[1]['rawPhone'] ?? '').toString();
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
          _additionalDrivers.add(AdditionalDriverInput(
            name: (item['name'] ?? '').toString(),
            document: (item['document'] ?? '').toString(),
            phone: (item['rawPhone'] ?? '').toString(),
          ));
        }
      }
    }
  }

  void _addDriverField() => setState(() => _additionalDrivers.add(AdditionalDriverInput()));

  void _removeDriverField(int index) {
    setState(() {
      final removed = _additionalDrivers.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _saveRegistration() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa los campos obligatorios marcados.'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    setState(() => _isSaving = true);

    final normalizedPlate = _plateController.text.trim().toUpperCase().replaceAll(' ', '');
    final ownerRawPhone = _ownerPhoneController.text.trim();
    final e1RawPhone = _emergency1PhoneController.text.trim();
    final e2RawPhone = _emergency2PhoneController.text.trim();

    final emergencyContacts = >[
      {'name': _emergency1NameController.text.trim(), 'phone': '${_selectedCountry.dialCode} $e1RawPhone', 'rawPhone': e1RawPhone},
      if (_emergency2NameController.text.trim().isNotEmpty || e2RawPhone.isNotEmpty)
        {'name': _emergency2NameController.text.trim(), 'phone': '${_selectedCountry.dialCode} $e2RawPhone', 'rawPhone': e2RawPhone},
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
      'ownerPhone': '${_selectedCountry.dialCode} $ownerRawPhone',
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
            .set({...registrationData, 'serverUpdatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true))
            .timeout(const Duration(seconds: 6));
      }
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vehículo $normalizedPlate registrado y guardado.'), backgroundColor: Colors.green.shade700),
      );
      Navigator.of(context).pop(registrationData);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Guardado localmente. Sincronización pendiente ($e).'), backgroundColor: Colors.orange.shade800),
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
                    _buildSectionHeader(icon: Icons.public, title: '1. Ubicación (Continente Americano)'),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<CountryDialInfo>(
                      value: _selectedCountry,
                      decoration: const InputDecoration(labelText: 'País *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.flag)),
                      items: _americanCountries.map((c) => DropdownMenuItem(value: c, child: Text('${c.flag} ${c.name} (${c.dialCode})'))).toList(),
                      onChanged: (v) { if (v != null) setState(() => _selectedCountry = v); },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cityController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Ciudad / Municipio *', hintText: 'Ej. Medellín, Sincelejo', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_city)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa tu ciudad' : null,
                    ),
                    const SizedBox(height: 22),
                    _buildSectionHeader(icon: Icons.directions_car, title: '2. Datos del Vehículo'),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedVehicleType,
                      decoration: const InputDecoration(labelText: 'Tipo de vehículo *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.commute)),
                      items: _vehicleTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) { if (v != null) setState(() => _selectedVehicleType = v); },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _plateController,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9-]')), LengthLimitingTextInputFormatter(10)],
                      decoration: const InputDecoration(labelText: 'Placa del vehículo *', hintText: 'Ej. ABC123', border: OutlineInputBorder(), prefixIcon: Icon(Icons.pin)),
                      validator: (v) {
                        final clean = (v ?? '').trim();
                        if (clean.isEmpty) return 'La placa es obligatoria';
                        if (clean.length < 4) return 'Placa no válida';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _brandController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(labelText: 'Marca *', hintText: 'Ej. Chevrolet', border: OutlineInputBorder()),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _modelController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(labelText: 'Línea / Modelo *', hintText: 'Ej. Spark', border: OutlineInputBorder()),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _colorController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Color *', hintText: 'Ej. Gris Plata', border: OutlineInputBorder(), prefixIcon: Icon(Icons.color_lens)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el color' : null,
                    ),
                    const SizedBox(height: 22),
                    _buildSectionHeader(icon: Icons.person, title: '3. Propietario / Conductor Principal'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _ownerNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Nombre completo *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el nombre' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ownerDocumentController,
                      decoration: const InputDecoration(labelText: 'Documento de identidad (Cédula / ID) *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.credit_card)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el documento' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ownerPhoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(labelText: 'Teléfono / WhatsApp *', prefixText: '${_selectedCountry.dialCode} ', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.phone_android)),
                      validator: (v) {
                        final clean = (v ?? '').trim();
                        if (clean.isEmpty) return 'Ingresa un teléfono';
                        if (clean.length < 7) return 'Número muy corto';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ownerEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Correo electrónico (opcional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: _buildSectionHeader(icon: Icons.group_add, title: '4. Conductores Autorizados (Misma Placa)')),
                        TextButton.icon(onPressed: _addDriverField, icon: const Icon(Icons.add_circle), label: const Text('Agregar')),
                      ],
                    ),
                    if (_additionalDrivers.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text('Agrega otros conductores autorizados para esta misma placa.', style: TextStyle(color: Colors.black54, fontSize: 13)),
                      ),
                    ...List.generate(_additionalDrivers.length, (index) {
                      final driver = _additionalDrivers[index];
                      return Card(
                        margin: const EdgeInsets.only(top: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Conductor adicional #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _removeDriverField(index)),
                                ],
                              ),
                              TextFormField(
                                controller: driver.nameController,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(labelText: 'Nombre del conductor *', border: OutlineInputBorder()),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el nombre' : null,
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: driver.documentController,
                                decoration: const InputDecoration(labelText: 'Documento de identidad *', border: OutlineInputBorder()),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el documento' : null,
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: driver.phoneController,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(labelText: 'Teléfono / WhatsApp *', prefixText: '${_selectedCountry.dialCode} ', border: const OutlineInputBorder()),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el teléfono' : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 22),
                    _buildSectionHeader(icon: Icons.emergency_share, title: '5. Contactos de Emergencia'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _emergency1NameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Contacto de emergencia 1 (Nombre) *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_pin)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa al menos 1 contacto' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _emergency1PhoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(labelText: 'Teléfono contacto 1 *', prefixText: '${_selectedCountry.dialCode} ', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.phone)),
                      validator: (v) {
                        final clean = (v ?? '').trim();
                        if (clean.isEmpty) return 'Teléfono requerido';
                        if (clean.length < 7) return 'Número muy corto';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emergency2NameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Contacto de emergencia 2 (Nombre - opcional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_pin_outlined)),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _emergency2PhoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(labelText: 'Teléfono contacto 2 (opcional)', prefixText: '${_selectedCountry.dialCode} ', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.phone_outlined)),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB71C1C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isSaving ? null : _saveRegistration,
                        icon: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save),
                        label: Text(_isSaving ? 'GUARDANDO REGISTRO...' : 'GUARDAR REGISTRO', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
