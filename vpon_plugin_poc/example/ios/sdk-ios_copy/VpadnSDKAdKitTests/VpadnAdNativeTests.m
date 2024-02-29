//
//  VpadnAdNativeTests.m
//  VpadnSDKAdKitTests
//
//  Created by Yi-Hsiang, Chien on 2020/4/7.
//  Copyright © 2020 com.vpon. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AdSupport/AdSupport.h>
#import "../VpadnSDKAdKit/VpadnSDKAdKit.h"
#import <VpadnSDKAdKit/VpadnSDKAdKit-Swift.h>

@interface VpadnAdNativeTests : XCTestCase <VpadnNativeAdDelegate>

@property (nonatomic, strong) VpadnNativeAd *testNative;

@property (nonatomic, strong) VpadnAdRequest *testRequest;

@property (nonatomic, assign) BOOL callBackInvoked;

@property (nonatomic, assign) BOOL failLoadedInvoked;

@end

@implementation VpadnAdNativeTests

- (void)setUp {
    [super setUp];
    [self initConfig];
    [self initRequest];
    [self initNative];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void) testRequestNotNil {
    [self initRequest];
    XCTAssertNotNil(_testRequest, "VpadnAdRequest object is nil");
}

- (void) testNativeNotNil {
    [self initNative];
    XCTAssertNotNil(_testNative, "VpadnNative object is nil");
}

- (void) testNativeCallBackNotInvokedAndResponse {
    [self request];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:3.0]];
    XCTAssertTrue(self.callBackInvoked, "Native call back not invoked");
}

- (void) test_NativeWithWrongLicenseKey_ShouldFailToLoad {
    // Given
    VpadnAdRequest *request = [[VpadnAdRequest alloc] init];
    VpadnNativeAd *native = [[VpadnNativeAd alloc] initWithLicenseKey:@"123"];
    native.delegate = self;
    
    // When
    [native loadRequest:request];
    
    // Then
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:3.0]];
    XCTAssertTrue(self.failLoadedInvoked, "Native call back not invoked");
}

#pragma mark - Initial

- (void) initNative {
    _testNative = [[VpadnNativeAd alloc] initWithLicenseKey:@"8a80854b668a2bb90166a05efc8e1844"];
    _testNative.delegate = self;
}

- (void) initConfig {
    VpadnAdConfiguration *config = VpadnAdConfiguration.shared;
    config.logLevel = VpadnLogLevelDebug;
    [config initializeSdk];
        
    _callBackInvoked = NO;
    _failLoadedInvoked = NO;
}

- (void) initRequest {
    _testRequest = [[VpadnAdRequest alloc] init];
    [_testRequest setTestDevices:@[[ASIdentifierManager sharedManager].advertisingIdentifier.UUIDString]];
    [_testRequest setAutoRefresh:YES];
    [_testRequest setUserInfoGender:VpadnUserGenderMale];
    [_testRequest setUserInfoBirthdayWithYear:2000 month:8 day:17];
    [_testRequest setTagForMaxAdContentRating:VpadnMaxAdContentRatingParentalGuidance];
    [_testRequest setTagForUnderAgeOfConsent:VpadnTagForUnderAgeOfConsentNo];
    [_testRequest setTagForChildDirectedTreatment:VpadnTagForChildDirectedTreatmentNo];
}
    
- (void) request {
    [_testNative loadRequest:self.testRequest];
}

#pragma mark - VpadnNativeAd Delegate

- (void) onVpadnNativeAdLoaded:(VpadnNativeAd *)nativeAd {
    self.callBackInvoked = YES;
}

- (void) onVpadnNativeAd:(VpadnNativeAd *)nativeAd failedToLoad:(NSError *)error {
    self.callBackInvoked = YES;
    self.failLoadedInvoked = YES;
}

@end
