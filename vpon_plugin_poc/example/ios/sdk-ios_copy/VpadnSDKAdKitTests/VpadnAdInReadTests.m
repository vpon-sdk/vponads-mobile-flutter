//
//  VpadnAdInReadTests.m
//  VpadnSDKAdKitTests
//
//  Created by Yi-Hsiang, Chien on 2020/4/7.
//  Copyright © 2020 com.vpon. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AdSupport/AdSupport.h>
#import "../VpadnSDKAdKit/VpadnSDKAdKit.h"
#import <VpadnSDKAdKit/VpadnSDKAdKit-Swift.h>

//@interface VpadnAdInReadTests : XCTestCase <VpadnInReadAdDelegate>
//
//@property (nonatomic, strong) VpadnInReadAd *testInRead;
//
//@property (nonatomic, assign) BOOL callBackInvoked;
//
//@property (nonatomic, assign) BOOL failLoadedInvoked;
//
//
//
//@end
//
//@implementation VpadnAdInReadTests
//
//- (void)setUp {
//    [super setUp];
//    [self initConfig];
//    [self initInReadAd];
//}
//
//- (void)tearDown {
//    // Put teardown code here. This method is called after the invocation of each test method in the class.
//}
//
//- (void) testInReadAdNotNil {
//    [self initInReadAd];
//    XCTAssertNotNil(_testInRead, "VpadnInterstitial object is nil");
//}
//
//- (void) testInterstitialCallBackNotInvokedAndResponse {
//    [self request];
//    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:3.0]];
//    XCTAssertTrue(self.callBackInvoked, "Interstitial call back not invoked");
//}
//
//#pragma mark - Initial
//
//- (void) initInReadAd {
//    _testInRead = [[VpadnInReadAd alloc] initWithPlacementId:@"V215zE57559927l5B64" delegate:self];
//}
//
//- (void) initConfig {
//    VpadnAdConfiguration *config = VpadnAdConfiguration.shared;
//    config.logLevel = VpadnLogLevelDebug;
//    [config initializeSdk];
//        
//    _callBackInvoked = NO;
//    _failLoadedInvoked = NO;
//}
//    
//- (void) request {
//    [_testInRead loadAdWithTestIdentifiers:@[[ASIdentifierManager sharedManager].advertisingIdentifier.UUIDString]];
//}
//
//#pragma mark - VpadnInReadAd Delegate
//
//- (void) vpadnInReadAdDidLoad:(VpadnInReadAd *)ad {
//    self.callBackInvoked = YES;
//}
//
//- (void) vpadnInReadAd:(VpadnInReadAd *)ad didFailLoading:(NSError *)error {
//    self.callBackInvoked = YES;
//    self.failLoadedInvoked = YES;
//}
//
//
//@end
