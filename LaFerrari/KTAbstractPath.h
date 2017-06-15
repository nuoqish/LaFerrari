//
//  KTAbstractPath.h
//  LaFerrari
//
//  Created by stanshen on 17/6/11.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTStylable.h"

@protocol KTPathPainter;

@class KTFillTransform;
@class KTStrokeStyle;

typedef enum {
    KTFillRuleNonZeroWinding = 0,
    KTFillRuleEvenOdd
} KTFillRule;

@interface KTAbstractPath : KTStylable <NSCoding, NSCopying>

@property (nonatomic, assign) KTFillRule fillRule;
@property (nonatomic, readonly) CGPathRef path;
@property (nonatomic, readonly) CGPathRef strokePath;

+ (KTAbstractPath *)pathWithCGPathRef:(CGPathRef)pathRef;

- (NSUInteger)subpathCount;
- (NSString *)nodeSVGRepresentation;
- (void)addSVGArrowHeadsToGroup:(KTXMLElement *)group;
- (BOOL)canOutlineStroke;
- (KTAbstractPath *)outlineStroke;

// subclass can override this to enhance the default outline
- (void)addElementsToOutlinedStroke:(CGMutablePathRef)pathRef;
- (NSArray *)erase:(KTAbstractPath *)erasePath;

- (void)simplify;
- (void)flatten;

- (KTAbstractPath *)pathByFlatteningPath;

- (void)renderStrokeInContext:(CGContextRef)ctx;

@end
