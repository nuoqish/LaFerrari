//
//  KTTextRenderer.h
//  LaFerrari
//
//  Created by stanshen on 17/6/9.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol KTTextRenderer <NSObject>

@required
- (void)drawTextInContext:(CGContextRef)ctx drawingMode:(CGTextDrawingMode)mode;
- (void)drawTextInContext:(CGContextRef)ctx drawingMode:(CGTextDrawingMode)mode didClip:(BOOL *)didClip;

- (CGAffineTransform)transform;
- (NSArray *)outlines;

- (void)drawOpenGLTextOutlinesWithTransform:(CGAffineTransform)transform viewTransform:(CGAffineTransform)viewTransform;


@end
