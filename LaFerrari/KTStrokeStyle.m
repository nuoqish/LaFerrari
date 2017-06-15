//
//  KTStrokeStyle.m
//  LaFerrari
//
//  Created by stanshen on 17/6/11.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTStrokeStyle.h"

#import "KTColor.h"
#import "KTXMLElement.h"

NSString *KTStrokeArrowNone = @"";

NSString *KTStrokeColorKey = @"KTStrokeColorKey";
NSString *KTStrokeWidthKey = @"KTStrokeWidthKey";
NSString *KTStrokeCapKey = @"KTStrokeCapKey";
NSString *KTStrokeJoinKey = @"KTStrokeJoinKey";
NSString *KTStrokeDashPatternKey = @"KTStrokeDashPatternKey";
NSString *KTStrokeStartArrowKey = @"KTStrokeStartArrowKey";
NSString *KTStrokeEndArrowKey = @"KTStrokeEndArrowKey";


@interface KTStrokeStyle ()

@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGLineCap cap;
@property (nonatomic, assign) CGLineJoin join;
@property (nonatomic, strong) KTColor *color;
@property (nonatomic, strong) NSArray *dashPattern;
@property (nonatomic, strong) NSString *startArrow;
@property (nonatomic, strong) NSString *endArrow;

@end

@implementation KTStrokeStyle

+ (KTStrokeStyle *)strokeStyleWithWidth:(CGFloat)width cap:(CGLineCap)cap join:(CGLineJoin)join color:(KTColor *)color dashPattern:(NSArray *)dashPattern {
    KTStrokeStyle *style = [[KTStrokeStyle alloc] initWithWidth:width cap:cap join:join color:color dashPattern:dashPattern startArrow:KTStrokeArrowNone endArrow:KTStrokeArrowNone];
    return style;
}

+ (KTStrokeStyle *)strokeStyleWithWidth:(CGFloat)width cap:(CGLineCap)cap join:(CGLineJoin)join color:(KTColor *)color dashPattern:(NSArray *)dashPattern startArrow:(NSString *)startArrow endArrow:(NSString *)endArrow {
    KTStrokeStyle *style = [[KTStrokeStyle alloc] initWithWidth:width cap:cap join:join color:color dashPattern:dashPattern startArrow:startArrow endArrow:endArrow];
    return style;
}

- (KTStrokeStyle *)strokeStyleWithSwappedArrows {
    if ([self.startArrow isEqualToString:self.endArrow]) {
        return self;
    }
    
    return [KTStrokeStyle strokeStyleWithWidth:self.width cap:self.cap join:self.join color:self.color dashPattern:self.dashPattern startArrow:self.startArrow endArrow:self.endArrow];
}

- (KTStrokeStyle *)strokeStyleSansArrows {
    if (![self hasArrow]) {
        return self;
    }
    return [KTStrokeStyle strokeStyleWithWidth:self.width cap:self.cap join:self.join color:self.color dashPattern:self.dashPattern startArrow:KTStrokeArrowNone endArrow:KTStrokeArrowNone];
}

- (KTStrokeStyle *)adjustColor:(KTColor *(^)(KTColor *))adjustment {
    return [KTStrokeStyle strokeStyleWithWidth:self.width cap:self.cap join:self.join color:[self.color adjustColor:adjustment] dashPattern:self.dashPattern startArrow:self.startArrow endArrow:self.endArrow];
}

- (instancetype)init {
    return [self initWithWidth:1 cap:kCGLineCapRound join:kCGLineJoinRound color:[KTColor blackColor] dashPattern:@[] startArrow:KTStrokeArrowNone endArrow:KTStrokeArrowNone];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)initWithWidth:(CGFloat)width cap:(CGLineCap)cap join:(CGLineJoin)join color:(KTColor *)color dashPattern:(NSArray *)dashPattern startArrow:(NSString *)startArrow endArrow:(NSString *)endArrow {
    self = [super init];
    
    if (self) {
        self.width = width;
        self.cap = cap;
        self.join = join;
        self.color = color;
        self.dashPattern = dashPattern ?: @[];
        self.startArrow = startArrow ?: KTStrokeArrowNone;
        self.endArrow = endArrow ?: KTStrokeArrowNone;
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    
    self.width = [aDecoder decodeFloatForKey:KTStrokeWidthKey];
    self.cap = [aDecoder decodeInt32ForKey:KTStrokeCapKey];
    self.join = [aDecoder decodeInt32ForKey:KTStrokeJoinKey];
    self.color = [aDecoder decodeObjectForKey:KTStrokeColorKey];
    self.dashPattern = [aDecoder decodeObjectForKey:KTStrokeDashPatternKey] ?: @[];
    self.startArrow = [aDecoder decodeObjectForKey:KTStrokeStartArrowKey] ?: KTStrokeArrowNone;
    self.endArrow = [aDecoder decodeObjectForKey:KTStrokeEndArrowKey] ?: KTStrokeArrowNone;
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeFloat:(float)self.width forKey:KTStrokeWidthKey];
    [aCoder encodeInt32:self.cap forKey:KTStrokeCapKey];
    [aCoder encodeInt32:self.join forKey:KTStrokeJoinKey];
    [aCoder encodeObject:self.color forKey:KTStrokeColorKey];
    
    if ([self hasPattern]) {
        [aCoder encodeObject:self.dashPattern forKey:KTStrokeDashPatternKey];
    }
    
    if (self.startArrow) {
        [aCoder encodeObject:self.startArrow forKey:KTStrokeStartArrowKey];
    }
    
    if (self.endArrow) {
        [aCoder encodeObject:self.endArrow forKey:KTStrokeEndArrowKey];
    }
    
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@: width: %f, cap: %d, join: %d, color:%@, dastPattern: %@, start arrow: %@, end arrow: %@",
            [super description], self.width, self.cap, self.join, [self.color description], [self.dashPattern description], self.startArrow, self.endArrow];
    
}

- (void)randomize {
    self.width = random() % 100 / 10;
    self.color = [KTColor randomColor];
    self.cap = kCGLineCapRound;
    self.join = kCGLineJoinRound;
}

- (void)applyPatternInContext:(CGContextRef)ctx {
    NSMutableArray *dashes = self.dashPattern.mutableCopy;
    
    while ([[dashes lastObject] intValue] == 0) {
        [dashes removeLastObject];
    }
    
    if (dashes.count % 2) {
        NSArray *repeat = dashes.copy;
        [dashes addObjectsFromArray:repeat];
    }
    
    CGFloat lengths[dashes.count];
    int i = 0;
    for (NSNumber *number in dashes) {
        lengths[i] = [number floatValue];
        if (self.cap != kCGLineCapRound && lengths[i] == 0) {
            lengths[i] = 0.1;
        }
        i++;
    }
    
    CGContextSetLineDash(ctx, 0.0f, lengths, dashes.count);
}

- (void)applyInContext:(CGContextRef)ctx {
    if (![self willRender]) {
        return;
    }
    
    CGContextSetLineWidth(ctx, self.width);
    CGContextSetLineCap(ctx, self.cap);
    CGContextSetLineJoin(ctx, self.join);
    CGContextSetStrokeColorWithColor(ctx, self.color.CGColor);
    
    if (self.hasPattern) {
        [self applyPatternInContext:ctx];
    }
    else {
        // turn off dash
        CGContextSetLineDash(ctx, 0.0f, NULL, 0);
    }
    
}


NSString * KTSVGStringForCGLineJoin(CGLineJoin join)
{
    NSString *joins[] = {@"miter", @"round", @"bevel"};
    return joins[join];
}

NSString * KTSVGStringForCGLineCap(CGLineCap cap)
{
    NSString *caps[] = {@"butt", @"round", @"square"};
    return caps[cap];
}
- (void)addSVGAttributes:(KTXMLElement *)element {
    [element setAttribute:@"stroke-color" value:[self.color hexValue]];
    [element setAttribute:@"stroke-width" value:[NSString stringWithFormat:@"%g", self.width]];
    
    [element setAttribute:@"stroke-linecap" value:KTSVGStringForCGLineCap(self.cap)];
    [element setAttribute:@"stroke-linejoin" value:KTSVGStringForCGLineJoin(self.join)];
    [element setAttribute:@"stroke-opacity" floatValue:self.color.alpha];
    
    if (self.hasPattern) {
        NSMutableArray *dashes = self.dashPattern.mutableCopy;
        NSMutableString *svgPattern = @"".mutableCopy;
        
        while ([[dashes lastObject] intValue] == 0) {
            [dashes removeLastObject];
        }
        
        BOOL first = YES;
        for (NSNumber *number in dashes) {
            if (!first) {
                [svgPattern appendString:@","];
            }
            first = NO;
            [svgPattern appendString:[number stringValue]];
        }
        
        [element setAttribute:@"stroke-dasharray" value:svgPattern];
        
        
    }
    
}

- (BOOL)isEqual:(KTStrokeStyle *)stroke {
    
    if (stroke == self) {
        return YES;
    }
    if (![stroke isKindOfClass:[KTStrokeStyle class]]) {
        return NO;
    }
    
    return (self.width == stroke.width && [self.color isEqual:stroke.color] && self.cap == stroke.cap && self.join == stroke.join && [self.dashPattern isEqual:stroke.dashPattern] &&
            [self.startArrow isEqualToString:stroke.startArrow] && [self.endArrow isEqualToString:stroke.endArrow]);
}

- (BOOL)willRender {
    return (self.color && self.color.alpha > 0 & self.width > 0);
}

- (BOOL)isNullStroke {
    if (!self.color && ![self hasPattern] && !self.width && !self.cap && !self.join && ![self hasArrow]) {
        return YES;
    }
    if (self.width == 0) {
        return YES;
    }
    return NO;
}

- (BOOL)hasPattern {
    if (!self.dashPattern || self.dashPattern.count == 0) {
        return NO;
    }
    
    float sum = 0;
    for (NSNumber *number in self.dashPattern) {
        sum += [number floatValue];
    }
    
    return sum > 0 ;
}

- (BOOL)hasArrow {
    return [self hasStartArrow] && [self hasEndArrow];
}

- (BOOL)hasStartArrow {
    return ![self.startArrow isEqualToString:KTStrokeArrowNone];
}

- (BOOL)hasEndArrow {
    return ![self.endArrow isEqualToString:KTStrokeArrowNone];
}



































@end
