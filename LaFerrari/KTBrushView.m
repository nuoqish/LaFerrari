//
//  KTBrushView.m
//  MoguMattor
//
//  Created by longyan on 2017/5/10.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#import "KTBrushView.h"

@implementation KTBrushView
- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    
    if (self) {
        
        self.lineWith = 10.;
    }
    
    return self;
}


- (void)reset {
    
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    
    //[[NSColor colorWithWhite:1.f alpha:0] set];// 设置背景
    //NSRectFill(dirtyRect);
    
    if (self.pointsArray.count == 0) {
        return;
    }
    
    CGContextRef ref = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    [self drawWithContext:ref];
    
    
}

- (CGContextRef)drawWithContext:(CGContextRef)contextRef {
    if (!contextRef) {
        CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
        size_t imageWidth = self.bounds.size.width;
        size_t imageHeight = self.bounds.size.height;
        size_t bitmapBytesPerRow = (imageWidth * 4);
        
        contextRef = CGBitmapContextCreate(NULL,
                                           imageWidth,
                                           imageHeight ,
                                           8,
                                           bitmapBytesPerRow,
                                           colorspace,
                                           (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
        CGColorSpaceRelease(colorspace);
        
    }
    
    CGFloat red = 1.0, green = 1., blue = 1., alpha = 1.0;
    CGContextSetRGBStrokeColor(contextRef, red, green, blue, alpha);
    CGContextSetLineWidth(contextRef, self.lineWith);
    CGContextSetLineCap(contextRef, kCGLineCapRound);
    CGContextSetLineJoin(contextRef, kCGLineJoinRound);
    NSPoint point = [[self.pointsArray objectAtIndex:0] pointValue];
    CGContextBeginPath(contextRef);
    CGContextMoveToPoint(contextRef, point.x, point.y);
    for (NSUInteger i = 1; i < self.pointsArray.count; i++) {
        point = [[self.pointsArray objectAtIndex:i] pointValue];
        CGContextAddLineToPoint(contextRef, point.x, point.y);
    }
    CGContextDrawPath(contextRef, kCGPathStroke);
    
    return contextRef;
}


- (NSImage *)generateMaskWithScale:(CGFloat)scale {
    CGContextRef contextRef = [self drawWithContext:NULL];
    CGImageRef imageRef = CGBitmapContextCreateImage(contextRef);
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    NSLog(@"generateMaskWithScale:(%zu,%zu),scale:%f",width, height, scale);
    NSImage *image = [[NSImage alloc] initWithCGImage:imageRef size:NSMakeSize(ceil(width * scale), ceil(height * scale))];
    CGImageRelease(imageRef);
    CGContextRelease(contextRef);
    return image;
}


@end
