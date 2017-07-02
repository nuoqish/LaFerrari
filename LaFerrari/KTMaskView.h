//
//  KTMaskView.h
//  LaFerrari
//
//  Created by stanshen on 17/6/29.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface KTMaskView : NSView

@property (nonatomic, strong) NSImage *maskImage;
@property (nonatomic, assign) CGFloat scaleRatio;

@end
