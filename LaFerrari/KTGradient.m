//
//  KTGradient.m
//  LaFerrari
//
//  Created by stanshen on 17/6/11.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTGradient.h"

#import "KTGradientStop.h"
#import "KTColor.h"
#import "KTPath.h"
#import "KTText.h"
#import "KTFillTransform.h"
#import "KTXMLElement.h"
#import "KTUtilities.h"
#import "KTGLUtilities.h"

NSString *KTGradientTypeKey = @"KTGradientTypeKey";
NSString *KTGradientStopsKey = @"KTGradientStopsKey";

@interface KTGradient ()

@property (nonatomic, assign) KTGradientType type;
@property (nonatomic, strong) NSArray *stops;

@end

@implementation KTGradient {
    CGGradientRef       gradientRef_; // for rendering
}

+ (KTGradient *)randomGradient {
    NSMutableArray *stops = @[].mutableCopy;
    
    for (int i = 0; i < 3; i++) {
        float ratio = (random() % 10000) / 10000.;
        [stops addObject:[KTGradientStop stopWithColor:[KTColor randomColor] andRatio:ratio]];
    }
    
    return [KTGradient gradientWithType:(KTGradientType)(random() % 2) stops:stops];
}

+ (KTGradient *)defaultGradient {
    // return a gradient that fades from black to white
    return [KTGradient gradientWithStart:[KTColor blackColor] andEnd:[KTColor whiteColor]];
}

+ (KTGradient *)gradientWithStart:(KTColor *)start andEnd:(KTColor *)end {
    
    NSArray *stops = @[[KTGradientStop stopWithColor:start andRatio:0.0],
                       [KTGradientStop stopWithColor:end andRatio:1.0]];
    
    KTGradient *gradient = [[KTGradient alloc] initWithType:KTGradientTypeLinear stops:stops];
    
    return gradient;
}

+ (KTGradient *)gradientWithType:(KTGradientType)type stops:(NSArray *)stops {
    return [[KTGradient alloc] initWithType:type stops:stops];
}

- (id)initWithType:(KTGradientType)type stops:(NSArray *)stops {
    self = [super init];
    
    if (self) {
        
        self.type = type;
        
        if (!stops || !stops.count) {
            self.stops = @[[KTGradientStop stopWithColor:[KTColor blackColor] andRatio:0.0],
                           [KTGradientStop stopWithColor:[KTColor whiteColor] andRatio:1.0]];
        }
        else {
            self.stops = [stops sortedArrayUsingSelector:@selector(compare:)];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInt32:self.type forKey:KTGradientTypeKey];
    [aCoder encodeObject:self.stops forKey:KTGradientStopsKey];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    
    self.type = [aDecoder decodeInt32ForKey:KTGradientTypeKey];
    self.stops = [aDecoder decodeObjectForKey:KTGradientStopsKey];
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (void)dealloc {
    CGGradientRelease(gradientRef_);
}

- (KTGradient *)gradientByReversing {
    NSMutableArray *reversed = @[].mutableCopy;
    
    for (KTGradientStop *stop in [self.stops reverseObjectEnumerator]) {
        [reversed addObject:[stop stopWithRatio:1.f - stop.ratio]];
    }
    return [self gradientWithStops:reversed];
}

- (KTGradient *)gradientByDistributingEvenly {
    NSMutableArray *distributed = @[].mutableCopy;
    
    float offset = 0.0f;
    float spacing = 1.0 / (self.stops.count - 1);
    
    for (KTGradientStop *stop in self.stops) {
        [distributed addObject:[stop stopWithRatio:offset]];
        offset += spacing;
    }
    
    return [self gradientWithStops:distributed];
    
}

- (KTGradient *)adjustColor:(KTColor *(^)(KTColor *))adjustment {
    NSMutableArray *adjusted = @[].mutableCopy;
    
    for (KTGradientStop *stop in self.stops) {
        [adjusted addObject:[stop stopWithColor:[stop.color adjustColor:adjustment]]];
    }
    return [self gradientWithStops:adjusted];
}

- (KTGradient *)gradientWithStops:(NSArray *)stops {
    return [KTGradient gradientWithType:self.type stops:stops];
}

- (KTGradient *)gradientWithType:(KTGradientType)type {
    return [KTGradient gradientWithType:type stops:self.stops];
}

- (KTGradient *)gradientByRemovingStop:(KTGradientStop *)stopToRemove {
    NSMutableArray *remaining = @[].mutableCopy;
    
    for (KTGradientStop *stop in self.stops) {
        if (stop != stopToRemove) {
            [remaining addObject:stop];
        }
    }
    return [self gradientWithStops:remaining];
}

- (KTGradient *)gradientWithStop:(KTGradientStop *)newStop substitutedForStop:(KTGradientStop *)replace {
    NSMutableArray *substituted = @[].mutableCopy;
    
    for (KTGradientStop *stop in self.stops) {
        [substituted addObject:(stop == replace ? newStop : stop)];
    }
    
    return [self gradientWithStops:substituted];
}

- (KTGradient *)gradientWithStopAtRatio:(float)ratio {
    NSMutableArray *tempStops = self.stops.mutableCopy;
    
    KTGradientStop *previous = nil;
    BOOL added = NO;
    
    for (KTGradientStop *stop in tempStops) {
        if (stop.ratio > ratio) {
            if (!previous) {
                [tempStops insertObject:[KTGradientStop stopWithColor:stop.color andRatio:ratio] atIndex:0];
                added = YES;
            }
            else {
                float fraction  = (ratio - previous.ratio) / (stop.ratio - previous.ratio);
                KTColor *blended = [previous.color blendedColorWithFraction:fraction ofColor:stop.color];
                NSUInteger index = [tempStops indexOfObject:stop];
                
                [tempStops insertObject:[KTGradientStop stopWithColor:blended andRatio:ratio] atIndex:index];
                added = YES;
            }
            break;
        }
        previous = stop;
    }
    
    if (!added) {
        KTGradientStop *lastStop = (KTGradientStop *)tempStops.lastObject;
        [tempStops addObject:[KTGradientStop stopWithColor:lastStop.color andRatio:ratio]];
    }
    
    KTGradient *result = [KTGradient gradientWithType:self.type stops:tempStops];
    return result;
}

- (KTGradient *)gradientByAddingStop:(KTGradientStop *)newStop {
    NSMutableArray  *tempStops = self.stops.mutableCopy;
    BOOL            added =  NO;
    
    for (KTGradientStop *stop in tempStops) {
        if (stop.ratio > newStop.ratio) {
            [tempStops insertObject:newStop atIndex:[tempStops indexOfObject:stop]];
            added = YES;
            break;
        }
    }
    
    if (!added) {
        [tempStops addObject:newStop];
    }
    
    KTGradient *result = [KTGradient gradientWithType:self.type stops:tempStops];
    return result;
}

- (KTColor *)colorAtRatio:(float)ratio {
    KTGradientStop  *previous = nil;
    
    ratio = KTClamp(0.0f, 1.0f, ratio);
    
    for (KTGradientStop *stop in self.stops) {
        if (stop.ratio > ratio) { // we've passed the point of insertion
            if (!previous) {
                return stop.color;
            } else {
                float fraction = (ratio - previous.ratio) / (stop.ratio - previous.ratio);
                return [previous.color blendedColorWithFraction:fraction ofColor:stop.color];
            }
        }
        previous = stop;
    }
    
    KTGradientStop *lastStop = (KTGradientStop *) self.stops.lastObject;
    return lastStop.color;
}

- (BOOL)isEqual:(KTGradient *)gradient {
    
    if (!gradient || ![gradient isKindOfClass:[KTGradient class]]) {
        return NO;
    }
    
    // test relevant ivars in fastest to slowest order
    if (self.type != gradient.type) {
        return NO;
    }
    
    if (![self.stops isEqualToArray:gradient.stops]) {
        return NO;
    }
    
    return YES;
    
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@: type: %d stops: %@", [super description], _type, _stops];
}

- (CGGradientRef)newGradientRef {
    NSMutableArray *colors = @[].mutableCopy;
    CGFloat locations[self.stops.count];
    int idx = 0;
    for (KTGradientStop *stop in self.stops) {
        [colors addObject:(id)stop.color.CGColor];
        locations[idx++] = stop.ratio;
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef result = CGGradientCreateWithColors(colorSpace, (CFArrayRef)colors, locations);
    CGColorSpaceRelease(colorSpace);
    
    return result;
}

- (CGGradientRef)gradientRef {
    if (!gradientRef_) {
        gradientRef_ = [self newGradientRef];
    }
    return gradientRef_;
}

- (void)drawSwatchInRect:(CGRect)rect {
    CGContextRef ctx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    
    CGGradientDrawingOptions options = kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation;
    
    KTCGDrawCheckersInRect(ctx, rect, 7);
    
    CGContextSaveGState(ctx);
    CGContextClipToRect(ctx, rect);
    
    CGContextSetInterpolationQuality(ctx, kCGInterpolationHigh);
    
    if (self.type == KTGradientTypeRadial) {
        float   width = CGRectGetWidth(rect) / 2;
        float   height = CGRectGetHeight(rect) / 2;
        float   radius = sqrt(width * width + height * height);
        
        CGContextDrawRadialGradient(ctx, [self gradientRef], KTCenterOfRect(rect), 0,  KTCenterOfRect(rect), radius, options);
    } else {
        CGContextDrawLinearGradient(ctx, [self gradientRef], rect.origin, CGPointMake(CGRectGetMaxX(rect), rect.origin.y), options);
    }
    
    CGContextRestoreGState(ctx);
    
    
}

- (void)drawEyedropperSwatchInRect:(CGRect)rect {
    CGContextRef ctx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    
    CGGradientDrawingOptions options = kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation;
    
    KTCGDrawCheckersInRect(ctx, rect, 7);
    
    CGContextSaveGState(ctx);
    CGContextClipToRect(ctx, rect);
    
    CGContextSetInterpolationQuality(ctx, kCGInterpolationHigh);
    CGContextDrawLinearGradient(ctx, [self gradientRef], rect.origin, CGPointMake(CGRectGetMaxX(rect), rect.origin.y), options);
    CGContextRestoreGState(ctx);
    
}

- (void)paintPath:(KTPath *)path inContext:(CGContextRef)ctx {
    KTFillTransform *fillTransform = path.fillTransform;
    CGGradientDrawingOptions options = kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation;
    
    CGContextSaveGState(ctx);
    CGContextAddPath(ctx, path.path);
    if (path.fillRule == KTFillRuleEvenOdd) {
        CGContextEOClip(ctx);
    }
    else {
        CGContextClip(ctx);
    }
    CGContextConcatCTM(ctx, fillTransform.transform);
    
    if (_type == KTGradientTypeRadial) {
        CGPoint delta = KTSubtractPoints(fillTransform.end, fillTransform.start);
        CGContextDrawRadialGradient(ctx, [self gradientRef], fillTransform.start, 0, fillTransform.start, KTMagnitudeVector(delta), options);
    }
    else {
        CGContextDrawLinearGradient(ctx, [self gradientRef], fillTransform.start, fillTransform.end, options);
    }
    
    CGContextRestoreGState(ctx);
}

- (BOOL)wantsCenteredFillTransform {
    return _type == KTGradientTypeRadial;
}

- (BOOL)transformable {
    return YES;
}

- (BOOL)canPaintStroke {
    return NO;
}

- (void)paintText:(KTText *)text inContext:(CGContextRef)ctx {
    if (!text.text || text.text.length == 0) {
        return;
    }
    
    KTFillTransform             *fillTransform = text.fillTransform;
    CGGradientDrawingOptions    options = kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation;
    BOOL                        didClip;
    
    CGContextSaveGState(ctx);
    [text drawTextInContext:(CGContextRef)ctx drawingMode:kCGTextClip didClip:&didClip];
    
    if (!didClip) {
        CGContextRestoreGState(ctx);
        return;
    }
    
    // apply the fill transform
    CGContextConcatCTM(ctx, fillTransform.transform);
    
    if (_type == KTGradientTypeRadial) {
        CGPoint delta = KTSubtractPoints(fillTransform.end, fillTransform.start);
        CGContextDrawRadialGradient(ctx, [self gradientRef], fillTransform.start, 0, fillTransform.start, KTMagnitudeVector(delta), options);
    } else {
        CGContextDrawLinearGradient(ctx, [self gradientRef], fillTransform.start, fillTransform.end, options);
    }
    
    CGContextRestoreGState(ctx);
    
}

- (KTXMLElement *)SVGElementWithID:(NSString *)uniqueId fillTransform:(KTFillTransform *)fillTransform {
    KTXMLElement *gradient;
    
    if (_type == KTGradientTypeRadial) {
        gradient = [KTXMLElement elementWithName:@"radialGradient"];
        [gradient setAttribute:@"cx" floatValue:fillTransform.start.x];
        [gradient setAttribute:@"cy" floatValue:fillTransform.start.y];
        [gradient setAttribute:@"r" floatValue:KTDistanceL2(fillTransform.end, fillTransform.start)];
    } else {
        gradient = [KTXMLElement elementWithName:@"linearGradient"];
        [gradient setAttribute:@"x1" floatValue:fillTransform.start.x];
        [gradient setAttribute:@"y1" floatValue:fillTransform.start.y];
        [gradient setAttribute:@"x2" floatValue:fillTransform.end.x];
        [gradient setAttribute:@"y2" floatValue:fillTransform.end.y];
    }
    
    [gradient setAttribute:@"id" value:uniqueId];
    [gradient setAttribute:@"gradientUnits" value:@"userSpaceOnUse"];
    [gradient setAttribute:@"gradientTransform" value:KTSVGStringFromCGAffineTransform(fillTransform.transform)];
    
    for (KTGradientStop *stop in _stops) {
        [gradient addChild:[stop SVGXMLElement]];
    }
    
    return gradient;
}

@end
