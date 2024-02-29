//
//  VpadnAdExpandViewController.h
//  vpon-sdk
//
//  Created by Yi-Hsiang, Chien on 2019/12/11.
//  Copyright © 2019 com.vpon. All rights reserved.
//

#import "VpadnAdInterstitialViewController.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^WillPresent) (void);
typedef void(^DidDismiss) (void);

@interface VpadnAdExpandViewController : VpadnAdInterstitialViewController

@end

NS_ASSUME_NONNULL_END
