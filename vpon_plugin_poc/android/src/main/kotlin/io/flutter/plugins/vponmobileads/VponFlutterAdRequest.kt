package io.flutter.plugins.vponmobileads

import com.vpon.ads.VponAdRequest

internal class VponFlutterAdRequest private constructor(
    private val keywords: List<String>?,
    private val contentUrl: String?,
    private val contentData: HashMap<String, Any>?
) {

    fun getKeywords(): List<String>? {
        return keywords
    }

    fun getContentUrl(): String? {
        return contentUrl
    }

    fun getContentData(): HashMap<String, Any>? {
        return contentData
    }

    fun asVponAdRequest(): VponAdRequest {
        val vponAdRequestBuilder = VponAdRequest.Builder()
        contentData?.let { vponAdRequestBuilder.setContentData(it) }
        contentUrl?.let { vponAdRequestBuilder.setContentUrl(it) }
        keywords?.let { vponAdRequestBuilder.addKeywords(HashSet<String>(it)) }
        return vponAdRequestBuilder.build()
    }

    internal class Builder {

        var keywords: List<String>? = null
            private set
        var contentUrl: String? = null
            private set
        var contentData: HashMap<String, Any>? = HashMap()
            private set

        fun setKeywords(keywords: List<String>?) = apply { this.keywords = keywords }
        fun setContentUrl(contentUrl: String?) = apply { this.contentUrl = contentUrl }
        fun setContentData(contentData: HashMap<String, Any>?) =
            apply { this.contentData = contentData }

        fun addContentData(key: String, value: Any) = apply { this.contentData?.set(key, value) }

        fun build(): VponFlutterAdRequest {
            return VponFlutterAdRequest(keywords, contentUrl, contentData)
        }
    }
}
