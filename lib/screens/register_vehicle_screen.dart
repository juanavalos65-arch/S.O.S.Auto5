import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/background_alert_permission_service.dart';
import '../services/vehicle_session.dart';

class CountryDialCode {
  final String name;
  final String dialCode;

  const CountryDialCode(this.name, this.dialCode);
}

const List americanCountries = [
  CountryDialCode('Colombia', '+57'),
  CountryDialCode('Argentina', '+54'),
  CountryDialCode('Bolivia', '+591'),
  CountryDialCode('Brasil', '+55'),
  CountryDialCode('Canadá', '+1'),
  CountryDialCode('Chile', '+56'),
  CountryDialCode('Costa Rica', '+506'),
  CountryDialCode('Cuba', '+53'),
  CountryDialCode('Ecuador', '+593'),
  CountryDialCode('El Salvador', '+503'),
  CountryDialCode('Estados Unidos', '+1'),
  CountryDialCode('Guatemala', '+502'),
  CountryDialCode('Honduras', '+504'),
  CountryDialCode('México', '+52'),
  CountryDialCode('Nicaragua', '+505'),
  CountryDialCode('Panamá', '+507'),
  CountryDialCode('Paraguay', '+595'),
  CountryDialCode('Perú', '+51'),
  CountryDialCode('Puerto Rico', '+1'),
  CountryDialCode('República Dominicana', '+1'),
  CountryDialCode('Uruguay', '+598'),
  CountryDialCode('Venezuela', '+58'),
];

class DriverControllers {
  final TextEditingController nameController;
  final TextEditingController documentController;
  final TextEditingController phoneController;
  String dialCode;

  DriverControllers({
    String name = '',
    String document = '',
    String phone = '',
    this.dialCode = '+57',
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
  const RegisterVehicleScreen({super.key});

  @override
  State createState() => _RegisterVehicleScreenState();
}

class _RegisterVehicleScreenState extends State {
  final _formKey = GlobalKey();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _isSaving = false;
  bool _aceptaPoliticaDatos = false;

  // 1. Ubicación Continental (País, Código Internacional y Ciudad)
  CountryDialCode _selectedCountry = americanCountries.first;
  final TextEditingController _cityController = TextEditingController();

  // 2. Datos del Vehículo
  String _selectedVehicleType = 'Automóvil';
  final List _vehicleTypes = [
    'Automóvil',
    'Motocicleta',
    'Camioneta',
    'Camión',
    'Bus',
  ];

  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();

  // 3. Propietario y Múltiples Conductores
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _ownerDocumentController = TextEditingController();
  String _ownerDialCode = '+57';
  final TextEditingController _ownerPhoneController = TextEditingController();
  final List _additionalDrivers = [];

  // 4. Dos Contactos de Emergencia (con indicativo internacional independiente)
  final TextEditingController _emergency1NameController = TextEditingController();
  String _emergency1DialCode = '+57';
  final TextEditingController _emergency1PhoneController = TextEditingController();

  final TextEditingController _emergency2NameController = TextEditingController();
  String _emergency2DialCode = '+57';
  final TextEditingController _emergency2PhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedRegistration();
  }

  /// Precarga el vehículo guardado en el dispositivo si el usuario vuelve a abrir la pantalla
  Future _loadSavedRegistration() async {
    try {
      final rawJson = await _secureStorage.read(key: 'sos_auto_registered_vehicle');
      if (rawJson == null || rawJson.isEmpty) return;

      final Map data = jsonDecode(rawJson) as Map;
      if (!mounted) return;

      setState(() {
        _aceptaPoliticaDatos = data['privacyPolicyAccepted'] as bool? ?? true;

        final location = data['location'] as Map? ?? {};
        final savedCountryName = location['country'] as String? ?? 'Colombia';
        _selectedCountry = americanCountries.firstWhere(
          (c) => (c as CountryDialCode).name == savedCountryName,
          orElse: () => americanCountries.first,
        );
        _cityController.text = location['city'] as String? ?? '';

        final vehicle = data['vehicle'] as Map? ?? {};
        final savedType = vehicle['type'] as String? ?? 'Automóvil';
        if (_vehicleTypes.contains(savedType)) {
          _selectedVehicleType = savedType;
        }
        _plateController.text = vehicle['plate'] as String? ?? '';
        _brandController.text = vehicle['brand'] as String? ?? '';
        _modelController.text = vehicle['model'] as String? ?? '';
        _colorController.text = vehicle['color'] as String? ?? '';

        final owner = data['owner'] as Map? ?? {};
        _ownerNameController.text = owner['name'] as String? ?? '';
        _ownerDocumentController.text = owner['document'] as String? ?? '';
        _ownerDialCode = owner['dialCode'] as String? ?? _selectedCountry.dialCode;
        _ownerPhoneController.text = owner['phone'] as String? ?? '';

        for (final d in _additionalDrivers) {
          (d as DriverControllers).dispose();
        }
        _additionalDrivers.clear();
        final driversList = data['additionalDrivers'] as List? ?? [];
        for (final item in driversList) {
          final dMap = item as Map;
          _additionalDrivers.add(
            DriverControllers(
              name: dMap['name'] as String? ?? '',
              document: dMap['document'] as String? ?? '',
              phone: dMap['phone'] as String? ?? '',
              dialCode: dMap['dialCode'] as String? ?? _selectedCountry.dialCode,
            ),
          );
        }

        final contacts = data['emergencyContacts'] as List? ?? [];
        if (contacts.isNotEmpty) {
          final c1 = contacts[0] as Map;
          _emergency1NameController.text = c1['name'] as String? ?? '';
          _emergency1DialCode = c1['dialCode'] as String? ?? _selectedCountry.dialCode;
          _emergency1PhoneController.text = c1['phone'] as String? ?? '';
        }
        if (contacts.length > 1) {
          final c2 = contacts[1] as Map;
          _emergency2NameController.text = c2['name'] as String? ?? '';
          _emergency2DialCode = c2['dialCode'] as String? ?? _selectedCountry.dialCode;
          _emergency2PhoneController.text = c2['phone'] as String? ?? '';
        }
      });
    } catch (_) {
      // Si no hay registro previo o es corrupto, inicia limpio sin bloquear la pantalla
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    _plateController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _ownerNameController.dispose();
    _ownerDocumentController.dispose();
    _ownerPhoneController.dispose();
    for (final driver in _additionalDrivers) {
      (driver as DriverControllers).dispose();
    }
    _emergency1NameController.dispose();
    _emergency1PhoneController.dispose();
    _emergency2NameController.dispose();
    _emergency2PhoneController.dispose();
    super.dispose();
  }

  void _onCountryChanged(CountryDialCode newCountry) {
    setState(() {
      final previousDial = _selectedCountry.dialCode;
      _selectedCountry = newCountry;

      if (_ownerDialCode == previousDial) {
        _ownerDialCode = newCountry.dialCode;
      }
      if (_emergency1DialCode == previousDial) {
        _emergency1DialCode = newCountry.dialCode;
      }
      if (_emergency2DialCode == previousDial) {
        _emergency2DialCode = newCountry.dialCode;
      }
      for (final item in _additionalDrivers) {
        final driver = item as DriverControllers;
        if (driver.dialCode == previousDial) {
          driver.dialCode = newCountry.dialCode;
        }
      }
    });
  }

  void _addDriver() {
    setState(() {
      _additionalDrivers.add(DriverControllers(dialCode: _selectedCountry.dialCode));
    });
  }

  void _removeDriver(int index) {
    setState(() {
      (_additionalDrivers[index] as DriverControllers).dispose();
      _additionalDrivers.removeAt(index);
    });
  }

  void _mostrarPoliticaTratamientoDatos() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified_user, color: Color(0xFF1B5E20)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Política de Tratamiento de Datos Personales',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            'POLÍTICA DE PRIVACIDAD Y PROTECCIÓN DE DATOS — S.O.S. AUTO\n\n'
            '1. CONFIDENCIALIDAD Y NO DIVULGACIÓN: Tus datos personales (nombre, documento de identidad, teléfonos y contactos de emergencia) están cifrados y protegidos bajo la Ley 1581 de 2012 (Habeas Data). S.O.S. Auto NO vende, alquila ni comparte tus datos personales con terceros ni entidades comerciales.\n\n'
            '2. USO EXCLUSIVO EN EMERGENCIA O ROBO: Únicamente cuando actives de forma voluntaria una alerta de Robo de Auto o Emergencia Crítica, el sistema compartirá exclusivamente la PLACA y las CARACTERÍSTICAS DEL VEHÍCULO (tipo, marca, modelo y color) con la red de apoyo y autoridades para facilitar su ubicación.\n\n'
            '3. SEGURIDAD Y CIFRADO: La información en tu dispositivo se guarda mediante almacenamiento seguro cifrado (AES / Keystore) y las comunicaciones viajan por canales cifrados TLS.\n\n'
            '4. DERECHOS DEL TITULAR: Puedes actualizar, rectificar o eliminar tus datos en cualquier momento o solicitarlo al correo soporte.applay65@gmail.com.',
            style: TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _aceptaPoliticaDatos = true);
              Navigator.of(ctx).pop();
            },
            child: const Text(
              'ACEPTAR Y CERRAR',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future _submitForm() async {
    if (_isSaving) return;

    final formState = _formKey.currentState as FormState?;
    if (formState == null || !formState.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa los campos obligatorios marcados.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!_aceptaPoliticaDatos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes aceptar la Política de Tratamiento de Datos Personales para continuar.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final String cleanPlate = _plateController.text.trim().toUpperCase();

    final Map registrationData = {
      'plate': cleanPlate,
      'privacyPolicyAccepted': true,
      'privacyPolicyAcceptedAt': DateTime.now().toIso8601String(),
      'location': {
        'country': _selectedCountry.name,
        'dialCode': _selectedCountry.dialCode,
        'city': _cityController.text.trim(),
      },
      'vehicle': {
        'type': _selectedVehicleType,
        'plate': cleanPlate,
        'brand': _brandController.text.trim(),
        'model': _modelController.text.trim(),
        'color': _colorController.text.trim(),
      },
      'owner': {
        'name': _ownerNameController.text.trim(),
        'document': _ownerDocumentController.text.trim(),
        'dialCode': _ownerDialCode,
        'phone': _ownerPhoneController.text.trim(),
        'fullPhone': '$_ownerDialCode${_ownerPhoneController.text.trim()}',
      },
      'additionalDrivers': _additionalDrivers.map((item) {
        final d = item as DriverControllers;
        return {
          'name': d.nameController.text.trim(),
          'document': d.documentController.text.trim(),
          'dialCode': d.dialCode,
          'phone': d.phoneController.text.trim(),
          'fullPhone': '${d.dialCode}${d.phoneController.text.trim()}',
        };
      }).toList(),
      'emergencyContacts': [
        {
          'name': _emergency1NameController.text.trim(),
          'dialCode': _emergency1DialCode,
          'phone': _emergency1PhoneController.text.trim(),
          'fullPhone': '$_emergency1DialCode${_emergency1PhoneController.text.trim()}',
        },
        if (_emergency2NameController.text.trim().isNotEmpty ||
            _emergency2PhoneController.text.trim().isNotEmpty)
          {
            'name': _emergency2NameController.text.trim(),
            'dialCode': _emergency2DialCode,
            'phone': _emergency2PhoneController.text.trim(),
            'fullPhone': '$_emergency2DialCode${_emergency2PhoneController.text.trim()}',
          },
      ],
    };

    try {
      // 1. Sincronizar con VehicleSession para carga inmediata en Me Varé, Accidente y Robo
      await VehicleSession.save(
        newDriverName: _ownerNameController.text.trim(),
        newPhone: '$_ownerDialCode${_ownerPhoneController.text.trim()}',
        newCountry: _selectedCountry.name,
        newCity: _cityController.text.trim(),
        newVehicleType: _selectedVehicleType,
        newPlate: cleanPlate,
        newBrand: _brandController.text.trim(),
        newModel: _modelController.text.trim(),
        newColor: _colorController.text.trim(),
        newEcName: _emergency1NameController.text.trim(),
        newEcPhone: '$_emergency1DialCode${_emergency1PhoneController.text.trim()}',
      );

      // 2. Guardar copia cifrada localmente en el teléfono (disponible sin internet)
      await _secureStorage.write(
        key: 'sos_auto_registered_vehicle',
        value: jsonEncode(registrationData),
      );
      await _secureStorage.write(
        key: 'sos_auto_active_plate',
        value: cleanPlate,
      );

      // 3. Autenticación anónima si no hay sesión activa y guardado en Cloud Firestore
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        try {
          final cred = await FirebaseAuth.instance.signInAnonymously();
          currentUser = cred.user;
        } catch (_) {
          // Si Auth anónimo no está habilitado en consola, continúa directo a Firestore
        }
      }

      final Map cloudPayload = {
        ...registrationData,
        'uid': currentUser?.uid ?? 'local_device',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('vehiculos')
          .doc(cleanPlate)
          .set(Map.from(cloudPayload), SetOptions(merge: true))
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vehículo $cleanPlate (${_selectedCountry.name}) guardado y protegido con cifrado.',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );

      // 4. Solicitar permiso de ubicación en segundo plano y alertas de sirena post-registro
      await BackgroundAlertPermissionService.solicitarPermisoAlertasCerrada(context);

      if (!mounted) return;
      Navigator.pop(context, registrationData);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vehículo $cleanPlate guardado localmente con cifrado. Se sincronizará automáticamente.',
          ),
          backgroundColor: Colors.orange.shade800,
        ),
      );

      // Solicitar permisos incluso si se guardó en modo local sin conexión
      await BackgroundAlertPermissionService.solicitarPermisoAlertasCerrada(context);

      if (!mounted) return;
      Navigator.pop(context, registrationData);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 18.0, bottom: 10.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _buildInternationalPhoneField({
    required String currentDialCode,
    required ValueChanged onDialCodeChanged,
    required TextEditingController phoneController,
    required String label,
    String? hint,
    required bool isRequired,
    TextEditingController? linkedNameController,
  }) {
    final uniqueDialCodes = americanCountries
        .map((c) => (c as CountryDialCode).dialCode)
        .toSet()
        .toList()
      ..sort();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: DropdownButtonFormField(
            value: currentDialCode,
            decoration: InputDecoration(
              labelText: 'Código *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            ),
            items: uniqueDialCodes.map((code) {
              return DropdownMenuItem(
                value: code,
                child: Text(
                  code,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                onDialCodeChanged(value as String);
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
            ],
            decoration: _inputDecoration(
              label: label,
              hint: hint,
              icon: Icons.phone_android,
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              final hasLinkedName =
                  linkedNameController != null && linkedNameController.text.trim().isNotEmpty;

              if (isRequired || hasLinkedName) {
                if (text.isEmpty) {
                  return 'Ingresa el número celular';
                }
                if (text.length != 10 && text.length != 7 && text.length != 8 && text.length != 9 && text.length != 11 && text.length != 12) {
                  return 'Número no válido';
                }
              } else if (text.isNotEmpty && text.length != 10 && text.length != 7 && text.length != 8 && text.length != 9 && text.length != 11 && text.length != 12) {
                return 'Número no válido';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Vehículo y Alertas'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ==========================================
                // BANNER SUPERIOR DE SEGURIDAD Y PRIVACIDAD
                // ==========================================
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2E7D32)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.shield, color: Color(0xFF1B5E20), size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tus datos personales están cifrados y protegidos; no se comparten con nadie. Únicamente se publicarán las características del vehículo y la placa si reportas una emergencia o robo.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF1B5E20),
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ==========================================
                // SECCIÓN 1: PAÍS Y CIUDAD (COBERTURA AMÉRICA)
                // ==========================================
                _buildSectionHeader(
                  icon: Icons.public,
                  title: '1. País y Ciudad de Operación',
                  color: primaryColor,
                ),
                DropdownButtonFormField(
                  value: _selectedCountry,
                  decoration: _inputDecoration(
                    label: 'País *',
                    icon: Icons.flag_outlined,
                  ),
                  items: americanCountries.map((country) {
                    final c = country as CountryDialCode;
                    return DropdownMenuItem(
                      value: c,
                      child: Text('${c.name} (${c.dialCode})'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _onCountryChanged(value as CountryDialCode);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cityController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(
                    label: 'Ciudad / Municipio *',
                    hint: 'Ej: Medellín, Ciudad de México, Bogotá...',
                    icon: Icons.location_city,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Ingresa la ciudad'
                      : null,
                ),

                const Divider(height: 32, thickness: 1),

                // ==========================================
                // SECCIÓN 2: DATOS DEL VEHÍCULO
                // ==========================================
                _buildSectionHeader(
                  icon: Icons.directions_car,
                  title: '2. Datos del Vehículo',
                  color: primaryColor,
                ),
                DropdownButtonFormField(
                  value: _selectedVehicleType,
                  decoration: _inputDecoration(
                    label: 'Tipo de vehículo *',
                    icon: Icons.commute,
                  ),
                  items: _vehicleTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type as String),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedVehicleType = value as String;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _plateController,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9-]')),
                    LengthLimitingTextInputFormatter(8),
                  ],
                  decoration: _inputDecoration(
                    label: 'Placa / Patente *',
                    hint: 'Ej: ABC123',
                    icon: Icons.pin,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa la placa del vehículo';
                    }
                    if (value.trim().length == 1 || value.trim().length == 2 || value.trim().length == 3) {
                      return 'Placa no válida';
                    }
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
                        decoration: _inputDecoration(
                          label: 'Marca *',
                          hint: 'Ej: Chevrolet',
                        ),
                        validator: (value) => (value == null || value.trim().isEmpty)
                            ? 'Ingresa la marca'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _modelController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _inputDecoration(
                          label: 'Modelo / Año *',
                          hint: 'Ej: Onix 2023',
                        ),
                        validator: (value) => (value == null || value.trim().isEmpty)
                            ? 'Ingresa el modelo'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _colorController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(
                    label: 'Color *',
                    hint: 'Ej: Blanco',
                    icon: Icons.color_lens_outlined,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Ingresa el color'
                      : null,
                ),

                const Divider(height: 32, thickness: 1),

                // ==========================================
                // SECCIÓN 3: PROPIETARIO Y CONDUCTORES
                // ==========================================
                _buildSectionHeader(
                  icon: Icons.person_pin,
                  title: '3. Propietario y Conductores Autorizados',
                  color: primaryColor,
                ),
                TextFormField(
                  controller: _ownerNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(
                    label: 'Nombre completo del propietario *',
                    icon: Icons.person,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Ingresa el nombre del propietario'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ownerDocumentController,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9-]')),
                    LengthLimitingTextInputFormatter(15),
                  ],
                  decoration: _inputDecoration(
                    label: 'Documento de identidad (ID / DNI / C.C.) *',
                    hint: 'Para validación y prevención de fraude',
                    icon: Icons.badge,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el documento de identidad';
                    }
                    if (value.trim().length == 1 || value.trim().length == 2 || value.trim().length == 3 || value.trim().length == 4) {
                      return 'Documento no válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildInternationalPhoneField(
                  currentDialCode: _ownerDialCode,
                  onDialCodeChanged: (code) => setState(() => _ownerDialCode = code as String),
                  phoneController: _ownerPhoneController,
                  label: 'Celular del propietario *',
                  hint: 'Ej: 3116479280',
                  isRequired: true,
                ),
                const SizedBox(height: 12),

                // Lista dinámica de conductores adicionales por placa
                ..._additionalDrivers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final driver = entry.value as DriverControllers;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Conductor adicional #${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                tooltip: 'Eliminar conductor',
                                onPressed: () => _removeDriver(index),
                              ),
                            ],
                          ),
                          TextFormField(
                            controller: driver.nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: _inputDecoration(
                              label: 'Nombre del conductor *',
                              icon: Icons.person_outline,
                            ),
                            validator: (value) => (value == null || value.trim().isEmpty)
                                ? 'Ingresa el nombre del conductor'
                                : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: driver.documentController,
                            keyboardType: TextInputType.text,
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9-]')),
                              LengthLimitingTextInputFormatter(15),
                            ],
                            decoration: _inputDecoration(
                              label: 'Documento de identidad *',
                              icon: Icons.badge_outlined,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresa el documento del conductor';
                              }
                              if (value.trim().length == 1 || value.trim().length == 2 || value.trim().length == 3 || value.trim().length == 4) {
                                return 'Documento no válido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          _buildInternationalPhoneField(
                            currentDialCode: driver.dialCode,
                            onDialCodeChanged: (code) =>
                                setState(() => driver.dialCode = code as String),
                            phoneController: driver.phoneController,
                            label: 'Celular del conductor *',
                            isRequired: true,
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                OutlinedButton.icon(
                  onPressed: _addDriver,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Agregar otro conductor para esta placa'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const Divider(height: 32, thickness: 1),

                // ==========================================
                // SECCIÓN 4: 2 CONTACTOS DE EMERGENCIA
                // ==========================================
                _buildSectionHeader(
                  icon: Icons.emergency_share,
                  title: '4. Contactos de Emergencia (Alertas Automáticas)',
                  color: Colors.red.shade700,
                ),
                const Text(
                  'Recibirán tu ubicación GPS automática en cualquier país de América si activas una alerta de emergencia.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 12),

                // Contacto de Emergencia 1 (Obligatorio)
                const Text(
                  'Contacto de Emergencia 1 (Principal) *',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emergency1NameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(
                    label: 'Nombre completo *',
                    hint: 'Ej: Familiar o persona de confianza',
                    icon: Icons.contact_emergency,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Ingresa el nombre del contacto 1'
                      : null,
                ),
                const SizedBox(height: 10),
                _buildInternationalPhoneField(
                  currentDialCode: _emergency1DialCode,
                  onDialCodeChanged: (code) =>
                      setState(() => _emergency1DialCode = code as String),
                  phoneController: _emergency1PhoneController,
                  label: 'Celular / WhatsApp *',
                  hint: 'Ej: 3116479280',
                  isRequired: true,
                ),

                const SizedBox(height: 18),

                // Contacto de Emergencia 2 (Respaldo)
                const Text(
                  'Contacto de Emergencia 2 (Respaldo)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emergency2NameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(
                    label: 'Nombre completo',
                    hint: 'Segundo contacto de respaldo',
                    icon: Icons.contact_emergency_outlined,
                  ),
                  validator: (value) {
                    if (_emergency2PhoneController.text.trim().isNotEmpty &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Ingresa el nombre del contacto 2';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                _buildInternationalPhoneField(
                  currentDialCode: _emergency2DialCode,
                  onDialCodeChanged: (code) =>
                      setState(() => _emergency2DialCode = code as String),
                  phoneController: _emergency2PhoneController,
                  label: 'Celular / WhatsApp',
                  hint: 'Ej: 3009876543',
                  isRequired: false,
                  linkedNameController: _emergency2NameController,
                ),

                const SizedBox(height: 22),

                // ==========================================
                // SECCIÓN 5: POLÍTICA DE TRATAMIENTO DE DATOS
                // ==========================================
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _aceptaPoliticaDatos
                          ? const Color(0xFF2E7D32)
                          : Colors.grey.shade400,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lock, color: Color(0xFF1B5E20), size: 18),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Privacidad Garantizada (Ley 1581 de 2012)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tus datos personales nunca se comparten con terceros. Solo se publican la placa y características del vehículo en caso de emergencia o robo.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: const Color(0xFF1B5E20),
                        value: _aceptaPoliticaDatos,
                        onChanged: (val) =>
                            setState(() => _aceptaPoliticaDatos = val ?? false),
                        title: GestureDetector(
                          onTap: _mostrarPoliticaTratamientoDatos,
                          child: const Text.rich(
                            TextSpan(
                              text: 'He leído y acepto la ',
                              style: TextStyle(fontSize: 12.5, color: Colors.black87),
                              children: [
                                TextSpan(
                                  text: 'Política de Tratamiento de Datos Personales',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D47A1),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ==========================================
                // BOTÓN GUARDAR REGISTRO
                // ==========================================
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _submitForm,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_alt, color: Colors.white),
                  label: Text(
                    _isSaving
                        ? 'GUARDANDO REGISTRO...'
                        : 'GUARDAR REGISTRO COMPLETO',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
