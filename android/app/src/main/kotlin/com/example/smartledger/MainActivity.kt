package com.example.smartledger

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import com.example.smartledger.BuildConfig
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    companion object {
        private const val APP_ICON_CHANNEL = "smart_ledger/app_icon"
        private const val DEEP_LINK_CHANNEL = "com.example.smartledger/deeplink"
        private const val ICON_THEME_AUTO = "auto"
        private const val ICON_THEME_LIGHT = "light"
        private const val ICON_THEME_DARK = "dark"
        private const val ICON_THEME_LIGHT_INTENSE = "light_intense"
        private const val ICON_THEME_DARK_INTENSE = "dark_intense"
    }

    private var deepLinkChannel: MethodChannel? = null
    private var initialDeepLink: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Deep Link Channel for App Actions / Bixby / Voice Assistants
        deepLinkChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DEEP_LINK_CHANNEL
        ).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialLink" -> {
                        result.success(initialDeepLink)
                        initialDeepLink = null // Clear after consumed
                    }
                    else -> result.notImplemented()
                }
            }
        }

        // Process initial intent
        handleIntent(intent)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_ICON_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAppIconPngBytes" -> {
                        try {
                            val drawable = packageManager.getApplicationIcon(packageName)
                            val bitmap = drawableToBitmap(drawable)
                            val out = ByteArrayOutputStream()
                            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
                            result.success(out.toByteArray())
                        } catch (e: Exception) {
                            result.error("APP_ICON_ERROR", e.message, null)
                        }
                    }
                    "setLauncherIconTheme" -> {
                        try {
                            val theme = call.argument<String>("theme")?.trim()?.lowercase()
                                ?: call.argument<String>("id")?.trim()?.lowercase()
                                ?: call.arguments as? String
                                ?: ICON_THEME_AUTO

                            setLauncherIconTheme(theme)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("APP_ICON_THEME_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun setLauncherIconTheme(theme: String) {
        val aliasMap = mapOf(
            ICON_THEME_AUTO to "$packageName.MainActivityAliasAuto",
            ICON_THEME_LIGHT to "$packageName.MainActivityAliasLight",
            ICON_THEME_DARK to "$packageName.MainActivityAliasDark",
            ICON_THEME_LIGHT_INTENSE to "$packageName.MainActivityAliasLightIntense",
            ICON_THEME_DARK_INTENSE to "$packageName.MainActivityAliasDarkIntense",
        )

        val aliasToEnable = aliasMap[theme] ?: aliasMap[ICON_THEME_AUTO]

        aliasMap.values.forEach { aliasName ->
            val desiredState = if (aliasName == aliasToEnable) {
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            } else {
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            }

            setComponentState(ComponentName(this, aliasName), desiredState)
        }

        // MainActivity MUST always be ENABLED because it is the targetActivity for all aliases.
        // If we disable it, the aliases will also stop working, leading to the "App Info" screen.
        setComponentState(
            ComponentName(this, "$packageName.MainActivity"),
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED
        )
    }

    private fun setComponentState(component: ComponentName, desiredState: Int) {
        if (packageManager.getComponentEnabledSetting(component) == desiredState) return

        packageManager.setComponentEnabledSetting(
            component,
            desiredState,
            PackageManager.DONT_KILL_APP
        )
    }

    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        if (drawable is BitmapDrawable) {
            val bmp = drawable.bitmap
            if (bmp != null) return bmp
        }

        val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 128
        val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 128
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Deep Link Handling (App Actions / Bixby / Voice Assistants)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return

        val uri: Uri? = intent.data
        if (uri != null && uri.scheme == "smartledger") {
            val uriString = uri.toString()

            // If Flutter engine is ready, send immediately
            if (deepLinkChannel != null) {
                deepLinkChannel?.invokeMethod("onDeepLink", uriString)
            } else {
                // Store for later retrieval via getInitialLink
                initialDeepLink = uriString
            }
        }
    }
}
