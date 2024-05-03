package io.flutter.plugins.vponmobileads

import android.content.Context
import android.graphics.Color
import android.util.Log
import android.view.View
import android.widget.TextView
import com.example.vpon_plugin_poc.BuildConfig
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import java.util.Locale

internal class VponMobileAdsViewFactory(private val manager: VponAdInstanceManager) :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context?, viewId: Int, args: Any?): PlatformView {
        if (args == null) {
            return getErrorView(context!!, 0)
        }
        val adId = args as Int
        val ad: VponFlutterAd? = manager.adForId(adId)

        if (ad?.getPlatformView() == null) {
            return getErrorView(context!!, adId)
        }
        return ad.getPlatformView()!!
    }

    private class ErrorTextView constructor(context: Context, message: String) :
        PlatformView {

        private val textView = TextView(context)

        init {
            textView.setBackgroundColor(Color.RED)
            textView.setTextColor(Color.YELLOW)
            textView.text = message
        }

        override fun getView(): View {
            return textView
        }

        override fun dispose() {
        }

    }

    companion object {
        private fun getErrorView(context: Context, adId: Int): PlatformView {
            val message = String.format(
                Locale.getDefault(),
                "This ad may have not been loaded or has been disposed. "
                        + "Ad with the following id could not be found: %d.",
                adId
            )
            if (BuildConfig.DEBUG) {
                return ErrorTextView(context, message)
            } else {
                Log.e("VponAdsViewFactory", message)
                return object : PlatformView {
                    override fun getView(): View {
                        return View(context)
                    }

                    override fun dispose() {
                        // Do nothing.
                    }
                }
            }
        }
    }
}
