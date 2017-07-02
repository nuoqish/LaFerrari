//
//  KTBezierNode.m
//  LaFerrari
//
//  Created by stanshen on 17/6/9.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTBezierNode.h"

#import "KTUtilities.h"
#import "KTGLUtilities.h"
#import "NSColor+Utils.h"
#import "KTColor.h"

NSString *KTPointArrayKey = @"KTPointArrayKey";

@interface KTBezierNode ()

@property (nonatomic, assign) CGPoint inPoint;
@property (nonatomic, assign) CGPoint anchorPoint;
@property (nonatomic, assign) CGPoint outPoint;


@end


@implementation KTBezierNode

+ (KTBezierNode *)bezierNodeWithAnchorPoint:(CGPoint)anchorPoint {
    return [[KTBezierNode alloc] initWithAnchorPoint:anchorPoint];
}

+ (KTBezierNode *)bezierNodeWithInPoint:(CGPoint)inPoint anchorPoint:(CGPoint)anchorPoint outPoint:(CGPoint)outPoint {
    return [[KTBezierNode alloc] initWithInPoint:inPoint anchorPoint:anchorPoint outPoint:outPoint];
}

- (id)initWithAnchorPoint:(CGPoint)anchorPoint {
    return [self initWithInPoint:anchorPoint anchorPoint:anchorPoint outPoint:anchorPoint];
}

- (id)initWithInPoint:(CGPoint)inPoint anchorPoint:(CGPoint)anchorPoint outPoint:(CGPoint)outPoint {
    self = [super init];
    if (self) {
        self.inPoint = inPoint;
        self.anchorPoint = anchorPoint;
        self.outPoint = outPoint;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    KTBezierNode *node = [[KTBezierNode alloc] init];
    node.inPoint = _inPoint;
    node.anchorPoint = _anchorPoint;
    node.outPoint = _outPoint;
    node.selected = _selected;
    return node;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        const uint8_t *bytes = [aDecoder decodeBytesForKey:KTPointArrayKey returnedLength:NULL];
        CFSwappedFloat32 *swapped = (CFSwappedFloat32 *)bytes;
        self.inPoint = CGPointMake(CFConvertFloatSwappedToHost(swapped[0]), CFConvertFloatSwappedToHost(swapped[1]));
        self.anchorPoint = CGPointMake(CFConvertFloatSwappedToHost(swapped[2]), CFConvertFloatSwappedToHost(swapped[3]));
        self.outPoint = CGPointMake(CFConvertFloatSwappedToHost(swapped[4]), CFConvertFloatSwappedToHost(swapped[5]));
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    CFSwappedFloat32 swapped[6];
    float points[6] = {_inPoint.x, _inPoint.y, _anchorPoint.x, _anchorPoint.y, _outPoint.x, _outPoint.y};
    for (NSUInteger idx = 0; idx < 6; idx++) {
        swapped[idx] = CFConvertFloat32HostToSwapped(points[idx]);
    }
    [aCoder encodeBytes:(const uint8_t *)swapped length:(6 * sizeof(CFSwappedFloat32)) forKey:KTPointArrayKey];
}

- (BOOL)isEqual:(id)obj {
    if (obj == self) {
        return YES;
    }
    if (![obj isKindOfClass:[KTBezierNode class]]) {
        return NO;
    }
    KTBezierNode *node = (KTBezierNode *)obj;
    return (CGPointEqualToPoint(self.inPoint, node.inPoint) &&
            CGPointEqualToPoint(self.anchorPoint, node.anchorPoint) &&
            CGPointEqualToPoint(self.outPoint, node.outPoint));
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@: (%@) -- [%@] -- (%@)", [super description], NSStringFromPoint(_inPoint), NSStringFromPoint(_anchorPoint), NSStringFromPoint(_outPoint)];
}

- (KTBezierNodeReflectionMode)reflectionMode {
    // normalize whether the handle points first
    CGPoint a = KTAddPoints(_anchorPoint, KTNormalizeVector(KTSubtractPoints(_inPoint, _anchorPoint)));
    CGPoint b = KTAddPoints(_anchorPoint, KTNormalizeVector(KTSubtractPoints(_outPoint, _anchorPoint)));
    
    // then compute the area of the triangle
    float triangleArea = fabs(_anchorPoint.x * (a.y - b.y) + a.x * (b.y - _anchorPoint.y) + b.x * (_anchorPoint.y - a.y));
    if (triangleArea < 1.e-3 && !CGPointEqualToPoint(_inPoint, _outPoint)) {
        return KTBezierNodeReflectionReflectIndependent;
    }
    return KTBezierNodeReflectionIndependent;
}

- (BOOL)hasInPoint {
    return !CGPointEqualToPoint(_anchorPoint, _inPoint);
}

- (BOOL)hasOutPoint {
    return !CGPointEqualToPoint(_anchorPoint, _outPoint);
}

- (BOOL)isCorner {
    if (![self hasInPoint] || ![self hasOutPoint]) {
        return YES;
    }
    return !KTCollinear(_inPoint, _anchorPoint, _outPoint);
}

- (KTBezierNode *)flippedNode {
    return [KTBezierNode bezierNodeWithInPoint:_outPoint anchorPoint:_anchorPoint outPoint:_inPoint];
}

- (KTBezierNode *)chopHandles {
    if ([self hasInPoint] || [self hasOutPoint]) {
        return [KTBezierNode bezierNodeWithAnchorPoint:_anchorPoint];
    }
    else {
        return self;
    }
}

- (KTBezierNode *)chopInHandle {
    if ([self hasInPoint]) {
        return [KTBezierNode bezierNodeWithInPoint:_anchorPoint anchorPoint:_anchorPoint outPoint:_outPoint];
    }
    else {
        return self;
    }
}

- (KTBezierNode *)chopOutHandle {
    if ([self hasOutPoint]) {
        return [KTBezierNode bezierNodeWithInPoint:_inPoint anchorPoint:_anchorPoint outPoint:_anchorPoint];
    }
    else {
        return self;
    }
}

- (KTBezierNode *)transform:(CGAffineTransform)transform {
    CGPoint tIn = CGPointApplyAffineTransform(_inPoint, transform);
    CGPoint tAnchor = CGPointApplyAffineTransform(_anchorPoint, transform);
    CGPoint tOut = CGPointApplyAffineTransform(_outPoint, transform);
    KTBezierNode *transformed = [[KTBezierNode alloc] initWithInPoint:tIn anchorPoint:tAnchor outPoint:tOut];
    return transformed;
}

- (KTBezierNode *)setInPoint:(CGPoint)inPoint reflectionMode:(KTBezierNodeReflectionMode)reflectionMode {
    CGPoint flippedPoint = KTAddPoints(_anchorPoint, KTSubtractPoints(_anchorPoint, inPoint));
    return [self moveControlHandle:KTInPoint toPoint:flippedPoint reflectionMode:reflectionMode];
}

- (void)getInPoint:(CGPoint *)inPoint anchorPoint:(CGPoint *)anchorPoint outPoint:(CGPoint *)outPoint selected:(BOOL *)selected {
    *inPoint = _inPoint;
    *anchorPoint = _anchorPoint;
    *outPoint = _outPoint;
    if (selected) {
        *selected = _selected;
    }
}

- (KTBezierNode *)moveControlHandle:(KTPickResultType)pointToTransform toPoint:(CGPoint)point reflectionMode:(KTBezierNodeReflectionMode)reflectioinMode {
    CGPoint inPoint = _inPoint, outPoint = _outPoint;
    if (pointToTransform == KTInPoint) {
        inPoint = point;
        if (reflectioinMode == KTBezierNodeReflectionReflect) {
            CGPoint delta = KTSubtractPoints(_anchorPoint, inPoint);
            outPoint = KTAddPoints(_anchorPoint, delta);
        }
        else if (reflectioinMode == KTBezierNodeReflectionReflectIndependent) {
            CGPoint inVector  = KTNormalizeVector(KTSubtractPoints(_anchorPoint, inPoint));
            if (CGPointEqualToPoint(inVector, CGPointZero)) {
                // If the inVector is 0, we'll inadvertently chop the out vector
                outPoint = _outPoint;
            }
            else {
                CGPoint outVector = KTSubtractPoints(_outPoint, _anchorPoint);
                float magnitude = KTMagnitudeVector(outVector);
                outVector = KTMultiplyPointScalar(inVector, magnitude);
                outPoint = KTAddPoints(_anchorPoint, outVector);
            }
        }
    }
    else if (pointToTransform == KTOutPoint) {
        outPoint = point;
        if (reflectioinMode == KTBezierNodeReflectionReflect) {
            CGPoint delta = KTSubtractPoints(_anchorPoint, outPoint);
            inPoint = KTAddPoints(_anchorPoint, delta);
        }
        else if (reflectioinMode == KTBezierNodeReflectionReflectIndependent) {
            CGPoint outVector = KTNormalizeVector(KTSubtractPoints(_anchorPoint, outPoint));
            if (CGPointEqualToPoint(outVector, CGPointZero)) {
                inPoint = _inPoint;
            }
            else {
                CGPoint inVector = KTSubtractPoints(_inPoint, _anchorPoint);
                float magnitude = KTMagnitudeVector(inVector);
                inVector = KTMultiplyPointScalar(outVector, magnitude);
                inPoint = KTAddPoints(_anchorPoint, inVector);
            }
        }
    }
    
    return [[KTBezierNode alloc] initWithInPoint:inPoint anchorPoint:_anchorPoint outPoint:outPoint];
}


// glrendering

- (void)drawGLWithViewTransform:(CGAffineTransform)transform color:(NSColor *)color mode:(KTBezierNodeRenderMode)renderMode {
    CGPoint anchor, inPoint, outPoint;
    
    anchor = CGPointApplyAffineTransform(_anchorPoint, transform);
    inPoint = CGPointApplyAffineTransform(_inPoint, transform);
    outPoint = CGPointApplyAffineTransform(_outPoint, transform);
    
    CGRect anchorRect = CGRectMake(anchor.x - kKTAnchorRadius, anchor.y - kKTAnchorRadius, kKTAnchorRadius * 2, kKTAnchorRadius * 2);
    
    // draw the control handles
    if (renderMode == KTBezierNodeRenderSelected) {
        [color openGLSet];
        
        if ([self hasInPoint]) {
            KTGLLineFromPointToPoint(inPoint, anchor);
        }
        
        if ([self hasOutPoint]) {
            KTGLLineFromPointToPoint(outPoint, anchor);
        }
    }
    
    // draw the anchor
    if (renderMode == KTBezierNodeRenderClosed) {
        [color openGLSet];
        anchorRect = CGRectInset(anchorRect, 1, 1);
        KTGLFillRect(anchorRect);
    } else if (renderMode == KTBezierNodeRenderSelected) {
        [color openGLSet];
        KTGLFillRect(anchorRect);
        glColor4f(1, 1, 1, 1);
        KTGLStrokeRect(anchorRect);
    } else {
        glColor4f(1, 1, 1, 1);
        KTGLFillRect(anchorRect);
        [color openGLSet];
        KTGLStrokeRect(anchorRect);
    }
    
    // draw the control handle knobs
    if (renderMode == KTBezierNodeRenderSelected) {
        [color openGLSet];
        
        if ([self hasInPoint]) {
            inPoint = KTRoundPoint(inPoint);
            KTGLFillCircle(inPoint, kKTControlPointRadius, 10);
        }
        
        if ([self hasOutPoint]) {
            outPoint = KTRoundPoint(outPoint);
            KTGLFillCircle(outPoint, kKTControlPointRadius, 10);
        }
    }
}

- (void)drawNodeWithCGContext:(CGContextRef)ctx ViewTransform:(CGAffineTransform)transform colosr:(KTColor *)color mode:(KTBezierNodeRenderMode)renderMode {
    
    CGPoint anchorPoint, inPoint, outPoint;
    anchorPoint = CGPointApplyAffineTransform(_anchorPoint, transform);
    inPoint = CGPointApplyAffineTransform(_inPoint, transform);
    outPoint = CGPointApplyAffineTransform(_outPoint, transform);
    
    float red, green, blue, alpha;
    [color getRed:&red Green:&green Blue:&blue Alpha:&alpha];
    
    if (renderMode == KTBezierNodeRenderSelected) {
        
        if ([self hasInPoint]) {
            KTCGDrawLineFromPointToPoint(ctx, inPoint, anchorPoint, red, green, blue, alpha);
        }
        if ([self hasOutPoint]) {
            KTCGDrawLineFromPointToPoint(ctx, outPoint, anchorPoint, red, green, blue, alpha);
        }
    }
    
    CGRect anchorRect = CGRectMake(_anchorPoint.x - kKTAnchorRadius, _anchorPoint.y - kKTAnchorRadius, kKTAnchorRadius * 2, kKTAnchorRadius * 2);
    anchorRect = CGRectApplyAffineTransform(anchorRect, transform);
    KTCGDrawRect(ctx, anchorRect);
    
    CGRect inRect = CGRectMake(_inPoint.x - kKTAnchorRadius, _inPoint.y - kKTAnchorRadius, kKTAnchorRadius * 2, kKTAnchorRadius * 2);
    inRect = CGRectApplyAffineTransform(inRect, transform);
    CGRect outRect = CGRectMake(_outPoint.x - kKTAnchorRadius, _outPoint.y - kKTAnchorRadius, kKTAnchorRadius * 2, kKTAnchorRadius * 2);
    outRect = CGRectApplyAffineTransform(outRect, transform);
    KTCGDrawCircle(ctx, inRect);
    KTCGDrawCircle(ctx, outRect);
    
}


@end
