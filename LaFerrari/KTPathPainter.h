//
//  KTPathPainter.h
//  LaFerrari
//
//  Created by stanshen on 17/6/9.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KTTextRenderer.h"

@class KTAbstractPath;
@class KTColor;


@protocol KTPathPainter <NSObject>

@required
- (void)paintPath:(KTAbstractPath *)path inContext:(CGContextRef)ctx;
- (BOOL)transformable;
- (BOOL)wantsCenteredFillTransform;
- (BOOL)canPaintStroke;
- (void)drawSwatchInRect:(CGRect)rect;
- (void)drawEyedropperSwatchInRect:(CGRect)rect;
- (void)paintText:(id<KTTextRenderer>)text inContext:(CGContextRef)ctx;
- (id)adjustColor:(KTColor * (^)(KTColor *color))adjustment;

@end
