package com.freebrowser.free_browser

import android.Manifest
import android.app.DownloadManager
import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val STORAGE_PERMISSION_REQUEST_CODE = 4102
    }

    private val channelName = "com.freebrowser.free_browser/downloads"
    private val allowedVideoUrls = setOf(
        "https://media.w3.org/2010/05/bunny/trailer.mp4",
        "https://media.w3.org/2010/05/sintel/trailer_hd.mp4",
        "https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4"
    )
    private var pendingDownloadResult: MethodChannel.Result? = null
    private var pendingDownloadUrl: String? = null
    private var pendingDownloadTitle: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "downloadVideo") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val url = call.argument<String>("url")
                val title = call.argument<String>("title")
                if (url == null || title == null) {
                    result.error("invalid_arguments", "A video URL and title are required.", null)
                    return@setMethodCallHandler
                }

                try {
                    startVideoDownload(url, title, result)
                } catch (error: IllegalArgumentException) {
                    result.error("invalid_video_url", error.message, null)
                } catch (error: Exception) {
                    result.error("download_failed", error.message, null)
                }
            }
    }

    private fun startVideoDownload(
        url: String,
        title: String,
        result: MethodChannel.Result
    ) {
        require(url in allowedVideoUrls) {
            "Only the app's public sample videos can be downloaded."
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            Build.VERSION.SDK_INT < Build.VERSION_CODES.Q &&
            checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED
        ) {
            if (pendingDownloadResult != null) {
                result.error("download_in_progress", "A download request is already in progress.", null)
                return
            }
            pendingDownloadResult = result
            pendingDownloadUrl = url
            pendingDownloadTitle = title
            requestPermissions(
                arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                STORAGE_PERMISSION_REQUEST_CODE
            )
            return
        }

        result.success(enqueueVideoDownload(url, title))
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != STORAGE_PERMISSION_REQUEST_CODE) return

        val result = pendingDownloadResult ?: return
        val url = pendingDownloadUrl
        val title = pendingDownloadTitle
        pendingDownloadResult = null
        pendingDownloadUrl = null
        pendingDownloadTitle = null

        if (grantResults.firstOrNull() != PackageManager.PERMISSION_GRANTED) {
            result.error("storage_permission_denied", "Storage permission is required to save this video.", null)
            return
        }
        if (url == null || title == null) {
            result.error("invalid_arguments", "A video URL and title are required.", null)
            return
        }

        try {
            result.success(enqueueVideoDownload(url, title))
        } catch (error: Exception) {
            result.error("download_failed", error.message, null)
        }
    }

    private fun enqueueVideoDownload(url: String, title: String): Long {
        val uri = Uri.parse(url)
        require(uri.toString() in allowedVideoUrls) {
            "Only the app's public sample videos can be downloaded."
        }

        val fileName = title
            .replace(Regex("[^A-Za-z0-9._-]+"), "_")
            .trim('_', '.', '-')
            .ifEmpty { "OpenWave_video" } + "-${System.currentTimeMillis()}.mp4"
        val request = DownloadManager.Request(uri)
            .setTitle(title)
            .setDescription("OpenWave video")
            .setMimeType("video/mp4")
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
            .setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, fileName)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            request.setAllowedOverMetered(true)
            request.setAllowedOverRoaming(false)
        }

        val manager = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        return manager.enqueue(request)
    }
}
