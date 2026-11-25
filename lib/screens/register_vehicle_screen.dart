import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _isRegisteredLocked = false;
  bool _isCloudSynced = false;
  String _syncErrorDetail = '';
  String _activeOtpCode = '';

  List> get validAdditionalDrivers {
    final List> result = [];
    for (final driver in _additionalDrivers) {
      final name = driver.nameController.text.trim();
      final doc = driver.documentController.text.trim();
      final phone = driver.phoneController.text.trim();
      if (name.isNotEmpty || doc.isNotEmpty || phone.isNotEmpty) {
        result.add({
          'name': name,
          'nombre': name,
          'document': doc,
          'documento': doc,
          'phone': phone.isNotEmpty ? '${_selectedCountry.dialCode} $phone' : '',
          'telefono': phone.isNotEmpty ? '${_selectedCountry.dialCode} $phone' : '',
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
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
        final rawJson = prefs.getString(_storageKey) ??
            prefs.getString('registered_vehicle') ??
            prefs.getString('vehiculo_registrado');
        if (rawJson != null && rawJson.isNotEmpty) {
          final decoded = jsonDecode(rawJson);
          if (decoded is Map) {
            sourceData = Map<String, dynamic>.from(decoded);
          }
        }
      } catch (_) {}
    }

    final plateVal =
        (sourceData?['plate'] ?? sourceData?['placa'] ?? '').toString();
    if (sourceData != null && plateVal.isNotEmpty) {
      _applyDataToControllers(sourceData);
      _isRegisteredLocked = true;
      _isCloudSynced = sourceData['cloudSynced'] == true;
      _syncErrorDetail = (sourceData['syncError'] ?? '').toString();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyDataToControllers(Map<String, dynamic> data) {
    final savedCountry = (data['country'] ?? data['pais'] ?? '').toString();
    if (savedCountry.isNotEmpty) {
      for (final c in _americanCountries) {
        if (c.name == savedCountry) {
          _selectedCountry = c;
          break;
        }
      }
    }

    final savedType =
        (data['vehicleType'] ?? data['tipoVehiculo'] ?? '').toString();
    if (_vehicleTypes.contains(savedType)) {
      _selectedVehicleType = savedType;
    }

    _plateController.text = (data['plate'] ?? data['placa'] ?? '').toString();
    _brandController.text = (data['brand'] ?? data['marca'] ?? '').toString();
    _modelController.text = (data['model'] ?? data['modelo'] ?? '').toString();
    _colorController.text = (data['color'] ?? '').toString();
    _cityController.text = (data['city'] ?? data['ciudad'] ?? '').toString();

    _ownerNameController.text =
        (data['ownerName'] ?? data['propietario'] ?? '').toString();
    _ownerDocumentController.text =
        (data['ownerDocument'] ?? data['documento'] ?? '').toString();
    _ownerPhoneController.text =
        (data['ownerRawPhone'] ?? data['telefono'] ?? '').toString();
    _ownerEmailController.text =
        (data['ownerEmail'] ?? data['correo'] ?? '').toString();

    final contacts = data['emergencyContacts'] ?? data['contactosEmergencia'];
    if (contacts is List) {
      if (contacts.isNotEmpty && contacts[0] is Map) {
        _emergency1NameController.text =
            (contacts[0]['name'] ?? contacts[0]['nombre'] ?? '').toString();
        _emergency1PhoneController.text =
            (contacts[0]['rawPhone'] ?? contacts[0]['telefono'] ?? '')
                .toString();
      }
      if (contacts.length > 1 && contacts[1] is Map) {
        _emergency2NameController.text =
            (contacts[1]['name'] ?? contacts[1]['nombre'] ?? '').toString();
        _emergency2PhoneController.text =
            (contacts[1]['rawPhone'] ?? contacts[1]['telefono'] ?? '')
                .toString();
      }
    }

    for (final d in _additionalDrivers) {
      d.dispose();
    }
    _additionalDrivers.clear();

    final drivers = data['additionalDrivers'] ?? data['conductoresAdicionales'];
    if (drivers is List) {
      for (final item in drivers) {
        if (item is Map) {
          _additionalDrivers.add(
            AdditionalDriverInput(
              name: (item['name'] ?? item['nombre'] ?? '').toString(),
              document: (item['document'] ?? item['documento'] ?? '').toString(),
              phone: (item['rawPhone'] ?? item['telefono'] ?? '').toString(),
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

  String _generateOtpCode() {
    final random = Random.secure();
    final code = 100000 + random.nextInt(900000);
    return code.toString();
  }

  String _maskPhone(String rawPhone) {
    if (rawPhone.length <= 4) return rawPhone;
    final visible = rawPhone.substring(rawPhone.length - 4);
    return '****$visible';
  }

  Future<void> _sendOtpToRegisteredPhone(
    String otpCode, {
    required bool viaWhatsApp,
  }) async {
    final rawPhone = _ownerPhoneController.text.trim();
    final dialDigits = _selectedCountry.dialCode.replaceAll('+', '');
    final fullPhoneNoPlus = '$dialDigits$rawPhone';
    final fullPhoneWithPlus = '${_selectedCountry.dialCode}$rawPhone';
    final plate = _plateController.text.trim().toUpperCase();

    final messageText =
        'S.O.S. AUTO - Codigo de seguridad: $otpCode para autorizar cambio o venta del vehiculo placa $plate. No compartas este codigo.';
    final encodedText = Uri.encodeComponent(messageText);

    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('otp_verifications')
            .doc(plate)
            .set({
              'plate': plate,
              'phone': fullPhoneWithPlus,
              'otpCode': otpCode,
              'channel': viaWhatsApp ? 'whatsapp' : 'sms',
              'createdAt': FieldValue.serverTimestamp(),
            })
            .timeout(const Duration(seconds: 6));
      }
    } catch (_) {}

    if (viaWhatsApp) {
      final waUri = Uri.parse('https://wa.me/$fullPhoneNoPlus?text=$encodedText');
      if (await canLaunchUrl(waUri)) {
        await launchUrl(waUri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    final smsUri = Uri.parse('sms:$fullPhoneWithPlus?body=$encodedText');
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _requestUnlockByPhoneCode() async {
    final rawPhone = _ownerPhoneController.text.trim();
    if (rawPhone.isEmpty) {
      setState(() => _isRegisteredLocked = false);
      return;
    }

    _activeOtpCode = _generateOtpCode();
    final maskedPhone = '${_selectedCountry.dialCode} ${_maskPhone(rawPhone)}';
    final codeInputController = TextEditingController();
    String? errorMsg;
    bool codeSent = false;

    final unlocked = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.phonelink_lock, color: Color(0xFFB71C1C)),
                  SizedBox(width: 8),
                  Expanded(child: Text('Verificación Antifraude')),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Para cambiar el registro o transferir el vehículo por venta, enviaremos un código de 6 dígitos al teléfono registrado:\n$maskedPhone',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              await _sendOtpToRegisteredPhone(
                                _activeOtpCode,
                                viaWhatsApp: true,
                              );
                              setDialogState(() {
                                codeSent = true;
                                errorMsg = null;
                              });
                            },
                            icon: const Icon(Icons.chat, size: 18),
                            label: const Text(
                              'WhatsApp',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await _sendOtpToRegisteredPhone(
                                _activeOtpCode,
                                viaWhatsApp: false,
                              );
                              setDialogState(() {
                                codeSent = true;
                                errorMsg = null;
                              });
                            },
                            icon: const Icon(Icons.sms, size: 18),
                            label: const Text(
                              'Enviar SMS',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (codeSent) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Código enviado a $maskedPhone. Ingrésalo abajo:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: codeInputController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Código de seguridad (6 dígitos)',
                        border: const OutlineInputBorder(),
                        errorText: errorMsg,
                        prefixIcon: const Icon(Icons.password),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final entered = codeInputController.text.trim();
                    if (entered.isNotEmpty && entered == _activeOtpCode) {
                      Navigator.of(ctx).pop(true);
                    } else {
                      setDialogState(() {
                        errorMsg = 'Código incorrecto. Envía e ingresa el código.';
                      });
                    }
                  },
                  child: const Text('Verificar y Desbloquear'),
                ),
              ],
            );
          },
        );
      },
    );

    codeInputController.dispose();

    if (unlocked == true && mounted) {
      setState(() {
        _isRegisteredLocked = false;
        _activeOtpCode = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Teléfono verificado. Ya puedes modificar el registro del vehículo.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _persistToAllLocalKeys(
    SharedPreferences prefs,
    Map<String, dynamic> data,
  ) async {
    final encoded = jsonEncode(data);
    await prefs.setString(_storageKey, encoded);
    await prefs.setString('registered_vehicle', encoded);
    await prefs.setString('vehiculo_registrado', encoded);
    await prefs.setString('vehicle_data', encoded);

    await prefs.setString('vehicle_plate', data['plate'] ?? '');
    await prefs.setString('placa', data['plate'] ?? '');
    await prefs.setString('vehicle_type', data['vehicleType'] ?? '');
    await prefs.setString('tipo_vehiculo', data['vehicleType'] ?? '');
    await prefs.setString('vehicle_brand', data['brand'] ?? '');
    await prefs.setString('marca', data['brand'] ?? '');
    await prefs.setString('vehicle_model', data['model'] ?? '');
    await prefs.setString('modelo', data['model'] ?? '');
    await prefs.setString('vehicle_color', data['color'] ?? '');
    await prefs.setString('color', data['color'] ?? '');
    await prefs.setString('owner_name', data['ownerName'] ?? '');
    await prefs.setString('owner_phone', data['ownerPhone'] ?? '');
    await prefs.setString('emergency1_name', _emergency1NameController.text.trim());
    await prefs.setString('emergency1_phone', '${_selectedCountry.dialCode} ${_emergency1PhoneController.text.trim()}');
  }

  Future<void> _saveRegistration() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa los campos obligatorios marcados.'),
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

    final emergencyContacts = [
      {
        'name': _emergency1NameController.text.trim(),
        'nombre': _emergency1NameController.text.trim(),
        'phone': '${_selectedCountry.dialCode} $e1RawPhone',
        'telefono': '${_selectedCountry.dialCode} $e1RawPhone',
        'rawPhone': e1RawPhone,
      },
      if (_emergency2NameController.text.trim().isNotEmpty ||
          e2RawPhone.isNotEmpty)
        {
          'name': _emergency2NameController.text.trim(),
          'nombre': _emergency2NameController.text.trim(),
          'phone': '${_selectedCountry.dialCode} $e2RawPhone',
          'telefono': '${_selectedCountry.dialCode} $e2RawPhone',
          'rawPhone': e2RawPhone,
        },
    ];

    final registrationData = <String, dynamic>{
      'vehicleType': _selectedVehicleType,
      'tipoVehiculo': _selectedVehicleType,
      'plate': normalizedPlate,
      'placa': normalizedPlate,
      'brand': _brandController.text.trim(),
      'marca': _brandController.text.trim(),
      'model': _modelController.text.trim(),
      'modelo': _modelController.text.trim(),
      'color': _colorController.text.trim(),
      'country': _selectedCountry.name,
      'pais': _selectedCountry.name,
      'dialCode': _selectedCountry.dialCode,
      'city': _cityController.text.trim(),
      'ciudad': _cityController.text.trim(),
      'ownerName': _ownerNameController.text.trim(),
      'propietario': _ownerNameController.text.trim(),
      'ownerDocument': _ownerDocumentController.text.trim(),
      'documento': _ownerDocumentController.text.trim(),
      'ownerPhone': '${_selectedCountry.dialCode} $ownerRawPhone',
      'telefono': '${_selectedCountry.dialCode} $ownerRawPhone',
      'ownerRawPhone': ownerRawPhone,
      'ownerEmail': _ownerEmailController.text.trim(),
      'correo': _ownerEmailController.text.trim(),
      'additionalDrivers': validAdditionalDrivers,
      'conductoresAdicionales': validAdditionalDrivers,
      'emergencyContacts': emergencyContacts,
      'contactosEmergencia': emergencyContacts,
      'updatedAt': DateTime.now().toIso8601String(),
      'cloudSynced': false,
    };

    final prefs = await SharedPreferences.getInstance();
    await _persistToAllLocalKeys(prefs, registrationData);

    unawaited(() async {
      try {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp();
        }
        await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(normalizedPlate)
            .set(
              {
                ...registrationData,
                'cloudSynced': true,
                'serverUpdatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
        registrationData['cloudSynced'] = true;
        await _persistToAllLocalKeys(prefs, registrationData);
      } catch (_) {}
    }());

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _isRegisteredLocked = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Vehículo $normalizedPlate registrado y activo para emergencias.',
        ),
        backgroundColor: Colors.green.shade700,
      ),
    );

    Navigator.of(context).pop(registrationData);
  }

  Future<void> _retryCloudSync() async {
    setState(() => _isSaving = true);
    final normalizedPlate =
        _plateController.text.trim().toUpperCase().replaceAll(' ', '');
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final data = Map<String, dynamic>.from(jsonDecode(raw));
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp();
        }
        await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(normalizedPlate)
            .set(
              {
                ...data,
                'cloudSynced': true,
                'serverUpdatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            )
            .timeout(const Duration(seconds: 12));

        data['cloudSynced'] = true;
        data['syncError'] = '';
        await _persistToAllLocalKeys(prefs, data);

        if (!mounted) return;
        setState(() {
          _isSaving = false;
          _isCloudSynced = true;
          _syncErrorDetail = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sincronización con la nube completada.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _syncErrorDetail = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo conectar aún: $e'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
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

  Widget _buildLockedSummaryView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.green.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.green.shade700, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.verified_user,
                      color: Colors.green.shade800,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'VEHÍCULO REGISTRADO Y ACTIVO',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      _isCloudSynced ? Icons.cloud_done : Icons.phone_android,
                      size: 16,
                      color: _isCloudSynced
                          ? Colors.green.shade800
                          : Colors.blue.shade800,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _isCloudSynced
                            ? 'Sincronizado en la nube y disponible en Accidente, Peligro, Robo y Banner.'
                            : 'Activo en el dispositivo para Accidente, Peligro, Robo y Banner.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isCloudSynced
                              ? Colors.green.shade900
                              : Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!_isCloudSynced) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : _retryCloudSync,
                    icon: const Icon(Icons.sync, size: 18),
                    label: Text(
                      _isSaving ? 'Sincronizando...' : 'Sincronizar ahora con la nube',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  if (_syncErrorDetail.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Detalle técnico: $_syncErrorDetail',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                ],
                const Divider(height: 24),
                _summaryRow('Placa:', _plateController.text.toUpperCase()),
                _summaryRow('Tipo:', _selectedVehicleType),
                _summaryRow(
                  'Vehículo:',
                  '${_brandController.text} ${_modelController.text} (${_colorController.text})',
                ),
                _summaryRow(
                  'Ubicación:',
                  '${_cityController.text}, ${_selectedCountry.name}',
                ),
                _summaryRow('Propietario:', _ownerNameController.text),
                _summaryRow('Documento:', _ownerDocumentController.text),
                _summaryRow(
                  'Teléfono:',
                  '${_selectedCountry.dialCode} ${_ownerPhoneController.text}',
                ),
                _summaryRow(
                  'Contacto Emergencia 1:',
                  '${_emergency1NameController.text} (${_selectedCountry.dialCode} ${_emergency1PhoneController.text})',
                ),
                if (_emergency2NameController.text.trim().isNotEmpty)
                  _summaryRow(
                    'Contacto Emergencia 2:',
                    '${_emergency2NameController.text} (${_selectedCountry.dialCode} ${_emergency2PhoneController.text})',
                  ),
                _summaryRow(
                  'Conductores adicionales:',
                  '${_additionalDrivers.length}',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.shade700),
          ),
          child: const Row(
            children: [
              Icon(Icons.security, color: Colors.black87),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Este registro queda guardado permanentemente. Si vendes o cambias el vehículo, solicita un código de seguridad al teléfono registrado para habilitar el cambio.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _requestUnlockByPhoneCode,
            icon: const Icon(Icons.sms_failed_outlined),
            label: const Text(
              'CAMBIAR REGISTRO (CÓDIGO AL TELÉFONO)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 145,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
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
              child: _isRegisteredLocked
                  ? _buildLockedSummaryView()
                  : Form(
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
                            items: _americanCountries
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(
                                      '${c.flag} ${c.name} (${c.dialCode})',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedCountry = v);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _cityController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Ciudad / Municipio *',
                              hintText: 'Ej. Medellín, Sincelejo',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_city),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Ingresa tu ciudad'
                                : null,
                          ),
                          const SizedBox(height: 22),
                          _buildSectionHeader(
                            icon: Icons.directions_car,
                            title: '2. Datos del Vehículo',
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: _selectedVehicleType,
                            decoration: const InputDecoration(
                              labelText: 'Tipo de vehículo *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.commute),
                            ),
                            items: _vehicleTypes
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedVehicleType = v);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _plateController,
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z0-9-]'),
                              ),
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Placa del vehículo *',
                              hintText: 'Ej. ABC123',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.pin),
                            ),
                            validator: (v) {
                              final clean = (v ?? '').trim();
                              if (clean.isEmpty) {
                                return 'La placa es obligatoria';
                              }
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
                                  decoration: const InputDecoration(
                                    labelText: 'Marca *',
                                    hintText: 'Ej. Chevrolet',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Requerido'
                                          : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _modelController,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: const InputDecoration(
                                    labelText: 'Línea / Modelo *',
                                    hintText: 'Ej. Spark',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Requerido'
                                          : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _colorController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Color *',
                              hintText: 'Ej. Gris Plata',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.color_lens),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Ingresa el color'
                                : null,
                          ),
                          const SizedBox(height: 22),
                          _buildSectionHeader(
                            icon: Icons.person,
                            title: '3. Propietario / Conductor Principal',
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _ownerNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Nombre completo *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.badge),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Ingresa el nombre'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _ownerDocumentController,
                            decoration: const InputDecoration(
                              labelText:
                                  'Documento de identidad (Cédula / ID) *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.credit_card),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Ingresa el documento'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _ownerPhoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              labelText: 'Teléfono / WhatsApp (Recibirá código) *',
                              prefixText: '${_selectedCountry.dialCode} ',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.phone_android),
                            ),
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
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico (opcional)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: _buildSectionHeader(
                                  icon: Icons.group_add,
                                  title:
                                      '4. Conductores Autorizados (Misma Placa)',
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _addDriverField,
                                icon: const Icon(Icons.add_circle),
                                label: const Text('Agregar'),
                              ),
                            ],
                          ),
                          if (_additionalDrivers.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                'Agrega otros conductores autorizados para esta misma placa.',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13,
                                ),
                              ),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Conductor adicional #${index + 1}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _removeDriverField(index),
                                        ),
                                      ],
                                    ),
                                    TextFormField(
                                      controller: driver.nameController,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      decoration: const InputDecoration(
                                        labelText: 'Nombre del conductor *',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Ingresa el nombre'
                                              : null,
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: driver.documentController,
                                      decoration: const InputDecoration(
                                        labelText: 'Documento de identidad *',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Ingresa el documento'
                                              : null,
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: driver.phoneController,
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: InputDecoration(
                                        labelText: 'Teléfono / WhatsApp *',
                                        prefixText:
                                            '${_selectedCountry.dialCode} ',
                                        border: const OutlineInputBorder(),
                                      ),
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Ingresa el teléfono'
                                              : null,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 22),
                          _buildSectionHeader(
                            icon: Icons.emergency_share,
                            title: '5. Contactos de Emergencia',
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _emergency1NameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText:
                                  'Contacto de emergencia 1 (Nombre) *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person_pin),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Ingresa al menos 1 contacto'
                                : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _emergency1PhoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              labelText: 'Teléfono contacto 1 *',
                              prefixText: '${_selectedCountry.dialCode} ',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.phone),
                            ),
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
                            decoration: const InputDecoration(
                              labelText:
                                  'Contacto de emergencia 2 (Nombre - opcional)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person_pin_outlined),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _emergency2PhoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              labelText: 'Teléfono contacto 2 (opcional)',
                              prefixText: '${_selectedCountry.dialCode} ',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.phone_outlined),
                            ),
                          ),
                          const SizedBox(height: 26),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB71C1C),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _isSaving ? null : _saveRegistration,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(
                                _isSaving
                                    ? 'GUARDANDO REGISTRO...'
                                    : 'GUARDAR REGISTRO',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
