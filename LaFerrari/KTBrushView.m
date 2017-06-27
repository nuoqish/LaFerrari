//
//  KTBrushView.m
//  MoguMattor
//
//  Created by longyan on 2017/5/10.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#import "KTBrushView.h"

#import "KTGLUtilities.h"

@interface KTBrushView ()

@end


@implementation KTBrushView
- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    
    if (self) {
        _lineWith = 10.;
        
        
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
    
    KTCGDrawBrushWithPoints(contextRef, self.pointsArray, self.lineWith);
    
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

- (NSImage *)genereateMaskWithSize:(CGSize)size {
    CGContextRef contextRef = [self drawWithContext:NULL];
    CGImageRef imageRef = CGBitmapContextCreateImage(contextRef);
    NSImage *image = [[NSImage alloc] initWithCGImage:imageRef size: size];
    CGImageRelease(imageRef);
    CGContextRelease(contextRef);
    return image;
}


@end
