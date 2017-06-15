//
//  KTColor.m
//  LaFerrari
//
//  Created by stanshen on 17/6/9.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTColor.h"

#import "KTAbstractPath.h"

#import "KTUtilities.h"
#import "KTGLUtilities.h"
#import "NSColor+Utils.h"

NSString *KTColorHueKey = @"KTColorHueKey";
NSString *KTColorSaturationKey = @"KTColorSaturationKey";
NSString *KTColorBrightnessKey = @"KTColorBrightnessKey";
NSString *KTColorAlphaKey = @"KTColorAlphaKey";

void HSV2RGB(float h, float s, float v, float *r, float *g, float *b);
void RGB2HSV(float r, float g, float b, float *h, float *s, float *v);

@interface KTColor ()

@property (nonatomic, assign) CGFloat hue;
@property (nonatomic, assign) CGFloat saturation;
@property (nonatomic, assign) CGFloat brightness;
@property (nonatomic, assign) CGFloat alpha;

@end

@implementation KTColor

+ (KTColor *)randomColor {
    float component[4];
    for (int i = 0; i < 4; i++) {
        component[i] = KTRandomFloat();
    }
    component[3] = 0.5 + component[3] * 0.5;
    return [KTColor colorWithHue:component[0] saturation:component[1] brightness:component[2] alpha:component[3]];
}

+ (KTColor *)colorWithWhite:(float)white alpha:(CGFloat)alpha {
    return [KTColor colorWithHue:0 saturation:0 brightness:white alpha:alpha];
}

+ (KTColor *)colorWithRed:(float)red green:(float)green blue:(float)blue alpha:(CGFloat)alpha {
    float hue, saturation, bright;
    RGB2HSV(red, green, blue, &hue, &saturation, &bright);
    return [KTColor colorWithHue:hue saturation:saturation brightness:bright alpha:alpha];
}

+ (KTColor *)colorWithHue:(CGFloat)hue saturation:(CGFloat)saturation brightness:(CGFloat)brightness alpha:(CGFloat)alpha {
    return [[KTColor alloc] initWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
}

- (KTColor *)initWithHue:(CGFloat)hue saturation:(CGFloat)saturation brightness:(CGFloat)brightness alpha:(CGFloat)alpha {
    self = [super init];
    if (self) {
        _hue = hue;
        _saturation = saturation;
        _brightness = brightness;
        _alpha = alpha;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    
    _hue = [aDecoder decodeFloatForKey:KTColorHueKey];
    _saturation = [aDecoder decodeFloatForKey:KTColorSaturationKey];
    _brightness = [aDecoder decodeFloatForKey:KTColorBrightnessKey];
    _alpha = [aDecoder decodeFloatForKey:KTColorAlphaKey];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeFloat:_hue forKey:KTColorHueKey];
    [aCoder encodeFloat:_saturation forKey:KTColorSaturationKey];
    [aCoder encodeFloat:_brightness forKey:KTColorBrightnessKey];
    [aCoder encodeFloat:_alpha forKey:KTColorAlphaKey];
}

- (id)copyWithZone:(NSZone *)zone {
    return self; // this object is imutable
}

- (BOOL)isEqual:(id)object {
    if (object == self) {
        return YES;
    }
    if (![object isKindOfClass:[KTColor class]]) {
        return NO;
    }
    KTColor *color = (KTColor *)object;
    return (_hue == color.hue) && (_saturation == color.saturation) && (_brightness == color.brightness) && (_alpha == color.alpha);
}

+ (KTColor *)colorWithDictionary:(NSDictionary *)dict {
    float hue = [dict[@"hue"] floatValue];
    float saturation = [dict[@"saturation"] floatValue];
    float brightness = [dict[@"brightness"] floatValue];
    float alpha = [dict[@"alpha"] floatValue];
    return [KTColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
}

- (NSDictionary *)dictionary {
    return @{@"hue":@(_hue), @"saturation":@(_saturation), @"brightness":@(_brightness), @"alpha":@(_alpha)};
}

+ (KTColor *)colorWithData:(NSData *)data {
    UInt16 *values = (UInt16 *)[data bytes];
    float components[4];
    for (int i = 0; i < 4; i++) {
        components[i] = CFSwapInt16LittleToHost(values[i]);
        components[i] /= USHRT_MAX;
    }
    return [KTColor colorWithHue:components[0] saturation:components[1] brightness:components[2] alpha:components[3]];
}

- (NSData *)colorData {
    UInt16 data[4];
    data[0] = _hue * USHRT_MAX;
    data[1] = _saturation * USHRT_MAX;
    data[2] = _brightness * USHRT_MAX;
    data[3] = _alpha * USHRT_MAX;
    for (int i = 0; i < 4; i++) {
        data[i] = CFSwapInt16HostToLittle(data[i]);
    }
    return [NSData dataWithBytes:data length:8];
}

- (void)set {
    [[self color] set];
}

- (void)openGlSet {
    [[self color] openGLSet];
}

- (NSColor *)color {
    return [NSColor colorWithHue:_hue saturation:_saturation brightness:_brightness alpha:_alpha];
}

- (NSColor *)opaqueColor {
    return [NSColor colorWithHue:_hue saturation:_saturation brightness:_brightness alpha:1.];
}

- (CGColorRef)CGColor {
    return [[self color] CGColor];
}

- (CGColorRef)opaqueCGColor {
    return [[self opaqueColor] CGColor];
}

- (KTColor *)colorWithAlphaComponent:(float)alpha {
    return [KTColor colorWithHue:_hue saturation:_saturation brightness:_brightness alpha:alpha];
}


- (float)red {
    float r,g,b;
    HSV2RGB(_hue, _saturation, _brightness, &r, &g, &b);
    return r;
}

- (float)green {
    float r,g,b;
    HSV2RGB(_hue, _saturation, _brightness, &r, &g, &b);
    return g;
}

- (float)blue {
    float r,g,b;
    HSV2RGB(_hue, _saturation, _brightness, &r, &g, &b);
    return b;
}

- (KTColor *)colorBalanceRed:(float)rShift green:(float)gShift blue:(float)bShift {
    float r,g,b,h,s,v;
    HSV2RGB(_hue, _saturation, _brightness, &r, &g, &b);
    r = KTClamp(0, 1, rShift);
    g = KTClamp(0, 1, gShift);
    b = KTClamp(0, 1, bShift);
    RGB2HSV(r, g, b, &h, &s, &v);
    return [KTColor colorWithHue:h saturation:s brightness:v alpha:_alpha];
}

- (KTColor *)adjustHue:(float)hShift saturation:(float)sShift brightness:(float)bShift {
    float h = _hue + hShift;
    BOOL negative = (h < 0);
    h = fmodf(fabs(h), 1.0f);
    if (negative) {
        h = 1.f - h;
    }
    float s = KTClamp(0, 1, _saturation * (1 + sShift));
    float v = KTClamp(0, 1, _brightness * (1 + bShift));
    return [KTColor colorWithHue:h saturation:s brightness:v alpha:_alpha];
}

- (KTColor *)inverted {
    float r, g, b;
    HSV2RGB(_hue, _saturation, _brightness, &r, &g, &b);
    return [KTColor colorWithRed:(1.f - r) green:(1.f - g) blue:(1.f - b) alpha:_alpha];
}

+ (KTColor *)blackColor {
    return [KTColor colorWithHue:0.f saturation:0.f brightness:0.f alpha:1.f];
}

+ (KTColor *)grayColor {
    return [KTColor colorWithHue:0.f saturation:0.f brightness:0.25f alpha:1.f];
}

+ (KTColor *)whiteColor {
    return [KTColor colorWithHue:0.f saturation:0.f brightness:1.f alpha:1.f];
}

+ (KTColor *)cyanColor {
    return [KTColor colorWithRed:0.f green:1.f blue:1.f alpha:1.f];
}

+ (KTColor *)redColor {
    return [KTColor colorWithRed:1.f green:0.f blue:0.f alpha:1.f];
}

+ (KTColor *)magentaColor {
    return [KTColor colorWithRed:1.f green:0.f blue:1.f alpha:1.f];
}

+ (KTColor *)greenColor {
    return [KTColor colorWithRed:0.f green:1.f blue:0.f alpha:1.f];
}

+ (KTColor *)yellowColor {
    return [KTColor colorWithRed:1.f green:1.f blue:0.f alpha:1.f];
}

+ (KTColor *)blueColor {
    return [KTColor colorWithRed:0.f green:0.f blue:1.f alpha:1.f];
}

- (KTColor *)blendedColorWithFraction:(float)fraction ofColor:(KTColor *)color {
    float inR, inG, inB;
    float selfR, selfG, selfB;
    HSV2RGB(color.hue, color.saturation, color.brightness, &inR, &inG, &inB);
    HSV2RGB(_hue, _saturation, _brightness, &selfR, &selfG, &selfB);
    float r = fraction * inR + (1.f - fraction) * selfR;
    float g = fraction * inG + (1.f - fraction) * selfG;
    float b = fraction * inB + (1.f - fraction) * selfB;
    float a = fraction * color.alpha + (1.f - fraction) * _alpha;
    return [KTColor colorWithRed:r green:g blue:b alpha:a];
}

- (NSString *)hexValue {
    float r, g, b;
    HSV2RGB(_hue, _saturation, _brightness, &r, &g, &b);
    return [NSString stringWithFormat:@"#%.2x%.2x%.2x", (int)(r * 255 + 0.5f), (int)(g * 255 + 0.5f), (int)(b * 255 + 0.5f)];
}

- (void)paintPath:(KTAbstractPath *)path inContext:(CGContextRef)ctx {
    CGContextAddPath(ctx, path.path);
    CGContextSetFillColorWithColor(ctx, self.CGColor);
    if (path.fillRule == KTFillRuleEvenOdd) {
        CGContextEOFillPath(ctx);
    }
    else {
        CGContextFillPath(ctx);
    }
}

- (void)drawSwatchInRect:(CGRect)rect {
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    KTCGDrawTransparencyDiamondInRect(ctx, rect);
    [self set];
    CGContextFillRect(ctx, rect);
}

- (void)drawEyedropperSwatchInRect:(CGRect)rect {
    [self drawSwatchInRect:rect];
}

- (BOOL)wantsCenteredFillTransform {
    return NO;
}

- (BOOL)transformable {
    return NO;
}

- (BOOL)canPaintStroke {
    return YES;
}

- (void)paintText:(id<KTTextRenderer>)text inContext:(CGContextRef)ctx {
    [self set];
    [text drawTextInContext:ctx drawingMode:kCGTextFill];
}

- (KTColor *)adjustColor:(KTColor *(^)(KTColor *))adjustment {
    return adjustment(self);
}


@end

#pragma mark Color Conversion

void HSV2RGB(float h, float s, float v, float *r, float *g, float *b)
{
    if (s == 0) {
        *r = *g = *b = v;
    } else {
        float   f,p,q,t;
        int     i;
        
        h *= 360;
        
        if (h == 360.0f) {
            h = 0.0f;
        }
        
        h /= 60;
        i = floor(h);
        
        f = h - i;
        p = v * (1.0 - s);
        q = v * (1.0 - (s*f));
        t = v * (1.0 - (s * (1.0 - f)));
        
        switch (i) {
            case 0: *r = v; *g = t; *b = p; break;
            case 1: *r = q; *g = v; *b = p; break;
            case 2: *r = p; *g = v; *b = t; break;
            case 3: *r = p; *g = q; *b = v; break;
            case 4: *r = t; *g = p; *b = v; break;
            case 5: *r = v; *g = p; *b = q; break;
        }
    }
}

void RGB2HSV(float r, float g, float b, float *h, float *s, float *v)
{
    float max = MAX(r, MAX(g, b));
    float min = MIN(r, MIN(g, b));
    float delta = max - min;
    
    *v = max;
    *s = (max != 0.0f) ? (delta / max) : 0.0f;
    
    if (*s == 0.0f) {
        *h = 0.0f;
    } else {
        if (r == max) {
            *h = (g - b) / delta;
        } else if (g == max) {
            *h = 2.0f + (b - r) / delta;
        } else if (b == max) {
            *h = 4.0f + (r - g) / delta;
        }
        
        *h *= 60.0f;
        
        if (*h < 0.0f) {
            *h += 360.0f;
        }
    }
    
    *h /= 360.0f;
}

