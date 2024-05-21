//
//  VpadnAdResponseTests.m
//  VpadnSDKAdKitTests
//
//  Created by Yi-Hsiang, Chien on 2020/4/6.
//  Copyright © 2020 com.vpon. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "VpadnAdResponse.h"

@interface VpadnAdResponseTests : XCTestCase

@property (nonatomic, strong) NSURL *url;

@end

@implementation VpadnAdResponseTests

- (void)setUp {
    [super setUp];
    
    _url = [NSURL URLWithString:@"https://tw-api.vpon.com/api/webviewAdReq?sdk=vpadn-sdk-i-v5.0.4&cdt=1&lang=en&uac=1&af=7&app_name=16091.iphone.com.apple.dt.xctest.tool&u_sd=3&i_o=0&s_h=812&dev_fname=x86_64&macr=1&track=1&sid=1586143616&s_w=375&build=20200401&os_v=13.4&format=320x50_mb&adtest=1&seq=0&ms=397XXx7%2F404Qdmqm9IXkl5N1tfktLLt51hW8zYAGsWhRDFueppUJObe%2BHfIllf4Ay543yhAkWqRyX4cV5whYub5msUotE3PjDCSm66S%2BL1Zn4nJILDFP9I%2Bi6fSeqCzALcjhO3WhEQKusFqbHAA7D1PsD9yCaksqTDMBuqoT%2BwBeO8IZ5cXh2T05RZPJ9zXI&cap=m2_a_vid_vid2_vid3_vid4_vid5_crazyAd_stoPic_exp_inv&ni=0&u_o=0&bid=8a808182447617bf0144d414ff2a3db1"];
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void) testResponseFail {
    NSDictionary *headers = @{};
    NSHTTPURLResponse *test = [[NSHTTPURLResponse alloc] initWithURL:_url
                                                          statusCode:200
                                                         HTTPVersion:@""
                                                        headerFields:headers];
    VpadnAdResponse *response = [[VpadnAdResponse alloc] initWithResponse:test];
    XCTAssertNotNil(response, "VpadnAdResponse object is nil");
    XCTAssertFalse(response.isVaild);
}

- (void) testResponseSuccess {
    NSDictionary *headers = @{
        @"Location": @"https://m.vpon.com/tpl/vpadn-tpl.html?t=ban_img&a=1&lnk=http%3A%2F%2Fwww.vpon.com&u_w=320&u_h=50&r=TW&img_1=https%3A%2F%2Ftw-img.vpon.com%2Fimg%2Ftestadnew%2F320-50.gif&img_2=https%3A%2F%2Ftw-img.vpon.com%2Fimg%2Ftestadnew%2F640-100.gif&om=%7B%22t%22%3A%22d%22%2C%22v%22%3A%5B%7B%22k%22%3A%22%22%2C%22u%22%3A%5B%22https%3A%2F%2Ftw-img.vpon.com%2Fimg%2Ftest%2Fmi%2Fomlog%2Fomid-validation-verification-script-v1.js%22%5D%2C%22p%22%3A%22%22%7D%5D%7D&u_lat=24.146896362304688&u_lon=120.68389892578125&u_sd=3.0&sdk=vpadn-sdk-i-v5.0.4&u_precision=&o_s_w=375&o_s_h=812",
        @"Vpadn-Imp": @"https://tw-api.vpon.com/api/webviewAdImp/?d=ZjKqH%2FjCPyvcbWpta1vhmn0KTRvui7YwBqeLMIAEpr1FQlgnkJ0OCUrVGftPvyYqyPoYMAk7%2FujXPFfY2TmdwhOFICOHmrQw7my8WjRDGb1OHMXCjNkzTF2x4NdDDw3RV0xd3Xv4%2FgIzNVqLWiZVJ3M6xPXPMOKL9pyN2iTCyNbfdbf7hWdwPwNt%2Ff4csM0yOnSMLfaRzgju5vX5wOzCzR9ILiHMqVOtHixPI1gWwpvn9OGmb4En5L6QYRSuZq7b9QMNY5sC5dU3ICl8HyY33RKkhbHltASUf%2BmgJgODbPeuuuYLBQwUDANHrweCxAV0Ig3JPYezNVogS9OUM9rl7oVWb4ZQlwPJdTRLrpSO9D7zTLqGvu8wrgqeRnyqW1OKHl%2FxQSCtov2Z1pugVGZeFIFGL7t%2FAFhoZDmc5x4NO5pkkZVcqOTTfMowfsOkwe0pVINNZI9qishHZEU6%2BBayEA%3D%3D",
        @"Vpadn-Refresh-Time": @"45",
        @"Vpadn-Status-Code": @"0",
    };
    NSHTTPURLResponse *test = [[NSHTTPURLResponse alloc] initWithURL:_url
                                                          statusCode:302
                                                         HTTPVersion:nil
                                                        headerFields:headers];
    VpadnAdResponse *response = [[VpadnAdResponse alloc] initWithResponse:test];
    XCTAssertNotNil(response, "VpadnAdResponse object is nil.");
    XCTAssertTrue(response.isVaild, "VpadnAdResponse is invaild.");
}

@end
