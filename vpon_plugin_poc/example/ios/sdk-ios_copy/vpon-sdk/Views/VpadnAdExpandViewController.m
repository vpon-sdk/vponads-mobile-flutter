//
//  VpadnAdExpandViewController.m
//  vpon-sdk
//
//  Created by Yi-Hsiang, Chien on 2019/12/11.
//  Copyright © 2019 com.vpon. All rights reserved.
//

#import "VpadnAdExpandViewController.h"

@interface VpadnAdExpandViewController ()

/**
 present block
 */
@property (nonatomic, strong) WillPresent presentCallBack;

/**
 dismiss block
 */
@property (nonatomic, strong) DidDismiss dismissCallBack;

@end

@implementation VpadnAdExpandViewController

+ (void) presentWithScheme:(VpadnAdScheme *)scheme
             rootViewCtrl:(UIViewController *)rootViewCtrl
              willPresent:(WillPresent)willPresent
               didDismiss:(DidDismiss)didDismiss {
    
//    VpadnAdExpandViewController *expand =
//
//    [rootViewCtrl presentViewController:expand animated:YES completion:^{
//
//    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
