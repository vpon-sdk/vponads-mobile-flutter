package io.flutter.plugins.vponmobileads

import android.view.View
import io.flutter.plugin.platform.PlatformView

internal class VponFlutterPlatformView(private var view: View?) : PlatformView {
    override fun getView(): View? {
        return view
    }

    override fun dispose() {
        view = null
    }
}
