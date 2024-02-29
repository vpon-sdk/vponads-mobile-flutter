//
//  VpadnAdReuqestTests.swift
//  VpadnSDKAdKitTests
//
//  Created by Judy Tsai on 2023/2/10.
//  Copyright © 2023 com.vpon. All rights reserved.
//

//import XCTest
//@testable import VpadnSDKAdKit
//
//final class VpadnAdReuqestTests: XCTestCase {
//
//    override func setUpWithError() throws {
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//    }
//
//    override func tearDownWithError() throws {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//    }
//
//    func test_AdRequestService_ShouldInitAdResponse() throws {
//        // Given
//        let requestURL = URL(string: "https://tw-api.vpadn.com/api/webviewAdReq?tz=GMT%2B8&sdk=vpadn-sdk-i-v5.4.4&lang=en&uac=-1&cdt=-1&af=7&app_name=3.iphone.com.vpon.tw.sdkv5&u_sd=3&s_h=844&dev_fname=arm64&macr=-1&u_cb=0&content_data=%7B%22uiTestTag%22%3A%22Static%C2%A0Native,%20In%20Scroll%22%7D&sid=1670840704&dev_man=Apple&s_w=390&adtest=0&dev_mod=iPhone&os_v=16.0&format=na&build=normal&seq=0&content_url=www.vpon.com&ms=397XXx7%2F404Qdmqm9IXkl5N1tfktLLt51hW8zYAGsWhRDFueppUJObe%2BHfIllf4Ay7g3R4TTgr%2BQROGm29MrQRNJU5tVTVhISx0FQLbG1eILkbeTUrztuRWdWFHuqHeyg1bJNpaLthqeD7HVYu1QpICOBbDxMmENev9%2FmtONtFjNK19Zfy7CoOjpiiKHCUWC4GEkDB9JKbugPIZlJ%2F05byhCMUnztXTI7lmLc8ATImWGVp2LTpPfu5e%2BEhBAVtixWOyaVS8M%2FGWVXl0%2F0XI8Ocq1p30PtmBX5wjUYdPZtYQ3al5SnZ8TJ%2FN%2F%2F3wad8Xu&ni=0&u_o=1&bid=8a80854b668a2bb90166a05efc8e1844")!
//        let sut = VpadnAdRequestAdService()
//        
//        // When
//        sut.request(with: requestURL) { data, request, response in
//            let adResponse = VpadnAdResponse(response: response)
//            // Then
//            XCTAssertNotNil(adResponse, "Can't init VpadnAdResponse.")
//        } failure: { error in
//            // Then
//            XCTAssertNil(error, "Error sending request with VpadnAdRequestAdService: \(error.localizedDescription)")
//        }
//    }
//    
//    func test_AdRequestService_AdResponseShouldBeValid() throws {
//        // Given
//        let requestURL = URL(string: "https://tw-api.vpadn.com/api/webviewAdReq?tz=GMT%2B8&sdk=vpadn-sdk-i-v5.4.4&lang=en&uac=-1&cdt=-1&af=7&app_name=3.iphone.com.vpon.tw.sdkv5&u_sd=3&s_h=844&dev_fname=arm64&macr=-1&u_cb=0&content_data=%7B%22uiTestTag%22%3A%22Static%C2%A0Native,%20In%20Scroll%22%7D&sid=1670840704&dev_man=Apple&s_w=390&adtest=0&dev_mod=iPhone&os_v=16.0&format=na&build=normal&seq=0&content_url=www.vpon.com&ms=397XXx7%2F404Qdmqm9IXkl5N1tfktLLt51hW8zYAGsWhRDFueppUJObe%2BHfIllf4Ay7g3R4TTgr%2BQROGm29MrQRNJU5tVTVhISx0FQLbG1eILkbeTUrztuRWdWFHuqHeyg1bJNpaLthqeD7HVYu1QpICOBbDxMmENev9%2FmtONtFjNK19Zfy7CoOjpiiKHCUWC4GEkDB9JKbugPIZlJ%2F05byhCMUnztXTI7lmLc8ATImWGVp2LTpPfu5e%2BEhBAVtixWOyaVS8M%2FGWVXl0%2F0XI8Ocq1p30PtmBX5wjUYdPZtYQ3al5SnZ8TJ%2FN%2F%2F3wad8Xu&ni=0&u_o=1&bid=8a80854b668a2bb90166a05efc8e1844")!
//        let sut = VpadnAdRequestAdService()
//        
//        // When
//        sut.request(with: requestURL) { data, request, response in
//            let adResponse = VpadnAdResponse(response: response)
//            
//            // Then
//            XCTAssertTrue(adResponse.isVaild, "Invalid ad response!")
//        } failure: { error in
//            // Then
//            XCTAssertNil(error, "Error sending request with VpadnAdRequestAdService: \(error.localizedDescription)")
//        }
//    }
//
//
//
//}
