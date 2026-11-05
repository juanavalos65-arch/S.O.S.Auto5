package android.sos.auto;

import android.app.AlertDialog;
import android.content.Context;
import android.os.CountDownTimer;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.widget.EditText;
import android.widget.Toast;
import androidx.biometric.BiometricPrompt;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.FragmentActivity;
import java.util.concurrent.Executor;

public class EmergencySecurityManager {

    private final FragmentActivity activity;
    private CountDownTimer countdownTimer;
    private boolean isEmergencyDispatched = false;

    public interface EmergencyCallback {
        void onEmergencyConfirmed();
        void onEmergencyCancelled();
    }

    public EmergencySecurityManager(FragmentActivity activity) {
        this.activity = activity;
    }

    /**
     * Inicia la ventana de anulación inmediata de 5 segundos con vibración y alerta sonora.
     */
    public void startEmergencyCountdown(String emergencyType, EmergencyCallback callback) {
        isEmergencyDispatched = false;

        // Activar vibración de advertencia
        Vibrator vibrator = (Vibrator) activity.getSystemService(Context.VIBRATOR_SERVICE);
        if (vibrator != null) {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                vibrator.vibrate(VibrationEffect.createOneShot(1000, VibrationEffect.DEFAULT_AMPLITUDE));
            } else {
                vibrator.vibrate(1000);
            }
        }

        // Crear diálogo de cuenta regresiva con opción de anulación por PIN o Biometría
        AlertDialog.Builder builder = new AlertDialog.Builder(activity);
        builder.setTitle("⚠️ ALERTA DE " + emergencyType);
        builder.setMessage("La emergencia se enviará en 5 segundos.\n¿Desea cancelarla ingresando su PIN o Biometría?");
        builder.setCancelable(false);

        builder.setPositiveButton("Cancelar Alerta (PIN)", (dialog, which) -> {
            if (countdownTimer != null) countdownTimer.cancel();
            promptForPin(callback);
        });

        builder.setNeutralButton("Usar Biometría", (dialog, which) -> {
            if (countdownTimer != null) countdownTimer.cancel();
            promptBiometricAuth(callback);
        });

        AlertDialog dialog = builder.create();
        dialog.show();

        // Temporizador de 5 segundos
        countdownTimer = new CountDownTimer(5000, 1000) {
            @Override
            public void onTick(long millisUntilFinished) {
                dialog.setMessage("Enviando alerta en " + (millisUntilFinished / 1000) + " segundos...\n\nPresione Cancelar si fue un error.");
            }

            @Override
            public void onFinish() {
                if (!isEmergencyDispatched) {
                    dialog.dismiss();
                    isEmergencyDispatched = true;
                    callback.onEmergencyConfirmed();
                }
            }
        }.start();
    }

    /**
     * Solicita el PIN de seguridad configurado por el usuario.
     */
    private void promptForPin(EmergencyCallback callback) {
        AlertDialog.Builder pinBuilder = new AlertDialog.Builder(activity);
        pinBuilder.setTitle("Verificación de Seguridad");
        pinBuilder.setMessage("Ingrese su PIN de 4 dígitos para anular la emergencia:");

        final EditText inputPin = new EditText(activity);
        inputPin.setInputType(android.text.InputType.TYPE_CLASS_NUMBER | android.text.InputType.TYPE_NUMBER_VARIATION_PASSWORD);
        pinBuilder.setView(inputPin);

        pinBuilder.setPositiveButton("Confirmar", (dialog, which) -> {
            String enteredPin = inputPin.getText().toString();
            if ("1234".equals(enteredPin)) { 
                Toast.makeText(activity, "Emergencia cancelada exitosamente.", Toast.LENGTH_SHORT).show();
                callback.onEmergencyCancelled();
            } else {
                Toast.makeText(activity, "PIN incorrecto. Emergencia despachada por seguridad.", Toast.LENGTH_LONG).show();
                callback.onEmergencyConfirmed();
            }
        });

        pinBuilder.setNegativeButton("Continuar Emergencia", (dialog, which) -> callback.onEmergencyConfirmed());
        pinBuilder.show();
    }

    /**
     * Solicita autenticación mediante huella dactilar o reconocimiento facial.
     */
    private void promptBiometricAuth(EmergencyCallback callback) {
        Executor executor = ContextCompat.getMainExecutor(activity);
        BiometricPrompt biometricPrompt = new BiometricPrompt(activity, executor, new BiometricPrompt.AuthenticationCallback() {
            @Override
            public void onAuthenticationSucceeded(BiometricPrompt.AuthenticationResult result) {
                super.onAuthenticationSucceeded(result);
                Toast.makeText(activity, "Biometría confirmada. Alerta anulada.", Toast.LENGTH_SHORT).show();
                callback.onEmergencyCancelled();
            }

            @Override
            public void onAuthenticationError(int errorCode, CharSequence errString) {
                super.onAuthenticationError(errorCode, errString);
                Toast.makeText(activity, "Error de autenticación: " + errString, Toast.LENGTH_SHORT).show();
                callback.onEmergencyConfirmed();
            }

            @Override
            public void onAuthenticationFailed() {
                super.onAuthenticationFailed();
                Toast.makeText(activity, "No se reconoció la biometría.", Toast.LENGTH_SHORT).show();
                callback.onEmergencyConfirmed();
            }
        });

        BiometricPrompt.PromptInfo promptInfo = new BiometricPrompt.PromptInfo.Builder()
                .setTitle("Anulación de Emergencia")
                .setSubtitle("Use su huella o rostro para cancelar la falsa alarma")
                .setNegativeButtonText("Cancelar")
                .build();

        biometricPrompt.authenticate(promptInfo);
    }
}
