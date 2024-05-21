//
//  VpadnNativeAd+Internal.h
//  vpon-sdk
//
//  Created by Vpon on 10/6/16.
//  Copyright © 2016 Vpon. All rights reserved.
//

@class VponNativeViewController;

@interface VpadnNativeAd (Internal)

/// Branding 圖片
@property (nonatomic, strong) VpadnAdImage *icon;

/// Campaign 圖片
@property (nonatomic, strong) VpadnAdImage *coverImage;

/// 星數得分
@property (nonatomic, assign) CGFloat ratingValue;

/// 星數範圍
@property (nonatomic, assign) NSInteger ratingScale;

/// 主標題
@property (nonatomic, copy) NSString *title;

/// 內文
@property (nonatomic, copy) NSString *body;

/// 點擊鈕文案
@property (nonatomic, copy) NSString *callToAction;

/// 副標題
@property (nonatomic, copy) NSString *socialContext;

/// 內部info
@property (nonatomic, copy) NSString *e;

/// video tracking
@property (nonatomic, copy) NSString *tid;

/// UID
@property (nonatomic, copy) NSString *uid;

/// AD
@property (nonatomic, copy) NSString *ad;

/// All Properties
@property (nonatomic, strong) NSMutableDictionary *properties;

@property (nonatomic, strong) VponNativeViewController *nativeViewController;

#pragma Fake UUID
- (void)setUseFakeUUID:(BOOL)bSetEnforceUseFakeUUID;
- (void)setFakeUUID:(NSString*)strTargetFakeUUID;
- (BOOL)getUseFakeUUID;

#pragma Extra data
- (void)addPublisherExtraData:(NSString*)strKey withValue:(NSString*)strValue;

@end
