//
//  KTShadow.m
//  LaFerrari
//
//  Created by stanshen on 17/6/10.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTShadow.h"

#import "KTColor.h"
#import "KTXMLElement.h"

NSString *KTShadowColorKey = @"KTShadowColorKey";
NSString *KTShadowRadiusKey = @"KTShadowRadiusKey";
NSString *KTShadowOffsetKey = @"KTShadowOffsetKey";
NSString *KTShadowAngleKey = @"KTShadowAngleKey";

@implementation KTShadow

+ (KTShadow *) shadowWithColor:(KTColor *)color radius:(float)radius offset:(float)offset angle:(float)angle
{
    KTShadow *shadow = [[KTShadow alloc] initWithColor:color radius:radius offset:offset angle:angle];
    return shadow;
}

- (id) initWithColor:(KTColor *)color radius:(float)radius offset:(float)offset angle:(float)angle
{
    self = [super init];
    
    if (self) {
        _color = color;
        _radius = radius;
        _offset = offset;
        _angle = angle;
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_color forKey:KTShadowColorKey];
    [coder encodeFloat:_radius forKey:KTShadowRadiusKey];
    [coder encodeFloat:_offset forKey:KTShadowOffsetKey];
    [coder encodeFloat:_angle forKey:KTShadowAngleKey];
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    
    _color = [coder decodeObjectForKey:KTShadowColorKey];
    _radius = [coder decodeFloatForKey:KTShadowRadiusKey];
    _offset = [coder decodeFloatForKey:KTShadowOffsetKey];
    _angle = [coder decodeFloatForKey:KTShadowAngleKey];
    
    return self;
}


- (BOOL) isEqual:(KTShadow *)shadow
{
    if (shadow == self) {
        return YES;
    }
    
    if (![shadow isKindOfClass:[KTShadow class]]) {
        return NO;
    }
    
    return ((_radius == shadow.radius) && (_offset == shadow.offset) && (_angle == shadow.angle) && [_color isEqual:shadow.color]);
}


- (void) applyInContext:(CGContextRef)ctx metaData:(KTRenderingMetaData)metaData
{
    float x = cos(_angle) * _offset * metaData.scale;
    float y = sin(_angle) * _offset * metaData.scale;
    
#if !TARGET_OS_IPHONE
    y *= -1;
#endif
    
    if (metaData.flags & KTRenderFlipped) {
        y *= -1;
    }
    
    CGContextSetShadowWithColor(ctx, CGSizeMake(x,y), _radius * metaData.scale, _color.CGColor);
}

- (KTShadow *) adjustColor:(KTColor * (^)(KTColor *color))adjustment
{
    return [KTShadow shadowWithColor:[self.color adjustColor:adjustment] radius:self.radius offset:self.offset angle:self.angle];
}

- (void) addSVGAttributes:(KTXMLElement *)element
{
    [element setAttribute:@"kato:shadowColor" value:[self.color hexValue]];
    [element setAttribute:@"kato:shadowOpacity" floatValue:[self.color alpha]];
    [element setAttribute:@"kato:shadowRadius" floatValue:self.radius];
    [element setAttribute:@"kato:shadowOffset" floatValue:self.offset];
    [element setAttribute:@"kato:shadowAngle" floatValue:self.angle];
}


@end
