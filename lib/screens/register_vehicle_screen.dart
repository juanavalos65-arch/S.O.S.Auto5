import 'package:flutter/material.dart';

class _AuthorizedDriver {
  final String name;
  final String phone;

  const _AuthorizedDriver({
    required this.name,
    required this.phone,
  });
}

class RegisterVehicleScreen extends StatefulWidget {
  const RegisterVehicleScreen({super.key});

  @override
  State<RegisterVehicleScreen> createState() => _RegisterVehicleScreenState();
}

class _RegisterVehicleScreenState extends State<RegisterVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  // 1. Datos del vehículo
  String _vehicleType = 'Automóvil';
  final _plateController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _colorController = TextEditingController();

  // 2. Datos del conductor principal
  String _driverRole = 'Propietario Principal';
  final _nameController = TextEditingController();
  final _docIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _pinController = TextEditingController();
  final _emergencyContactController = TextEditingController();

  // 3. Fechas de documentos
  DateTime? _soatExpiry;
  DateTime? _tecnoExpiry;

  // 4. Múltiples conductores asociados a la misma placa (sin < > anidados)
  final _authorizedDrivers = <_AuthorizedDriver>[];
  final _extraDriverNameController = TextEditingController();
  final _extraDriverPhoneController = TextEditingController();

  @override
  void dispose() {
    _plateController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _nameController.dispose();
    _docIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _pinController.dispose();
    _emergencyContactController.dispose();
    _extraDriverNameController.dispose();
    _extraDriverPhoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isSoat) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 180)),
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() {
        if (isSoat) {
          _soatExpiry = picked;
        } else {
          _tecnoExpiry = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Seleccionar fecha';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  void _addAuthorizedDriver() {
    final name = _extraDriverNameController.text.trim();
    final phone = _extraDriverPhoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa nombre y celular del conductor adicional.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() {
      _authorizedDrivers.add(_AuthorizedDriver(name: name, phone: phone));
      _extraDriverNameController.clear();
      _extraDriverPhoneController.clear();
    });
  }

  void _saveRegistration() {
    if (!_formKey.currentState!.validate()) return;

    final plate = _plateController.text.trim().toUpperCase();
    final brand = _brandController.text.trim();
    final model = _modelController.text.trim();
    final color = _colorController.text.trim();
    final pin = _pinController.text.trim();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified_user, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Registro Exitoso',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vehículo: $_vehicleType'),
            const SizedBox(height: 4),
            Text('Placa: $plate'),
            const SizedBox(height: 4),
            Text('Marca y Modelo: $brand $model'),
            const SizedBox(height: 4),
            Text('Color: $color'),
            const Divider(height: 16),
            Text('Conductor: ${_nameController.text.trim()} ($_driverRole)'),
            const SizedBox(height: 4),
            Text('Conductores adicionales: ${_authorizedDrivers.length}'),
            const SizedBox(height: 4),
            const Text('PIN de seguridad S.O.S.: Configurado'),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D1B2A),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, {
                'plate': plate,
                'pin': pin,
                'vehicleType': _vehicleType,
                'brand': brand,
                'model': model,
                'color': color,
                'driverName': _nameController.text.trim(),
              });
            },
            child: const Text('Volver al Mapa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        title: const Text(
          'Registro de Vehículo',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // SECCIÓN 1: DATOS DEL VEHÍCULO
            _buildSectionHeader(Icons.directions_car, '1. Datos del Vehículo (Obligatorio)'),
            const SizedBox(height: 12),

            // Tipo de vehículo
            DropdownButtonFormField<String>(
              value: _vehicleType,
              decoration: const InputDecoration(
                labelText: 'Tipo de vehículo *',
                prefixIcon: Icon(Icons.commute),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Automóvil', child: Text('Automóvil')),
                DropdownMenuItem(value: 'Motocicleta', child: Text('Motocicleta')),
                DropdownMenuItem(value: 'Camioneta', child: Text('Camioneta')),
                DropdownMenuItem(value: 'Camión', child: Text('Camión')),
                DropdownMenuItem(value: 'Bus', child: Text('Bus')),
                DropdownMenuItem(value: 'Servicio Público / Taxi', child: Text('Servicio Público / Taxi')),
                DropdownMenuItem(value: 'Otro', child: Text('Otro')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _vehicleType = val);
              },
            ),
            const SizedBox(height: 12),

            // Placa y Marca
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _plateController,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 7,
                    decoration: const InputDecoration(
                      labelText: 'Placa *',
                      hintText: 'ABC123',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().length < 5) {
                        return 'Placa inválida';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _brandController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Marca *',
                      hintText: 'Ej: Renault, Mazda, Yamaha',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Ingresa la marca' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Modelo y Color
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _modelController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Modelo *',
                      hintText: 'Ej: Duster 2022',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Ingresa el modelo' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _colorController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Color *',
                      hintText: 'Ej: Blanco',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Ingresa el color' : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // SECCIÓN 2: CONDUCTOR Y SEGURIDAD PIN
            _buildSectionHeader(Icons.person_pin, '2. Conductor y Seguridad S.O.S.'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _driverRole,
              decoration: const InputDecoration(
                labelText: 'Rol respecto al vehículo',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Propietario Principal', child: Text('Propietario Principal')),
                DropdownMenuItem(value: 'Conductor Familiar', child: Text('Conductor Familiar')),
                DropdownMenuItem(value: 'Conductor Autorizado / Empresa', child: Text('Conductor Autorizado / Empresa')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _driverRole = val);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre Completo *',
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _docIdController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cédula *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().length < 5) ? 'Inválida' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Celular / WhatsApp *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().length < 7) ? 'Inválido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo de Recuperación (Google / Respaldo) *',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || !v.contains('@'))
                  ? 'Ingresa un correo válido para recuperación'
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    decoration: const InputDecoration(
                      labelText: 'PIN Desactivación (4 dígitos) *',
                      hintText: 'Ej: 1234',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    validator: (v) => (v == null || v.trim().length != 4)
                        ? 'Debe ser de 4 dígitos'
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _emergencyContactController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Celular Emergencia *',
                      hintText: 'Familiar / Contacto',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().length < 7) ? 'Requerido' : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // SECCIÓN 3: VENCIMIENTO DE DOCUMENTOS (SOAT Y TECNOMECÁNICA)
            _buildSectionHeader(Icons.event_available, '3. Alertas de Documentos'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context, true),
                    icon: const Icon(Icons.security),
                    label: Text(
                      'SOAT:\n${_formatDate(_soatExpiry)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context, false),
                    icon: const Icon(Icons.build_circle_outlined),
                    label: Text(
                      'Tecnomecánica:\n${_formatDate(_tecnoExpiry)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // SECCIÓN 4: MÚLTIPLES CONDUCTORES POR PLACA
            _buildSectionHeader(Icons.group_add, '4. Conductores Adicionales en esta Placa'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _extraDriverNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _extraDriverPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Celular',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                  ),
                  onPressed: _addAuthorizedDriver,
                  icon: const Icon(Icons.add),
                  tooltip: 'Agregar conductor',
                ),
              ],
            ),
            if (_authorizedDrivers.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._authorizedDrivers.asMap().entries.map((entry) {
                final idx = entry.key;
                final drv = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.person_outline, color: Color(0xFF0D1B2A)),
                    title: Text(drv.name),
                    subtitle: Text('Tel: ${drv.phone}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        setState(() => _authorizedDrivers.removeAt(idx));
                      },
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 24),

            // BOTÓN GUARDAR
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D1B2A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saveRegistration,
                icon: const Icon(Icons.save),
                label: const Text(
                  'GUARDAR REGISTRO DE VEHÍCULO',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0D1B2A), size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D1B2A),
            ),
          ),
        ),
      ],
    );
  }
}
