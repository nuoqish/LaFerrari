//
//  KTGradientStop.m
//  LaFerrari
//
//  Created by stanshen on 17/6/11.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTGradientStop.h"

#import "KTColor.h"
#import "KTUtilities.h"
#import "KTXMLElement.h"

NSString *KTGradientStopRatioKey = @"KTGradientStopRatioKey";
NSString *KTGradientStopColorKey = @"KTGradientStopColorKey";

@interface KTGradientStop ()

@property (nonatomic, assign) float ratio;
@property (nonatomic, strong) KTColor *color;

@end

@implementation KTGradientStop

+ (KTGradientStop *)stopWithColor:(KTColor *)color andRatio:(float)ratio {
    KTGradientStop *stop = [[KTGradientStop alloc] initWithColor:color andRatio:ratio];
    return stop;
}

- (id)initWithColor:(KTColor *)color andRatio:(float)ratio {
    self = [super init];
    if (self) {
        self.color = color ?: [KTColor blackColor];
        self.ratio = KTClamp(0.f, 1.f, ratio);
    }
    return self;
}

- (KTGradientStop *)stopWithRatio:(float)ratio {
    return [KTGradientStop stopWithColor:self.color andRatio:ratio];
}

- (KTGradientStop *)stopWithColor:(KTColor *)color {
    return [KTGradientStop stopWithColor:color andRatio:self.ratio];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeFloat:self.ratio forKey:KTGradientStopRatioKey];
    [aCoder encodeObject:self.color forKey:KTGradientStopColorKey];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    
    self.ratio = [aDecoder decodeFloatForKey:KTGradientStopRatioKey];
    self.color = [aDecoder decodeObjectForKey:KTGradientStopColorKey];
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@: ratio: %f color: %@", [super description], self.ratio, [self.color description]];
}

- (BOOL)isEqual:(KTGradientStop *)stop {
    if (self.ratio != stop.ratio) {
        return NO;
    }
    if (![self.color isEqual:stop.color]) {
        return NO;
    }
    return YES;
}


- (KTXMLElement *)SVGXMLElement {
    KTXMLElement *stop = [KTXMLElement elementWithName:@"gradientStop"];
    [stop setAttribute:@"stop-ratio" value:[NSString stringWithFormat:@"%g", self.ratio]];
    [stop setAttribute:@"stop-color" value:self.color.hexValue];
    
    if (self.color.alpha != 1.0) {
        [stop setAttribute:@"stop-apacity" value:[NSString stringWithFormat:@"%g", self.color.alpha]];
    }
    return stop;
}

- (NSComparisonResult) compare:(KTGradientStop *)stop
{
    if (self.ratio < stop.ratio) {
        return NSOrderedAscending;
    } else if (self.ratio > stop.ratio) {
        return NSOrderedDescending;
    }
    
    return NSOrderedSame;
}


@end
