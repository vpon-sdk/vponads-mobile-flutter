//
//  VpadnAdVaildTests.m
//  VpadnSDKAdKitTests
//
//  Created by Yi-Hsiang, Chien on 2020/4/6.
//  Copyright © 2020 com.vpon. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "VpadnAdVaildViewModel.h"

@interface VpadnAdVaildTests : XCTestCase

@end

@implementation VpadnAdVaildTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void) testFormatURL {
    NSString *value = nil;
    NSString *expected = @"";
    XCTAssertTrue([[VpadnAdVaildViewModel formatUrl:value] isEqualToString:expected], "FormatURL test1 have error.");
    
    value = @"";
    expected = @"";
    XCTAssertTrue([[VpadnAdVaildViewModel formatUrl:value] isEqualToString:expected], "FormatURL test2 have error.");
    
    value = @"https://tw-api.vpon.com/api/webviewAdReq?sdk={vpadn-sdk-i-v5.0.4}";
    expected = @"https://tw-api.vpon.com/api/webviewAdReq?sdk=vpadn-sdk-i-v5.0.4";
    XCTAssertTrue([[VpadnAdVaildViewModel formatUrl:value] isEqualToString:expected], "FormatURL test3 have error.");
}

- (void) testFormatPhoneNumber {
    NSString *value = nil;
    XCTAssertNil([VpadnAdVaildViewModel formatPhoneNumber:value], "FormatPhoneNumber test1 have error.");
    
    value = @"";
    NSString *expected = @"";
    XCTAssertTrue([[VpadnAdVaildViewModel formatPhoneNumber:value] isEqualToString:expected], "FormatPhoneNumber test2 have error.");
    
    value = @"+886-02-77308328";
    expected = @"8860277308328";
    XCTAssertTrue([[VpadnAdVaildViewModel formatPhoneNumber:value] isEqualToString:expected], "FormatPhoneNumber test3 have error.");
    
    value = @"(02)7730-8328#102";
    expected = @"0277308328#102";
    XCTAssertTrue([[VpadnAdVaildViewModel formatPhoneNumber:value] isEqualToString:expected], "FormatPhoneNumber test4 have error.");
    
    value = @"(02) 7730 8328#102";
    expected = @"0277308328#102";
    XCTAssertTrue([[VpadnAdVaildViewModel formatPhoneNumber:value] isEqualToString:expected], "FormatPhoneNumber test5 have error.");
}

- (void) testIsDicVaild {
    NSDictionary *checked = nil;
    XCTAssertFalse([VpadnAdVaildViewModel isDicVaild:checked], "IsDicVaild test1 have error");
    
    checked = @[];
    XCTAssertFalse([VpadnAdVaildViewModel isDicVaild:checked], "IsDicVaild test2 have error");
    
    checked = @{
        @"key1": @"value1"
    };
    XCTAssertTrue([VpadnAdVaildViewModel isDicVaild:checked], "IsDicVaild test3 have error");
    
    checked = @{
        @"key1": @"value1",
        @"key2": @(2),
        @"key3": @[]
    };
    XCTAssertTrue([VpadnAdVaildViewModel isDicVaild:checked], "IsDicVaild test4 have error");
}

- (void) testIsDicVaildAndDefaultDic {
    NSDictionary *checked = nil;
    NSDictionary *defaulted = @{};
    NSDictionary *expected = @{};
    XCTAssertEqualObjects([VpadnAdVaildViewModel isDicVaild:checked defaultDic:defaulted], expected, "IsDicVaildAndDefaultDic test1 have error");
    
    checked = @[];
    defaulted = @{
        @"key1": @"value1"
    };
    expected = @{
        @"key1": @"value1"
    };
    XCTAssertEqualObjects([VpadnAdVaildViewModel isDicVaild:checked defaultDic:defaulted], expected, "IsDicVaildAndDefaultDic test2 have error");
}

- (void) testIsArrVaild {
    NSArray *checked = nil;
    XCTAssertFalse([VpadnAdVaildViewModel isArrVaild:checked], "IsArrVaild test1 have error");
    
    checked = @{};
    XCTAssertFalse([VpadnAdVaildViewModel isArrVaild:checked], "IsArrVaild test2 have error");
    
    checked = @[
        @"value1"
    ];
    XCTAssertTrue([VpadnAdVaildViewModel isArrVaild:checked], "IsArrVaild test3 have error");
    
    checked = @[
        @"value1",
        @(2),
        @{}
    ];
    XCTAssertTrue([VpadnAdVaildViewModel isArrVaild:checked], "IsArrVaild test4 have error");
}

- (void) testIsArrVaildAndDefaultArray {
    NSArray *checked = nil;
    NSArray *defaulted = @[];
    NSArray *expected = @[];
    XCTAssertEqualObjects([VpadnAdVaildViewModel isArrVaild:checked defaultArray:defaulted], expected, "IsArrVaildAndDefaultArray test1 have error");
    
    checked = @{};
    defaulted = @[
        @"value1",
        @(2),
        @{}
    ];
    expected = @[
        @"value1",
        @(2),
        @{}
    ];
    XCTAssertEqualObjects([VpadnAdVaildViewModel isArrVaild:checked defaultArray:defaulted], expected, "IsArrVaildAndDefaultArray test2 have error");
}

- (void) testIsStrVaild {
    NSString *checked = nil;
    XCTAssertFalse([VpadnAdVaildViewModel isStrVaild:checked], "IsStrVaild test1 have error");
    
    checked = @{};
    XCTAssertFalse([VpadnAdVaildViewModel isStrVaild:checked], "IsStrVaild test2 have error");
    
    checked = @"test";
    XCTAssertTrue([VpadnAdVaildViewModel isStrVaild:checked], "IsStrVaild test3 have error");
}

- (void)testIsStrVaildAndDefaultStr {
    NSString *checked = nil;
    NSString *defaulted = @"";
    NSString *expected = @"";
    XCTAssertEqual([VpadnAdVaildViewModel isStrVaild:checked defaultString:defaulted], expected, "IsStrVaildAndDefaultStr test1 have error");
    
    checked = @{};
    defaulted = @"";
    expected = @"";
    XCTAssertEqual([VpadnAdVaildViewModel isStrVaild:checked defaultString:defaulted], expected, "IsStrVaildAndDefaultStr test2 have error");
}

- (void)testIsURLVaild {
    NSURL *checked = nil;
    XCTAssertFalse([VpadnAdVaildViewModel isURLVaild:checked], "IsURLVaild test1 have error");
    
    checked = @"https://tw-api.vpon.com/api/webviewAdReq?sdk=vpadn-sdk-i-v5.0.4";
    XCTAssertFalse([VpadnAdVaildViewModel isURLVaild:checked], "IsURLVaild test2 have error");
}

- (void)testIsDicContains {
    NSDictionary *checked = nil;
    NSString *searchedKey = @"key1";
    XCTAssertFalse([VpadnAdVaildViewModel isDic:checked contain:searchedKey], "IsDicContains test1 have error");
    
    checked = @{
        searchedKey: @"value1",
        @"bool": @(YES),
        @"float": @(1.5),
        @"int": @(1),
    };
    XCTAssertTrue([VpadnAdVaildViewModel isDic:checked contain:searchedKey], "IsDicContains test2 have error");
}

- (void)testGetDicArguments {
    NSDictionary *checked = nil;
    XCTAssertNotNil([VpadnAdVaildViewModel args:checked urlByKey:@"url"], "GetDicArguments test1 have error");
    XCTAssertNotNil([VpadnAdVaildViewModel args:checked arrayByKey:@"array"], "GetDicArguments test2 have error");
    XCTAssertNotNil([VpadnAdVaildViewModel args:checked dictionaryByKey:@"dictionary"], "GetDicArguments test3 have error");
    XCTAssertNil([VpadnAdVaildViewModel args:checked stringByKey:@"string"], "GetDicArguments test4 have error");
    XCTAssertEqual([VpadnAdVaildViewModel args:checked boolByKey:@"bool"], NO, "GetDicArguments test5 have error");
    XCTAssertEqual([VpadnAdVaildViewModel args:checked floatByKey:@"float"], 0, "GetDicArguments test6 have error");
    XCTAssertEqual([VpadnAdVaildViewModel args:checked integerByKey:@"int"], 0, "GetDicArguments test7 have error");
    
    checked = @{
        @"array": @[],
        @"dictionary": @{},
        @"string": @"test",
        @"bool": @(YES),
        @"float": @(1.5),
        @"int": @(1),
    };
    
    XCTAssertEqualObjects([VpadnAdVaildViewModel args:checked arrayByKey:@"array"], @[], "GetDicArguments2 test1 have error");
    XCTAssertEqualObjects([VpadnAdVaildViewModel args:checked dictionaryByKey:@"dictionary"], @{}, "GetDicArguments2 test2 have error");
    XCTAssertEqual([VpadnAdVaildViewModel args:checked stringByKey:@"string"], @"test", "GetDicArguments2 test3 have error");
    XCTAssertEqual([VpadnAdVaildViewModel args:checked boolByKey:@"bool"], YES, "GetDicArguments2 test4 have error");
    XCTAssertEqual([VpadnAdVaildViewModel args:checked floatByKey:@"float"], 1.5, "GetDicArguments2 test5 have error");
    XCTAssertEqual([VpadnAdVaildViewModel args:checked integerByKey:@"int"], 1, "GetDicArguments2 test6 have error");
    
    checked = @{
        @"array": @{},
        @"dictionary": @[],
        @"string": @[],
        @"bool": @"",
        @"float": @"",
        @"int": @"",
    };
    
    XCTAssertEqualObjects([VpadnAdVaildViewModel args:checked arrayByKey:@"array"], @[], "GetDicArguments3 test1 have error");
    XCTAssertEqualObjects([VpadnAdVaildViewModel args:checked dictionaryByKey:@"dictionary"], @{}, "GetDicArguments3 test2 have error");
    XCTAssertEqual([VpadnAdVaildViewModel args:checked stringByKey:@"string" defaultValue:@"test"], @"test", "GetDicArguments3 test3 have error");
    XCTAssertEqual([VpadnAdVaildViewModel args:checked boolByKey:@"bool" defaultValue:NO], NO, "GetDicArguments3 test4 have error");
    XCTAssertEqual([VpadnAdVaildViewModel args:checked floatByKey:@"float" defaultValue:1.5], 0, "GetDicArguments3 test5 have error");
    XCTAssertEqual([VpadnAdVaildViewModel args:checked integerByKey:@"int" defaultValue:1], 0, "GetDicArguments3 test6 have error");
}

@end
