package com.example.readers_hub

import android.app.DownloadManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Environment
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.readers_hub/download"
    private var downloadManager: DownloadManager? = null
    private var methodChannel: MethodChannel? = null

    private val downloadReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val id = intent?.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, -1L) ?: -1L
            if (id != -1L) {
                notifyDownloadStatus(id)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        downloadManager = getSystemService(Context.DOWNLOAD_SERVICE) as? DownloadManager
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestNotificationPermission" -> {
                    requestNotificationPermission()
                    result.success(true)
                }
                "enqueueDownload" -> {
                    val url = call.argument<String>("url")
                    val title = call.argument<String>("title") ?: "Book Download"
                    val filename = call.argument<String>("filename") ?: "book.epub"
                    val mimeType = call.argument<String>("mimeType") ?: "application/epub+zip"

                    if (url.isNullOrEmpty()) {
                        result.error("INVALID_URL", "Download URL is empty", null)
                        return@setMethodCallHandler
                    }

                    try {
                        requestNotificationPermission()
                        val downloadId = startDownload(url, title, filename, mimeType)
                        result.success(downloadId)
                    } catch (e: Exception) {
                        result.error("ENQUEUE_FAILED", e.localizedMessage, null)
                    }
                }
                "getDownloadProgress" -> {
                    val downloadId = (call.argument<Number>("downloadId"))?.toLong()
                    if (downloadId == null) {
                        result.error("INVALID_ID", "Download ID is null", null)
                        return@setMethodCallHandler
                    }
                    val progressMap = queryDownload(downloadId)
                    result.success(progressMap)
                }
                "cancelDownload" -> {
                    val downloadId = (call.argument<Number>("downloadId"))?.toLong()
                    if (downloadId != null) {
                        downloadManager?.remove(downloadId)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "openDownloadedFile" -> {
                    val downloadId = (call.argument<Number>("downloadId"))?.toLong()
                    val localUriStr = call.argument<String>("uri")
                    val mimeType = call.argument<String>("mimeType") ?: "*/*"
                    val opened = openFile(downloadId, localUriStr, mimeType)
                    result.success(opened)
                }
                else -> result.notImplemented()
            }
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(
                    downloadReceiver,
                    IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE),
                    Context.RECEIVER_EXPORTED
                )
            } else {
                registerReceiver(
                    downloadReceiver,
                    IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE)
                )
            }
        } catch (_: Exception) {}
    }

    override fun onDestroy() {
        try {
            unregisterReceiver(downloadReceiver)
        } catch (_: Exception) {}
        super.onDestroy()
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS)
                != PackageManager.PERMISSION_GRANTED) {
                requestPermissions(
                    arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                    1001
                )
            }
        }
    }

    private fun startDownload(url: String, title: String, filename: String, mimeType: String): Long {
        val dm = downloadManager ?: throw IllegalStateException("DownloadManager not available")
        val uri = Uri.parse(url)

        val request = DownloadManager.Request(uri).apply {
            setTitle(title)
            setDescription("Downloading $title • LiRead")
            setMimeType(mimeType)
            setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
            setAllowedOverMetered(true)
            setAllowedOverRoaming(true)
            setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, "Liread_Books/$filename")
            addRequestHeader("User-Agent", "LireadMobile/1.0 (contact: liread@app.local)")
        }

        return dm.enqueue(request)
    }

    private fun queryDownload(downloadId: Long): Map<String, Any?> {
        val dm = downloadManager ?: return mapOf("status" to "error", "message" to "No manager")
        val query = DownloadManager.Query().setFilterById(downloadId)
        var cursor: Cursor? = null

        try {
            cursor = dm.query(query)
            if (cursor != null && cursor.moveToFirst()) {
                val statusIndex = cursor.getColumnIndex(DownloadManager.COLUMN_STATUS)
                val status = if (statusIndex != -1) cursor.getInt(statusIndex) else -1

                val downloadedIndex = cursor.getColumnIndex(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR)
                val downloadedBytes = if (downloadedIndex != -1) cursor.getLong(downloadedIndex) else 0L

                val totalIndex = cursor.getColumnIndex(DownloadManager.COLUMN_TOTAL_SIZE_BYTES)
                val totalBytes = if (totalIndex != -1) cursor.getLong(totalIndex) else -1L

                val uriIndex = cursor.getColumnIndex(DownloadManager.COLUMN_LOCAL_URI)
                val localUri = if (uriIndex != -1) cursor.getString(uriIndex) else null

                val reasonIndex = cursor.getColumnIndex(DownloadManager.COLUMN_REASON)
                val reason = if (reasonIndex != -1) cursor.getInt(reasonIndex) else 0

                val statusStr = when (status) {
                    DownloadManager.STATUS_RUNNING -> "running"
                    DownloadManager.STATUS_SUCCESSFUL -> "completed"
                    DownloadManager.STATUS_FAILED -> "failed"
                    DownloadManager.STATUS_PENDING -> "pending"
                    DownloadManager.STATUS_PAUSED -> "paused"
                    else -> "unknown"
                }

                val progress = if (totalBytes > 0) {
                    (downloadedBytes.toDouble() / totalBytes.toDouble()).coerceIn(0.0, 1.0)
                } else {
                    -1.0
                }

                return mapOf(
                    "status" to statusStr,
                    "downloadedBytes" to downloadedBytes,
                    "totalBytes" to totalBytes,
                    "progress" to progress,
                    "localUri" to localUri,
                    "reason" to reason
                )
            }
        } catch (e: Exception) {
            return mapOf("status" to "error", "message" to e.localizedMessage)
        } finally {
            cursor?.close()
        }

        return mapOf("status" to "notFound")
    }

    private fun notifyDownloadStatus(downloadId: Long) {
        val info = queryDownload(downloadId)
        runOnUiThread {
            methodChannel?.invokeMethod("onDownloadStatusUpdate", mapOf(
                "downloadId" to downloadId,
                "info" to info
            ))
        }
    }

    private fun openFile(downloadId: Long?, uriStr: String?, mimeType: String): Boolean {
        val dm = downloadManager
        var targetUri: Uri? = null

        if (downloadId != null && dm != null) {
            try {
                targetUri = dm.getUriForDownloadedFile(downloadId)
            } catch (_: Exception) {}
        }

        if (targetUri == null && !uriStr.isNullOrEmpty()) {
            targetUri = Uri.parse(uriStr)
        }

        if (targetUri == null) return false

        return try {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(targetUri, mimeType)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            true
        } catch (e: Exception) {
            try {
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(targetUri, "*/*")
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(intent)
                true
            } catch (e2: Exception) {
                false
            }
        }
    }
}
