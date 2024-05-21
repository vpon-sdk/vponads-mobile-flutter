//
//  VpadnAdMIConfig.m
//  vpon-sdk
//
//  Created by EricChien on 2019/4/10.
//  Copyright © 2019 com.vpon. All rights reserved.
//

#import "VpadnAdMIConfig.h"

@implementation VpadnAdMIConfig

- (id) initWithHtml:(NSString *)html cd:(NSInteger)cd {
    self = [super init];
    if (self) {
        NSDictionary *data = [VpadnAdMIConfig parseHtmlMIConfig:html];
        
        _close_button_delay = [VpadnAdVaildViewModel args:data
                                             integerByKey:VMIKEY_CLOSE_BUTTON_DELAY
                                             defaultValue:cd] / 1000;
        
        NSString *close_size = [VpadnAdVaildViewModel args:data
                                               stringByKey:VMIKEY_CLOSE_BUTTON_SIZE
                                              defaultValue:VMIDEFAULT_CLOSE_BUTTON_SIZE_BIG];
        
        if ([close_size isEqualToString:VMIDEFAULT_CLOSE_BUTTON_SIZE_BIG]) {
            _close_button_Size = VpadnCloseButtonBig;
        } else {
            _close_button_Size = VpadnCloseButtonSmall;
        }
        
        if (_close_button_delay < 1 || _close_button_delay > 60) {
            _show_progress_wheel = NO;
        } else {
            _show_progress_wheel = [VpadnAdVaildViewModel args:data
                                                     boolByKey:VMIKEY_SHOW_PROGRESS_WHEEL
                                                  defaultValue:VMIDEFAULT_SHOW_PROGRESS_WHEEL];
        }
        
        _set_screenshot = [VpadnAdVaildViewModel args:data
                                            boolByKey:VMIKEY_SET_SCREENSHOT
                                         defaultValue:VMIDEFAULT_SET_SCREEN_SHOT];
        
        if (_set_screenshot) {
            _ios_compress_screenshot = [VpadnAdVaildViewModel args:data
                                                      integerByKey:VMIKEY_IOS_COMPRESS_SCREENSHOT
                                                      defaultValue:VMIDEFAULT_COMPRESS_SCREENSHOT];
            
            _screenshot_forbidden_list = [VpadnAdVaildViewModel args:data
                                                          arrayByKey:VMIKEY_SCREENSHOT_FORBIDDEN_LIST];
        }
    }
    return self;
}

- (id) initWithHtml:(NSString *)html {
    return [self initWithHtml:html cd:VMIDEFAULT_CLOSE_BUTTON_DELAY];
}

#pragma mark - Parse Method

+ (NSDictionary *)parseHtmlMIConfig:(NSString *)html {
    // parse MI_CONFIG
    
    NSMutableDictionary *miConfig = [[NSMutableDictionary alloc] init];
    
    NSRange startRange = [html rangeOfString:@"MI_CONFIG_START"];
    NSRange endRange = [html rangeOfString:@"MI_CONFIG_END"];
    
    if (startRange.location != NSNotFound && endRange.location != NSNotFound) {
        NSUInteger parseStartIndex = startRange.length + startRange.location + 1;
        NSUInteger parseEndIndex = endRange.location;
        
        NSString *parseJson = [[html substringWithRange:NSMakeRange(parseStartIndex, parseEndIndex - parseStartIndex)] stringByTrimmingCharactersInSet:[NSCharacterSet  whitespaceAndNewlineCharacterSet]];
        NSData *data = [parseJson dataUsingEncoding:NSUTF8StringEncoding];
        
        NSError * error = nil;
        id json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        if (json) {
            if ([json isKindOfClass:[NSDictionary class]]) {
                miConfig = [json mutableCopy];
            }
        }
    }
    [VpadnAdSdkViewModel log:VpadnFmt(@"MI Config Dictionary: \n%@", miConfig)];
    return miConfig;
}

- (BOOL) needShowWheel {
    return _show_progress_wheel;
}

- (BOOL) needScreenShot {
    return _set_screenshot;
}

@end
