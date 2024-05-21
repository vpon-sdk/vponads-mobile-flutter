//
//  VpadnAdBannerTests.m
//  VpadnSDKAdKitTests
//
//  Created by Yi-Hsiang, Chien on 2020/3/27.
//  Copyright © 2020 com.vpon. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AdSupport/AdSupport.h>
#import "../VpadnSDKAdKit/VpadnSDKAdKit.h"
#import <VpadnSDKAdKit/VpadnSDKAdKit-Swift.h>

@interface VpadnAdBannerTests : XCTestCase <VpadnBannerDelegate>

@property (nonatomic, strong) VpadnBanner *testBanner;

@property (nonatomic, strong) VpadnAdRequest *testRequest;

@property (nonatomic, assign) BOOL callBackInvoked;

@property (nonatomic, assign) BOOL failLoadedInvoked;

@end

@implementation VpadnAdBannerTests

- (void)setUp {
    [super setUp];
    [self initConfig];
    [self initRequest];
    [self initBanner];
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

- (void) testBannerNotNil {
    [self initBanner];
    XCTAssertNotNil(_testBanner, "VpadnBanner object is nil");
}

- (void) testBannerCallBackNotInvokedAndResponse {
    [self request];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:5.0]];
    XCTAssertTrue(self.callBackInvoked, "Banner call back not invoked");
}

#pragma mark - Initial

- (void) initBanner {
    _testBanner = [[VpadnBanner alloc] initWithLicenseKey:@"8a808182447617bf0144d414ff2a3db1" adSize:[VpadnAdSize banner]];
    _testBanner.delegate = self;
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
    [_testRequest setTagForMaxAdContentRating:VpadnMaxAdContentRatingParentalGuidance];
    [_testRequest setTagForUnderAgeOfConsent:VpadnTagForUnderAgeOfConsentNo];
    [_testRequest setTagForChildDirectedTreatment:VpadnTagForChildDirectedTreatmentNo];
}

- (void) request {
    [_testBanner loadRequest:self.testRequest];
}

#pragma mark - VpadnBanner Delegate

- (void) onVpadnAdLoaded:(VpadnBanner *)banner {
    self.callBackInvoked = YES;
}

- (void) onVpadnAd:(VpadnBanner *)banner failedToLoad:(NSError *)error {
    self.callBackInvoked = YES;
    self.failLoadedInvoked = YES;
}

@end
