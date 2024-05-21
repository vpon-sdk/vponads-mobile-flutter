//
//  VpadnAdInterstitialTests.m
//  VpadnSDKAdKitTests
//
//  Created by Yi-Hsiang, Chien on 2020/4/7.
//  Copyright © 2020 com.vpon. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AdSupport/AdSupport.h>
#import "../VpadnSDKAdKit/VpadnSDKAdKit.h"
#import <VpadnSDKAdKit/VpadnSDKAdKit-Swift.h>

@interface VpadnAdInterstitialTests : XCTestCase <VpadnInterstitialDelegate>

@property (nonatomic, strong) VpadnInterstitial *testInterstitial;

@property (nonatomic, strong) VpadnAdRequest *testRequest;

@property (nonatomic, assign) BOOL callBackInvoked;

@property (nonatomic, assign) BOOL failLoadedInvoked;

@end

@implementation VpadnAdInterstitialTests

- (void)setUp {
    [self initConfig];
    [self initRequest];
    [self initInterstitail];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testPerformanceExample {
        // This is an example of a performance test case.
    [self measureBlock:^{
            // Put the code you want to measure the time of here.
    }];
}

- (void) testRequestNotNil {
    [self initRequest];
    XCTAssertNotNil(_testRequest, "VpadnAdRequest object is nil");
}

- (void) testInterstitialNotNil {
    [self initInterstitail];
    XCTAssertNotNil(_testInterstitial, "VpadnInterstitial object is nil");
}

- (void) testInterstitialCallBackNotInvokedAndResponse {
    [self request];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:3.0]];
    XCTAssertTrue(self.callBackInvoked, "Interstitial call back not invoked");
}

#pragma mark - Initial

- (void) initInterstitail {
    _testInterstitial = [[VpadnInterstitial alloc] initWithLicenseKey:@"8a80854b668a2bb90166a05edc361843"];
    _testInterstitial.delegate = self;
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
    [_testInterstitial loadRequest:self.testRequest];
}

#pragma mark - VpadnInterstitial Delegate

- (void) onVpadnInterstitialLoaded:(VpadnInterstitial *)interstitial {
    self.callBackInvoked = YES;
}

- (void) onVpadnInterstitial:(VpadnInterstitial *)interstitial failedToLoad:(NSError *)error {
    self.callBackInvoked = YES;
    self.failLoadedInvoked = YES;
}

@end
