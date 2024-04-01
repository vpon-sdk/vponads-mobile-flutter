package io.flutter.plugins.vponmobileads;

import androidx.annotation.Nullable;

import com.vpon.ads.VponAdRequest;

import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;

class VponFlutterAdRequest {
    @Nullable
    private final List<String> keywords;
    @Nullable
    private final String contentUrl;

    @Nullable
    private final HashMap<String, Object> contentData;

    protected static class Builder {
        @Nullable
        private List<String> keywords;
        @Nullable
        private String contentUrl;
        @Nullable
        private HashMap<String, Object> contentData = new HashMap<>();

        Builder setKeywords(@Nullable List<String> keywords) {
            this.keywords = keywords;
            return this;
        }

        Builder setContentUrl(@Nullable String contentUrl) {
            this.contentUrl = contentUrl;
            return this;
        }

        Builder setContentData(@Nullable HashMap<String, Object> contentData) {
            this.contentData = contentData;
            return this;
        }

        Builder addContentData(String key, Object value) {
            if (this.contentData != null) {
                this.contentData.put(key, value);
            }
            return this;
        }

        @Nullable
        protected List<String> getKeywords() {
            return keywords;
        }

        @Nullable
        protected String getContentUrl() {
            return contentUrl;
        }

        @Nullable
        protected HashMap<String, Object> getContentData() {
            return contentData;
        }

        VponFlutterAdRequest build() {
            return new VponFlutterAdRequest(
                    keywords,
                    contentUrl,
                    contentData);
        }
    }

    protected VponFlutterAdRequest(
            @Nullable List<String> keywords,
            @Nullable String contentUrl,
            @Nullable HashMap<String, Object> contentData) {
        this.keywords = keywords;
        this.contentUrl = contentUrl;
        this.contentData = contentData;
    }

    VponAdRequest asVponAdRequest() {
        VponAdRequest.Builder builder = new VponAdRequest.Builder();
        if (contentData != null) {
            builder.setContentData(contentData);
        }
        if (contentUrl != null) {
            builder.setContentUrl(contentUrl);
        }
        if (keywords != null) {
            builder.addKeywords(new HashSet<>(keywords));
        }
        builder.setAutoRefresh(false);
        return builder.build();
    }

    @Nullable
    protected List<String> getKeywords() {
        return keywords;
    }

    @Nullable
    protected String getContentUrl() {
        return contentUrl;
    }

    @Nullable
    protected Map<String, Object> getContentData() {
        return contentData;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        } else if (!(o instanceof VponFlutterAdRequest)) {
            return false;
        }

        VponFlutterAdRequest request = (VponFlutterAdRequest) o;
        return Objects.equals(keywords, request.keywords)
                && Objects.equals(contentUrl, request.contentUrl)
                && Objects.equals(contentData, request.contentData);
    }

    @Override
    public int hashCode() {
        return Objects.hash(
                keywords, contentUrl, contentData);
    }
}
