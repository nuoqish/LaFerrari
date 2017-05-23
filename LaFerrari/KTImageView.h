//
//  KTImageView.h
//  MoguMattor
//
//  Created by longyan on 2017/5/10.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface KTImageView : NSScrollView

@property (nonatomic, strong) NSImage *image;
@property (nonatomic, assign) CGSize maxFrameSize;
@property (nonatomic, readonly) CGRect imageFrame;
@property (nonatomic, strong) NSColor *bkColor;

- (void)addCustomView:(NSView *)customView;

@end
