//
//  VpadnAd.m
//  XMLParser
//
//  Created by EricChien on 2018/5/22.
//  Copyright © 2018年 Soul. All rights reserved.
//

#import "VpadnAd.h"
#import "VponAdManager.h"
#import "VpadnVideoAdView.h"
#import "VpadnCoveredDetector.h"
#import "VpadnAdImageBytes.h"
#import "VpadnVideoAdTabCell.h"
#import "VpadnAdParams.h"
#import <AdSupport/AdSupport.h>

@interface VpadnAd () <NSURLSessionDelegate, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, VpadnVideoAdViewDelegate, VpadnAdDelegate>

/* placementId */
@property (nonatomic, copy) NSString *pid;
@property (nonatomic, strong) UIImageView *adImageView;

/*
 loadedScroll:要置入廣告的ScrollView
 placeHolder:廣告要新增在哪個View上
 heightConstraint:用來調整廣告高度的Constraint
 */
@property (nonatomic, weak) UIView *placeHolder;
@property (nonatomic, weak) UIScrollView *loadedScroll;
@property (nonatomic, weak) NSLayoutConstraint *heightConstraint;
@property (nonatomic, weak) NSLayoutConstraint *ratioConstraint;

/*
 loadedTable:要置入廣告的TableView
 startIndexPath:廣告要從哪個NSIndexPath開始加入
 placementRepeat:是否要重複加入
 rowStride:重複的間距
 */
@property (nonatomic, weak) UITableView *loadedTable;
@property (nonatomic, strong) NSMutableArray *vpadnAds;
@property (nonatomic, weak) NSIndexPath *startIndexPath;
@property (nonatomic, assign) BOOL placementRepeat;
@property (nonatomic, strong) NSArray *adIndexPaths;
@property (nonatomic, assign) NSInteger rowStride;

@property (nonatomic, strong) NSArray *hConstraints;
@property (nonatomic, strong) NSArray *vConstraints;

@property (nonatomic, strong) NSMutableArray *vpadnAdCells;
@property (nonatomic, weak) id targetDelegate;
@property (nonatomic, weak) id targetDataSource;


/* 遮蔽偵測Timer */
@property (nonatomic, weak) NSTimer *coverTimer;

/* 廣告View */
@property (nonatomic, strong) UIView *returnView;
@property (nonatomic, strong) VpadnVideoAdView *videoAdView;

/* 是否拉取測試廣告 */
@property (nonatomic, assign) BOOL bIsTestMode;

/* 是否Request過 */
@property (nonatomic, assign) BOOL bIsAlreadyRequest;

/* 取得到廣告的Flag。 */
@property (assign, nonatomic) BOOL bIsAdRequest;

@property (nonatomic, copy) NSArray *arrayTestIdentifiers;

@end

@implementation VpadnAd

@synthesize pid = _pid;

#pragma mark - Custom Ad

- (id _Nonnull) initWithPlacementId:(nonnull NSString *)placementId delegate:(nullable id<VpadnAdDelegate>)delegate {
    self = [self init];
    if (self) {
        _vpadnAdType = VpadnAdTypeOfCustomAd;
        _pid = placementId;
        _delegate = delegate;
        _bIsAlreadyRequest = NO;
        _videoAdView = [[VpadnVideoAdView alloc] init];
        _videoAdView.n_delegate = self;
    }
    return self;
}

- (id _Nonnull) initWithPlacementId:(nonnull NSString *)placementId scrollView:(nonnull UIScrollView *)scrollView delegate:(nullable id<VpadnAdDelegate>)delegate {
    self = [self initWithPlacementId:placementId delegate:delegate];
    if (self) {
        _loadedScroll = scrollView;
        if (_loadedScroll.delegate) _targetDelegate = _loadedScroll.delegate;
    }
    return self;
}

- (id _Nonnull) initWithPlacementId:(nonnull NSString *)placementId placeholder:(nonnull UIView *)placeHolder heightConstraint:(nonnull NSLayoutConstraint *)constraint scrollView:(nonnull UIScrollView *)scrollView delegate:(nullable id<VpadnAdDelegate>)delegate {
    self = [self initWithPlacementId:placementId scrollView:scrollView delegate:delegate];
    if (self) {
        _vpadnAdType = VpadnAdTypeOfInScroll;
        _placeHolder = placeHolder;
        _heightConstraint = constraint;
    }
    return self;
}

- (id _Nonnull) initWithPlacementId:(nonnull NSString *)placementId insertionIndexPath:(nonnull NSIndexPath *)indexPath tableView:(nonnull UITableView *)tableView delegate:(nullable id<VpadnAdDelegate>)delegate {
    self = [self initWithPlacementId:placementId delegate:delegate];
    if (self) {
        _vpadnAdType = VpadnAdTypeOfInTable;
        _startIndexPath = indexPath;
        _adIndexPaths = @[indexPath];
        _placementRepeat = NO;
        _loadedTable = tableView;
        if (_loadedTable.delegate) _targetDelegate = _loadedTable.delegate;
        if (_loadedTable.dataSource) _targetDataSource = _loadedTable.dataSource;
    }
    return self;
}

- (id _Nonnull) initWithPlacementId:(nonnull NSString *)placementId insertionIndexPath:(nonnull NSIndexPath *)indexPath repeatMode:(BOOL)repeat tableView:(nonnull UITableView *)tableView delegate:(nullable id<VpadnAdDelegate>)delegate {
    self = [self initWithPlacementId:placementId insertionIndexPath:indexPath tableView:tableView delegate:delegate];
    if (self) {
        _vpadnAdCells = [[NSMutableArray alloc] init];
        _vpadnAds = [[NSMutableArray alloc] init];
        _placementRepeat = YES;
        _vpadnAdType = VpadnAdTypeOfInTableRepeat;
        _rowStride = indexPath.row;
    }
    return self;
}

#pragma mark - Common Method

- (void) loadAdWithTestIdentifiers:(NSArray *_Nullable)arrayTestIdentifiers {
    if (_bIsAlreadyRequest) {
        [VponAdManager showLog:@"Ad alreay request, please new one." level:VpadnLogTagOfError];
    } else if (_vpadnAdType == VpadnAdTypeOfInTableRepeat) {
        [VponAdManager showSdkLog];
        [self setArrayTestIdentifiers:arrayTestIdentifiers];
        [self checkTestMode];
        _loadedTable.dataSource = self;
        _loadedTable.delegate = self;
        [_loadedTable reloadData];
    } else {
        [VponAdManager showSdkLog];
        [self setArrayTestIdentifiers:arrayTestIdentifiers];
        [self checkTestMode];
        _bIsAlreadyRequest = YES;
        
        [VponAdManager showLog:VpadnFormat(@"Request Ad") level:VpadnLogTagOfNote];
        
        __block __weak VpadnAd *weakSelf = self;
        
        NSString *strURL = [[VpadnAdParams sharedInstance] genVastUrlWithExtrtnalData:@{ @"id":_pid}];
        NSURL *url = [NSURL URLWithString:strURL];
        
        [VponAdManager showLog:VpadnFormat(@"request Url:%@", strURL) level:VpadnLogTagOfDebug];
        
        [self connectToServerWithURL:url success:^(NSData * _Nullable data, NSURLResponse * _Nullable response) {
            NSError *error = nil;
            NSDictionary *coveredData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            
            NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [VponAdManager showLog:VpadnFormat(@"json string:%@", jsonString) level:VpadnLogTagOfDebug];
            
            if ([coveredData.allKeys containsObject:@"status"] && [coveredData[@"status"] isEqualToString:@"ok"]) {
                NSArray *ads = [[NSArray alloc] initWithArray:coveredData[@"ads"]];
                if (ads.count) {
                    NSDictionary *document = ads.firstObject;
                    [weakSelf readData:document[@"content"]];
                } else {
                    [weakSelf paserError];
                }
            } else {
                [weakSelf paserError];
            }
        } failure:^(NSError * _Nullable error) {
            [weakSelf paserError];
        }];
    }
}

- (void) paserError {
    if (_delegate && [_delegate respondsToSelector:@selector(vpadnAd:didFailLoading:)]) {
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:2 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Vast paser error fail", nil),
                                                                                     NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Vast paser error", nil),
                                                                                     NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Contact vpon fae", nil)}];
        [_delegate vpadnAd:self didFailLoading:error];
    }
}

- (void) readData:(NSString *)document {
    _videoAdView.document = document;
    if (_vpadnAdType == VpadnAdTypeOfInTableCustomAd) {
        _videoAdView.alwaysPass = YES;
    }
    [_videoAdView loadData];
    [VponAdManager showLog:document level:VpadnLogTagOfDebug];
}

- (void) connectToServerWithURL:(NSURL *)url  success:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response))success failure:(void(^)(NSError * _Nullable error))failure {
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
    [request addValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.87 Safari/537.36" forHTTPHeaderField:@"User-Agent"];
    [request setHTTPMethod:@"GET"];
    
    [VponAdManager showLog:VpadnFormat(@"Request:%@", request.allHTTPHeaderFields) level:VpadnLogTagOfDebug];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error == nil) {
            if (success) success(data, response);
        } else {
            if (failure) failure(error);
        }
    }];
    [task resume];
}

#pragma mark - Methods for Custom Ad

- (UIView *) addAdvertisement:(VpadnVideoAdView *_Nullable)videoView {
    if (_returnView != nil) {
        return _returnView;
    }
    
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor clearColor];
    view.clipsToBounds = YES;
    _returnView = view;
    
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.backgroundColor = [UIColor clearColor];
    NSData *imageData = [NSData dataWithBytes:(const void *)arrayAd length:sizeof(arrayAd)];
    imageView.image = [UIImage imageWithData:imageData];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:imageView];
    _adImageView = imageView;
    
    videoView.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:videoView];

    [imageView addConstraint:[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:imageView attribute:NSLayoutAttributeWidth multiplier:15.0/320.0 constant:0]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[imageView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(imageView)]];
    
    if (_vpadnAdType == VpadnAdTypeOfInScroll || _vpadnAdType == VpadnAdTypeOfInTable || _vpadnAdType == VpadnAdTypeOfInTableCustomAd) {
        [videoView addConstraint:[NSLayoutConstraint constraintWithItem:videoView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:videoView attribute:NSLayoutAttributeWidth multiplier:9.0/16.0 constant:0]];
    }
    
    [self addVideoViewConstraints];
    
//    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[videoView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(videoView)]];
//
//    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[imageView]-0-[videoView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(imageView, videoView)]];
    
    
    return _returnView;
}

- (UIView *_Nullable) videoView {
    return [self addAdvertisement:_videoAdView];
}

- (void) addVideoViewConstraints {
    if (_hConstraints != nil) {
        [_returnView removeConstraints:_hConstraints];
    }
    if (_vConstraints != nil) {
        [_returnView removeConstraints:_vConstraints];
    }
    
    _hConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_videoAdView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_videoAdView)];
    [_returnView addConstraints:_hConstraints];
    
    _vConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_adImageView]-0-[_videoAdView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_adImageView, _videoAdView)];
    [_returnView addConstraints:_vConstraints];
}

- (void) removeVideoViewConstraints {
    if (_hConstraints != nil) {
        [_returnView removeConstraints:_hConstraints];
    }
    if (_vConstraints != nil) {
        [_returnView removeConstraints:_vConstraints];
    }
    
    _vConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_adImageView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_adImageView)];
    [_returnView addConstraints:_vConstraints];
}

- (void) addConstraintToVideoView:(UIView *_Nullable)videoView width:(float)width {
    videoView.translatesAutoresizingMaskIntoConstraints = NO;
    float height = width * 195/320;
    _heightConstraint.constant = height;
    
    [videoView.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[videoView]-0-|"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:NSDictionaryOfVariableBindings(videoView)]];
    [videoView.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[videoView]-0-|"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:NSDictionaryOfVariableBindings(videoView)]];
}

#pragma mark 檢查是否為測試手機

- (void) checkTestMode {
    _bIsTestMode = NO;
    NSString* strSelfIdentifier = [VponAdManager sharedInstance].imei;
    for (NSString* strIdentifier in _arrayTestIdentifiers) {
        if ([strIdentifier isEqualToString:strSelfIdentifier]) {
            _bIsTestMode = YES;
            break;
        }
    }
}

- (void)setArrayTestIdentifiers:(NSArray *)arrayTestIdentifiers {
    _arrayTestIdentifiers = [arrayTestIdentifiers copy];
}

#pragma mark -

- (void) dealloc {
    if (_vpadnAds.count) {
        for (VpadnAd *ad in _vpadnAds) {
            if (ad.delegate) {
                ad.delegate = nil;
            }
        }
    }
    
    if (_videoAdView.n_delegate) {
        _videoAdView.n_delegate = nil;
    }
    
    if (_videoAdView.state == VpadnPlayerStatePlaying) {
        [_videoAdView releasePlayer];
    }
    
    if (_coverTimer != nil) {
        [_coverTimer invalidate];
        _coverTimer = nil;
    }

    if (_loadedTable != nil) {
        if (_targetDelegate != nil) {
            _loadedTable.delegate = _targetDelegate;
            _targetDelegate = nil;
        }
        if (_targetDataSource != nil) {
            _loadedTable.dataSource = _targetDataSource;
            _targetDataSource = nil;
        }
    }
    if (_loadedScroll != nil) {
        if (_targetDelegate != nil) {
            _loadedScroll.delegate = _targetDelegate;
            _targetDelegate = nil;
        }
    }
}

#pragma mark - VpadnVideoAdView Delegate

- (void)vpadnVideoAdViewDidLayoutSubviews:(VpadnVideoAdView *)adView {
    //VpadnLog(@"%s", __PRETTY_FUNCTION__);
    if (_vpadnAdType == VpadnAdTypeOfInScroll && adView.superview != nil) {
        _heightConstraint.constant = _placeHolder.frame.size.width * 195/320;
    }
    [self.videoView setNeedsLayout];
}

- (void)vpadnVideoAdView:(VpadnVideoAdView *)adView didFailLoading:(NSError *)error {
    //VpadnLog(@"%s", __PRETTY_FUNCTION__);
    if (_delegate && [_delegate respondsToSelector:@selector(vpadnAd:didFailLoading:)]) {
        [_delegate vpadnAd:self didFailLoading:error];
    }
}

- (void)vpadnVideoAdViewWillLoad:(VpadnVideoAdView *)adView {
    //VpadnLog(@"%s", __PRETTY_FUNCTION__);
    if (_delegate && [_delegate respondsToSelector:@selector(vpadnAdWillLoad:)]) {
        [_delegate vpadnAdWillLoad:self];
    }
}

- (void)vpadnVideoAdViewDidLoad:(VpadnVideoAdView *)adView {
    //VpadnLog(@"%s", __PRETTY_FUNCTION__);
    if (_vpadnAdType == VpadnAdTypeOfInScroll) {
        _loadedScroll.delegate = self;
        UIView *view = [self addAdvertisement:adView];
        [_placeHolder addSubview:view];
        [self addConstraintToVideoView:view width:_placeHolder.bounds.size.width];
    } else if (_vpadnAdType == VpadnAdTypeOfInTable) {
        _loadedTable.dataSource = self;
        _loadedTable.delegate = self;
        [_loadedTable reloadData];
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(vpadnAdDidLoad:)]) {
        [_delegate vpadnAdDidLoad:self];
    }
}

- (void)vpadnVideoAdViewWillStart:(VpadnVideoAdView *)adView {
    //VpadnLog(@"%s", __PRETTY_FUNCTION__);
    if (_delegate && [_delegate respondsToSelector:@selector(vpadnAdWillStart:)]) {
        [_delegate vpadnAdWillStart:self];
    }
}

- (void)vpadnVideoAdViewDidStart:(VpadnVideoAdView *)adView {
    //VpadnLog(@"%s", __PRETTY_FUNCTION__);
    if (_delegate && [_delegate respondsToSelector:@selector(vpadnAdDidStart:)]) {
        [_delegate vpadnAdDidStart:self];
    }
}

- (void)vpadnVideoAdViewWillStop:(VpadnVideoAdView *)adView {
    //VpadnLog(@"%s", __PRETTY_FUNCTION__);
    if (_delegate && [_delegate respondsToSelector:@selector(vpadnAdWillStop:)]) {
        [_delegate vpadnAdWillStop:self];
    }
}

- (void)vpadnVideoAdViewDidStop:(VpadnVideoAdView *)adView {
    //VpadnLog(@"%s", __PRETTY_FUNCTION__);
    if (_delegate && [_delegate respondsToSelector:@selector(vpadnAdDidStop:)]) {
        [_delegate vpadnAdDidStop:self];
    }
}

- (void)vpadnVideoAdViewDidPause:(VpadnVideoAdView *)adView {
    //VpadnLog(@"%s", __PRETTY_FUNCTION__);
    if (_delegate && [_delegate respondsToSelector:@selector(vpadnAdDidPause:)]) {
        [_delegate vpadnAdDidPause:self];
    }
}

- (void)vpadnVideoAdViewDidResume:(VpadnVideoAdView *)adView {
    //VpadnLog(@"%s", __PRETTY_FUNCTION__);
    if (_delegate && [_delegate respondsToSelector:@selector(vpadnAdDidResume:)]) {
        [_delegate vpadnAdDidResume:self];
    }
}

- (void)vpadnVideoAdViewDidMute:(VpadnVideoAdView *)adView {
    //VpadnLog(@"%s", __PRETTY_FUNCTION__);
    if (_delegate && [_delegate respondsToSelector:@selector(vpadnAdDidMute:)]) {
        [_delegate vpadnAdDidMute:self];
    }
}

- (void)vpadnVideoAdViewDidUnmute:(VpadnVideoAdView *)adView {
    //VpadnLog(@"%s", __PRETTY_FUNCTION__);
    if (_delegate && [_delegate respondsToSelector:@selector(vpadnAdDidUnmute:)]) {
        [_delegate vpadnAdDidUnmute:self];
    }
}

- (void)vpadnVideoAdViewCanExpand:(VpadnVideoAdView *)adView withRatio:(CGFloat)ratio {
    //VpadnLog(@"%s", __PRETTY_FUNCTION__);
    if (_delegate && [_delegate respondsToSelector:@selector(vpadnAdCanExpand:withRatio:)]) {
        [_delegate vpadnAdCanExpand:self withRatio:ratio];
    }
}

- (void)vpadnVideoAdViewWillExpand:(VpadnVideoAdView *)adView {
    //VpadnLog(@"%s", __PRETTY_FUNCTION__);
    if (_delegate && [_delegate respondsToSelector:@selector(vpadnAdWillExpand:)]) {
        [_delegate vpadnAdWillExpand:self];
    }
}

- (void)vpadnVideoAdViewDidExpand:(VpadnVideoAdView *)adView {
    //VpadnLog(@"%s", __PRETTY_FUNCTION__);
    if (_delegate && [_delegate respondsToSelector:@selector(vpadnAdDidExpand:)]) {
        [_delegate vpadnAdDidExpand:self];
    }
}

- (void)vpadnVideoAdViewCanCollapse:(VpadnVideoAdView *)adView {
    //VpadnLog(@"%s", __PRETTY_FUNCTION__);
    if (_delegate && [_delegate respondsToSelector:@selector(vpadnAdCanCollapse:)]) {
        [_delegate vpadnAdCanCollapse:self];
    }
}

- (void)vpadnVideoAdViewWillCollapse:(VpadnVideoAdView *)adView {
    //VpadnLog(@"%s", __PRETTY_FUNCTION__);
    if (_delegate && [_delegate respondsToSelector:@selector(vpadnAdWillCollapse:)]) {
        [_delegate vpadnAdWillCollapse:self];
    }
}

- (void)vpadnVideoAdViewDidCollapse:(VpadnVideoAdView *)adView {
    //VpadnLog(@"%s", __PRETTY_FUNCTION__);
    if (_delegate && [_delegate respondsToSelector:@selector(vpadnAdDidCollapse:)]) {
        [_delegate vpadnAdDidCollapse:self];
    }
}

- (void)vpadnVideoAdViewWasClicked:(VpadnVideoAdView *)adView {
    //VpadnLog(@"%s", __PRETTY_FUNCTION__);
    if (_delegate && [_delegate respondsToSelector:@selector(vpadnAdWasClicked:)]) {
        [_delegate vpadnAdWasClicked:self];
    }
}

- (void)vpadnVideoAdViewDidClickBrowserClose:(VpadnVideoAdView *)adView {
    //VpadnLog(@"%s", __PRETTY_FUNCTION__);
    if (_delegate && [_delegate respondsToSelector:@selector(vpadnAdDidClickBrowserClose:)]) {
        [_delegate vpadnAdDidClickBrowserClose:self];
    }
}

- (void)vpadnVideoAdViewWillTakeOverFullScreen:(VpadnVideoAdView *)adView {
    //VpadnLog(@"%s", __PRETTY_FUNCTION__);
    [self removeVideoViewConstraints];
    if (_delegate && [_delegate respondsToSelector:@selector(vpadnAdWillTakeOverFullScreen:)]) {
        [_delegate vpadnAdWillTakeOverFullScreen:self];
    }
}

- (void)vpadnVideoAdViewDidTakeOverFullScreen:(VpadnVideoAdView *)adView {
    //VpadnLog(@"%s", __PRETTY_FUNCTION__);
    if (_delegate && [_delegate respondsToSelector:@selector(vpadnAdDidTakeOverFullScreen:)]) {
        [_delegate vpadnAdDidTakeOverFullScreen:self];
    }
}

- (void)vpadnVideoAdViewWillDismissFullscreen:(VpadnVideoAdView *)adView {
    //VpadnLog(@"%s", __PRETTY_FUNCTION__);
    if (_delegate && [_delegate respondsToSelector:@selector(vpadnAdWillDismissFullscreen:)]) {
        [_delegate vpadnAdWillDismissFullscreen:self];
    }
}

- (void)vpadnVideoAdViewDidDismissFullscreen:(VpadnVideoAdView *)adView {
    //VpadnLog(@"%s", __PRETTY_FUNCTION__);
    [self addVideoViewConstraints];
    if (_delegate && [_delegate respondsToSelector:@selector(vpadnAdDidDismissFullscreen:)]) {
        [_delegate vpadnAdDidDismissFullscreen:self];
    }
}

- (void)vpadnVideoAdViewSkipButtonTapped:(VpadnVideoAdView *)adView {
    //VpadnLog(@"%s", __PRETTY_FUNCTION__);
    if (_delegate && [_delegate respondsToSelector:@selector(vpadnAdSkipButtonTapped:)]) {
        [_delegate vpadnAdSkipButtonTapped:self];
    }
}

- (void)vpadnVideoAdViewSkipButtonDidShow:(VpadnVideoAdView *)adView {
    //VpadnLog(@"%s", __PRETTY_FUNCTION__);
    if (_delegate && [_delegate respondsToSelector:@selector(vpadnAdSkipButtonDidShow:)]) {
        [_delegate vpadnAdSkipButtonDidShow:self];
    }
}

- (void)vpadnVideoAdViewDidReset:(VpadnVideoAdView *)adView {
    //VpadnLog(@"%s", __PRETTY_FUNCTION__);
    if (_delegate && [_delegate respondsToSelector:@selector(vpadnAdDidReset:)]) {
        [_delegate vpadnAdDidReset:self];
    }
}

- (void)vpadnVideoAdViewDidClean:(VpadnVideoAdView *)adView {
    //VpadnLog(@"%s", __PRETTY_FUNCTION__);
    if (_delegate && [_delegate respondsToSelector:@selector(vpadnAdDidClean:)]) {
        [_delegate vpadnAdDidClean:self];
    }
}

#pragma mark - UIScrollView Delegate

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
    if (_vpadnAdType == VpadnAdTypeOfInTable || _vpadnAdType == VpadnAdTypeOfInScroll) {
        [_videoAdView coveredDetect];
    } else if (_vpadnAdType == VpadnAdTypeOfInTableRepeat) {
        for (UITableViewCell *cell in [_loadedTable visibleCells]) {
            if ([cell isKindOfClass:[VpadnVideoAdTabCell class]]) {
                [((VpadnVideoAdTabCell *)cell).vpadnInReadAd.videoAdView coveredDetect];
            }
        }
    }
    if (_targetDelegate && [_targetDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) [_targetDelegate scrollViewDidScroll:scrollView];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    if (_targetDelegate && [_targetDelegate respondsToSelector:@selector(scrollViewDidZoom:)]) [_targetDelegate scrollViewDidZoom:scrollView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (_targetDelegate && [_targetDelegate respondsToSelector:@selector(scrollViewWillBeginDragging:)]) [_targetDelegate scrollViewWillBeginDragging:scrollView];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (_targetDelegate && [_targetDelegate respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)]) [_targetDelegate scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (_targetDelegate && [_targetDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) [_targetDelegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    if (_targetDelegate && [_targetDelegate respondsToSelector:@selector(scrollViewWillBeginDecelerating:)]) [_targetDelegate scrollViewWillBeginDecelerating:scrollView];
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (_targetDelegate && [_targetDelegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) [_targetDelegate scrollViewDidEndDecelerating:scrollView];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (_targetDelegate && [_targetDelegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)]) [_targetDelegate scrollViewDidEndScrollingAnimation:scrollView];
}

- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    if (_targetDelegate && [_targetDelegate respondsToSelector:@selector(viewForZoomingInScrollView:)]) {
        return [_targetDelegate viewForZoomingInScrollView:scrollView];
    } else {
        return nil;
    }
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view {
    if (_targetDelegate && [_targetDelegate respondsToSelector:@selector(scrollViewWillBeginZooming:withView:)]) [_targetDelegate scrollViewWillBeginZooming:scrollView withView:view];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view atScale:(CGFloat)scale {
    if (_targetDelegate && [_targetDelegate respondsToSelector:@selector(scrollViewDidEndZooming:withView:atScale:)]) [_targetDelegate scrollViewDidEndZooming:scrollView withView:view atScale:scale];
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    if (_targetDelegate && [_targetDelegate respondsToSelector:@selector(scrollViewShouldScrollToTop:)]) {
        return [_targetDelegate scrollViewShouldScrollToTop:scrollView];
    } else {
        return NO;
    }
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    if (_targetDelegate && [_targetDelegate respondsToSelector:@selector(scrollViewDidScrollToTop:)]) [_targetDelegate scrollViewDidScrollToTop:scrollView];
}

- (void)scrollViewDidChangeAdjustedContentInset:(UIScrollView *)scrollView API_AVAILABLE(ios(11.0)) {
    if (_targetDelegate && [_targetDelegate respondsToSelector:@selector(scrollViewDidChangeAdjustedContentInset:)]) [_targetDelegate scrollViewDidChangeAdjustedContentInset:scrollView];
}

#pragma mark - Calculate Video Ad Tab Cell

- (BOOL) isVideoAd:(NSIndexPath *)indexPath stride:(NSInteger)stride {
    if (_vpadnAdType == VpadnAdTypeOfInTableRepeat) {
        return indexPath.row % (stride + 1) == stride;
    } else if (_vpadnAdType == VpadnAdTypeOfInTable) {
        return [indexPath isEqual:_startIndexPath];
    } else {
        return NO;
    }
}

- (VpadnVideoAdTabCell *) currentVpadnAdCell:(NSIndexPath *)indexPath {
    if (_vpadnAdType == VpadnAdTypeOfInTableRepeat) {
        if (_vpadnAdCells.count >= indexPath.row / (_rowStride + 1) + 1) {
            return _vpadnAdCells[indexPath.row / (_rowStride + 1)];
        }
    }
    return nil;
}

- (BOOL) isVideoAd:(NSIndexPath *)indexPath {
    return [self isVideoAd:indexPath stride:_rowStride];
}

- (NSIndexPath *) currentIndexPath:(NSIndexPath *)indexPath {
    if (_vpadnAdType == VpadnAdTypeOfInTableRepeat) {
        NSInteger row = indexPath.row - indexPath.row / ( _rowStride + 1);
        return [NSIndexPath indexPathForRow:row inSection:indexPath.section];
    } else if (_vpadnAdType == VpadnAdTypeOfInTable) {
        if (indexPath.section == _startIndexPath.section && indexPath.row > _startIndexPath.row) {
            return [NSIndexPath indexPathForRow:(indexPath.row-1) inSection:indexPath.section];
        } else {
            return indexPath;
        }
    } else {
        return indexPath;
    }
}

#pragma mark - UITableView DataSource

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_vpadnAdType == VpadnAdTypeOfInTableRepeat) {
        NSInteger index = [_targetDataSource tableView:tableView numberOfRowsInSection:section];
        index = index + index / _rowStride;
        return index;
    } else {
        NSInteger index = [_targetDataSource tableView:tableView numberOfRowsInSection:section] + _adIndexPaths.count;
        return index;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isVideoAd:indexPath]) {
        VpadnVideoAdTabCell *cell = [self currentVpadnAdCell:indexPath];
        if (cell == nil) {
            cell = [[VpadnVideoAdTabCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"VpadnVideoAdTabCell"];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.mainTable = tableView;
            if (_vpadnAdType == VpadnAdTypeOfInTableRepeat) {
                VpadnAd *vpadnAd = [cell loadWithPid:_pid identifiers:_arrayTestIdentifiers indexPath:indexPath delegate:_delegate];
                [_vpadnAdCells addObject:cell];
                [_vpadnAds addObject:vpadnAd];
            } else {
                UIView *view = [self addAdvertisement:_videoAdView];
                [cell.contentView addSubview:view];
                [self addConstraintToVideoView:view width:[UIScreen mainScreen].bounds.size.width];
            }
        }
        return cell;
    } else {
        return [_targetDataSource tableView:tableView cellForRowAtIndexPath:[self currentIndexPath:indexPath]];
    }
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return [_targetDataSource numberOfSectionsInTableView:tableView];
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (_targetDataSource && [_targetDataSource respondsToSelector:@selector(tableView:heightForHeaderInSection:)]) {
        return [_targetDataSource tableView:tableView titleForHeaderInSection:section];
    } else {
        return nil;
    }
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (_targetDataSource && [_targetDataSource respondsToSelector:@selector(tableView:titleForFooterInSection:)]) {
        return [_targetDataSource tableView:tableView titleForFooterInSection:section];
    } else {
        return nil;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![self isVideoAd:indexPath] && [_targetDataSource respondsToSelector:@selector(tableView:canEditRowAtIndexPath:)]) {
        return [_targetDataSource tableView:tableView canEditRowAtIndexPath:[self currentIndexPath:indexPath]];
    } else {
        return NO;
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![self isVideoAd:indexPath] && [_targetDataSource respondsToSelector:@selector(tableView:canMoveRowAtIndexPath:)]) {
        return [_targetDataSource tableView:tableView canMoveRowAtIndexPath:[self currentIndexPath:indexPath]];
    } else {
        return NO;
    }
}

- (nullable NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (_targetDataSource && [_targetDataSource respondsToSelector:@selector(sectionIndexTitlesForTableView:)]) {
        return [_targetDataSource sectionIndexTitlesForTableView:tableView];
    } else {
        return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    if ([_targetDataSource respondsToSelector:@selector(tableView:sectionForSectionIndexTitle:atIndex:)]) {
        return [_targetDataSource tableView:tableView sectionForSectionIndexTitle:title atIndex:index];
    } else {
        return 0;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![self isVideoAd:indexPath] && [_targetDataSource respondsToSelector:@selector(tableView:commitEditingStyle:forRowAtIndexPath:)]) {
        [_targetDataSource tableView:tableView commitEditingStyle:editingStyle forRowAtIndexPath:[self currentIndexPath:indexPath]];
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    if (![self isVideoAd:sourceIndexPath] && ![self isVideoAd:destinationIndexPath] && [_targetDataSource respondsToSelector:@selector(tableView:moveRowAtIndexPath:toIndexPath:)]) {
        [_targetDataSource tableView:tableView moveRowAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
    }
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![self isVideoAd:indexPath] && [_targetDelegate respondsToSelector:@selector(tableView:willDisplayCell:forRowAtIndexPath:)]) {
        [_targetDelegate tableView:tableView willDisplayCell:cell forRowAtIndexPath:[self currentIndexPath:indexPath]];
    }
}
- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([_targetDelegate respondsToSelector:@selector(tableView:willDisplayHeaderView:forSection:)]) {
        [_targetDelegate tableView:tableView willDisplayHeaderView:view forSection:section];
    }
}
- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    if ([_targetDelegate respondsToSelector:@selector(tableView:willDisplayFooterView:forSection:)]) {
        [_targetDelegate tableView:tableView willDisplayFooterView:view forSection:section];
    }
}
- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    if (![self isVideoAd:indexPath] && [_targetDelegate respondsToSelector:@selector(tableView:didEndDisplayingCell:forRowAtIndexPath:)]) {
        [_targetDelegate tableView:tableView didEndDisplayingCell:cell forRowAtIndexPath:[self currentIndexPath:indexPath]];
    }
}
- (void)tableView:(UITableView *)tableView didEndDisplayingHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([_targetDelegate respondsToSelector:@selector(tableView:didEndDisplayingHeaderView:forSection:)]) {
        [_targetDelegate tableView:tableView didEndDisplayingHeaderView:view forSection:section];
    }
}
- (void)tableView:(UITableView *)tableView didEndDisplayingFooterView:(UIView *)view forSection:(NSInteger)section {
    if ([_targetDelegate respondsToSelector:@selector(tableView:didEndDisplayingFooterView:forSection:)]) {
        [_targetDelegate tableView:tableView didEndDisplayingFooterView:view forSection:section];
    }
}

// 會Crash
//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (![self isVideoAd:indexPath] && [_targetDelegate respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)]) {
//        return [_targetDelegate tableView:tableView heightForRowAtIndexPath:[self currentIndexPath:indexPath]];
//    } return UITableViewAutomaticDimension;
//}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if ([_targetDelegate respondsToSelector:@selector(tableView:heightForHeaderInSection:)]) {
        return [_targetDelegate tableView:tableView heightForHeaderInSection:section];
    } else return 0;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if ([_targetDelegate respondsToSelector:@selector(tableView:heightForFooterInSection:)]) {
        return [_targetDelegate tableView:tableView heightForFooterInSection:section];
    } else return 0;
}
- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![self isVideoAd:indexPath] && [_targetDelegate respondsToSelector:@selector(tableView:estimatedHeightForRowAtIndexPath:)]) {
        return [_targetDelegate tableView:tableView estimatedHeightForRowAtIndexPath:[self currentIndexPath:indexPath]];
    } else return 44.0f;
}
- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section {
    if ([_targetDelegate respondsToSelector:@selector(tableView:estimatedHeightForHeaderInSection:)]) {
        return [_targetDelegate tableView:tableView estimatedHeightForHeaderInSection:section];
    } else return 0;
}
- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForFooterInSection:(NSInteger)section {
    if ([_targetDelegate respondsToSelector:@selector(tableView:estimatedHeightForFooterInSection:)]) {
        return [_targetDelegate tableView:tableView estimatedHeightForFooterInSection:section];
    } else return 0;
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if ([_targetDelegate respondsToSelector:@selector(tableView:viewForHeaderInSection:)]) {
        return [_targetDelegate tableView:tableView viewForHeaderInSection:section];
    } else return nil;
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if ([_targetDelegate respondsToSelector:@selector(tableView:viewForFooterInSection:)]) {
        return [_targetDelegate tableView:tableView viewForFooterInSection:section];
    } else return nil;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if ([_targetDelegate respondsToSelector:@selector(tableView:accessoryButtonTappedForRowWithIndexPath:)]) {
        [_targetDelegate tableView:tableView accessoryButtonTappedForRowWithIndexPath:[self currentIndexPath:indexPath]];
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![self isVideoAd:indexPath] && [_targetDelegate respondsToSelector:@selector(tableView:shouldHighlightRowAtIndexPath:)]) {
        return [_targetDelegate tableView:tableView shouldHighlightRowAtIndexPath:[self currentIndexPath:indexPath]];
    } else return NO;
}
- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![self isVideoAd:indexPath] && [_targetDelegate respondsToSelector:@selector(tableView:didHighlightRowAtIndexPath:)]) {
        [_targetDelegate tableView:tableView didHighlightRowAtIndexPath:[self currentIndexPath:indexPath]];
    }
}
- (void)tableView:(UITableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![self isVideoAd:indexPath] && [_targetDelegate respondsToSelector:@selector(tableView:didUnhighlightRowAtIndexPath:)]) {
        [_targetDelegate tableView:tableView didUnhighlightRowAtIndexPath:[self currentIndexPath:indexPath]];
    }
}
- (nullable NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![self isVideoAd:indexPath] && [_targetDelegate respondsToSelector:@selector(tableView:willSelectRowAtIndexPath:)]) {
        return [_targetDelegate tableView:tableView willSelectRowAtIndexPath:[self currentIndexPath:indexPath]];
    } return nil;
}
- (nullable NSIndexPath *)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![self isVideoAd:indexPath] && [_targetDelegate respondsToSelector:@selector(tableView:willDeselectRowAtIndexPath:)]) {
        return [_targetDelegate tableView:tableView willDeselectRowAtIndexPath:[self currentIndexPath:indexPath]];
    } return nil;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![self isVideoAd:indexPath] && [_targetDelegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
        [_targetDelegate tableView:tableView didSelectRowAtIndexPath:[self currentIndexPath:indexPath]];
    }
}
- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![self isVideoAd:indexPath] && [_targetDelegate respondsToSelector:@selector(tableView:didDeselectRowAtIndexPath:)]) {
        [_targetDelegate tableView:tableView didDeselectRowAtIndexPath:[self currentIndexPath:indexPath]];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![self isVideoAd:indexPath] && [_targetDelegate respondsToSelector:@selector(tableView:editingStyleForRowAtIndexPath:)]) {
        return [_targetDelegate tableView:tableView editingStyleForRowAtIndexPath:[self currentIndexPath:indexPath]];
    } else return UITableViewCellEditingStyleNone;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![self isVideoAd:indexPath] && [_targetDelegate respondsToSelector:@selector(tableView:titleForDeleteConfirmationButtonForRowAtIndexPath:)]) {
        return [_targetDelegate tableView:tableView titleForDeleteConfirmationButtonForRowAtIndexPath:[self currentIndexPath:indexPath]];
    } else return nil;
}

- (nullable NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![self isVideoAd:indexPath] && [_targetDelegate respondsToSelector:@selector(tableView:editActionsForRowAtIndexPath:)]) {
        return [_targetDelegate tableView:tableView editActionsForRowAtIndexPath:[self currentIndexPath:indexPath]];
    } else return nil;
}

- (nullable UISwipeActionsConfiguration *)tableView:(UITableView *)tableView leadingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath  API_AVAILABLE(ios(11.0)){
    if (![self isVideoAd:indexPath] && [_targetDelegate respondsToSelector:@selector(tableView:leadingSwipeActionsConfigurationForRowAtIndexPath:)]) {
        return [_targetDelegate tableView:tableView leadingSwipeActionsConfigurationForRowAtIndexPath:[self currentIndexPath:indexPath]];
    } else return nil;
}
- (nullable UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath  API_AVAILABLE(ios(11.0)){
    if (![self isVideoAd:indexPath] && [_targetDelegate respondsToSelector:@selector(tableView:trailingSwipeActionsConfigurationForRowAtIndexPath:)]) {
        return [_targetDelegate tableView:tableView trailingSwipeActionsConfigurationForRowAtIndexPath:[self currentIndexPath:indexPath]];
    } else return nil;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![self isVideoAd:indexPath] && [_targetDelegate respondsToSelector:@selector(tableView:shouldIndentWhileEditingRowAtIndexPath:)]) {
        return [_targetDelegate tableView:tableView shouldIndentWhileEditingRowAtIndexPath:[self currentIndexPath:indexPath]];
    } else return NO;
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![self isVideoAd:indexPath] && [_targetDelegate respondsToSelector:@selector(tableView:willBeginEditingRowAtIndexPath:)]) {
        [_targetDelegate tableView:tableView willBeginEditingRowAtIndexPath:[self currentIndexPath:indexPath]];
    }
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(nullable NSIndexPath *)indexPath {
    if (![self isVideoAd:indexPath] && [_targetDelegate respondsToSelector:@selector(tableView:didEndEditingRowAtIndexPath:)]) {
        [_targetDelegate tableView:tableView didEndEditingRowAtIndexPath:[self currentIndexPath:indexPath]];
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    if (![self isVideoAd:sourceIndexPath] && ![self isVideoAd:proposedDestinationIndexPath] && [_targetDelegate respondsToSelector:@selector(tableView:targetIndexPathForMoveFromRowAtIndexPath:toProposedIndexPath:)]) {
        return [_targetDelegate tableView:tableView targetIndexPathForMoveFromRowAtIndexPath:sourceIndexPath toProposedIndexPath:proposedDestinationIndexPath];
    } return nil;
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![self isVideoAd:indexPath] && [_targetDelegate respondsToSelector:@selector(tableView:indentationLevelForRowAtIndexPath:)]) {
        return [_targetDelegate tableView:tableView indentationLevelForRowAtIndexPath:[self currentIndexPath:indexPath]];
    } else return nil;
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![self isVideoAd:indexPath] && [_targetDelegate respondsToSelector:@selector(tableView:shouldShowMenuForRowAtIndexPath:)]) {
        return [_targetDelegate tableView:tableView shouldShowMenuForRowAtIndexPath:[self currentIndexPath:indexPath]];
    } else return NO;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(nullable id)sender {
    if (![self isVideoAd:indexPath] && [_targetDelegate respondsToSelector:@selector(tableView:canPerformAction:forRowAtIndexPath:withSender:)]) {
        return [_targetDelegate tableView:tableView canPerformAction:action forRowAtIndexPath:[self currentIndexPath:indexPath] withSender:sender];
    } else return NO;
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(nullable id)sender {
    if (![self isVideoAd:indexPath] && [_targetDelegate respondsToSelector:@selector(tableView:performAction:forRowAtIndexPath:withSender:)]) {
        [_targetDelegate tableView:tableView performAction:action forRowAtIndexPath:[self currentIndexPath:indexPath] withSender:sender];
    }
}

- (BOOL)tableView:(UITableView *)tableView canFocusRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![self isVideoAd:indexPath] && [_targetDelegate respondsToSelector:@selector(tableView:canFocusRowAtIndexPath:)]) {
        return [_targetDelegate tableView:tableView canFocusRowAtIndexPath:[self currentIndexPath:indexPath]];
    } else return NO;
}

- (BOOL)tableView:(UITableView *)tableView shouldUpdateFocusInContext:(UITableViewFocusUpdateContext *)context {
    if ([_targetDelegate respondsToSelector:@selector(tableView:shouldUpdateFocusInContext:)]) {
        return [_targetDelegate tableView:tableView shouldUpdateFocusInContext:context];
    } else return NO;
}

- (void)tableView:(UITableView *)tableView didUpdateFocusInContext:(UITableViewFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator{
    if ([_targetDelegate respondsToSelector:@selector(tableView:didUpdateFocusInContext:withAnimationCoordinator:)]) {
        [_targetDelegate tableView:tableView didUpdateFocusInContext:context withAnimationCoordinator:coordinator];
    }
}

- (nullable NSIndexPath *)indexPathForPreferredFocusedViewInTableView:(UITableView *)tableView {
    if ([_targetDelegate respondsToSelector:@selector(indexPathForPreferredFocusedViewInTableView:)]) {
        return [_targetDelegate indexPathForPreferredFocusedViewInTableView:tableView];
    } else return nil;
}

- (BOOL)tableView:(UITableView *)tableView shouldSpringLoadRowAtIndexPath:(NSIndexPath *)indexPath withContext:(id<UISpringLoadedInteractionContext>)context  API_AVAILABLE(ios(11.0)){
    if (![self isVideoAd:indexPath] && [_targetDelegate respondsToSelector:@selector(tableView:shouldSpringLoadRowAtIndexPath:withContext:)]) {
        return [_targetDelegate tableView:tableView shouldSpringLoadRowAtIndexPath:[self currentIndexPath:indexPath] withContext:context];
    } else return NO;
}

@end
