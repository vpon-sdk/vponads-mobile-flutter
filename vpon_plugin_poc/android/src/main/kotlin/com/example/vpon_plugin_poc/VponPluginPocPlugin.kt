package com.example.vpon_plugin_poc

import android.app.Activity
import android.content.Context
import android.util.Log
import com.vpon.ads.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** VponPluginPocPlugin */
class VponPluginPocPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var activity : Activity
  private lateinit var channel : MethodChannel

  private var pluginBinding: FlutterPlugin.FlutterPluginBinding? = null

  //TODO when is onAttachedToActivity called?
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
  }

  override fun onDetachedFromActivity() {
  }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "vpon_plugin_poc")
    channel.setMethodCallHandler(this)
    pluginBinding = flutterPluginBinding
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    // Use activity as context if available.
    val context: Context? =
      activity ?: pluginBinding?.getApplicationContext()

    if (context == null) {
      Log.e(
        "FlutterPlugin",
        "method call, but context null " + call.method
      )
      return
    }

    when (call.method) {
      "loadInterstitialAd" -> {
        //TODO change
        val vponInterstitialAd = VponInterstitialAd(context, "8a80854b75ab2b0101761cfb968d71c7")

        val builder: VponAdRequest.Builder = VponAdRequest.Builder()
        builder.addTestDevice("your device advertising id")
        // Set your test device's GAID here if you're trying to get Vpon test ad
        vponInterstitialAd.loadAd(builder.build())

        vponInterstitialAd.setAdListener(object : VponAdListener() {
          override fun onAdLoaded() {
            // Invoked if receive Interstitial Ad successfully
            if (vponInterstitialAd.isReady()) {
              // Show Interstitial Ad
              vponInterstitialAd.show()
            }
          }

          override fun onAdFailedToLoad(errorCode: Int) {
            // Invoked if received ad fail, check this callback to indicates what type of failure occurred
          }

          override fun onAdOpened() {
            // Invoked if the Interstitial Ad was clicked
          }

          override fun onAdLeftApplication() {
            // Invoked if user leave the app and the current app was backgrounded
          }

          override fun onAdClosed() {
            // Invoked if the Interstitial Ad was closed
//                    vponInterstitialAd.loadAd(Builder().build())
            // Load next ad if needed
          }
        })

        result.success(null)
      }


      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }

      else -> {
        result.notImplemented()
      }
    }



  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
