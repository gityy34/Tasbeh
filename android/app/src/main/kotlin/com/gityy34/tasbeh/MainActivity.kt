package com.gityy34.tasbeh

import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.pdf.PdfRenderer
import android.net.Uri
import android.os.Build
import android.os.ParcelFileDescriptor
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.OpenableColumns
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.util.TimeZone
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import kotlin.math.roundToInt

class MainActivity : FlutterFragmentActivity() {
    private companion object {
        const val channelName = "com.gityy34.tasbeh/azkar_pdf"
        const val maxPdfBytes = 50L * 1024L * 1024L
    }

    private val executor: ExecutorService = Executors.newSingleThreadExecutor()
    private var pendingPickResult: MethodChannel.Result? = null
    private var pendingCategory: String? = null
    private val openPdfLauncher = registerForActivityResult(
        ActivityResultContracts.OpenDocument(),
    ) { uri ->
        handlePickedPdf(uri)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.gityy34.tasbeh/device",
        ).setMethodCallHandler { call, result ->
            if (call.method == "getTimeZoneId") {
                result.success(TimeZone.getDefault().id)
            } else {
                result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.gityy34.tasbeh/haptics",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "targetCompleted" -> {
                    vibrateForTargetCompletion()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickPdf" -> pickPdf(call, result)
                "renderPage" -> renderPage(call, result)
                "deletePdf" -> deletePdf(call, result)
                else -> result.notImplemented()
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun vibrateForTargetCompletion() {
        val vibrator: Vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            getSystemService(VibratorManager::class.java).defaultVibrator
        } else {
            getSystemService(Vibrator::class.java)
        }
        if (!vibrator.hasVibrator()) return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(
                VibrationEffect.createOneShot(
                    120L,
                    VibrationEffect.DEFAULT_AMPLITUDE,
                ),
            )
        } else {
            vibrator.vibrate(120L)
        }
    }

    private fun pickPdf(call: MethodCall, result: MethodChannel.Result) {
        val category = call.argument<String>("category")
        if (category != "morning-evening" && category != "daily") {
            result.error("INVALID_CATEGORY", "Unsupported Azkar category", null)
            return
        }
        if (pendingPickResult != null) {
            result.error("PICKER_BUSY", "A PDF picker is already open", null)
            return
        }
        pendingPickResult = result
        pendingCategory = category
        try {
            openPdfLauncher.launch(arrayOf("application/pdf"))
        } catch (error: Exception) {
            pendingPickResult = null
            pendingCategory = null
            result.error("PICKER_UNAVAILABLE", error.message, null)
        }
    }

    private fun handlePickedPdf(uri: Uri?) {
        val result = pendingPickResult
        val category = pendingCategory
        pendingPickResult = null
        pendingCategory = null
        if (result == null) return
        if (uri == null || category == null) {
            result.success(null)
            return
        }

        try {
            contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION,
            )
        } catch (_: SecurityException) {
            // The copy below still works for providers that do not offer
            // persistable grants; the app only needs its private copy.
        }

        executor.execute {
            try {
                val copied = copyPdfIntoPrivateStorage(uri, category)
                runOnUiThread { result.success(copied) }
            } catch (error: Exception) {
                runOnUiThread {
                    result.error("PDF_COPY_FAILED", error.message, null)
                }
            }
        }
    }

    private fun copyPdfIntoPrivateStorage(uri: Uri, category: String): Map<String, Any> {
        val directory = File(filesDir, "azkar_documents").apply { mkdirs() }
        val destination = File(directory, "$category.pdf")
        val temporary = File(directory, "$category.pdf.tmp")
        try {
            var totalBytes = 0L
            contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(temporary).use { output ->
                    val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                    while (true) {
                        val count = input.read(buffer)
                        if (count <= 0) break
                        totalBytes += count
                        if (totalBytes > maxPdfBytes) {
                            throw IllegalArgumentException("PDF is larger than 50 MB")
                        }
                        output.write(buffer, 0, count)
                    }
                }
            } ?: throw IllegalArgumentException("The selected file could not be read")

            // Validate before replacing the previous good document.
            val pageCount = getPageCount(temporary)
            if (!temporary.renameTo(destination)) {
                temporary.copyTo(destination, overwrite = true)
                temporary.delete()
            }
            return mapOf(
                "path" to destination.absolutePath,
                "displayName" to displayName(uri),
                "pageCount" to pageCount,
            )
        } catch (error: Exception) {
            temporary.delete()
            throw error
        }
    }

    private fun displayName(uri: Uri): String {
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (index >= 0) return cursor.getString(index)
                }
            }
        return "Azkar PDF"
    }

    private fun renderPage(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path")
        val pageIndex = call.argument<Int>("pageIndex")
        val maxWidth = call.argument<Int>("maxWidth")
        if (path == null || pageIndex == null || maxWidth == null || maxWidth <= 0) {
            result.error("INVALID_PAGE", "Missing PDF page arguments", null)
            return
        }
        executor.execute {
            try {
                val bytes = renderPdfPage(path, pageIndex, maxWidth)
                runOnUiThread { result.success(bytes) }
            } catch (error: Exception) {
                runOnUiThread {
                    result.error("PDF_RENDER_FAILED", error.message, null)
                }
            }
        }
    }

    private fun renderPdfPage(path: String, pageIndex: Int, maxWidth: Int): ByteArray {
        val file = privatePdfFile(path)
        ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY).use { descriptor ->
            PdfRenderer(descriptor).use { renderer ->
                require(pageIndex in 0 until renderer.pageCount) { "Invalid PDF page" }
                renderer.openPage(pageIndex).use { page ->
                    val scale = maxWidth.toFloat() / page.width.toFloat()
                    val width = (page.width * scale).roundToInt().coerceAtLeast(1)
                    val height = (page.height * scale).roundToInt().coerceAtLeast(1)
                    val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                    Canvas(bitmap).drawColor(Color.WHITE)
                    val matrix = Matrix().apply { setScale(scale, scale) }
                    page.render(
                        bitmap,
                        null,
                        matrix,
                        PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY,
                    )
                    return ByteArrayOutputStream().use { output ->
                        bitmap.compress(Bitmap.CompressFormat.PNG, 100, output)
                        bitmap.recycle()
                        output.toByteArray()
                    }
                }
            }
        }
    }

    private fun getPageCount(file: File): Int {
        ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY).use { descriptor ->
            PdfRenderer(descriptor).use { renderer -> return renderer.pageCount }
        }
    }

    private fun privatePdfFile(path: String): File {
        val directory = File(filesDir, "azkar_documents").canonicalFile
        val file = File(path).canonicalFile
        require(file.parentFile == directory) { "PDF path is outside app storage" }
        require(file.isFile) { "PDF no longer exists" }
        return file
    }

    private fun deletePdf(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path")
        if (path == null) {
            result.error("INVALID_PATH", "Missing PDF path", null)
            return
        }
        try {
            privatePdfFile(path).delete()
            result.success(null)
        } catch (error: Exception) {
            result.error("PDF_DELETE_FAILED", error.message, null)
        }
    }

    override fun onDestroy() {
        pendingPickResult?.success(null)
        pendingPickResult = null
        pendingCategory = null
        executor.shutdownNow()
        super.onDestroy()
    }
}

