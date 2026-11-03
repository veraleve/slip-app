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
import android.media.MediaRecorder
import android.media.MediaPlayer

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.veraleve.slip/native"
    private val NOTIFICATION_CHANNEL_ID = "slip_blunders"
    private val PERMISSION_REQUEST_CODE = 1001
    private val CAMERA_REQUEST_CODE = 1002
    private val AUDIO_PERMISSION_REQUEST_CODE = 1003

    private var pendingPermissionResult: MethodChannel.Result? = null
    private var pendingCameraResult: MethodChannel.Result? = null
    private var cameraPhotoFile: File? = null

    // Native Audio Engine
    private var mediaRecorder: MediaRecorder? = null
    private var mediaPlayer: MediaPlayer? = null
    private var currentAudioRecordingFile: File? = null

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
                "startAudioRecording" -> {
                    if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
                        ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.RECORD_AUDIO), AUDIO_PERMISSION_REQUEST_CODE)
                        result.success(false)
                    } else {
                        val success = startRecordingAudio()
                        result.success(success)
                    }
                }
                "stopAudioRecording" -> {
                    val path = stopRecordingAudio()
                    result.success(path)
                }
                "playAudio" -> {
                    val path = call.argument<String>("path")
                    val success = playAudioFile(path)
                    result.success(success)
                }
                "stopAudio" -> {
                    stopPlayingAudio()
                    result.success(true)
                }
                "isAudioPlaying" -> {
                    result.success(mediaPlayer?.isPlaying == true)
                }
                "getAppCacheDir" -> {
                    result.success(cacheDir.absolutePath)
                }
                "canRequestPackageInstalls" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        result.success(packageManager.canRequestPackageInstalls())
                    } else {
                        result.success(true)
                    }
                }
                "openInstallUnknownAppsSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val intent = Intent(android.provider.Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                            data = android.net.Uri.parse("package:$packageName")
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(true)
                    } else {
                        result.success(true)
                    }
                }
                "installApk" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath.isNullOrBlank()) {
                        result.error("INVALID_PATH", "APK path is empty", null)
                    } else {
                        val file = File(filePath)
                        if (!file.exists()) {
                            result.error("FILE_NOT_FOUND", "APK file does not exist at $filePath", null)
                        } else {
                            try {
                                val contentUri = androidx.core.content.FileProvider.getUriForFile(
                                    this,
                                    "${applicationContext.packageName}.fileprovider",
                                    file
                                )
                                val intent = Intent(Intent.ACTION_VIEW).apply {
                                    setDataAndType(contentUri, "application/vnd.android.package-archive")
                                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
                                }
                                startActivity(intent)
                                result.success(true)
                            } catch (e: Exception) {
                                result.error("INSTALL_ERROR", e.localizedMessage, null)
                            }
                        }
                    }
                }
                "openUrl" -> {
                    val url = call.argument<String>("url")
                    if (!url.isNullOrBlank()) {
                        try {
                            val intent = Intent(Intent.ACTION_VIEW, android.net.Uri.parse(url)).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("OPEN_URL_ERROR", e.localizedMessage, null)
                        }
                    } else {
                        result.success(false)
                    }
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
        val hasMic = ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
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
            "mic" to hasMic,
            "notifications" to hasNotifications,
            "bluetooth" to hasBluetooth
        )
    }

    private fun requestAppPermissions() {
        val permissions = mutableListOf<String>()

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            permissions.add(Manifest.permission.CAMERA)
        }

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            permissions.add(Manifest.permission.RECORD_AUDIO)
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

        try {
            val photoFile = File(cacheDir, "slip_scratchpad_${System.currentTimeMillis()}.jpg")
            cameraPhotoFile = photoFile
            val photoURI = androidx.core.content.FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.fileprovider",
                photoFile
            )

            val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
                putExtra(MediaStore.EXTRA_OUTPUT, photoURI)
                addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }

            if (intent.resolveActivity(packageManager) != null) {
                startActivityForResult(intent, CAMERA_REQUEST_CODE)
            } else {
                pendingCameraResult?.error("NO_CAMERA", "No camera application found on device", null)
                pendingCameraResult = null
            }
        } catch (e: Exception) {
            pendingCameraResult?.error("CAMERA_ERROR", e.localizedMessage, null)
            pendingCameraResult = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == CAMERA_REQUEST_CODE) {
            if (resultCode == RESULT_OK) {
                val file = cameraPhotoFile
                if (file != null && file.exists() && file.length() > 0) {
                    try {
                        // Gentle compression: scale only if gigantic (above 2048px), preserving full handwriting and formula readability
                        val options = android.graphics.BitmapFactory.Options().apply {
                            inJustDecodeBounds = true
                        }
                        android.graphics.BitmapFactory.decodeFile(file.absolutePath, options)

                        var sampleSize = 1
                        val maxDim = 2048 // Full HD+ ensures formulas, superscripts and subscript letters are crisp
                        while (options.outWidth / sampleSize > maxDim || options.outHeight / sampleSize > maxDim) {
                            sampleSize *= 2
                        }

                        val decodeOptions = android.graphics.BitmapFactory.Options().apply {
                            inSampleSize = sampleSize
                        }
                        val fullBitmap = android.graphics.BitmapFactory.decodeFile(file.absolutePath, decodeOptions)
                        if (fullBitmap != null) {
                            val out = FileOutputStream(file)
                            // 92% quality preserves every letter and equation cleanly without artifacting
                            fullBitmap.compress(Bitmap.CompressFormat.JPEG, 92, out)
                            out.flush()
                            out.close()
                        }
                        pendingCameraResult?.success(file.absolutePath)
                    } catch (_: Exception) {
                        pendingCameraResult?.success(file.absolutePath)
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

    private fun startRecordingAudio(): Boolean {
        return try {
            val audioDir = File(cacheDir, "audio_notes").apply { mkdirs() }
            val audioFile = File(audioDir, "audio_${System.currentTimeMillis()}.m4a")
            currentAudioRecordingFile = audioFile

            mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(this)
            } else {
                @Suppress("DEPRECATION")
                MediaRecorder()
            }.apply {
                setAudioSource(MediaRecorder.AudioSource.MIC)
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                setAudioEncodingBitRate(64000)
                setAudioSamplingRate(44100)
                setOutputFile(audioFile.absolutePath)
                prepare()
                start()
            }
            true
        } catch (_: Exception) {
            mediaRecorder?.release()
            mediaRecorder = null
            false
        }
    }

    private fun stopRecordingAudio(): String? {
        return try {
            mediaRecorder?.stop()
            mediaRecorder?.release()
            mediaRecorder = null
            currentAudioRecordingFile?.absolutePath
        } catch (_: Exception) {
            mediaRecorder?.release()
            mediaRecorder = null
            null
        }
    }

    private fun playAudioFile(path: String?): Boolean {
        if (path.isNullOrBlank()) return false

        return try {
            mediaPlayer?.stop()
            mediaPlayer?.release()
            mediaPlayer = MediaPlayer().apply {
                if (path.startsWith("http://") || path.startsWith("https://")) {
                    setDataSource(path)
                } else {
                    val file = File(path)
                    if (!file.exists()) return false
                    setDataSource(file.absolutePath)
                }
                prepare()
                start()
                setOnCompletionListener {
                    it.release()
                    mediaPlayer = null
                }
            }
            true
        } catch (_: Exception) {
            mediaPlayer?.release()
            mediaPlayer = null
            false
        }
    }

    private fun stopPlayingAudio() {
        try {
            mediaPlayer?.stop()
            mediaPlayer?.release()
        } catch (_: Exception) {}
        mediaPlayer = null
    }
}
