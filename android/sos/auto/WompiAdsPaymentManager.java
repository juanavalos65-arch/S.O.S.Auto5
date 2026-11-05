package android.sos.auto;

import android.app.AlertDialog;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.widget.Toast;

public class WompiAdsPaymentManager {

    private final Context context;

    // Datos oficiales proporcionados para pauta y aliados
    private static final String BANCOLOMBIA_ACCOUNT = "31954613201";
    private static final String ACCOUNT_KEY = "71663024";
    private static final String WOMPI_CHECKOUT_URL = "https://checkout.wompi.co/l/VPOS_3Odu3K";

    public WompiAdsPaymentManager(Context context) {
        this.context = context;
    }

    /**
     * Muestra el selector de pago para el plan publicitario (Aliados S.O.S. Auto)
     * distinguiendo si el usuario está en Colombia o en el exterior.
     */
    public void showPaymentOptionsDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        builder.setTitle("📢 Paute con Nosotros - S.O.S. Auto");
        builder.setMessage("Seleccione su ubicación para procesar el pago de su plan publicitario / aliado:");

        // Opción 1: Transferencia directa en Colombia (Bancolombia)
        builder.setPositiveButton("🇨🇴 Desde Colombia (Bancolombia)", (dialog, which) -> {
            showColombiaDirectTransferInfo();
        });

        // Opción 2: Pagos Internacionales (Pasarela Wompi con misma cuenta/llave)
        builder.setNeutralButton("🌍 Desde el Exterior (Wompi)", (dialog, which) -> {
            openWompiInternationalGateway();
        });

        builder.setNegativeButton("Cancelar", (dialog, which) -> dialog.dismiss());
        builder.show();
    }

    /**
     * Muestra los datos de la cuenta Bancolombia para pagos locales en Colombia.
     */
    private void showColombiaDirectTransferInfo() {
        AlertDialog.Builder infoBuilder = new AlertDialog.Builder(context);
        infoBuilder.setTitle("Transferencia Directa - Colombia");
        infoBuilder.setMessage(
            "Para activar su pauta publicitaria o membresía de aliado de forma inmediata:\n\n" +
            "🏦 **Entidad:** Bancolombia\n" +
            "📂 **Tipo:** Cuenta de Ahorros\n" +
            "🔢 **Número:** " + BANCOLOMBIA_ACCOUNT + "\n" +
            "🔑 **Llave / NIT:** " + ACCOUNT_KEY + "\n\n" +
            "Una vez realizada la transferencia, envíe su comprobante a soporte.applay65@gmail.com para habilitar su banner."
        );

        infoBuilder.setPositiveButton("Copiar Datos y Finalizar", (dialog, which) -> {
            // Copiar al portapapeles o notificar
            Toast.makeText(context, "Datos de cuenta listos. ¡Gracias por pautar en S.O.S. Auto!", Toast.LENGTH_LONG).show();
        });

        infoBuilder.show();
    }

    /**
     * Abre la pasarela Wompi oficial para pagos internacionales utilizando el enlace configurado.
     */
    private void openWompiInternationalGateway() {
        try {
            Uri webpage = Uri.parse(WOMPI_CHECKOUT_URL);
            Intent intent = new Intent(Intent.ACTION_VIEW, webpage);
            
            Toast.makeText(context, "Abriendo pasarela Wompi (Cuenta Asociada: " + BANCOLOMBIA_ACCOUNT + ")...", Toast.LENGTH_SHORT).show();
            context.startActivity(intent);
        } catch (Exception e) {
            Toast.makeText(context, "No se pudo abrir el enlace de Wompi. Verifique su conexión a internet.", Toast.LENGTH_LONG).show();
        }
    }
}
