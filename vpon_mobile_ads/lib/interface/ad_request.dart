class VponAdRequest {
  String? contentUrl;
  List<String> keywords = [];
  Map<String, dynamic> extraData = {};
  Map<String, dynamic> contentData = {};

  /// 新增 content data
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
}

class VponRequestConfiguration {
  /// 最高可投放的年齡(分類)限制
  final VponMaxAdContentRating? maxAdContentRating;

  /// 是否專為兒童投放
  final VponTagForChildDirectedTreatment? tagForChildDirectedTreatment;

  /// 是否專為特定年齡投放
  final VponTagForUnderAgeOfConsent? tagForUnderAgeOfConsent;

  /// 測試用的裝置 IDFA，以取得 Vpon 測試廣告
  final List<String>? testDeviceIds;

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
