package com.veraleve.slip

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.os.Build
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.veraleve.slip/native"
    private val NOTIFICATION_CHANNEL_ID = "slip_blunders"
    private val PERMISSION_REQUEST_CODE = 1001
    private val CAMERA_REQUEST_CODE = 1002

    private var pendingPermissionResult: MethodChannel.Result? = null
    private var pendingCameraResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        createNotificationChannel()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermissions" -> {
                    pendingPermissionResult = result
                    requestAppPermissions()
                }
                "checkPermissions" -> {
                    result.success(checkCurrentPermissions())
                }
                "showNotification" -> {
                    val title = call.argument<String>("title") ?: "Slip Inoculation"
                    val body = call.argument<String>("body") ?: "A new exam blunder has been logged."
                    val id = call.argument<Int>("id") ?: 101
                    showNativeNotification(title, body, id)
                    result.success(true)
                }
                "openCamera" -> {
                    pendingCameraResult = result
                    launchCameraIntent()
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Slip Blunder Alerts"
            val descriptionText = "Daily mistake inoculation reminders and campus peer blunder alerts."
            val importance = NotificationManager.IMPORTANCE_DEFAULT
            val channel = NotificationChannel(NOTIFICATION_CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun checkCurrentPermissions(): Map<String, Boolean> {
        val hasCamera = ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
        val hasNotifications = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
        val hasBluetooth = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED
        } else {
            ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH) == PackageManager.PERMISSION_GRANTED
        }

        return mapOf(
            "camera" to hasCamera,
            "notifications" to hasNotifications,
            "bluetooth" to hasBluetooth
        )
    }

    private fun requestAppPermissions() {
        val permissions = mutableListOf<String>()

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            permissions.add(Manifest.permission.CAMERA)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                permissions.add(Manifest.permission.POST_NOTIFICATIONS)
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN) != PackageManager.PERMISSION_GRANTED) {
                permissions.add(Manifest.permission.BLUETOOTH_SCAN)
            }
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
                permissions.add(Manifest.permission.BLUETOOTH_CONNECT)
            }
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_ADVERTISE) != PackageManager.PERMISSION_GRANTED) {
                permissions.add(Manifest.permission.BLUETOOTH_ADVERTISE)
            }
        }

        if (permissions.isEmpty()) {
            pendingPermissionResult?.success(checkCurrentPermissions())
            pendingPermissionResult = null
        } else {
            ActivityCompat.requestPermissions(this, permissions.toTypedArray(), PERMISSION_REQUEST_CODE)
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            pendingPermissionResult?.success(checkCurrentPermissions())
            pendingPermissionResult = null
        }
    }

    private fun showNativeNotification(title: String, body: String, id: Int) {
        val builder = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.stat_notify_chat)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)

        try {
            with(NotificationManagerCompat.from(this)) {
                if (ActivityCompat.checkSelfPermission(this@MainActivity, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED ||
                    Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                    notify(id, builder.build())
                }
            }
        } catch (_: Exception) {}
    }

    private fun launchCameraIntent() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.CAMERA), CAMERA_REQUEST_CODE)
            return
        }

        val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
        if (intent.resolveActivity(packageManager) != null) {
            startActivityForResult(intent, CAMERA_REQUEST_CODE)
        } else {
            pendingCameraResult?.error("NO_CAMERA", "No camera application found on device", null)
            pendingCameraResult = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == CAMERA_REQUEST_CODE) {
            if (resultCode == RESULT_OK && data != null) {
                val bitmap = data.extras?.get("data") as? Bitmap
                if (bitmap != null) {
                    try {
                        val file = File(cacheDir, "slip_blunder_${System.currentTimeMillis()}.jpg")
                        val out = FileOutputStream(file)
                        bitmap.compress(Bitmap.CompressFormat.JPEG, 90, out)
                        out.flush()
                        out.close()
                        pendingCameraResult?.success(file.absolutePath)
                    } catch (e: Exception) {
                        pendingCameraResult?.error("SAVE_FAILED", e.localizedMessage, null)
                    }
                } else {
                    pendingCameraResult?.success(null)
                }
            } else {
                pendingCameraResult?.success(null)
            }
            pendingCameraResult = null
        }
    }
}
