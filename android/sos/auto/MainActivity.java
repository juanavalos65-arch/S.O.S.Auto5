package android.sos.auto;

import android.content.Intent;
import android.os.Bundle;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import com.google.android.material.floatingactionbutton.FloatingActionButton;

public class MainActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // Inicialización de la barra de mandos flotante y botones de emergencia
        FloatingActionButton fabDanger = findViewById(R.id.fabDanger);
        FloatingActionButton fabRobo = findViewById(R.id.fabRobo);
        FloatingActionButton fabVarado = findViewById(R.id.fabVarado);
        FloatingActionButton fabAds = findViewById(R.id.fabAds);

        // Botón: Estoy en Peligro (Requiere validación de PIN/Biometría)
        fabDanger.setOnClickListener(v -> {
            triggerEmergencyProtocol("PELIGRO");
        });

        // Botón: Robo de Auto (Requiere validación de PIN/Biometría)
        fabRobo.setOnClickListener(v -> {
            triggerEmergencyProtocol("ROBO");
        });

        // Botón: Estoy Varado (Requiere validación de PIN/Biometría)
        fabVarado.setOnClickListener(v -> {
            triggerEmergencyProtocol("VARADO");
        });

        // Botón: Paute con Nosotros (Acceso a Wompi / Banner publicitario)
        fabAds.setOnClickListener(v -> {
            Toast.makeText(this, "Abriendo pasarela de aliados y publicidad...", Toast.LENGTH_SHORT).show();
            // Aquí puedes lanzar la vista o enlace web de Wompi / pauta
        });
    }

    private void triggerEmergencyProtocol(String emergencyType) {
        // Ventana de cuenta regresiva de 5 segundos con anulación por PIN/Biometría
        Toast.makeText(this, "Activando alerta de " + emergencyType + ". Presione para cancelar con PIN.", Toast.LENGTH_LONG).show();
        // Lógica de temporizador y envío de coordenadas GPS cifradas (E2EE)
    }
}
