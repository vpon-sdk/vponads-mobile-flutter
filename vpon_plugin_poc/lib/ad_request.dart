
import 'package:flutter/foundation.dart';

class AdRequest {
  const AdRequest({
    this.contentUrl,
    this.keywords,
    this.contentData,
    this.format
  });

  final String? contentUrl;
  final List<String>? keywords;
  final Map<String, String>? contentData;
  final String? format;

  // List<FriendlyObstruction> friendlyObstructions = [];

  void setUserInfoAge(int age) {}

  void setUserInfoBirthday(int year, int month, int day) {}

  // void setUserInfoGender(VponUserGender gender) {}

// void addFriendlyObstruction(FriendlyObstruction obstruction) {
//   friendlyObstructions.add(obstruction);
// }

  @override
  bool operator ==(Object other) {
    return other is AdRequest &&
        contentUrl == other.contentUrl &&
        listEquals<String>(keywords, other.keywords) &&
        mapEquals<String, String>(contentData, other.contentData) &&
        format == other.format;
  }

/*  @override
  int get hashCode {
    return Object.hash(contentUrl, keywords, contentData, format);
  }*/
}

class RequestConfiguration {
  /// Maximum content rating that will be shown.
  final String? maxAdContentRating;

  /// Whether to tag as child directed.
  final int? tagForChildDirectedTreatment;

  /// Whether to tag as under age of consent.
  final int? tagForUnderAgeOfConsent;

  /// List of test device ids to set.
  final List<String>? testDeviceIds;

  /// Creates a [RequestConfiguration].
  RequestConfiguration(
      {this.maxAdContentRating,
        this.tagForChildDirectedTreatment,
        this.tagForUnderAgeOfConsent,
        this.testDeviceIds});
}

/// Values for [RequestConfiguration.maxAdContentRating].
class MaxAdContentRating {
  static const String unspecified = '';
  static const String general = 'G';
  static const String parentalGuidance = 'PG';
  static const String teen = 'T';
  static const String matureAudience = 'MA';
}

/// Values for [RequestConfiguration.tagForUnderAgeOfConsent].
class TagForUnderAgeOfConsent {
  static const int yes = 1;
  static const int no = 0;
  static const int unspecified = -1;
}

/// Values for [RequestConfiguration.tagForChildDirectedTreatment].
class TagForChildDirectedTreatment {
  static const int yes = 1;
  static const int no = 0;
  static const int unspecified = -1;
}
