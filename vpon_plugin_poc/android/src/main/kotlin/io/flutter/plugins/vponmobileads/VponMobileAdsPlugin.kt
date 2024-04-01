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

                Constants.METHOD_GET_VERSION_STRING -> result.success(VponAdRequest.VERSION)
                Constants.METHOD_GET_VPON_ID -> result.success(VponMobileAds.getVponID(context))
                Constants.METHOD_SET_CONSENT_STATUS -> result.success(null)
                Constants.METHOD_LOAD_INTERSTITIAL_AD ->                     // check arguments
                    if (call.hasArgument("licenseKey")
                        && call.hasArgument("adId") && call.hasArgument("request")
                    ) {

                        val interstitial = VponFlutterInterstitialAd(
                            call.argument("adId")!!,
                            adInstanceManager,
                            call.argument("licenseKey"),
                            call.argument("request"), VponFlutterAdLoader(context)
                        )
                        interstitial.load()
                        result.success(null)
                    } else {
                        result.error(
                            "invalidArgument", "invalidArgument", null
                        )
                    }

                Constants._init, Constants.METHOD_INITIALIZE_SDK, Constants.METHOD_SET_LOG_LEVEL, Constants.METHOD_ENABLE_LOCATION_MANAGER, Constants.METHOD_SET_AUDIO_MANAGER, Constants.METHOD_NOTICE_APPLICATION_AUDIO_DID_END, Constants.METHOD_UPDATE_REQUEST_CONFIGURATION -> result.success(
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
            Constants.CHANNEL_NAME_TO_FLUTTER,
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
