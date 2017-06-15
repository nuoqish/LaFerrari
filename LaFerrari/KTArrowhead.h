//
//  KTArrowhead.h
//  LaFerrari
//
//  Created by stanshen on 17/6/11.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KTArrowhead : NSObject

@property (nonatomic, readonly) CGPoint attachment;
@property (nonatomic, readonly) CGPoint capAdjustment;
@property (nonatomic, readonly) CGPathRef path;
@property (nonatomic, readonly) CGRect bounds;
@property (nonatomic, readonly) float insetLength;

+ (NSDictionary *)arrowheads;

+ (KTArrowhead *)arrowheadWithPath:(CGPathRef)pathRef attachment:(CGPoint)attach;
+ (KTArrowhead *)arrowheadWithPath:(CGPathRef)pathRef attachment:(CGPoint)attach capAdjustment:(CGPoint)adjustment;
- (id)initWithPath:(CGPathRef)pathRef attachment:(CGPoint)attach capAdjustment:(CGPoint)adjustment;

- (CGRect)boundingBoxAtPosition:(CGPoint)point scale:(float)scale angle:(float)angle useAdjustment:(BOOL)adjust;
- (void)addToMutablePath:(CGMutablePathRef)pathRef position:(CGPoint)point scale:(float)scale angle:(float)angle useAdjustment:(BOOL)adjust;
- (void)addArrowInContext:(CGContextRef)ctx position:(CGPoint)point scale:(float)scale angle:(float)angle useAdjustment:(BOOL)adjust;
- (float)insetLength:(BOOL)adjusted;

@end
