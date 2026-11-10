import 'package:flutter/material.dart';

class RegisterVehicleScreen extends StatefulWidget {
  const RegisterVehicleScreen({super.key});

  @override
  State<RegisterVehicleScreen> createState() => _RegisterVehicleScreenState();
}

class _RegisterVehicleScreenState extends State<RegisterVehicleScreen> {
  String selectedType = 'Carro';
  bool addAnotherDriver = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('S.O.S. Auto', style: TextStyle(color: Color(0xFF0A2540))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0A2540)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFD6E4FC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Registre su vehículo',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF0A2540),
                    ),
                  ),
                  Text(
                    'PASO 1/2',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF0A2540),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '1. Datos de su vehículo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0A2540)),
            ),
            const Text(
              'Así la ayuda llega más rápido y con sus datos listos',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['Carro', 'Moto', 'Taxi', 'Camión'].map((type) {
                bool isSelected = selectedType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  selectedColor: const Color(0xFF0A2540),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF0A2540),
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      selectedType = type;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _buildTextField('Placa del vehículo *', 'Ej: ABC-123'),
            _buildTextField('Marca *', 'Ej: Chevrolet, Yamaha, Mazda...'),
            _buildTextField('Modelo / Línea', 'Ej: Spark, NMax, CX-5...'),
            _buildTextField('Color', 'Ej: Blanco, Negro, Rojo...'),
            _buildTextField('Año', 'Ej: 2020'),
            const SizedBox(height: 15),
            const Text(
              'Documentos del vehículo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0A2540)),
            ),
            const SizedBox(height: 10),
            _buildInfoBox('SOAT - Fecha de vencimiento', 'Te avisamos antes de que se venza >'),
            const SizedBox(height: 8),
            _buildInfoBox('Revisión Tecnomecánica - Vencimiento', 'Te avisamos antes de que se venza >'),
            const SizedBox(height: 20),
            const Text(
              '2. Propietario y conductor(es) de este vehículo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0A2540)),
            ),
            const SizedBox(height: 12),
            _buildTextField('Nombre completo del propietario *', 'Ej: Juan Pérez'),
            _buildTextField('Cédula del propietario *', 'Ej: 1.100.000.000'),
            _buildTextField('Celular del propietario *', 'Ej: 300 123 4567'),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  addAnotherDriver = !addAnotherDriver;
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('AGREGAR OTRO CONDUCTOR'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0A2540),
                side: const BorderSide(color: Color(0xFF0A2540)),
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
            if (addAnotherDriver) ...[
              const SizedBox(height: 15),
              const Text('Conductor adicional', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildTextField('Nombre completo del conductor', 'Ej: María Gómez'),
              _buildTextField('Cédula del conductor', 'Ej: 1.100.000.000'),
              _buildTextField('Celular del conductor', 'Ej: 300 123 4567'),
              _buildTextField('Parentesco / Relación', 'Ej: Esposa, Hijo, Empleado...'),
            ],
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vehículo registrado correctamente')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A2540),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('REGISTRAR VEHÍCULO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildInfoBox(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0A2540))),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.blueAccent)),
        ],
      ),
    );
  }
}
