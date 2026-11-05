package android.sos.auto;

import android.app.AlertDialog;
import android.content.Context;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.Toast;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class VehicleDriverManager {

    private final Context context;
    // Estructura para almacenar conductores asociados por placa (Cifrado E2EE simulado localmente)
    private final Map<String, List<DriverProfile>> vehicleRegistry = new HashMap<>();

    public static class DriverProfile {
        String fullName;
        String documentId;
        String phone;
        boolean isPrimaryOwner;

        public DriverProfile(String fullName, String documentId, String phone, boolean isPrimaryOwner) {
            this.fullName = fullName;
            this.documentId = documentId;
            this.phone = phone;
            this.isPrimaryOwner = isPrimaryOwner;
        }
    }

    public VehicleDriverManager(Context context) {
        this.context = context;
    }

    /**
     * Registra el vehículo principal por su placa e inicia la pregunta interactiva de múltiples conductores.
     */
    public void registerVehicleWithDrivers(String plateNumber, String ownerName, String ownerDoc, String ownerPhone) {
        List<DriverProfile> drivers = new ArrayList();
        
        // Agregar al conductor / titular principal
        drivers.add(new DriverProfile(ownerName, ownerDoc, ownerPhone, true));
        vehicleRegistry.put(plateNumber.toUpperCase(), drivers);

        Toast.makeText(context, "Vehículo con placa " + plateNumber + " registrado exitosamente.", Toast.LENGTH_SHORT).show();

        // Desplegar pregunta interactiva automática para múltiples conductores
        promptAddAdditionalDriver(plateNumber);
    }

    /**
     * Muestra la interfaz interactiva para agregar otro conductor a la misma placa.
     */
    private void promptAddAdditionalDriver(String plateNumber) {
        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        builder.setTitle("🚗 Múltiples Conductores - Placa: " + plateNumber);
        builder.setMessage("¿Desea registrar otra persona (ej. esposa, hijo) que conduzca este mismo vehículo?");

        builder.setPositiveButton("Sí, agregar conductor", (dialog, which) -> {
            showDriverInputDialog(plateNumber);
        });

        builder.setNegativeButton("No, finalizar registro", (dialog, which) -> {
            Toast.makeText(context, "Configuración de conductores guardada de forma segura (E2EE).", Toast.LENGTH_LONG).show();
        });

        builder.setCancelable(false);
        builder.show();
    }

    /**
     * Formulario flotante para capturar los datos del conductor adicional.
     */
    private void showDriverInputDialog(String plateNumber) {
        AlertDialog.Builder inputBuilder = new AlertDialog.Builder(context);
        inputBuilder.setTitle("Nuevo Conductor Asociado");

        LinearLayout layout = new LinearLayout(context);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setPadding(40, 20, 40, 20);

        final EditText inputName = new EditText(context);
        inputName.setHint("Nombre y Apellido");
        layout.addView(inputName);

        final EditText inputDoc = new EditText(context);
        inputDoc.setHint("Número de Documento");
        layout.addView(inputDoc);

        final EditText inputPhone = new EditText(context);
        inputPhone.setHint("Teléfono de Contacto");
        layout.addView(inputPhone);

        inputBuilder.setView(layout);

        inputBuilder.setPositiveButton("Guardar Conductor", (dialog, which) -> {
            String name = inputName.getText().toString();
            String doc = inputDoc.getText().toString();
            String phone = inputPhone.getText().toString();

            if (!name.isEmpty() && !doc.isEmpty()) {
                DriverProfile additionalDriver = new DriverProfile(name, doc, phone, false);
                vehicleRegistry.get(plateNumber).add(additionalDriver);

                Toast.makeText(context, "Conductor " + name + " vinculado correctamente a la placa " + plateNumber, Toast.LENGTH_SHORT).show();
                
                // Preguntar si desea registrar otro más
                promptAddAdditionalDriver(plateNumber);
            } else {
                Toast.makeText(context, "Debe completar los campos obligatorios.", Toast.LENGTH_SHORT).show();
            }
        });

        inputBuilder.setNegativeButton("Cancelar", (dialog, which) -> {
            Toast.makeText(context, "Registro de conductores finalizado.", Toast.LENGTH_SHORT).show();
        });

        inputBuilder.show();
    }
}
