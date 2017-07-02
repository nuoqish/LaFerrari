//
//  KTImage.m
//  LaFerrari
//
//  Created by stanshen on 17/6/14.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTImage.h"

#import "KTImageData.h"
#import "KTPath.h"
#import "KTLayer.h"
#import "KTColor.h"
#import "KTXMLElement.h"
#import "KTSVGHelper.h"
#import "KTUtilities.h"
#import "KTGLUtilities.h"
#import "NSColor+Utils.h"

NSString *KTImageDataKey = @"KTImageDatakey";

@implementation KTImage {
    CGMutablePathRef _pathRef;
    CGPoint _corners[4];
}

+ (KTImage *)imageWithNSImage:(NSImage *)image {
    return [[KTImage alloc] initWithNSImage:image];
}

- (id)initWithNSImage:(NSImage *)image {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _transform = CGAffineTransformIdentity;
    _imageData = [KTImageData imageDataWithNSImage:image];
    
    [self computeCorners];
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    KTImage *image = [super copyWithZone:zone];
    image->_transform = _transform;
    image->_imageData = _imageData.copy;
    return image;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    _imageData = [aDecoder decodeObjectForKey:KTImageDataKey];
    NSValue *value = [aDecoder decodeObjectForKey:KTTransformKey]; //?
    [value getValue:&_transform];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:_imageData forKey:KTImageDataKey];
    [aCoder encodeObject:[NSValue valueWithBytes:&_transform objCType:@encode(CGAffineTransform)] forKey:KTTransformKey];//?
    
}


- (void)computeCorners {
    CGRect bounds = [self naturalBounds];
    
    _corners[0] = bounds.origin;
    _corners[1] = CGPointMake(CGRectGetMaxX(bounds), 0);
    _corners[2] = CGPointMake(CGRectGetMaxX(bounds), CGRectGetMaxY(bounds));
    _corners[3] = CGPointMake(0, CGRectGetMaxY(bounds));
}

- (CGRect)naturalBounds {
    CGSize naturalSize = _imageData.image.size;
    return CGRectMake(0, 0, naturalSize.width, naturalSize.height);
}

- (CGRect)bounds {
    return CGRectApplyAffineTransform(self.naturalBounds, _transform);
}

- (CGMutablePathRef)pathRef {
    if (!_pathRef) {
        _pathRef = CGPathCreateMutable();
        CGPathAddRect(_pathRef, &_transform, self.naturalBounds);
    }
    return _pathRef;
}

- (BOOL)containsPoint:(CGPoint)point {
    return CGPathContainsPoint([self pathRef], NULL, point, 0);
}

- (BOOL)intersectsRect:(CGRect)rect {
    CGPoint     ul, ur, lr, ll;
    
    ul = CGPointZero;
    ur = CGPointMake(CGRectGetWidth(self.naturalBounds), 0);
    lr = CGPointMake(CGRectGetWidth(self.naturalBounds), CGRectGetHeight(self.naturalBounds));
    ll = CGPointMake(0, CGRectGetHeight(self.naturalBounds));
    
    ul = CGPointApplyAffineTransform(ul, _transform);
    ur = CGPointApplyAffineTransform(ur, _transform);
    lr = CGPointApplyAffineTransform(lr, _transform);
    ll = CGPointApplyAffineTransform(ll, _transform);
    
    return (KTLineInRect(ul, ur, rect) ||
            KTLineInRect(ur, lr, rect) ||
            KTLineInRect(lr, ll, rect) ||
            KTLineInRect(ll, ul, rect));
}

- (void)setTransform:(CGAffineTransform)transform {
    [self cacheDirtyBounds];
    [(KTImage *)[self.undoManager prepareWithInvocationTarget:self] setTransform:_transform];
    _transform = transform;
    
    CGPathRelease(_pathRef);
    _pathRef = NULL;
    
    [self postDirtyBoundsChange];
}

- (NSSet *)transform:(CGAffineTransform)transform {
    [self setTransform:CGAffineTransformConcat(_transform, transform)];
    return nil;
}

- (void)renderInContext:(CGContextRef)ctx metaData:(KTRenderingMetaData)metaData {
    if (metaData.flags & KTRenderOutlineOnly) {
        CGContextAddPath(ctx, [self pathRef]);
        
        // draw X to mark the spot
        CGPoint corners[4];
        corners[0] = _corners[0]; // ul;
        corners[1] = _corners[2]; // lr;
        corners[2] = _corners[1]; // ur;
        corners[3] = _corners[3]; // ll;
        for (int i = 0; i < 4; i++) {
            corners[i] = CGPointApplyAffineTransform(corners[i], _transform);
        }
        CGContextAddLines(ctx, corners, 4);
        CGContextStrokePath(ctx);
    }
    else {
        CGContextSaveGState(ctx);
        CGContextConcatCTM(ctx, _transform);
        if (metaData.flags & KTRenderThumbnail) {
            [_imageData.thumbnailImage drawInRect:_imageData.naturalBounds fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:self.opacity]; //?
        }
        else {
            [_imageData.image drawInRect:_imageData.naturalBounds fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:self.opacity];//?
        }
        
        CGContextRestoreGState(ctx);
    }
}

- (void)drawOpenGLAnchorsWithViewTransform:(CGAffineTransform)transform {
    for (int i = 0; i < 4; i++) {
        [self drawOpenGLAnchorAtPoint:CGPointApplyAffineTransform(_corners[i], _transform) transform:transform selected:YES];
    }
}

- (void)drawOpenGLHandlesWithTransform:(CGAffineTransform)transform viewTransform:(CGAffineTransform)viewTransform {
    for (int i = 0; i < 4; i++) {
        [self drawOpenGLAnchorAtPoint:CGPointApplyAffineTransform(_corners[i], _transform) transform:viewTransform selected:YES];
    }
}

- (void)drawOpenGLHighlightWithTransform:(CGAffineTransform)transform viewTransform:(CGAffineTransform)viewTransform {
    CGAffineTransform   tX;
    CGPoint             ul, ur, lr, ll;
    
    tX = CGAffineTransformConcat(_transform, transform);
    tX = CGAffineTransformConcat(tX, viewTransform);
    
    ul = CGPointZero;
    ur = CGPointMake(CGRectGetWidth(self.naturalBounds), 0);
    lr = CGPointMake(CGRectGetWidth(self.naturalBounds), CGRectGetHeight(self.naturalBounds));
    ll = CGPointMake(0, CGRectGetHeight(self.naturalBounds));
    
    ul = CGPointApplyAffineTransform(ul, tX);
    ur = CGPointApplyAffineTransform(ur, tX);
    lr = CGPointApplyAffineTransform(lr, tX);
    ll = CGPointApplyAffineTransform(ll, tX);
    
    // draw outline
    [self.layer.highlightColor openGLSet];
    
    
    KTGLLineFromPointToPoint(ul, ur);
    KTGLLineFromPointToPoint(ur, lr);
    KTGLLineFromPointToPoint(lr, ll);
    KTGLLineFromPointToPoint(ll, ul);
    
    // draw 'X'
    KTGLLineFromPointToPoint(ul, lr);
    KTGLLineFromPointToPoint(ll, ur);
}

- (KTPickResult *)hitResultForPoint:(CGPoint)point viewScale:(float)viewScale snapFlags:(int)flags {
    KTPickResult *result = [KTPickResult pickResult];
    
    CGRect pointRect = KTRectFromPoint(point, kNodeSelectionTolerance / viewScale, kNodeSelectionTolerance / viewScale);
    if (!CGRectIntersectsRect(pointRect, [self bounds])) {
        return result;
    }
    
    if ((flags & KTSnapNodes) || (flags & KTSnapEdges)) {
        result = KTSnapToRectangle([self naturalBounds], &_transform, point, viewScale, flags);
        if (result.snapped) {
            result.element = self;
            return result;
        }
    }
    if (flags & KTSnapFills) {
        if (CGPathContainsPoint([self pathRef], NULL, point, true)) {
            result.element = self;
            result.type = KTObjectFill;
            return result;
        }
    }
    
    return result;
}

- (KTPickResult *)snappedPoint:(CGPoint)point viewScale:(float)viewScale snapFlags:(int)flags {
    KTPickResult *result = [KTPickResult pickResult];
    
    CGRect pointRect = KTRectFromPoint(point, kNodeSelectionTolerance / viewScale, kNodeSelectionTolerance / viewScale);
    if (!CGRectIntersectsRect(pointRect, [self bounds])) {
        return result;
    }
    
    if ((flags & KTSnapNodes) || (flags & KTSnapEdges)) {
        result = KTSnapToRectangle([self naturalBounds], &_transform, point, viewScale, flags);
        if (result.snapped) {
            result.element = self;
            return result;
        }
    }
    
    return result;
}

- (id)pathPainterAtPoint:(CGPoint)pt {
    if (!CGPathContainsPoint([self pathRef], NULL, pt, true)) {
        return nil;
    }
    
    CGAffineTransform transform = CGAffineTransformInvert(_transform);
    pt = CGPointApplyAffineTransform(pt, transform);
    CGImageRef imageRef = [_imageData.image CGImageForProposedRect:NULL context:NULL hints:NULL];
    CGImageRef tinyRef = CGImageCreateWithImageInRect(imageRef, CGRectMake(pt.x, pt.x, 1, 1));
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    UInt8 rawData[4] = {255, 255, 255, 255};
    CGContextRef context = CGBitmapContextCreate(rawData, 1, 1, 8, 4, colorSpace, kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context, CGRectMake(0, 0, 1, 1), tinyRef);
    CGContextRelease(context);
    CGImageRelease(tinyRef);
    
    CGFloat red = rawData[0] / 255.f;
    CGFloat green = rawData[1] / 255.f;
    CGFloat blue = rawData[2] / 255.f;
    return [KTColor colorWithRed:red green:green blue:blue alpha:1.0f];
}

- (KTXMLElement *)SVGElement {
    NSString *unique = [[KTSVGHelper sharedSVGHelper] imageIDForDigest:_imageData.digest];
    KTXMLElement *image = [KTXMLElement elementWithName:@"use"];
    [self addSVGOpacityAndShadowAttributes:image];
    [image setAttribute:@"xlink:href" value:[NSString stringWithFormat:@"#%@", unique]];
    [image setAttribute:@"transform" value:KTSVGStringFromCGAffineTransform(_transform)];
    return image;
}

- (BOOL)needsTransparencyLayer:(float)scale {
    return NO;
}

- (void)useTrackedImageData {
    
}

@end
