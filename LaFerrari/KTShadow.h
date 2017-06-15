//
//  KTShadow.h
//  LaFerrari
//
//  Created by stanshen on 17/6/10.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KTDrawing.h"

@class KTColor;
@class KTXMLElement;

@interface KTShadow : NSObject <NSCoding, NSCopying>

@property (nonatomic, readonly) KTColor *color;
@property (nonatomic, readonly) float radius;
@property (nonatomic, readonly) float offset;
@property (nonatomic, readonly) float angle;

+ (KTShadow *) shadowWithColor:(KTColor *)color radius:(float)radius offset:(float)offset angle:(float)angle;
- (id) initWithColor:(KTColor *)color radius:(float)radius offset:(float)offset angle:(float)angle;

- (void) applyInContext:(CGContextRef)ctx metaData:(KTRenderingMetaData)metaData;

- (KTShadow *) adjustColor:(KTColor * (^)(KTColor *color))adjustment;

- (void) addSVGAttributes:(KTXMLElement *)element;


@end
