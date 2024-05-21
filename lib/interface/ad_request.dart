class VponAdRequest {
  String? contentUrl;
  List<String> keywords = [];
  Map<String, dynamic> extraData = {};
  Map<String, dynamic> contentData = {};

  /// Add content data
  void addContentData({required String key, required String value}) {
    contentData[key] = value;
  }

  /// 設定關鍵字
  ///
  /// 可以使用 Key:Value 的方式 addKeyword("Keyword1: Value1")，同時也可以直接關鍵字直接加入 addKeyword("Keyword")
  void addKeyword(String keyword) {
    List<String> arrExtraData = keyword.split(':');

    if (arrExtraData.length >= 2) {
      String strValue = arrExtraData[1];

      if (arrExtraData.length > 2) {
        for (var i = 2; i < arrExtraData.length; i++) {
          strValue = "$strValue:${arrExtraData[i]}";
        }
      }

      _addPublisherExtraData(key: arrExtraData[0], value: strValue);
    } else {
      keywords.add(keyword);
    }
  }

  void _addPublisherExtraData({required String key, required String value}) {
    extraData[key] = value;
  }

  // @override
  // bool operator ==(Object other) {
  //   return other is AdRequest &&
  //       contentUrl == other.contentUrl &&
  //       listEquals<String>(keywords, other.keywords) &&
  //       mapEquals<String, String>(contentData, other.contentData) &&
  //       format == other.format;
  // }
}

class VponRequestConfiguration {
  /// Maximum content rating that will be shown.
  final VponMaxAdContentRating? maxAdContentRating;

  /// Whether to tag as child directed.
  final VponTagForChildDirectedTreatment? tagForChildDirectedTreatment;

  /// Whether to tag as under age of consent.
  final VponTagForUnderAgeOfConsent? tagForUnderAgeOfConsent;

  /// List of test device ids to set.
  final List<String>? testDeviceIds;

  /// Creates a [VponRequestConfiguration].
  VponRequestConfiguration(
      {this.maxAdContentRating,
      this.tagForChildDirectedTreatment,
      this.tagForUnderAgeOfConsent,
      this.testDeviceIds});
}

/// Values for [VponRequestConfiguration.maxAdContentRating].
enum VponMaxAdContentRating {
  unspecified(-1),
  general(0),
  parentalGuidance(1),
  teen(2),
  matureAudience(3);

  const VponMaxAdContentRating(this.value);
  final int value;
}

/// Values for [VponRequestConfiguration.tagForUnderAgeOfConsent].
enum VponTagForUnderAgeOfConsent {
  unspecified(-1),
  no(0),
  yes(1);

  const VponTagForUnderAgeOfConsent(this.value);
  final int value;
}

/// Values for [VponRequestConfiguration.tagForChildDirectedTreatment].
enum VponTagForChildDirectedTreatment {
  unspecified(-1),
  no(0),
  yes(1);

  const VponTagForChildDirectedTreatment(this.value);
  final int value;
}
