//
//  KTGradient.h
//  LaFerrari
//
//  Created by stanshen on 17/6/11.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KTPathPainter.h"

typedef enum {
    KTGradientTypeLinear = 0,
    KTGradientTypeRadial
} KTGradientType;

@class KTColor;
@class KTGradientStop;
@class KTFillTransform;
@class KTXMLElement;;

@interface KTGradient : NSObject <NSCopying, NSCoding, KTPathPainter>

@property (nonatomic, readonly) KTGradientType type;
@property (nonatomic, readonly) NSArray *stops;


+ (KTGradient *)randomGradient;
+ (KTGradient *)defaultGradient;
+ (KTGradient *)gradientWithStart:(KTColor *)start andEnd:(KTColor *)end;
+ (KTGradient *)gradientWithType:(KTGradientType)type stops:(NSArray *)stops;

- (id)initWithType:(KTGradientType)type stops:(NSArray *)stops;

- (KTGradient *)gradientByReversing;
- (KTGradient *)gradientByDistributingEvenly;
- (KTGradient *)gradientWithStops:(NSArray *)stops;
- (KTGradient *)gradientWithType:(KTGradientType)type;
- (KTGradient *)gradientWithStop:(KTGradientStop *)stop substitutedForStop:(KTGradientStop *)replace;
- (KTGradient *)gradientByRemovingStop:(KTGradientStop *)stop;
- (KTGradient *)gradientByAddingStop:(KTGradientStop *)stop;
- (KTGradient *)gradientWithStopAtRatio:(float)ratio;
- (KTGradient *)adjustColor:(KTColor * (^)(KTColor *color))adjustment;

- (KTColor *)colorAtRatio:(float)ratio;
- (CGGradientRef)gradientRef;
- (void)drawSwatchInRect:(CGRect)rect;
- (KTXMLElement *)SVGElementWithID:(NSString *)uniqueId fillTransform:(KTFillTransform *)fillTransform;


@end
