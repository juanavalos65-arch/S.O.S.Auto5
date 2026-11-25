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

    // 1. GUARDA INMEDIATAMENTE EN EL TELÉFONO (SIN ESPERAR RED)
    final prefs = await SharedPreferences.getInstance();
    await _persistToAllLocalKeys(prefs, registrationData);

    // 2. SINCRONIZA EN FIRESTORE EN SEGUNDO PLANO (NO BLOQUEA)
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
      } catch (_) {
        // Si no hay conexión, queda guardado localmente y activo para emergencias
      }
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
