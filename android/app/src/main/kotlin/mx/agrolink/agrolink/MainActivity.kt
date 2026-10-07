package mx.agrolink.agrolink

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Canal de las notificaciones push (Android 8+). Importancia alta: aviso emergente con sonido.
        // Mismo id que el backend (android.notification.channel_id) y que el AndroidManifest.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "agrolink_default",
                "Mensajes y ofertas",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply { description = "Avisos de mensajes nuevos y ofertas" }
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }
}
