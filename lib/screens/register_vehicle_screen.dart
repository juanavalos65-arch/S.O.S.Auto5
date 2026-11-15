import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CountryDialCode {
  final String name;
  final String dialCode;

  const CountryDialCode(this.name, this.dialCode);
}

const List<CountryDialCode> americanCountries = [
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

  DriverControllers({this.dialCode = '+57'})
      : nameController = TextEditingController(),
        documentController = TextEditingController(),
        phoneController = TextEditingController();

  void dispose() {
    nameController.dispose();
    documentController.dispose();
    phoneController.dispose();
  }
}

class RegisterVehicleScreen extends StatefulWidget {
  const RegisterVehicleScreen({super.key});

  @override
  State<RegisterVehicleScreen> createState() => _RegisterVehicleScreenState();
}

class _RegisterVehicleScreenState extends State<RegisterVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  // 1. Ubicación Continental (País, Código Internacional y Ciudad)
  CountryDialCode _selectedCountry = americanCountries.first; // Colombia (+57)
  final TextEditingController _cityController = TextEditingController();

  // 2. Datos del Vehículo
  String _selectedVehicleType = 'Automóvil';
  final List<String> _vehicleTypes = [
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
  DateTime? _soatExpiryDate;
  DateTime? _tecnoExpiryDate;

  // 3. Propietario y Múltiples Conductores
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _ownerDocumentController = TextEditingController();
  String _ownerDialCode = '+57';
  final TextEditingController _ownerPhoneController = TextEditingController();
  final List<DriverControllers> _additionalDrivers = [];

  // 4. Dos Contactos de Emergencia (con indicativo internacional independiente)
  final TextEditingController _emergency1NameController = TextEditingController();
  String _emergency1DialCode = '+57';
  final TextEditingController _emergency1PhoneController = TextEditingController();

  final TextEditingController _emergency2NameController = TextEditingController();
  String _emergency2DialCode = '+57';
  final TextEditingController _emergency2PhoneController = TextEditingController();

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
      driver.dispose();
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

      // Actualiza automáticamente los indicativos que coincidían con el país anterior
      if (_ownerDialCode == previousDial) {
        _ownerDialCode = newCountry.dialCode;
      }
      if (_emergency1DialCode == previousDial) {
        _emergency1DialCode = newCountry.dialCode;
      }
      if (_emergency2DialCode == previousDial) {
        _emergency2DialCode = newCountry.dialCode;
      }
      for (final driver in _additionalDrivers) {
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
      _additionalDrivers[index].dispose();
      _additionalDrivers.removeAt(index);
    });
  }

  Future<void> _selectDate(BuildContext context, {required bool isSoat}) async {
    final now = DateTime.now();
    final initial = isSoat
        ? (_soatExpiryDate ?? now)
        : (_tecnoExpiryDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() {
        if (isSoat) {
          _soatExpiryDate = picked;
        } else {
          _tecnoExpiryDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Seleccionar fecha';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa los campos obligatorios marcados.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final Map<String, dynamic> registrationData = {
      'location': {
        'country': _selectedCountry.name,
        'dialCode': _selectedCountry.dialCode,
        'city': _cityController.text.trim(),
      },
      'vehicle': {
        'type': _selectedVehicleType,
        'plate': _plateController.text.trim().toUpperCase(),
        'brand': _brandController.text.trim(),
        'model': _modelController.text.trim(),
        'color': _colorController.text.trim(),
        'soatExpiry': _soatExpiryDate?.toIso8601String(),
        'tecnoExpiry': _tecnoExpiryDate?.toIso8601String(),
      },
      'owner': {
        'name': _ownerNameController.text.trim(),
        'document': _ownerDocumentController.text.trim(),
        'dialCode': _ownerDialCode,
        'phone': _ownerPhoneController.text.trim(),
        'fullPhone': '$_ownerDialCode${_ownerPhoneController.text.trim()}',
      },
      'additionalDrivers': _additionalDrivers
          .map((d) => {
                'name': d.nameController.text.trim(),
                'document': d.documentController.text.trim(),
                'dialCode': d.dialCode,
                'phone': d.phoneController.text.trim(),
                'fullPhone': '${d.dialCode}${d.phoneController.text.trim()}',
              })
          .toList(),
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Vehículo ${registrationData['vehicle']['plate']} (${_selectedCountry.name}) guardado.',
        ),
        backgroundColor: Colors.green.shade700,
      ),
    );

    Navigator.pop(context, registrationData);
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
    required ValueChanged<String> onDialCodeChanged,
    required TextEditingController phoneController,
    required String label,
    String? hint,
    required bool isRequired,
    TextEditingController? linkedNameController,
  }) {
    // Lista única de códigos de marcado disponibles en América
    final uniqueDialCodes = americanCountries
        .map((c) => c.dialCode)
        .toSet()
        .toList()
      ..sort();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: DropdownButtonFormField<String>(
            initialValue: currentDialCode,
            decoration: InputDecoration(
              labelText: 'Código *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            ),
            items: uniqueDialCodes.map((code) {
              return DropdownMenuItem<String>(
                value: code,
                child: Text(
                  code,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                onDialCodeChanged(value);
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
                if (text.length < 7) {
                  return 'Número no válido';
                }
              } else if (text.isNotEmpty && text.length < 7) {
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
                // SECCIÓN 1: PAÍS Y CIUDAD (COBERTURA AMÉRICA)
                // ==========================================
                _buildSectionHeader(
                  icon: Icons.public,
                  title: '1. País y Ciudad de Operación',
                  color: primaryColor,
                ),
                DropdownButtonFormField<CountryDialCode>(
                  initialValue: _selectedCountry,
                  decoration: _inputDecoration(
                    label: 'País *',
                    icon: Icons.flag_outlined,
                  ),
                  items: americanCountries.map((country) {
                    return DropdownMenuItem<CountryDialCode>(
                      value: country,
                      child: Text('${country.name} (${country.dialCode})'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _onCountryChanged(value);
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
                DropdownButtonFormField<String>(
                  initialValue: _selectedVehicleCountry,
                  decoration: _inputDecoration(
                    label: 'Tipo de vehículo *',
                    icon: Icons.commute,
                  ),
                  items: _vehicleTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedVehicleType = value;
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
                    if (value.trim().length < 4) {
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, isSoat: true),
                        borderRadius: BorderRadius.circular(10),
                        child: InputDecorator(
                          decoration: _inputDecoration(
                            label: 'Venc. Seguro / SOAT',
                            icon: Icons.event_available,
                          ),
                          child: Text(
                            _formatDate(_soatExpiryDate),
                            style: TextStyle(
                              color: _soatExpiryDate == null
                                  ? Colors.black54
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, isSoat: false),
                        borderRadius: BorderRadius.circular(10),
                        child: InputDecorator(
                          decoration: _inputDecoration(
                            label: 'Venc. Revisión Técnica',
                            icon: Icons.build_circle_outlined,
                          ),
                          child: Text(
                            _formatDate(_tecnoExpiryDate),
                            style: TextStyle(
                              color: _tecnoExpiryDate == null
                                  ? Colors.black54
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
                    if (value.trim().length < 5) {
                      return 'Documento no válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildInternationalPhoneField(
                  currentDialCode: _ownerDialCode,
                  onDialCodeChanged: (code) => setState(() => _ownerDialCode = code),
                  phoneController: _ownerPhoneController,
                  label: 'Celular del propietario *',
                  hint: 'Ej: 3116479280',
                  isRequired: true,
                ),
                const SizedBox(height: 12),

                // Lista dinámica de conductores adicionales por placa
                ..._additionalDrivers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final driver = entry.value;
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
                              if (value.trim().length < 5) {
                                return 'Documento no válido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          _buildInternationalPhoneField(
                            currentDialCode: driver.dialCode,
                            onDialCodeChanged: (code) =>
                                setState(() => driver.dialCode = code),
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
                      setState(() => _emergency1DialCode = code),
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
                      setState(() => _emergency2DialCode = code),
                  phoneController: _emergency2PhoneController,
                  label: 'Celular / WhatsApp',
                  hint: 'Ej: 3009876543',
                  isRequired: false,
                  linkedNameController: _emergency2NameController,
                ),

                const SizedBox(height: 28),

                // ==========================================
                // BOTÓN GUARDAR REGISTRO
                // ==========================================
                ElevatedButton.icon(
                  onPressed: _submitForm,
                  icon: const Icon(Icons.save_alt, color: Colors.white),
                  label: const Text(
                    'GUARDAR REGISTRO COMPLETO',
                    style: TextStyle(
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
