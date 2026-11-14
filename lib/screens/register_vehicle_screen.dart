import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DriverControllers {
  final TextEditingController nameController;
  final TextEditingController phoneController;

  DriverControllers()
      : nameController = TextEditingController(),
        phoneController = TextEditingController();

  void dispose() {
    nameController.dispose();
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

  // 1. Datos del Vehículo
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

  // 2. Propietario y Múltiples Conductores
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _ownerPhoneController = TextEditingController();
  final List<DriverControllers> _additionalDrivers = [];

  // 3. Dos Contactos de Emergencia
  final TextEditingController _emergency1NameController = TextEditingController();
  final TextEditingController _emergency1PhoneController = TextEditingController();
  final TextEditingController _emergency2NameController = TextEditingController();
  final TextEditingController _emergency2PhoneController = TextEditingController();

  @override
  void dispose() {
    _plateController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _ownerNameController.dispose();
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

  void _addDriver() {
    setState(() {
      _additionalDrivers.add(DriverControllers());
    });
  }

  void _removeDriver(int index) {
    setState(() {
      _additionalDrivers[index].dispose();
      _additionalDrivers.removeAt(index);
    });
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

    // Estructura consolidada lista para guardar localmente o enviar a backend
    final Map<String, dynamic> registrationData = {
      'vehicle': {
        'type': _selectedVehicleType,
        'plate': _plateController.text.trim().toUpperCase(),
        'brand': _brandController.text.trim(),
        'model': _modelController.text.trim(),
        'color': _colorController.text.trim(),
      },
      'owner': {
        'name': _ownerNameController.text.trim(),
        'phone': _ownerPhoneController.text.trim(),
      },
      'additionalDrivers': _additionalDrivers
          .map((d) => {
                'name': d.nameController.text.trim(),
                'phone': d.phoneController.text.trim(),
              })
          .toList(),
      'emergencyContacts': [
        {
          'name': _emergency1NameController.text.trim(),
          'phone': _emergency1PhoneController.text.trim(),
        },
        if (_emergency2NameController.text.trim().isNotEmpty ||
            _emergency2PhoneController.text.trim().isNotEmpty)
          {
            'name': _emergency2NameController.text.trim(),
            'phone': _emergency2PhoneController.text.trim(),
          },
      ],
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Vehículo ${registrationData['vehicle']['plate']} y contactos guardados correctamente.',
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
                // SECCIÓN 1: DATOS DEL VEHÍCULO
                // ==========================================
                _buildSectionHeader(
                  icon: Icons.directions_car,
                  title: '1. Datos del Vehículo',
                  color: primaryColor,
                ),
                DropdownButtonFormField<String>(
                  value: _selectedVehicleType,
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
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                    LengthLimitingTextInputFormatter(7),
                  ],
                  decoration: _inputDecoration(
                    label: 'Placa *',
                    hint: 'Ej: ABC123',
                    icon: Icons.pin,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa la placa del vehículo';
                    }
                    if (value.trim().length < 5) {
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
                // SECCIÓN 2: PROPIETARIO Y CONDUCTORES
                // ==========================================
                _buildSectionHeader(
                  icon: Icons.person_pin,
                  title: '2. Propietario y Conductores Autorizados',
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
                  controller: _ownerPhoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: _inputDecoration(
                    label: 'Celular del propietario *',
                    hint: 'Ej: 3001234567',
                    icon: Icons.phone_android,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el celular del propietario';
                    }
                    if (value.trim().length < 10) {
                      return 'Debe tener 10 dígitos';
                    }
                    return null;
                  },
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
                              icon: Icons.badge_outlined,
                            ),
                            validator: (value) => (value == null || value.trim().isEmpty)
                                ? 'Ingresa el nombre del conductor'
                                : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: driver.phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: _inputDecoration(
                              label: 'Celular del conductor *',
                              icon: Icons.phone,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresa el celular';
                              }
                              if (value.trim().length < 10) {
                                return 'Debe tener 10 dígitos';
                              }
                              return null;
                            },
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
                // SECCIÓN 3: 2 CONTACTOS DE EMERGENCIA
                // ==========================================
                _buildSectionHeader(
                  icon: Icons.emergency_share,
                  title: '3. Contactos de Emergencia (Alertas Automáticas)',
                  color: Colors.red.shade700,
                ),
                const Text(
                  'Recibirán tu ubicación GPS automática si activas "Me varé", "Accidente", "Estoy en peligro" o "Robo de auto".',
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
                TextFormField(
                  controller: _emergency1PhoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: _inputDecoration(
                    label: 'Celular / WhatsApp *',
                    hint: 'Ej: 3116479280',
                    icon: Icons.phone_in_talk,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el número del contacto 1';
                    }
                    if (value.trim().length < 10) {
                      return 'Debe tener 10 dígitos';
                    }
                    return null;
                  },
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
                TextFormField(
                  controller: _emergency2PhoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: _inputDecoration(
                    label: 'Celular / WhatsApp',
                    hint: 'Ej: 3009876543',
                    icon: Icons.phone_in_talk_outlined,
                  ),
                  validator: (value) {
                    final hasName = _emergency2NameController.text.trim().isNotEmpty;
                    final hasPhone = value != null && value.trim().isNotEmpty;
                    if (hasName && !hasPhone) {
                      return 'Ingresa el número del contacto 2';
                    }
                    if (hasPhone && value.trim().length < 10) {
                      return 'Debe tener 10 dígitos';
                    }
                    return null;
                  },
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
