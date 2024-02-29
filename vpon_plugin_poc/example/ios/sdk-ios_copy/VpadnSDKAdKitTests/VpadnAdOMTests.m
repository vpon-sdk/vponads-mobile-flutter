//
//  VpadnAdOMTests.m
//  VpadnSDKAdKitTests
//
//  Created by Yi-Hsiang, Chien on 2020/4/7.
//  Copyright © 2020 com.vpon. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "VpadnAdOMViewModel.h"

@interface VpadnAdOMTests : XCTestCase

@property (nonatomic, strong) VpadnAdOMViewModel *model;

@end

@implementation VpadnAdOMTests

- (void)setUp {
    [super setUp];
    [self initModel];
    [_model setupSession];
    [_model setupAdEvent];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testSetupSession {
//    [_model setupSession];
//    XCTAssertNotNil(_model.adSession, "AdSession object is nil");
}

- (void)testSetupAdEvent {
//    XCTAssertNotNil(_model.adEvents, "AdEvent object is nil");
}

//- (void)testParseVerifications {
//    XCTAssertNotNil(_model.adSession, "SetupSession object is nil");
//}

- (void) initModel {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake( 0, 0, 320, 480)];
//    _model = [[VpadnAdOMViewModel alloc] initWithType:VpadnOpenMeasureTypeForNative];
//    [_model omidJSService];
//    [_model setOmAdView:view];
    
}

@end
