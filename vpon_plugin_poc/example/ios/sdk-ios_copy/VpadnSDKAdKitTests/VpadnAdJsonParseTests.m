//
//  VpadnAdJsonParseTests.m
//  VpadnSDKAdKitTests
//
//  Created by Yi-Hsiang, Chien on 2020/4/7.
//  Copyright © 2020 com.vpon. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "VpadnAdJsonParseViewModel.h"

@interface VpadnAdJsonParseTests : XCTestCase

@end

@implementation VpadnAdJsonParseTests

- (void)setUp {
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testJsonToString {
    NSString *checked = @"{}";
    XCTAssertEqual([VpadnAdJsonParseViewModel jsonToString:checked], @"", "JsonToString test1 have error");
    
    checked = @"test";
    XCTAssertEqual([VpadnAdJsonParseViewModel jsonToString:checked], @"", "JsonToString test2 have error");
    
    checked = @"\"test\"";
    NSString *expected = @"test";
    XCTAssertTrue([[VpadnAdJsonParseViewModel jsonToString:checked] isEqualToString:expected], "JsonToString test3 have error");
}

- (void)testJsonToDictionary {
    NSString *checked = @"{}";
    XCTAssertEqual([VpadnAdJsonParseViewModel jsonToDictionary:checked], @{}, "JsonToDictionary test1 have error");
    
    checked = @"[]";
    XCTAssertEqual([VpadnAdJsonParseViewModel jsonToDictionary:checked], @{}, "JsonToDictionary test2 have error");
    
    checked = @"{\"key1\":\"value1\", \"key2\":[\"sub1\", \"sub2\"]}";
    NSDictionary *expected = @{
        @"key1": @"value1",
        @"key2": @[ @"sub1", @"sub2"]
    };
    XCTAssertEqualObjects([VpadnAdJsonParseViewModel jsonToDictionary:checked], expected, "JsonToDictionary test3 have error");
}

- (void)testJsonToArray {
    NSString *checked = @"[]";
    XCTAssertEqual([VpadnAdJsonParseViewModel jsonToArray:checked], @[], "JsonToArray test1 have error");
    
    checked = @"{}";
    XCTAssertEqual([VpadnAdJsonParseViewModel jsonToArray:checked], @[], "JsonToArray test2 have error");
    
    checked = @"[\"sub1\", {\"key1\":\"value1\"}]";
    NSArray *expected = @[ @"sub1", @{@"key1": @"value1"}];
    XCTAssertEqualObjects([VpadnAdJsonParseViewModel jsonToArray:checked], expected, "JsonToArray test3 have error");
}

@end
