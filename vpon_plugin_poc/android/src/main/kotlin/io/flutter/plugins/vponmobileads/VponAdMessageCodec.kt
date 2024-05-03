package io.flutter.plugins.vponmobileads

import android.util.Log
import io.flutter.plugin.common.StandardMessageCodec
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer

internal class VponAdMessageCodec : StandardMessageCodec() {

    override fun writeValue(stream: ByteArrayOutputStream, value: Any?) {

        when (value) {
            is VponFlutterAdSize -> {
                Log.d(TAG, "writeValue.case VponFlutterAdSize")
                writeAdSize(stream, value)
            }

            is VponFlutterAdRequest -> {
                Log.d(TAG, "writeValue.case VponFlutterAdRequest")
                stream.write(VALUE_AD_REQUEST.toInt())
                writeValue(stream, value.getContentUrl())
                writeValue(stream, value.getContentData())
                writeValue(stream, value.getKeywords())
            }

            else -> {
                super.writeValue(stream, value)
            }
        }

    }

    override fun readValueOfType(type: Byte, buffer: ByteBuffer): Any? {
        return when (type) {
            VALUE_SMART_BANNER_AD_SIZE -> {
                Log.d(TAG, "readValueOfType.case VALUE_SMART_BANNER_AD_SIZE")
                VponFlutterAdSize.SmartBannerAdSize()
            }

            VALUE_AD_SIZE -> {
                Log.d(TAG, "readValueOfType.case VALUE_AD_SIZE")
                VponFlutterAdSize(
                    (readValueOfType(buffer.get(), buffer) as Int?)!!,
                    (readValueOfType(buffer.get(), buffer) as Int?)!!
                )
            }

            VALUE_AD_REQUEST -> {
                Log.d(TAG, "readValueOfType.case VALUE_AD_REQUEST")
                @Suppress("UNCHECKED_CAST")
                VponFlutterAdRequest.Builder()
                    .setContentUrl(readValueOfType(buffer.get(), buffer) as String?)
                    .setContentData(
                        readValueOfType(
                            buffer.get(),
                            buffer
                        ) as HashMap<String, Any>?
                    )
                    .setKeywords(readValueOfType(buffer.get(), buffer) as List<String>?)
                    .build()
            }

            else ->
                super.readValueOfType(type, buffer)
        }
    }

    private fun writeAdSize(stream: ByteArrayOutputStream, flutterAdSize: VponFlutterAdSize) {
        if (flutterAdSize is VponFlutterAdSize.SmartBannerAdSize) {
            stream.write(VALUE_SMART_BANNER_AD_SIZE.toInt())
        } else {
            stream.write(VALUE_AD_SIZE.toInt())
            writeValue(stream, flutterAdSize.width)
            writeValue(stream, flutterAdSize.height)
        }
    }

    companion object {
        private const val TAG = "VponAdMessageCodec"
        private const val VALUE_AD_SIZE = 128.toByte()
        private const val VALUE_SMART_BANNER_AD_SIZE = 143.toByte()
        private const val VALUE_AD_REQUEST = 129.toByte()
    }
}