//
//  KTCropView.h
//  MoguMattor
//
//  Created by longyan on 2017/4/28.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class KTCropView;
@protocol KTCropViewDelegate <NSObject>

- (void)confirmButtonTappedForCropView:(KTCropView *)cropView;
- (void)closeButtonTappedForCropView:(KTCropView *)cropView;


@end

@interface KTCropView : NSView


@property(nonatomic, assign) CGFloat controlPointSize;
@property(nonatomic, assign) CGFloat minControlPointDistance;

@property(nonatomic, assign) CGRect cropRect;

@property(nonatomic, weak) id<KTCropViewDelegate> delegate;

- (void)showCloseButton:(BOOL)isShow;

@end
