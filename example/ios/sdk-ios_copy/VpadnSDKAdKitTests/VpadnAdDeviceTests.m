//
//  VpadnAdDeviceTests.m
//  VpadnSDKAdKitTests
//
//  Created by Yi-Hsiang, Chien on 2020/4/6.
//  Copyright © 2020 com.vpon. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "VpadnAdDeviceViewModel.h"

@interface VpadnAdDeviceTests : XCTestCase

@property (nonatomic, strong) VpadnAdDeviceViewModel *device;

@end

@implementation VpadnAdDeviceTests

- (void)setUp {
    [super setUp];
    _device = [VpadnAdDeviceViewModel sharedInstance];
}

- (void)tearDown {
    [super tearDown];
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void) testScreenScale {
    float value = [[_device getScreenScale] floatValue];
    XCTAssertGreaterThan( value, 0, "Screen scale need greater than 0");
}

- (void) testNativeScale {
    float value = [[_device getNativeScale] floatValue];
    XCTAssertGreaterThan( value, 0, "Native scale need greater than 0");
}

- (void) testScreenWidth {
    float value = [[_device getScreenWidth] floatValue];
    XCTAssertGreaterThan( value, 0, "Screen width need greater than 0");
}

- (void) testScreenHeight {
    float value = [[_device getScreenHeight] floatValue];
    XCTAssertGreaterThan( value, 0, "Screen height need greater than 0");
}

- (void) testNativeWidth {
    float value = [[_device getNativeWidth] floatValue];
    XCTAssertGreaterThan( value, 0, "Native width need greater than 0");
}

- (void) testNativeHeight {
    float value = [[_device getNativeHeight] floatValue];
    XCTAssertGreaterThan( value, 0, "Native height need greater than 0");
}

@end
