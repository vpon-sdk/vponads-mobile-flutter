
enum VpadnUserGender { male, female, unknown }
enum VpadnMaxAdContentRating { unspecified, general, parentalGuidance, teen, matureAudience }
enum VpadnTagForUnderAgeOfConsent { unspecified, notForUnderAgeOfConsent, forUnderAgeOfConsent }
enum VpadnTagForChildDirectedTreatment { unspecified, notForChildDirectedTreatment, forChildDirectedTreatment }

class AdRequest {
  bool autoRefresh = false;
  Map<String, dynamic> contentData = {};
  List<String> testDevices = [];
  VpadnMaxAdContentRating? maxAdContentRating;
  VpadnTagForUnderAgeOfConsent? underAgeOfConsent;
  VpadnTagForChildDirectedTreatment? childDirectedTreatment;
  String? contentUrl;
  final List<String> keywords = [];
  // List<FriendlyObstruction> friendlyObstructions = [];


  static String sdkVersion() {
    // 實作取得 SDK 版本的邏輯
    return '5.5.0';
  }

  void setAutoRefresh(bool autoRefresh) {
    this.autoRefresh = autoRefresh;
  }

  void setUserInfoLocation(double latitude, double longitude) {
    // 實作設定用戶位置的邏輯
  }

  void setUserInfoAge(int age) {
    // 實作設定用戶年齡的邏輯
  }

  void setUserInfoBirthday(int year, int month, int day) {
    // 實作設定用戶生日的邏輯
  }

  void setUserInfoGender(VpadnUserGender gender) {
    // 實作設定用戶性別的邏輯
  }

  void setTestDevices(List<String> devices) {
    testDevices = devices;
  }

  void setTagFor({VpadnMaxAdContentRating? maxAdContentRating, VpadnTagForUnderAgeOfConsent? underAgeOfConsent, VpadnTagForChildDirectedTreatment? childDirectedTreatment}) {
    this.maxAdContentRating = maxAdContentRating;
    this.underAgeOfConsent = underAgeOfConsent;
    this.childDirectedTreatment = childDirectedTreatment;
  }

  void setContentUrl(String contentURL) {
    contentUrl = contentURL;
  }

  void setContentData(Map<String, dynamic> data) {
    contentData = data;
  }

  void addContentData(String key, dynamic value) {
    contentData[key] = value;
  }

  // void addFriendlyObstruction(FriendlyObstruction obstruction) {
  //   friendlyObstructions.add(obstruction);
  // }

  void addKeyword(String keyword) {
    keywords.add(keyword);
  }
}
