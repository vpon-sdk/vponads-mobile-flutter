//
//  VpadnAdMIConfig.h
//  vpon-sdk
//
//  Created by EricChien on 2019/4/10.
//  Copyright © 2019 com.vpon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../ViewModels/VpadnAdSdkViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface VpadnAdMIConfig : NSObject

/**
 關閉按鈕延遲時間
 */
@property (nonatomic, assign) NSInteger close_button_delay;

/**
 CLOSE BUTTON 大小
 */
@property (nonatomic, assign) VpadnCloseButton close_button_Size;

/**
 是否出現轉圈特效
 */
@property (nonatomic, assign) BOOL show_progress_wheel;

/**
 是否擷取當前Pub頁面
 */
@property (nonatomic, assign) BOOL set_screenshot;

/**
 擷取圖片上傳係數
 */
@property (nonatomic, assign) NSInteger ios_compress_screenshot;

/**
 擷取圖片黑名單
 */
@property (nonatomic, copy) NSArray *screenshot_forbidden_list;

- (id) initWithHtml:(NSString *)html cd:(NSInteger)cd;

- (id) initWithHtml:(NSString *)html;

- (BOOL) needShowWheel;

- (BOOL) needScreenShot;

@end

NS_ASSUME_NONNULL_END
