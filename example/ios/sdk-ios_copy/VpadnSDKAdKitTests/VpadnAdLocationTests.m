//
//  VpadnAdLocationTests.m
//  VpadnSDKAdKitTests
//
//  Created by Yi-Hsiang, Chien on 2020/4/7.
//  Copyright © 2020 com.vpon. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "VpadnAdLocationViewModel.h"

#define TestNeedsToWaitForBlock() __block BOOL blockFinished = NO
#define BlockFinished() blockFinished = YES
#define WaitForBlock() while (CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, true) && !blockFinished)

@interface VpadnAdLocationTests : XCTestCase

@property (nonatomic, strong) VpadnAdLocationViewModel *model;

@end

@implementation VpadnAdLocationTests

- (void)setUp {
    [super setUp];
    [self initModel];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testLocation {
    TestNeedsToWaitForBlock();
    [_model updateLocationWithSuccess:^(CLLocationManager * _Nonnull manager, NSInteger locAge) {
        XCTAssertNotNil(manager, "Location test1 have error");
        BlockFinished();
    } failure:^(NSError * _Nonnull error) {
        XCTAssertNotNil(error, "Location test2 have error");
        BlockFinished();
    }];
    WaitForBlock();
}

- (void)initModel {
    _model = [VpadnAdLocationViewModel sharedInstance];
}

@end
