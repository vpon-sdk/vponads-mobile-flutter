package io.flutter.plugins.vponmobileads

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import android.view.View
import com.vpon.ads.VponAdRequest
import com.vpon.ads.VponMobileAds
import com.vpon.ads.VponNativeAd
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.StandardMethodCodec

/**
 * VponMobileAdsPlugin
 */
class VponMobileAdsPlugin : FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private var channel: MethodChannel? = null
    private val nativeAdFactories: HashMap<String, NativeAdFactory> = HashMap()
    private var context: Context? = null
    private var adInstanceManager: VponAdInstanceManager? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPluginBinding) {
        Log.e(TAG, "onAttachedToEngine invoked!!")
        context = flutterPluginBinding.applicationContext

        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            Constants.CHANNEL_NAME_TO_FLUTTER,
            StandardMethodCodec(VponAdMessageCodec())
        )

        channel?.let { methodChannel ->
            adInstanceManager = VponAdInstanceManager(methodChannel)
            methodChannel.setMethodCallHandler(this)
            adInstanceManager?.let {
                flutterPluginBinding
                    .platformViewRegistry
                    .registerViewFactory(
                        "${Constants.CHANNEL_NAME_TO_FLUTTER}/ad_widget",
                        VponMobileAdsViewFactory(it)
                    )
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        Log.e(TAG, "onDetachedFromEngine invoked!!")
        channel!!.setMethodCallHandler(null)
    }

    private fun addNativeAdFactory(factoryId: String, nativeAdFactory: NativeAdFactory): Boolean {
        if (nativeAdFactories.containsKey(factoryId)) {
            val errorMessage = String.format(
                "A NativeAdFactory with the following factoryId already exists: %s", factoryId
            )
            Log.e(TAG, errorMessage)
            return false
        }
        nativeAdFactories[factoryId] = nativeAdFactory
        return true
    }

    companion object {
        fun registerNativeAdFactory(
            flutterEngine: FlutterEngine,
            factoryId: String,
            nativeAdFactory: NativeAdFactory
        ): Boolean {
            val vponPlugin: VponMobileAdsPlugin? =
                flutterEngine.plugins[VponMobileAdsPlugin::class.java] as VponMobileAdsPlugin?
            return registerNativeAdFactory(vponPlugin, factoryId, nativeAdFactory)
        }

        private fun registerNativeAdFactory(
            plugin: VponMobileAdsPlugin?,
            factoryId: String,
            nativeAdFactory: NativeAdFactory
        ): Boolean {
            if (plugin == null) {
                val message = String.format(
                    "Could not find a %s instance. The plugin may have not been registered.",
                    TAG
                )
                throw IllegalStateException(message)
            }
            return plugin.addNativeAdFactory(factoryId, nativeAdFactory)
        }

        private const val TAG = "VponMobileAdsPlugin"
    }

    interface NativeAdFactory {
        fun createNativeAd(vponNativeAd: VponNativeAd): View
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        Log.e(TAG, "onMethodCall:" + call.method)
        val method = call.method

        when (method) {
            "getPlatformVersion" -> {
                // TODO remove after develop
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }

            Constants.METHOD_SHOW_AD_WITHOUT_VIEW -> {
                if (call.hasArgument(Constants.CHANNEL_ARGUMENT_ADID)) {
                    val adid = call.argument(Constants.CHANNEL_ARGUMENT_ADID) as Int?
                    adid?.let {
                        adInstanceManager?.showAd(it)
                        result.success(null)
                    }
                } else {
                    result.error(
                        "invalidArgument", "invalidArgument", null
                    )
                }
            }

            Constants._init -> {
                // cef23de9-9ed9-41dd-9cb2-e568c5053e4e
                // TODO remove after develop
                Log.e(TAG, "_init has been called!!")
                context?.let {
                    val sharedPreferences: SharedPreferences = it
                        .getSharedPreferences(
                            "_vpon_advertisingId",
                            Context.MODE_PRIVATE
                        )

                    sharedPreferences.edit()
                        .putString(
                            "_vpon_advertisingId",
                            "cef23de9-9ed9-41dd-9cb2-e568c5053e4e"
                        ).apply()
                    val _tmp = sharedPreferences.getString("_vpon_advertisingId", "XXXXX")
                    Log.e(TAG, "_tmp : $_tmp")
                }

            }

            Constants.METHOD_GET_VERSION_STRING -> result.success(VponAdRequest.VERSION)
            Constants.METHOD_GET_VPON_ID -> result.success(VponMobileAds.getVponID(context))
            Constants.METHOD_SET_CONSENT_STATUS -> result.success(null)
            Constants.METHOD_DISPOSE_AD ->
                if (call.hasArgument(Constants.CHANNEL_ARGUMENT_ADID)) {
                    adInstanceManager
                        ?.disposeAd(call.argument(Constants.CHANNEL_ARGUMENT_ADID)!!)
                    result.success(null)
                } else {
                    result.error(
                        "invalidArgument", "invalidArgument", null
                    )
                }

            Constants.METHOD_LOAD_BANNER_AD ->
                if (call.hasArgument(Constants.CHANNEL_ARGUMENT_LICENSE_KEY)
                    && call.hasArgument(Constants.CHANNEL_ARGUMENT_ADID)
                    && call.hasArgument(Constants.CHANNEL_ARGUMENT_AD_REQUEST)
                    && call.hasArgument(Constants.CHANNEL_ARGUMENT_AD_SIZE)
                ) {
                    val vponFlutterBannerAd = VponFlutterBannerAd(
                        context,
                        call.argument(Constants.CHANNEL_ARGUMENT_ADID)!!,
                        adInstanceManager,
                        call.argument(Constants.CHANNEL_ARGUMENT_LICENSE_KEY),
                        call.argument(Constants.CHANNEL_ARGUMENT_AD_REQUEST),
                        call.argument(Constants.CHANNEL_ARGUMENT_AD_SIZE)
                    )
                    vponFlutterBannerAd.load()
                    result.success(null)
                } else {
                    result.error(
                        "invalidArgument", "invalidArgument", null
                    )
                }

            Constants.METHOD_LOAD_INTERSTITIAL_AD ->                     // check arguments
                if (call.hasArgument(Constants.CHANNEL_ARGUMENT_LICENSE_KEY)
                    && call.hasArgument(Constants.CHANNEL_ARGUMENT_ADID)
                    && call.hasArgument(Constants.CHANNEL_ARGUMENT_AD_REQUEST)
                ) {
                    val vponFlutterInterstitialAd = VponFlutterInterstitialAd(
                        call.argument(Constants.CHANNEL_ARGUMENT_ADID)!!,
                        adInstanceManager,
                        call.argument(Constants.CHANNEL_ARGUMENT_LICENSE_KEY),
                        call.argument(Constants.CHANNEL_ARGUMENT_AD_REQUEST),
                        VponFlutterAdLoader(context)
                    )
                    vponFlutterInterstitialAd.load()
                    result.success(null)
                } else {
                    result.error(
                        "invalidArgument", "invalidArgument", null
                    )
                }

            Constants.METHOD_LOAD_NATIVE_AD -> {
                if (call.hasArgument(Constants.CHANNEL_ARGUMENT_LICENSE_KEY)
                    && call.hasArgument(Constants.CHANNEL_ARGUMENT_ADID)
                    && call.hasArgument(Constants.CHANNEL_ARGUMENT_AD_REQUEST)
                    && call.hasArgument(Constants.CHANNEL_ARGUMENT_FACTORY_ID)
                ) {
                    val factory =
                        nativeAdFactories[call.argument(Constants.CHANNEL_ARGUMENT_FACTORY_ID)]
                    adInstanceManager?.let { manager ->
                        factory?.let { factory ->
                            context?.let {
                                val vponFlutterNativeAd = VponFlutterNativeAd.Builder()
                                    .setManager(manager)
                                    .setAdFactory(factory)
                                    .setId(call.argument(Constants.CHANNEL_ARGUMENT_ADID)!!)
                                    .setLicenseKey(call.argument(Constants.CHANNEL_ARGUMENT_LICENSE_KEY)!!)
                                    .setFlutterAdLoader(VponFlutterAdLoader(it))
                                    .setRequest(call.argument(Constants.CHANNEL_ARGUMENT_AD_REQUEST)!!)
                                    .build()
                                vponFlutterNativeAd.load()
                                result.success(null)
                            }
                        }
                    }
                } else {
                    result.error(
                        "invalidArgument", "invalidArgument", null
                    )
                }
            }

            Constants.METHOD_INITIALIZE_SDK, Constants.METHOD_SET_LOG_LEVEL, Constants.METHOD_ENABLE_LOCATION_MANAGER, Constants.METHOD_SET_AUDIO_MANAGER, Constants.METHOD_NOTICE_APPLICATION_AUDIO_DID_END, Constants.METHOD_UPDATE_REQUEST_CONFIGURATION -> result.success(
                null
            )
            else -> result.notImplemented()
        }
    }

}
