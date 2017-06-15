//
//  KTArrowhead.m
//  LaFerrari
//
//  Created by stanshen on 17/6/11.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTArrowhead.h"

#import "KTUtilities.h"
#import "KTGLUtilities.h"

const float kArrowheadDimension = 7.0f;
const float kHalfArrowheadDimension = kArrowheadDimension / 2;

@interface KTArrowhead ()

@property (nonatomic, assign) CGPoint attachment;
@property (nonatomic, assign) CGPoint capAdjustment;
@property (nonatomic, assign) CGPathRef path;
@property (nonatomic, assign) CGRect bounds;

@end

@implementation KTArrowhead

+ (NSDictionary *)arrowheads {
    static NSDictionary *arrows = nil;
    if (!arrows) {
        arrows = [self buildArrows];
    }
    
    return arrows;
}

+ (KTArrowhead *)arrowheadWithPath:(CGPathRef)pathRef attachment:(CGPoint)attach {
    return [[KTArrowhead alloc] initWithPath:pathRef attachment:attach capAdjustment:CGPointZero];
}

+ (KTArrowhead *)arrowheadWithPath:(CGPathRef)pathRef attachment:(CGPoint)attach capAdjustment:(CGPoint)adjustment {
    return [[KTArrowhead alloc] initWithPath:pathRef attachment:attach capAdjustment:adjustment];
}

- (id)initWithPath:(CGPathRef)pathRef attachment:(CGPoint)attach capAdjustment:(CGPoint)adjustment {
    self = [super init];
    
    if (self) {
        
        // we want this path to butt up against the origin
        CGRect boundsTest = CGPathGetBoundingBox(pathRef);
        if (!CGPointEqualToPoint(boundsTest.origin, CGPointZero)) {
            CGAffineTransform tX = CGAffineTransformMakeTranslation(-boundsTest.origin.x, -boundsTest.origin.y);
            CGPathRef transformedPath = KTCreateTransformedCGPathRef(pathRef, tX);
            CGPathRelease(pathRef);
            _path = transformedPath;
            
            // need to shift the attachment point too
            attach = KTAddPoints(attach, KTMultiplyPointScalar(boundsTest.origin, -1));
        } else {
            _path = pathRef;
        }
        
        _attachment = attach;
        _capAdjustment = adjustment;
        _bounds = CGPathGetBoundingBox(_path);
        
    }
    
    return self;
}

- (void)dealloc {
    CGPathRelease(_path);
}

- (CGPoint)attachmentAdjusted:(BOOL)adjust {
    return adjust ? KTAddPoints(self.attachment, self.capAdjustment) : self.attachment;
}

- (float)insetLength {
    return CGRectGetWidth(_bounds) - self.attachment.x;
}

- (float)insetLength:(BOOL)adjusted {
    return CGRectGetWidth(_bounds) - [self attachmentAdjusted:adjusted].x;
}

- (CGAffineTransform)transformAtPosition:(CGPoint)point scale:(float)scale angle:(float)angle useAdjustment:(BOOL)adjust {
    
    CGPoint attach = [self attachmentAdjusted:adjust];
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, point.x, point.y);
    transform = CGAffineTransformScale(transform, scale, scale);
    transform = CGAffineTransformRotate(transform, angle);
    transform = CGAffineTransformTranslate(transform, -attach.x, -attach.y);
    
    return transform;
}

- (CGRect)boundingBoxAtPosition:(CGPoint)point scale:(float)scale angle:(float)angle useAdjustment:(BOOL)adjust {
    CGAffineTransform transform = [self transformAtPosition:point scale:scale angle:angle useAdjustment:adjust];
    CGPathRef rectPath = CGPathCreateWithRect(self.bounds, &transform);
    CGRect arrowBounds = CGPathGetBoundingBox(rectPath);
    CGPathRelease(rectPath);
    
    return arrowBounds;
}

- (void)addToMutablePath:(CGMutablePathRef)pathRef position:(CGPoint)point scale:(float)scale angle:(float)angle useAdjustment:(BOOL)adjust {
    CGAffineTransform transform = [self transformAtPosition:point scale:scale angle:angle useAdjustment:adjust];
    CGPathAddPath(pathRef, &transform, self.path);
}

- (void)addArrowInContext:(CGContextRef)ctx position:(CGPoint)point scale:(float)scale angle:(float)angle useAdjustment:(BOOL)adjust {
    CGContextSaveGState(ctx);
    CGContextConcatCTM(ctx, [self transformAtPosition:point scale:scale angle:angle useAdjustment:adjust]);
    CGContextAddPath(ctx, self.path);
    CGContextRestoreGState(ctx);
}



+ (NSDictionary *)buildArrows {
    NSMutableDictionary *arrows = @{}.mutableCopy;
    
    CGAffineTransform   flipTransform = CGAffineTransformIdentity;
    CGAffineTransform   diamondTransform = CGAffineTransformIdentity;
    CGMutablePathRef    pathRef;
    CGRect              defaultRect = CGRectMake(0, 0, kArrowheadDimension, kArrowheadDimension);
    
    /*
     * Arrows
     */
    
    pathRef = CGPathCreateMutable();
    CGPathMoveToPoint(pathRef, NULL, (3.0f / 8) * kArrowheadDimension, kHalfArrowheadDimension);
    CGPathAddLineToPoint(pathRef, NULL,  0, kArrowheadDimension);
    CGPathAddLineToPoint(pathRef, NULL, kArrowheadDimension, kHalfArrowheadDimension);
    CGPathAddLineToPoint(pathRef, NULL, 0, 0);
    CGPathCloseSubpath(pathRef);
    
    [arrows setObject:[KTArrowhead arrowheadWithPath:pathRef attachment:CGPointMake(kHalfArrowheadDimension, kHalfArrowheadDimension)]
               forKey:@"arrow1"];
    
    pathRef = CGPathCreateMutable();
    CGPathMoveToPoint(pathRef, NULL,  0, kArrowheadDimension);
    CGPathAddLineToPoint(pathRef, NULL, kArrowheadDimension - 1, kHalfArrowheadDimension);
    CGPathAddLineToPoint(pathRef, NULL, 0, 0);
    CGPathCloseSubpath(pathRef);
    
    [arrows setObject:[KTArrowhead arrowheadWithPath:pathRef attachment:CGPointMake(1.5f, kHalfArrowheadDimension)]
               forKey:@"arrow2"];
    
    pathRef = CGPathCreateMutable();
    CGPathMoveToPoint(pathRef, NULL,  kArrowheadDimension / 3 + 0.5f, kArrowheadDimension - 0.5f);
    CGPathAddLineToPoint(pathRef, NULL, kArrowheadDimension - 0.5f, kHalfArrowheadDimension);
    CGPathAddLineToPoint(pathRef, NULL, kArrowheadDimension / 3 + 0.5f, 0.5f);
    CGPathRef outline = CGPathCreateCopyByStrokingPath(pathRef, NULL, 1.0f, kCGLineCapRound, kCGLineJoinMiter, 4);
    CGPathRelease(pathRef);
    
    [arrows setObject:[KTArrowhead arrowheadWithPath:outline attachment:CGPointMake(kArrowheadDimension - 1, kHalfArrowheadDimension)]
               forKey:@"arrow3"];
    
    /*
     * Circles
     */
    
    flipTransform = CGAffineTransformTranslate(flipTransform, 0, kArrowheadDimension);
    flipTransform = CGAffineTransformScale(flipTransform, 1, -1);
    
    pathRef = CGPathCreateMutable();
    CGPathAddEllipseInRect(pathRef, &flipTransform, defaultRect);
    CGPathAddEllipseInRect(pathRef, NULL, CGRectInset(defaultRect, 1, 1));
    
    [arrows setObject:[KTArrowhead arrowheadWithPath:pathRef
                                          attachment:CGPointMake(0.25f, kHalfArrowheadDimension)
                                       capAdjustment:CGPointMake(0.25f, 0.0f)]
               forKey:@"open circle"];
    
    [arrows setObject:[KTArrowhead arrowheadWithPath:CGPathCreateWithEllipseInRect(defaultRect, &flipTransform)
                                          attachment:CGPointMake(0.5f, kHalfArrowheadDimension)]
               forKey:@"closed circle"];
    
    /*
     * Squares
     */
    
    pathRef = CGPathCreateMutable();
    CGPathAddRect(pathRef, &flipTransform, CGRectInset(defaultRect, 0.5f, 0.5f));
    CGPathAddRect(pathRef, NULL, CGRectInset(defaultRect, 1.5f, 1.5f));
    
    [arrows setObject:[KTArrowhead arrowheadWithPath:pathRef
                                          attachment:CGPointMake(0.75f, kHalfArrowheadDimension)
                                       capAdjustment:CGPointMake(0.25f, 0.0f)]
               forKey:@"open square"];
    
    [arrows setObject:[KTArrowhead arrowheadWithPath:CGPathCreateWithRect(CGRectInset(defaultRect, 0.5f, 0.5f), &flipTransform)
                                          attachment:CGPointMake(1.0f, kHalfArrowheadDimension)]
               forKey:@"closed square"];
    
    /*
     * T Shaped
     */
    
    pathRef = CGPathCreateMutable();
    CGPathAddRect(pathRef, &flipTransform, CGRectMake(0.0f, 0.5f, 1.0f, kArrowheadDimension - 1.0f));
    
    [arrows setObject:[KTArrowhead arrowheadWithPath:pathRef
                                          attachment:CGPointMake(0.25f, kHalfArrowheadDimension)
                                       capAdjustment:CGPointMake(0.25f, 0.0f)]
               forKey:@"T shape"];
    
    /*
     * Diamonds
     */
    
    diamondTransform = CGAffineTransformTranslate(diamondTransform, kHalfArrowheadDimension, kHalfArrowheadDimension);
    diamondTransform = CGAffineTransformRotate(diamondTransform, M_PI_4);
    diamondTransform = CGAffineTransformScale(diamondTransform, 1, -1);
    diamondTransform = CGAffineTransformTranslate(diamondTransform, -kHalfArrowheadDimension, -kHalfArrowheadDimension);
    
    CGPathRef diamond = CGPathCreateWithRect(CGRectInset(defaultRect, 1.5f, 1.5f), &diamondTransform);
    outline = CGPathCreateCopyByStrokingPath(diamond, NULL, 1.0f, kCGLineCapButt, kCGLineJoinMiter, 4);
    CGPathRelease(diamond);
    
    CGPoint attach = CGPointApplyAffineTransform(CGPointMake(1.5f, 1.5f), diamondTransform);
    
    [arrows setObject:[KTArrowhead arrowheadWithPath:outline
                                          attachment:attach
                                       capAdjustment:CGPointMake(0.25f, 0.0f)]
               forKey:@"open diamond"];
    
    [arrows setObject:[KTArrowhead arrowheadWithPath:CGPathCreateWithRect(CGRectInset(defaultRect, 1, 1), &diamondTransform)
                                          attachment:CGPointMake(1.0f, kHalfArrowheadDimension)]
               forKey:@"closed diamond"];
    
    
    return arrows;
}


@end
