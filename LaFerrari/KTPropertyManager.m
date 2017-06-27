//
//  KTPropertyManager.m
//  LaFerrari
//
//  Created by stanshen on 17/6/11.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTPropertyManager.h"

#import "KTInspectableProperties.h"
#import "KTStrokeStyle.h"
#import "KTShadow.h"
#import "KTColor.h"
#import "KTGradient.h"


NSString *KTInvalidPropertiesNotification = @"KTInvalidPropertiesNotification";
NSString *KTActiveStrokeChangedNotification = @"KTActiveStrokeChangedNotification";
NSString *KTActiveFillChangedNotification = @"KTActiveFillChangedNotification";
NSString *KTActiveShadowChangedNotification = @"KTActiveShadowChangedNotification";
NSString *KTInvalidPropertiesKey = @"KTInvalidPropertiesKey";

@interface KTPropertyManager ()

@property (nonatomic, strong) NSMutableDictionary *defaults;

@end


@implementation KTPropertyManager

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _defaults = @{}.mutableCopy;
    }
    
    return self;
}


- (BOOL)propertyAffectsActiveStroke:(NSString *)property {
    static NSSet *strokeProperties = nil;
    if (!strokeProperties) {
        strokeProperties = [NSSet setWithObjects:KTStrokeColorProperty, KTStrokeCapProperty, KTStrokeJoinProperty, KTStrokeWidthProperty, KTStrokeVisibleProperty, KTStrokeDashPatternProperty, KTStartArrowProperty, KTEndArrowProperty, nil];
    }
    return [strokeProperties containsObject:property];
}

- (BOOL)propertyAffectsActiveShadow:(NSString *)property {
    static NSSet *shadowProperties = nil;
    if (!shadowProperties) {
        shadowProperties = [NSSet setWithObjects:KTOpacityProperty, KTShadowColorProperty, KTShadowAngleProperty, KTShadowOffsetProperty, KTShadowRadiusProperty, KTShadowVisibleProperty, nil];
    }
    return [shadowProperties containsObject:property];
}

- (void)setDefaultValue:(id)value forProperty:(NSString *)property {
    if (!value) {
        return;
    }
    
    if ([property isEqualToString:KTFillProperty]) {
        // color or gradient
        if ([value isKindOfClass:[KTColor class]]) {
            _defaults[KTFillColorProperty] = [NSKeyedArchiver archivedDataWithRootObject:value];
        }
        else if ([value isKindOfClass:[KTGradient class]]) {
            _defaults[KTFillGradientProperty] = [NSKeyedArchiver archivedDataWithRootObject:value];
        }
    }
    
    if ([property isEqualToString:KTFillProperty] || [property isEqualToString:KTStrokeColorProperty] || [property isEqualToString:KTShadowColorProperty]) {
        value = [NSKeyedArchiver archivedDataWithRootObject:value];
    }
    
    if ([[_defaults valueForKey:property] isEqual:value]) {
        return;
    }
    
    _defaults[property] = value;
    
    if ([property isEqualToString:KTFillProperty]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:KTActiveFillChangedNotification object:self userInfo:nil];
    }
    else if ([self propertyAffectsActiveStroke:property]) {
        if (![property isEqual:KTStrokeVisibleProperty]) {
            _defaults[KTStrokeVisibleProperty] = @YES;
        }
        else if (![value boolValue]) {
            // turning off the stroke, so reset teh arrows;
            _defaults[KTStartArrowProperty] = KTStrokeArrowNone;
            _defaults[KTEndArrowProperty] = KTStrokeArrowNone;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:KTActiveStrokeChangedNotification object:self userInfo:nil];
    }
    else if ([self propertyAffectsActiveShadow:property]) {
        if (![property isEqual:KTShadowVisibleProperty] && ![property isEqual:KTOpacityProperty]) {
            _defaults[KTShadowVisibleProperty] = @YES;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:KTActiveShadowChangedNotification object:self userInfo:nil];
    }
}

- (id)defaultValueForProperty:(NSString *)property {
    id value = [_defaults valueForKey:property];
    if (!value) {
        value = [[NSUserDefaults standardUserDefaults] valueForKey:property];
        _defaults[property] = value;
    }
    if ([value isKindOfClass:[NSData class]]) {
        return [NSKeyedUnarchiver unarchiveObjectWithData:(NSData *)value];
    }
    return value;
}


- (id<KTPathPainter>)activeFillStyle {
    id value = [self defaultValueForProperty:KTFillProperty];
    if ([value isEqual:[NSNull null]]) {
        return nil;
    }
    return value;
}

- (id<KTPathPainter>)deafaultFillStyle {
    id value = [self defaultValueForProperty:KTFillProperty];
    if ([value isEqual:[NSNull null]]) {
        return nil;
    }
    return value;
}

- (KTStrokeStyle *)activeStrokeStyle {
    if ([[self defaultValueForProperty:KTStrokeVisibleProperty] boolValue]) {
        return [self defaultStrokeStyle];
    }
    return nil;
}

- (KTStrokeStyle *)defaultStrokeStyle {
    return [KTStrokeStyle strokeStyleWithWidth:[[self defaultValueForProperty:KTStrokeWidthProperty] floatValue]
                                           cap:(int)[[self defaultValueForProperty:KTStrokeCapProperty] integerValue]
                                          join:(int)[[self defaultValueForProperty:KTStrokeJoinProperty] integerValue]
                                         color:[self defaultValueForProperty:KTStrokeColorProperty]
                                   dashPattern:[self defaultValueForProperty:KTStrokeDashPatternProperty]
                                    startArrow:[self defaultValueForProperty:KTStartArrowProperty]
                                      endArrow:[self defaultValueForProperty:KTEndArrowProperty]];
}

- (KTShadow *)activeShadow {
    if ([self defaultValueForProperty:KTShadowVisibleProperty]) {
        return [self defaultShadow];
    }
    return nil;
}

- (KTShadow *)defaultShadow {
    return [KTShadow shadowWithColor:[self defaultValueForProperty:KTShadowColorProperty]
                              radius:[[self defaultValueForProperty:KTShadowRadiusProperty] floatValue]
                              offset:[[self defaultValueForProperty:KTShadowOffsetProperty] floatValue]
                               angle:[[self defaultValueForProperty:KTShadowAngleProperty] floatValue]];
}




















@end
