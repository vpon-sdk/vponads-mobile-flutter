//
//  VpadnAdNativeViewController.m
//  vpon-sdk
//
//  Created by EricChien on 2019/1/4.
//  Copyright © 2019 com.vpon. All rights reserved.
//

#import "VpadnAdNativeViewController.h"

#import "../Category/NSURL+VpadnAd.h"

#import "../ViewModels/VpadnAdCoveredViewModel.h"
#import "../ViewModels/VpadnAdSdkViewModel.h"
#import "../ViewModels/VpadnAdErrorViewModel.h"
#import "../ViewModels/VpadnAdJsonParseViewModel.h"

#import "../Interface/VpadnNativeAd.h"
#import "../Interface/VpadnNativeAd+Internal.h"

#import "../Interface/VpadnMediaView.h"
#import "../Interface/VpadnMediaView+Internal.h"

#import "VpadnAdDefinition.h"

typedef void(^DataValid) (void);
typedef void(^DataInValid) (void);

@interface VpadnAdNativeViewController ()

@property (nonatomic, strong) NSMutableArray *thirdTrackingUrls;

@property (nonatomic, strong) NSString *action;

@property (nonatomic, strong) NSURL *link;

@property (nonatomic, strong) NSFileManager *fileManager;

@property (nonatomic, copy) NSString *lastExposureMessage;

@property (nonatomic, copy) NSString *documentPath;

@property (nonatomic, copy) NSString *filePath;

@end

@implementation VpadnAdNativeViewController

- (id) initWithPrincipal:(VpadnAdPrincipal *)principal native:(VpadnNativeAd *)native {
    self = [super initWithPrincipal:principal];
    if (self) {
        self.native = native;
        _documentPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        _documentPath = [_documentPath stringByAppendingString:@"/vpadn/mediaview"];
        _filePath = [_documentPath stringByAppendingString:@"/source.html"];
        _fileManager = [[NSFileManager alloc] init];
        [self.omViewModel omidJSService];
        [self addAppLifeCycleObserver];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - Notification & Observer

- (void) addAppLifeCycleObserver {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [center addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void) removeAppLifeCycleObserver {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    @try {
        [center removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    } @catch(id exception) { }
    @try {
        [center removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    } @catch(id exception) { }
}

// iOS / iPadOS 12 or before
- (void) applicationWillResignActive:(NSNotification *)notification {
    [self sendWillResignActive];
}

- (void) applicationDidBecomeActive:(NSNotification *)notification {
    [self sendDidBecomeActive];
}

- (void) dealloc {
    if (_mediaView) {
        [_mediaView removeMediaView];
        _mediaView = nil;
    }
    [self removeAppLifeCycleObserver];
    
    [VpadnAdSdkViewModel log:@"VpadnAdNativeViewController dealloc"];
}

#pragma mark - 抓取廣告 call back

- (void) afterRequestSuccess:(VpadnAdResponse *)response {
    NSDictionary *data = [NSURL queryParametersFromURL:response.targetURL];
    if ([self verifyNativeData:data]) {
        [self notifyGetAd];
        [self saveNativeData:data];
    } else {
        [self notifyAdFailedToLoad:[VpadnAdErrorViewModel errorForNoAds]];
    }
}

- (void) afterRequestFailed:(NSError*)error {
    [self notifyAdFailedToLoad:error];
}

/// 驗證Native資料正確性
- (BOOL) verifyNativeData:(NSDictionary *)data  {
    NSString *title = [VpadnAdVaildViewModel args:data stringByKey:NATIVE_KEY_TITLE];
    NSString *actionName = [VpadnAdVaildViewModel args:data stringByKey:NATIVE_KEY_ACTION_NAME];
    if (title.length && actionName.length) {
        NSString *jsonString = [VpadnAdVaildViewModel args:data stringByKey:NATIVE_KEY_THIRD_TRACKINGS];
        NSDictionary *onedata = [VpadnAdJsonParseViewModel jsonToDictionary:jsonString];
        _thirdTrackingUrls = [[VpadnAdVaildViewModel args:onedata arrayByKey:@"urls"] mutableCopy];
        
        NSString *match = @"^tr\\d";
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF matches %@", match];
        NSArray *results = [data.allKeys filteredArrayUsingPredicate:predicate];
        for (NSString *key in results) {
            [_thirdTrackingUrls addObject:data[key]];
        }
        
        NSString *track = [VpadnAdVaildViewModel args:data regrexStringByKey:NATIVE_KEY_THIRD_SINGLE];
        if (track && track.length && ![_thirdTrackingUrls containsObject:track]) {
            [_thirdTrackingUrls addObject:track];
        }
        _link = [VpadnAdVaildViewModel args:data regrexUrlByKey:NATIVE_KEY_LINK];
        return YES;
    } else {
        return NO;
    }
}

- (void) saveNativeData:(NSDictionary *)data {
    _native.properties = [data mutableCopy];
    
    
//    NSString *charactersToEscape = @"!*'();:@&=+$,/?%#[]<>^";
//    NSCharacterSet *allowedCharacters = [[NSCharacterSet characterSetWithCharactersInString:charactersToEscape] invertedSet];
//    NSString *e = [data[@"e"] stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];
////    NSString *encode = [ stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
//    [_native.properties setValue:e forKey:@"e"];
    
    [_native.properties removeObjectsForKeys:@[
        NATIVE_KEY_TITLE,
        NATIVE_KEY_BODY,
        NATIVE_KEY_SOCIAL_CONTEXT,
        NATIVE_KEY_R_V,
        NATIVE_KEY_R_S,
        NATIVE_KEY_COVER_WIDTH,
        NATIVE_KEY_COVER_HEIGHT,
        NATIVE_KEY_ICON_HEIGHT,
        NATIVE_KEY_ICON_HEIGHT,
        NATIVE_KEY_ICON_URL,
        NATIVE_KEY_AD_LABEL,
        @"om"
    ]];
    [VpadnAdSdkViewModel log:VpadnFmt(@"%@", _native.properties)];
    
    _native.title = [VpadnAdVaildViewModel args:data stringByKey:NATIVE_KEY_TITLE];
    _native.body = [VpadnAdVaildViewModel args:data stringByKey:NATIVE_KEY_BODY];
    _native.socialContext = [VpadnAdVaildViewModel args:data stringByKey:NATIVE_KEY_SOCIAL_CONTEXT];
    _native.callToAction = [VpadnAdVaildViewModel args:data stringByKey:NATIVE_KEY_ACTION_NAME];
    _native.ratingValue = [VpadnAdVaildViewModel args:data floatByKey:NATIVE_KEY_R_V];
    _native.ratingScale = [VpadnAdVaildViewModel args:data integerByKey:NATIVE_KEY_R_S];
    
    _native.e = [VpadnAdVaildViewModel args:data stringByKey:NATIVE_KEY_E defaultValue:@""];
    _native.tid = [VpadnAdVaildViewModel args:data stringByKey:NATIVE_KEY_VID_TID defaultValue:@""];
    _native.ad = [VpadnAdVaildViewModel args:data stringByKey:NATIVE_KEY_AD defaultValue:@""];
    NSString *uid = [VpadnAdVaildViewModel args:data stringByKey:NATIVE_KEY_UID defaultValue:@""];
    if (uid.length == 0) {
        uid = [self.deviceViewModel getCTID];
    }
    _native.uid = uid;
    
    NSInteger c_w = [VpadnAdVaildViewModel args:data integerByKey:NATIVE_KEY_COVER_WIDTH defaultValue:NATIVE_DEFAULT_COVER_IMAGE_WIDTH];
    NSInteger c_h = [VpadnAdVaildViewModel args:data integerByKey:NATIVE_KEY_COVER_HEIGHT defaultValue:NATIVE_DEFAULT_COVER_IMAGE_HEIGHT];
    NSURL *c_u = [VpadnAdVaildViewModel args:data urlByKey:NATIVE_KEY_COVER_URL];
    _native.coverImage = [[VpadnAdImage alloc] initWithURL:c_u width:c_w height:c_h];
    
    NSInteger i_w = [VpadnAdVaildViewModel args:data integerByKey:NATIVE_KEY_ICON_WIDTH defaultValue:NATIVE_DEFAULT_ICON_IMAGE_WIDTH];
    NSInteger i_h = [VpadnAdVaildViewModel args:data integerByKey:NATIVE_KEY_ICON_HEIGHT defaultValue:NATIVE_DEFAULT_ICON_IMAGE_HEIGHT];
    NSURL *i_u = [VpadnAdVaildViewModel args:data urlByKey:NATIVE_KEY_ICON_URL];
    _native.icon = [[VpadnAdImage alloc] initWithURL:i_u width:i_w height:i_h];
    
    [self notifyAdLoaded];
}

#pragma mark - 遮蔽偵測

- (void) afterDetectCovered:(BOOL)result {
    if (result) {
        [VpadnAdSdkViewModel log:@"[AD VIEWABILITY] Detection finished"];
        self.isFinishDetectCovered = YES;
        [self sendImpression];
        [self.requestViewModel sendAsynchronousRequestWithUrls:_thirdTrackingUrls];
    } else {
        [VpadnAdSdkViewModel log:@"[AD VIEWABILITY] Fail to pass the detection, will restart after 0.5s"];
        [self startDetectCoveredTimer:0.5f];
    }
}

#pragma mark - 發送曝光

- (void) sendExposureChange {
    float percent = [self getExposedViewPercent];
    if (_mediaView.avoidPercentLessThan50 && percent < 50) return;
    NSString *message = [self getExposureFuncWithPercent:percent];
    if ([_lastExposureMessage isEqualToString:message]) return;
    else _lastExposureMessage = message;
    [_mediaView evaluateJSName:JS_CB_NA_ON_EXPOSURE_CHANGE message:message];
}

/// 計算 mediaView.adWebView 露出比例
- (float) getExposedViewPercent {
    if (!_mediaView || !_mediaView.adWebView) return 0;
    if (!_mediaViewCoveredViewModel) {
        _mediaViewCoveredViewModel = [[VpadnAdCoveredViewModel alloc] initWithAdView:_mediaView.adWebView inWindow:[UIApplication sharedApplication].keyWindow];
        _mediaViewCoveredViewModel.friendlyObstructions = self.principal.request.friendlyObstructions;
    }
    float percent = [_mediaViewCoveredViewModel exposedPercent];
    return percent;
}

// - FIXME: To be refactored
/// 計算 mediaView 露出比例的臨時方法，與上一隻用法重疊，有待重構
- (float) getMediaViewExposedViewPercent {
    if (!_mediaView) return 0;
    VpadnAdCoveredViewModel * tmpMediaViewCoveredViewModel = [[VpadnAdCoveredViewModel alloc] initWithAdView:_mediaView inWindow:[UIApplication sharedApplication].keyWindow];
    tmpMediaViewCoveredViewModel.friendlyObstructions = self.principal.request.friendlyObstructions;
    float percent = [tmpMediaViewCoveredViewModel exposedPercent];
    return percent;
}

- (NSString *) getExposureFuncWithPercent:(float)percent {
    NSMutableDictionary *onScreen = [[NSMutableDictionary alloc] init];
    CGRect onScreenRect = [_mediaViewCoveredViewModel onScreenRect:_mediaView.adWebView];
    [onScreen setValue:@(onScreenRect.origin.x)       forKey:@"x"];
    [onScreen setValue:@(onScreenRect.origin.y)       forKey:@"y"];
    [onScreen setValue:@(onScreenRect.size.width)     forKey:@"width"];
    [onScreen setValue:@(onScreenRect.size.height)    forKey:@"height"];
    NSMutableDictionary *ad = [[NSMutableDictionary alloc] init];
    CGRect adViewRect = [_mediaViewCoveredViewModel adViewRect:_mediaView.adWebView];
    [ad setValue:@(adViewRect.origin.x)       forKey:@"x"];
    [ad setValue:@(adViewRect.origin.y)       forKey:@"y"];
    [ad setValue:@(adViewRect.size.width)     forKey:@"width"];
    [ad setValue:@(adViewRect.size.height)    forKey:@"height"];
    return [NSString stringWithFormat:@"%.4f,'%@', null, '%@'", percent,
            [VpadnAdJsonParseViewModel dictionaryTojson:onScreen prettyPrint:NO],
            [VpadnAdJsonParseViewModel dictionaryTojson:ad prettyPrint:NO]];
}

#pragma mark - Click Handler

- (NSDictionary *) combineOutapp {
    return @{
             @"btntrackingurls": @[],
             @"action": @"out_url",
             @"launch_type": @"outapp",
             @"data": @{
                     @"u": _link == nil ? @"" : _link.absoluteString
                     },
             };
}

- (void) sendClick {
    if (self.omViewModel.isVideoAd) {
        [self.omViewModel adUserInteractionClick];
    }
    [super sendClick];
}

- (void) clickHandler:(id)sender {
    [self sendClick];
    [self filterFeature:[self combineOutapp]];
}

#pragma mark - Native (Active) -> JS

- (void) sendOnShow {
    [super sendOnShow];
    if (_mediaView) {
        [_mediaView evaluateJSName:JS_CB_ON_SHOW message:nil];
    }
}

- (void) sendImpression {
    [super sendImpression];
    if (_mediaView) {
        [_mediaView evaluateJSName:JS_CB_ON_IMPRESSION message:nil];
    }
}

- (void) sendWillResignActive {
    if (_mediaView) {
        [_mediaView evaluateJSName:JS_CB_WILL_RESIGN_ACTIVE message:nil];
    }
}

- (void) sendDidBecomeActive {
    if (_mediaView) {
        [_mediaView evaluateJSName:JS_CB_DID_BECOME_ACTIVE message:nil];
    }
}

#pragma mark Notify to Publisher

- (void) notifyGetAd {
    if (!_native || !_native.delegate) return;
    if ([_native.delegate respondsToSelector:@selector(onVpadnNativeGetAd:)]) {
        [_native.delegate onVpadnNativeGetAd:_native];
    }
}

- (void) notifyAdLoaded {
    if (self.hasBeenReceived != VpadnReceivedStateNone) return;
    [super notifyAdLoaded];
    if (!_native || !_native.delegate) return;
    if ([_native.delegate respondsToSelector:@selector(onVpadnNativeAdLoaded:)]) {
        [_native.delegate onVpadnNativeAdLoaded:_native];
    } else if ([_native.delegate respondsToSelector:@selector(onVpadnNativeAdReceived:)]) {
        [_native.delegate onVpadnNativeAdReceived:_native];
    }
}

- (void) notifyAdFailedToLoad:(NSError *)error {
    if (self.hasBeenReceived != VpadnReceivedStateNone) return;
    [super notifyAdFailedToLoad:error];
    if (!_native || !_native.delegate) return;
    if ([_native.delegate respondsToSelector:@selector(onVpadnNativeAd:failedToLoad:)]) {
        [_native.delegate onVpadnNativeAd:_native failedToLoad:[VpadnAdErrorViewModel errorForNoAds]];
    } else if ([_native.delegate respondsToSelector:@selector(onVpadnNativeAd:didFailToReceiveAdWithError:)]) {
        [_native.delegate onVpadnNativeAd:_native didFailToReceiveAdWithError:[VpadnAdErrorViewModel errorForNoAds]];
    }
}

- (void) notifyAdWillLeaveApplication {
    [super notifyAdWillLeaveApplication];
    if (!_native || !_native.delegate) return;
    if ([_native.delegate respondsToSelector:@selector(onVpadnNativeAdWillLeaveApplication:)]) {
        [_native.delegate onVpadnNativeAdWillLeaveApplication:_native];
    } else if ([_native.delegate respondsToSelector:@selector(onVpadnNativeAdLeaveApplication:)]) {
        [_native.delegate onVpadnNativeAdLeaveApplication:_native];
    }
}

- (void) notifyAdImpression {
    [super notifyAdImpression];
    if (!_native || !_native.delegate) return;
    if ([_native.delegate respondsToSelector:@selector(onVpadnNativeAdDidImpression:)]) {
        [_native.delegate onVpadnNativeAdDidImpression:_native];
    }
}

- (void) notifyAdClicked {
    [super notifyAdClicked];
    if (!_native || !_native.delegate) return;
    if ([_native.delegate respondsToSelector:@selector(onVpadnNativeAdClicked:)]) {
        [_native.delegate onVpadnNativeAdClicked:_native];
    } else if ([_native.delegate respondsToSelector:@selector(onVpadnNativeAdDidClicked:)]) {
        [_native.delegate onVpadnNativeAdDidClicked:_native];
    }
}

- (void) notifyAdOpened {
    [super notifyAdOpened];
}

- (void) notifyAdClosed {
    [super notifyAdClosed];
}

#pragma mark - Update Source

- (void) mediaSource {
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSArray *keys = userDefault.dictionaryRepresentation.allKeys;
    if (![keys containsObject:VPADN_MEDIA_SOURCE_KEY]) {
        [self updateSource];
        return;
    }
    NSTimeInterval last = [userDefault integerForKey:VPADN_MEDIA_SOURCE_KEY];
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if (now - last > VPADN_MEDIA_SOURCE_INTERVAL) {
        [self updateSource];
        return;
    }
}

- (void) updateSource {
    NSURL *url = [NSURL URLWithString:VPADN_MEDIA_SOURCE];
    __weak typeof(self) weakSelf = self;
    NSURLSession *defaultSession = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSString *source = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [weakSelf saveSourceToDirectory:source];
    }];
    [dataTask resume];
}

- (NSString *) getSourceFromDirectory {
    if (![_fileManager fileExistsAtPath:_filePath]) {
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSString *filePath = [bundle pathForResource:@"vpon-nativead-video-tpl-v2" ofType:@"html"];
        NSError *error = nil;
        NSString *resource = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            [VpadnAdSdkViewModel log:@"[MediaView] Video Template not found." level:VpadnLogTagError];
            return @"";
        }
        return resource;
    } else {
        return [[NSString alloc] initWithContentsOfFile:_filePath encoding:NSUTF8StringEncoding error:nil];
    }
}

- (void) saveSourceToDirectory:(NSString *)content {
    if (![_fileManager fileExistsAtPath:_documentPath]) {
        [_fileManager createDirectoryAtPath:_documentPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if ([content writeToFile:_filePath atomically:YES encoding:NSUTF8StringEncoding error:nil]) {
        NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
        NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
        [userDefault setInteger:now forKey:VPADN_MEDIA_SOURCE_KEY];
    }
}

@end
