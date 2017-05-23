//
//  KTBrushView.h
//  MoguMattor
//
//  Created by longyan on 2017/5/10.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface KTBrushView : NSView


@property (nonatomic, strong) NSArray *pointsArray;

@property (nonatomic, assign) CGFloat lineWith;
@property (nonatomic, strong) NSColor *lineColor;


- (NSImage *)generateMaskWithScale:(CGFloat)scale;

- (void)reset;

@end
