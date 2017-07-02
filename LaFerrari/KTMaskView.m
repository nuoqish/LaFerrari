//
//  KTMaskView.m
//  LaFerrari
//
//  Created by stanshen on 17/6/29.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTMaskView.h"

#import "KTBezierNode.h"
#import "KTBezierProcessor.h"
#import "KTColor.h"

@interface KTMaskView ()

@property (nonatomic, strong) NSImageView *maskImageView;
@property (nonatomic, strong) NSArray<NSArray<KTBezierNode*> *> *contours;

@end

@implementation KTMaskView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    
    if (!self) {
        return nil;
    }
    
    self.scaleRatio = 1.0f;
    
    return self;
}


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    if (_contours) {
        CGAffineTransform transform = CGAffineTransformScale(CGAffineTransformIdentity, 1. / self.scaleRatio, 1. / self.scaleRatio);
        CGContextRef ctx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
        CGContextSaveGState(ctx);
        [_contours enumerateObjectsUsingBlock:^(NSArray<KTBezierNode *> * _Nonnull nodes, NSUInteger idx, BOOL * _Nonnull stop) {
            
            CGPathRef path = [self computeBezierPath:nodes transform:transform shouldClose:YES];
            CGFloat red = 1.0, green = 0., blue = 0., alpha = 1.0;
            CGContextSetRGBStrokeColor(ctx, red, green, blue, alpha);
            CGContextSetLineWidth(ctx, 1.);
            CGContextSetLineCap(ctx, kCGLineCapRound);
            CGContextSetLineJoin(ctx, kCGLineJoinRound);
           
            CGContextAddPath(ctx, path);
            CGContextStrokePath(ctx);
            
            
            for (KTBezierNode *node in nodes) {
                [node drawNodeWithCGContext:ctx ViewTransform:transform colosr:[KTColor blackColor] mode:KTBezierNodeRenderSelected];
            }
            
        }];
        CGContextRestoreGState(ctx);
        
    }
}


- (void)setMaskImage:(NSImage *)maskImage {
    _maskImage = maskImage;
    
    _contours = [KTBezierProcessor processImage:maskImage];
    [self setNeedsDisplay:YES];
}

- (CGPathRef)computeBezierPath:(NSArray<KTBezierNode *> *)nodes transform:(CGAffineTransform)transform shouldClose:(BOOL)closed{
    if (nodes.count == 0) {
        return NULL;
    }
    CGMutablePathRef pathRef = CGPathCreateMutable();
    KTBezierNode *preNode = nil;
    BOOL firstTime = YES;
    
    for (KTBezierNode *node in nodes) {
        if (firstTime) {
            CGPathMoveToPoint(pathRef, &transform, node.anchorPoint.x, node.anchorPoint.y);
            firstTime = NO;
        }
        else if ([preNode hasOutPoint] || [node hasInPoint]) {
            CGPathAddCurveToPoint(pathRef, &transform, preNode.outPoint.x, preNode.outPoint.y, node.inPoint.x, node.inPoint.y, node.anchorPoint.x, node.anchorPoint.y);
        }
        else {
            CGPathAddLineToPoint(pathRef, &transform, node.anchorPoint.x, node.anchorPoint.y);
        }
        preNode = node;
    }
    
    if (closed && preNode) {
        KTBezierNode *node = nodes[0];
        CGPathAddCurveToPoint(pathRef, &transform, preNode.outPoint.x, preNode.outPoint.y, node.inPoint.x, node.inPoint.y, node.anchorPoint.x, node.anchorPoint.y);
        CGPathCloseSubpath(pathRef);
    }

    return pathRef;
}




@end
