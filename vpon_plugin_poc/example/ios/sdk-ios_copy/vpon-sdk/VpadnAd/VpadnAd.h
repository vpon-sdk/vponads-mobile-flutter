//
//  VpadnAd.h
//  XMLParser
//
//  Created by EricChien on 2018/5/22.
//  Copyright © 2018年 Soul. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class VpadnVideoAdView;
@class VpadnAd;

typedef enum VpadnAdType {
    VpadnAdTypeOfCustomAd,
    VpadnAdTypeOfInScroll,
    VpadnAdTypeOfInTable,
    VpadnAdTypeOfInTableRepeat,
    VpadnAdTypeOfInTableCustomAd
} VpadnAdType;


NS_ASSUME_NONNULL_BEGIN

@protocol VpadnAdDelegate <NSObject>

@optional

- (void)vpadnAd:(VpadnAd *)ad didFailLoading:(NSError *)error;

- (void)vpadnAdWillLoad:(VpadnAd *)ad;

- (void)vpadnAdDidLoad:(VpadnAd *)ad;

- (void)vpadnAdWillStart:(VpadnAd *)ad;

- (void)vpadnAdDidStart:(VpadnAd *)ad;

- (void)vpadnAdWillStop:(VpadnAd *)ad;

- (void)vpadnAdDidStop:(VpadnAd *)ad;

- (void)vpadnAdDidPause:(VpadnAd *)ad;

- (void)vpadnAdDidResume:(VpadnAd *)ad;

- (void)vpadnAdDidMute:(VpadnAd *)ad;

- (void)vpadnAdDidUnmute:(VpadnAd *)ad;

- (void)vpadnAdCanExpand:(VpadnAd *)ad withRatio:(CGFloat)ratio;

- (void)vpadnAdWillExpand:(VpadnAd *)ad;

- (void)vpadnAdDidExpand:(VpadnAd *)ad;

- (void)vpadnAdCanCollapse:(VpadnAd *)ad;

- (void)vpadnAdWillCollapse:(VpadnAd *)ad;

- (void)vpadnAdDidCollapse:(VpadnAd *)ad;

- (void)vpadnAdWasClicked:(VpadnAd *)ad;

- (void)vpadnAdDidClickBrowserClose:(VpadnAd *)ad;

- (void)vpadnAdWillTakeOverFullScreen:(VpadnAd *)ad;

- (void)vpadnAdDidTakeOverFullScreen:(VpadnAd *)ad;

- (void)vpadnAdWillDismissFullscreen:(VpadnAd *)ad;

- (void)vpadnAdDidDismissFullscreen:(VpadnAd *)ad;

- (void)vpadnAdSkipButtonTapped:(VpadnAd *)ad;

- (void)vpadnAdSkipButtonDidShow:(VpadnAd *)ad;

- (void)vpadnAdDidReset:(VpadnAd *)ad;

- (void)vpadnAdDidClean:(VpadnAd *)ad;

@end

NS_ASSUME_NONNULL_END

@interface VpadnAd : NSObject

/* interface type */
@property (nonatomic, assign) VpadnAdType vpadnAdType;

@property (nonatomic, assign) BOOL isLoaded;

@property (nonatomic, strong, nullable) NSIndexPath *indexPath;

@property (nonatomic, assign, nullable) id<VpadnAdDelegate> delegate;

- (void) dealloc;

#pragma mark - Custom Ad

- (id _Nonnull) initWithPlacementId:(nonnull NSString *)placementId delegate:(nullable id<VpadnAdDelegate>)delegate;

- (id _Nonnull) initWithPlacementId:(nonnull NSString *)placementId scrollView:(nonnull UIScrollView *)scrollView delegate:(nullable id<VpadnAdDelegate>)delegate;

#pragma mark - infeed

- (id _Nonnull) initWithPlacementId:(nonnull NSString *)placementId placeholder:(nonnull UIView *)placeHolder heightConstraint:(nonnull NSLayoutConstraint *)constraint scrollView:(nonnull UIScrollView *)scrollView delegate:(nullable id<VpadnAdDelegate>)delegate;

- (id _Nonnull) initWithPlacementId:(nonnull NSString *)placementId insertionIndexPath:(nonnull NSIndexPath *)indexPath tableView:(nonnull UITableView *)tableView delegate:(nullable id<VpadnAdDelegate>)delegate;

- (id _Nonnull) initWithPlacementId:(nonnull NSString *)placementId insertionIndexPath:(nonnull NSIndexPath *)indexPath repeatMode:(BOOL)repeat tableView:(nonnull UITableView *)tableView delegate:(nullable id<VpadnAdDelegate>)delegate;


#pragma mark - Common Method

- (void) loadAdWithTestIdentifiers:(NSArray *_Nullable)arrayTestIdentifiers;

#pragma mark - Methods for Custom Ad

- (UIView *_Nullable) videoView;

#pragma mark - Class Method

- (BOOL) isVideoAd:(NSIndexPath *)indexPath stride:(NSInteger)stride;

@end
