//
//  VpadnAdCapabilityTests.m
//  VpadnSDKAdKitTests
//
//  Created by Yi-Hsiang, Chien on 2020/4/6.
//  Copyright © 2020 com.vpon. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "VpadnAdCapabilityViewModel.h"

@interface VpadnAdCapabilityTests : XCTestCase

@property (nonatomic, strong) VpadnAdCapabilityViewModel *cap;

@property (nonatomic, strong) NSArray *caps;

@end

@implementation VpadnAdCapabilityTests

- (void)setUp {
    [super setUp];
    _cap = [VpadnAdCapabilityViewModel sharedInstance];
    _caps = [_cap getCapabilities];
}

- (void)tearDown {
    [super tearDown];
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void) testCapabilityNotNil {
    XCTAssertNotNil(_caps, "Capability is nil.");
}

- (void) testSupportSMS {
    BOOL result = [_cap supportSMS];
    if (result) {
        XCTAssertTrue([_caps containsObject:@"sms"], "SMS support: yes, but caps no contains.");
    } else {
        XCTAssertFalse([_caps containsObject:@"sms"], "SMS support: no, but caps contains. ");
    }
}
 
/// 是否支援電話
- (void) testSupportTel {
    BOOL result = [_cap supportTel];
    if (result) {
        XCTAssertTrue([_caps containsObject:@"sms"], "Tel support: yes, but caps no contains.");
    } else {
        XCTAssertFalse([_caps containsObject:@"sms"], "Tel support: no, but caps contains. ");
    }
}

- (void) testSupportCamera {
    BOOL result = [_cap supportCamera];
    if (result) {
        XCTAssertTrue([_caps containsObject:@"cam"], "Camera support: yes, but caps no contains.");
    } else {
        XCTAssertFalse([_caps containsObject:@"cam"], "Camera support: no, but caps contains. ");
    }
}

- (void) testSupportCal {
    BOOL result = [_cap supportCal];
    if (result) {
        XCTAssertTrue([_caps containsObject:@"cal"], "Calendar support: yes, but caps no contains.");
    } else {
        XCTAssertFalse([_caps containsObject:@"cal"], "Calendar support: no, but caps contains. ");
    }
}

- (void) testSupportLocation {
    BOOL result = [_cap supportLocation];
    if (result) {
        XCTAssertTrue([_caps containsObject:@"locF"], "Location support: yes, but caps no contains.");
    } else {
        XCTAssertFalse([_caps containsObject:@"locF"], "Location support: no, but caps contains. ");
    }
}

- (void) testSupportPhotoUsage {
    BOOL result = [_cap supportPhotoUsage];
    if (result) {
        XCTAssertTrue([_caps containsObject:@"fr"], "Photo support: yes, but caps no contains.");
    } else {
        XCTAssertFalse([_caps containsObject:@"fr"], "Photo support: no, but caps contains. ");
    }
}

- (BOOL) supportPhotoAddUsage {
    BOOL result = [_cap supportPhotoAddUsage];
    if (result) {
        XCTAssertTrue([_caps containsObject:@"fw"], "AddPhoto support: yes, but caps no contains.");
    } else {
        XCTAssertFalse([_caps containsObject:@"fw"], "AddPhoto support: no, but caps contains. ");
    }
}

@end
