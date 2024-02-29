//
//  AdRequestable.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/2.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

protocol AdRequestable {
    var requestHelper: AdRequestHelper? { get }
}
