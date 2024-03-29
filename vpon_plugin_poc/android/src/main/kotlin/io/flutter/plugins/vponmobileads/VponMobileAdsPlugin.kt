package io.flutter.plugins.vponmobileads

import android.content.Context
import android.util.Log
import com.vpon.ads.VponAdRequest
import com.vpon.ads.VponMobileAds
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.StandardMethodCodec

/**
 * VponMobileAdsPlugin
 */
class VponMobileAdsPlugin : FlutterPlugin {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private var channel: MethodChannel? = null

    internal class PluginMethodCallHandler(
        context: Context,
        adInstanceManager: VponAdInstanceManager
    ) : MethodCallHandler {
        private val context: Context
        private val adInstanceManager: VponAdInstanceManager

        init {
            this.context = context
            this.adInstanceManager = adInstanceManager
        }

        override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
            Log.e(TAG, "onMethodCall:" + call.method)
            val method = call.method

            when (method) {
                "getPlatformVersion" -> {
                    result.success("Android ${android.os.Build.VERSION.RELEASE}")
                }

                Utils.getVersionString -> result.success(VponAdRequest.VERSION)
                Utils.getVponID -> result.success(VponMobileAds.getVponID(context))
                Utils.setConsentStatus -> result.success(null)
                Utils.loadInterstitialAd ->                     // check arguments
                    if (call.hasArgument("licenseKey")
                        && call.hasArgument("adId") && call.hasArgument("request")
                    ) {

                        val interstitial = VponFlutterInterstitialAd(
                            call.argument("adId")!!,
                            adInstanceManager,
                            call.argument("adUnitId"),
                            call.argument("request"), VponFlutterAdLoader(context)
                        )
                        interstitial.load()
                        result.success(null)
                    } else {
                        result.error(
                            "invalidArgument", "invalidArgument", null
                        )
                    }

                Utils._init, Utils.initializeSDK, Utils.setLogLevel, Utils.setLocationManagerEnable, Utils.setAudioApplicationManaged, Utils.noticeApplicationAudioDidEnd, Utils.updateRequestConfiguration -> result.success(
                    null
                )

                else -> result.notImplemented()
            }
        }

        companion object {
            private const val TAG = "PluginMethodCallHandler"
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPluginBinding) {
        Log.e(TAG, "onAttachedToEngine invoked!!")
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            Utils.channelName,
            StandardMethodCodec(VponAdMessageCodec())
        )

        channel?.let {
            it.setMethodCallHandler(
                PluginMethodCallHandler(
                    flutterPluginBinding.applicationContext, VponAdInstanceManager(it)
                )
            )
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        Log.e(TAG, "onDetachedFromEngine invoked!!")
        channel!!.setMethodCallHandler(null)
    }

    companion object {
        private const val TAG = "VponMobileAdsPlugin"
    }
}
