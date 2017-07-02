//
//  KTColor.h
//  LaFerrari
//
//  Created by stanshen on 17/6/9.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import "KTPathPainter.h"

@interface KTColor : NSObject <NSCoding, NSCopying, KTPathPainter>

@property (nonatomic, readonly) CGFloat hue;
@property (nonatomic, readonly) CGFloat saturation;
@property (nonatomic, readonly) CGFloat brightness;
@property (nonatomic, readonly) CGFloat alpha;
@property (nonatomic, readonly) float red;
@property (nonatomic, readonly) float green;
@property (nonatomic, readonly) float blue;

+ (KTColor *)randomColor;
+ (KTColor *)colorWithHue:(CGFloat)hue saturation:(CGFloat)saturation brightness:(CGFloat)brightness alpha:(CGFloat)alpha;
+ (KTColor *)colorWithWhite:(float)white alpha:(CGFloat)alpha;
+ (KTColor *)colorWithRed:(float)red green:(float)green blue:(float)blue alpha:(CGFloat)alpha;
+ (KTColor *)colorWithDictionary:(NSDictionary *)dict;
+ (KTColor *)colorWithData:(NSData *)data;

- (KTColor *)initWithHue:(CGFloat)hue saturation:(CGFloat)saturation brightness:(CGFloat)brightness alpha:(CGFloat)alpha;

- (NSDictionary *)dictionary;
- (NSData *)colorData;

- (NSColor *)color;
- (NSColor *)opaqueColor;

- (CGColorRef)CGColor;
- (CGColorRef)opaqueCGColor;

- (void)set;
- (void)openGlSet;

- (KTColor *)adjustColor:(KTColor * (^)(KTColor *color))adjustment;
- (KTColor *)colorBalanceRed:(float)rShift green:(float)gShift blue:(float)bShift;
- (KTColor *)adjustHue:(float)hShift saturation:(float)sShift brightness:(float)bShift;
- (KTColor *)inverted;
- (KTColor *)colorWithAlphaComponent:(float)alpha;

+ (KTColor *)blackColor;
+ (KTColor *)grayColor;
+ (KTColor *)whiteColor;
+ (KTColor *)cyanColor;
+ (KTColor *)redColor;
+ (KTColor *)magentaColor;
+ (KTColor *)greenColor;
+ (KTColor *)yellowColor;
+ (KTColor *)blueColor;

- (NSString *)hexValue;
- (KTColor *)blendedColorWithFraction:(float)fraction ofColor:(KTColor *)color;


- (void)getRed:(float *)red Green:(float *)green Blue:(float *)blue Alpha:(float *)alpha;

@end
