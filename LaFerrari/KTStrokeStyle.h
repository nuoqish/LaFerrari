//
//  KTStrokeStyle.h
//  LaFerrari
//
//  Created by stanshen on 17/6/11.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    KTStrokeWidthAttribute = 1 << 0,
    KTStrokeCapAttribute = 1 << 1,
    KTStrokeJoinAttribute = 1 << 2,
    KTStrokeColorAttribute = 1 << 3,
    KTStrokeAllAttribute = 0xFFFF
} KTStrokeAttribute;

@class KTColor;
@class KTXMLElement;

extern NSString *KTStrokeArrowNone;

@interface KTStrokeStyle : NSObject <NSCoding, NSCopying>

@property (nonatomic, readonly) CGFloat width;
@property (nonatomic, readonly) CGLineCap cap;
@property (nonatomic, readonly) CGLineJoin join;
@property (nonatomic, readonly) KTColor *color;
@property (nonatomic, readonly) NSArray *dashPattern;
@property (nonatomic, readonly) NSString *startArrow;
@property (nonatomic, readonly) NSString *endArrow;

+ (KTStrokeStyle *)strokeStyleWithWidth:(CGFloat)width
                                    cap:(CGLineCap)cap
                                   join:(CGLineJoin)join
                                  color:(KTColor *)color
                            dashPattern:(NSArray *)dashPattern;
+ (KTStrokeStyle *)strokeStyleWithWidth:(CGFloat)width
                                    cap:(CGLineCap)cap
                                   join:(CGLineJoin)join
                                  color:(KTColor *)color
                            dashPattern:(NSArray *)dashPattern
                             startArrow:(NSString *)startArrow
                               endArrow:(NSString *)endArrow;
- (KTStrokeStyle *)strokeStyleWithSwappedArrows;
- (KTStrokeStyle *)strokeStyleSansArrows;
- (KTStrokeStyle *)adjustColor:(KTColor * (^)(KTColor *color))adjustment;

- (id)initWithWidth:(CGFloat)width
                cap:(CGLineCap)cap
               join:(CGLineJoin)join
              color:(KTColor *)color
        dashPattern:(NSArray *)dashPattern
         startArrow:(NSString *)startArrow
           endArrow:(NSString *)endArrow;


- (void)applyInContext:(CGContextRef)ctx;
- (void)randomize;
- (void)addSVGAttributes:(KTXMLElement *)element;

- (BOOL)isNullStroke;
- (BOOL)hasPattern;
- (BOOL)willRender;
- (BOOL)hasArrow;
- (BOOL)hasStartArrow;
- (BOOL)hasEndArrow;


@end
