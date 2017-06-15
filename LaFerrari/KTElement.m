//
//  KTElement.m
//  LaFerrari
//
//  Created by stanshen on 17/6/8.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTElement.h"

#import "KTLayer.h"
#import "KTShadow.h"
#import "KTGroup.h"
#import "KTColor.h"
#import "KTPickResult.h"
#import "KTXMLElement.h"

#import "KTSVGHelper.h"
#import "KTUtilities.h"
#import "KTGLUtilities.h"
#import "KTInspectableProperties.h"
#import "KTPropertyManager.h"

#import "NSColor+Utils.h"


NSString *KTElementChanged = @"KTElementChanged";
NSString *KTPropertyChangedNotification = @"KTPropertyChangedNotification";
NSString *KTPropertiesChangedNotification = @"KTPropertiesChangedNotification";
NSString *KTPropertyKey = @"KTPropertyKey";
NSString *KTPropertiesKey = @"KTPropertiesKey";
NSString *KTLayerKey = @"KTElementLayerKey";
NSString *KTGroupKey = @"KTGroupKey";
NSString *KTShadowKey = @"KTShadowKey";
NSString *KTOpacityKey = @"KTOpacityKey";
NSString *KTBlendModeKey = @"KTBlendModeKey";
NSString *KTStrokeKey = @"KTStrokeKey";
NSString *KTFillKey = @"KTFillKey";
NSString *KTFillTransformKey = @"KTFillTransformKey";
NSString *KTTransformKey = @"KTTransformKey";
NSString *KTTextKey = @"KTTextKey";
NSString *KTFontNameKey = @"KTFontNameKey";
NSString *KTFontSizeKey = @"KTFontSizeKey";

@implementation KTElement{
    CGRect dirtyBounds_;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.opacity = 1.0;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    
    _layer = [aDecoder decodeObjectForKey:KTLayerKey];
    _group = [aDecoder decodeObjectForKey:KTGroupKey];
    _shadow = [aDecoder decodeObjectForKey:KTShadowKey];
    
    if ([aDecoder containsValueForKey:KTOpacityKey]) {
        _opacity = [aDecoder decodeFloatForKey:KTOpacityKey];
    }
    else {
        _opacity = 1.0f;
    }
    
    _blendMode = [aDecoder decodeIntForKey:KTBlendModeKey] ?: kCGBlendModeNormal;
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeObject:_layer forKey:KTLayerKey];
    
    if (_group) {
        [aCoder encodeObject:_group forKey:KTGroupKey];
    }
    
    if (_layer) {
        [aCoder encodeObject:_layer forKey:KTLayerKey];
    }
    
    if (_opacity != 1.0f) {
        [aCoder encodeFloat:_opacity forKey:KTOpacityKey];
    }
    
    if (_blendMode != kCGBlendModeNormal) {
        [aCoder encodeInteger:_blendMode forKey:KTBlendModeKey];
    }
}

- (id)copyWithZone:(NSZone *)zone {
    KTElement *element = [[KTElement allocWithZone:zone] init];
    
    element.shadow = self.shadow.copy;
    element.opacity = self.opacity;
    element.blendMode = self.blendMode;
    
    return element;
}


- (void)awakeFromEncoding {
    
}

- (KTDrawing *)drawing {
    return self.layer.drawing;
}

- (NSUndoManager *)undoManager {
    return self.drawing.undoManager;
}

- (CGRect)bounds {
    return CGRectZero;
}

- (CGRect)styleBounds {
    return [self expandStyleBounds:self.bounds];
}

- (KTShadow *)shadowForStyleBounds {
    return self.shadow;
}

- (CGRect)expandStyleBounds:(CGRect)rect {
    KTShadow *shadow = [self shadowForStyleBounds];
    
    if (!shadow) {
        return (self.group) ? [self.group expandStyleBounds:rect] : rect;
    }
    
    // expand by the shadow radius
    CGRect shadowRect = CGRectInset(rect, -shadow.radius, -shadow.radius);
    
    // offset
    float x = cos(shadow.angle) * shadow.offset;
    float y = sin(shadow.angle) * shadow.offset;
    shadowRect = CGRectOffset(shadowRect, x, y);
    
    // if we're in a group which has its own shadow, we need to further expand our coverage
    if (self.group) {
        shadowRect = [self.group expandStyleBounds:shadowRect];
    }
    
    return CGRectUnion(shadowRect, rect);
}


- (CGRect) subselectionBounds
{
    return [self bounds];
}

- (void) clearSubselection
{
}

- (BOOL) containsPoint:(CGPoint)pt
{
    return CGRectContainsPoint([self bounds], pt);
}

- (BOOL) intersectsRect:(CGRect)rect
{
    return CGRectIntersectsRect([self bounds], rect);
}

- (void) renderInContext:(CGContextRef)ctx metaData:(KTRenderingMetaData)metaData
{
}

- (void) addHighlightInContext:(CGContextRef)ctx
{
}

- (void) tossCachedColorAdjustmentData
{
    self.initialShadow = nil;
}

- (void) restoreCachedColorAdjustmentData
{
    if (!self.initialShadow) {
        return;
    }
    
    self.shadow = self.initialShadow;
    self.initialShadow = nil;
}

- (void) registerUndoWithCachedColorAdjustmentData
{
    if (!self.initialShadow) {
        return;
    }
    
    [(KTElement *)[self.undoManager prepareWithInvocationTarget:self] setShadow:self.initialShadow];
    self.initialShadow = nil;
}

- (void) adjustColor:(KTColor * (^)(KTColor *color))adjustment scope:(KTColorAdjustmentScope)scope
{
    if (self.shadow && scope & KTColorAdjustShadow) {
        if (!self.initialShadow) {
            self.initialShadow = self.shadow;
        }
        self.shadow = [self.initialShadow adjustColor:adjustment];
    }
}

- (NSSet *) transform:(CGAffineTransform)transform
{
    return nil;
}

// OpenGL-based selection rendering

- (void) drawOpenGLAnchorAtPoint:(CGPoint)pt transform:(CGAffineTransform)transform selected:(BOOL)selected
{
    CGPoint location = KTRoundPoint(CGPointApplyAffineTransform(pt, transform));
    CGRect anchorRect = CGRectMake(location.x - kKTAnchorRadius, location.y - kKTAnchorRadius, kKTAnchorRadius * 2, kKTAnchorRadius * 2);
    
    if (!selected) {
        glColor4f(1, 1, 1, 1);
        KTGLFillRect(anchorRect);
        [self.layer.highlightColor openGLSet];
        KTGLStrokeRect(anchorRect);
    } else {
        anchorRect = CGRectInset(anchorRect, 1, 1);
        [self.layer.highlightColor openGLSet];
        KTGLFillRect(anchorRect);
    }
}

- (void) drawOpenGLZoomOutlineWithViewTransform:(CGAffineTransform)viewTransform visibleRect:(CGRect)visibleRect
{
    if (CGRectIntersectsRect(self.bounds, visibleRect)) {
        [self drawOpenGLHighlightWithTransform:CGAffineTransformIdentity viewTransform:viewTransform];
    }
}


- (void) drawOpenGLHighlightWithTransform:(CGAffineTransform)transform viewTransform:(CGAffineTransform)viewTransform
{
}

- (void) drawOpenGLHandlesWithTransform:(CGAffineTransform)transform viewTransform:(CGAffineTransform)viewTransform
{
}

- (void) drawOpenGLAnchorsWithViewTransform:(CGAffineTransform)transform
{
}

- (void) drawGradientControlsWithViewTransform:(CGAffineTransform)transform
{
}

- (void) drawTextPathControlsWithViewTransform:(CGAffineTransform)viewTransform viewScale:(float)viewScale
{
}


- (void) cacheDirtyBounds
{
    dirtyBounds_ = self.styleBounds;
}

- (void) postDirtyBoundsChange
{
    if (!self.drawing) {
        return;
    }
    
    // the layer should dirty its thumbnail
    [self.layer invalidateThumbnail];
    
    NSArray *rects = @[[NSValue valueWithRect:dirtyBounds_], [NSValue valueWithRect:self.styleBounds]];
    
    NSDictionary *userInfo = @{@"rects": rects};
    [[NSNotificationCenter defaultCenter] postNotificationName:KTElementChanged object:self.drawing userInfo:userInfo];
}



- (NSSet *) alignToRect:(CGRect)rect alignment:(KTAlignment)align
{
    CGRect              bounds = [self bounds];
    CGAffineTransform	translate = CGAffineTransformIdentity;
    CGPoint             center = KTCenterOfRect(bounds);
    
    CGPoint             topLeft = rect.origin;
    CGPoint             rectCenter = KTCenterOfRect(rect);
    CGPoint             bottomRight = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    
    switch(align) {
        case KTAlignLeft:
            translate = CGAffineTransformMakeTranslation(topLeft.x - CGRectGetMinX(bounds), 0.0f);
            break;
        case KTAlignCenter:
            translate = CGAffineTransformMakeTranslation(rectCenter.x - center.x, 0.0f);
            break;
        case KTAlignRight:
            translate = CGAffineTransformMakeTranslation(bottomRight.x - CGRectGetMaxX(bounds), 0.0f);
            break;
        case KTAlignTop:
            translate = CGAffineTransformMakeTranslation(0.0f, topLeft.y - CGRectGetMinY(bounds));
            break;
        case KTAlignMiddle:
            translate = CGAffineTransformMakeTranslation(0.0f, rectCenter.y - center.y);
            break;
        case KTAlignBottom:
            translate = CGAffineTransformMakeTranslation(0.0f, bottomRight.y - CGRectGetMaxY(bounds));
            break;
    }
    
    [self transform:translate];
    
    return nil;
}

- (KTPickResult *) hitResultForPoint:(CGPoint)pt viewScale:(float)viewScale snapFlags:(int)flags
{
    return [KTPickResult pickResult];
}

- (KTPickResult *) snappedPoint:(CGPoint)pt viewScale:(float)viewScale snapFlags:(int)flags
{
    return [KTPickResult pickResult];
}

- (void) addElementsToArray:(NSMutableArray *)array
{
    [array addObject:self];
}

- (void) addBlendablesToArray:(NSMutableArray *)array
{
}

- (KTXMLElement *) SVGElement
{
    // must be overriden by concrete subclasses
    return nil;
}

- (void) addSVGOpacityAndShadowAttributes:(KTXMLElement *)element
{
    [element setAttribute:@"opacity" floatValue:self.opacity];
    if (_blendMode != kCGBlendModeNormal) {
        [element setAttribute:@"kato:blendMode" value:[[KTSVGHelper sharedSVGHelper] displayNameForBlendMode:self.blendMode]];;
    }
    [(_initialShadow ?: _shadow) addSVGAttributes:element];
}

- (NSSet *) changedShadowPropertiesFrom:(KTShadow *)from to:(KTShadow *)to
{
    NSMutableSet *changedProperties = [NSMutableSet set];
    
    if ((!from && to) || (!to && from)) {
        [changedProperties addObject:KTShadowVisibleProperty];
    }
    
    if (![from.color isEqual:to.color]) {
        [changedProperties addObject:KTShadowColorProperty];
    }
    if (from.angle != to.angle) {
        [changedProperties addObject:KTShadowAngleProperty];
    }
    if (from.offset != to.offset) {
        [changedProperties addObject:KTShadowOffsetProperty];
    }
    if (from.radius != to.radius) {
        [changedProperties addObject:KTShadowRadiusProperty];
    }
    
    return changedProperties;
}


- (void) setShadow:(KTShadow *)shadow
{
    if ([_shadow isEqual:shadow]) {
        return;
    }
    
    [self cacheDirtyBounds];
    
    [(KTElement *)[self.undoManager prepareWithInvocationTarget:self] setShadow:_shadow];
    
    NSSet *changedProperties = [self changedShadowPropertiesFrom:_shadow to:shadow];
    
    _shadow = shadow;
    
    [self postDirtyBoundsChange];
    [self propertiesChanged:changedProperties];
}

- (void) setOpacity:(float)opacity
{
    if (opacity == _opacity) {
        return;
    }
    
    [self cacheDirtyBounds];
    
    [[self.undoManager prepareWithInvocationTarget:self] setOpacity:_opacity];
    
    _opacity = KTClamp(0, 1, opacity);
    
    [self postDirtyBoundsChange];
    [self propertyChanged:KTOpacityProperty];
}

- (void) setBlendMode:(CGBlendMode)blendMode
{
    if (blendMode == _blendMode) {
        return;
    }
    
    [self cacheDirtyBounds];
    
    [[self.undoManager prepareWithInvocationTarget:self] setBlendMode:_blendMode];
    
    _blendMode = blendMode;
    
    [self postDirtyBoundsChange];
    [self propertyChanged:KTBlendModeProperty];
}

- (void) setValue:(id)value forProperty:(NSString *)property propertyManager:(KTPropertyManager *)propertyManager
{
    if (!value) {
        return;
    }
    
    KTShadow *shadow = self.shadow;
    
    if ([property isEqualToString:KTOpacityProperty]) {
        self.opacity = [value floatValue];
    } else if ([property isEqualToString:KTBlendModeProperty]) {
        self.blendMode = [value intValue];
    } else if ([property isEqualToString:KTShadowVisibleProperty]) {
        if ([value boolValue] && !shadow) { // shadow enabled
            // shadow turned on and we don't have one so attach the default stroke
            self.shadow = [propertyManager defaultShadow];
        } else if (![value boolValue] && shadow) {
            self.shadow = nil;
        }
    } else if ([[NSSet setWithObjects:KTShadowColorProperty, KTShadowOffsetProperty, KTShadowRadiusProperty, KTShadowAngleProperty, nil] containsObject:property]) {
        if (!shadow) {
            shadow = [propertyManager defaultShadow];
        }
        
        if ([property isEqualToString:KTShadowColorProperty]) {
            self.shadow = [KTShadow shadowWithColor:value radius:shadow.radius offset:shadow.offset angle:shadow.angle];
        } else if ([property isEqualToString:KTShadowOffsetProperty]) {
            self.shadow = [KTShadow shadowWithColor:shadow.color radius:shadow.radius offset:[value floatValue] angle:shadow.angle];
        } else if ([property isEqualToString:KTShadowRadiusProperty]) {
            self.shadow = [KTShadow shadowWithColor:shadow.color radius:[value floatValue] offset:shadow.offset angle:shadow.angle];
        } else if ([property isEqualToString:KTShadowAngleProperty]) {
            self.shadow = [KTShadow shadowWithColor:shadow.color radius:shadow.radius offset:shadow.offset angle:[value floatValue]];
        }
    } 
}

- (id)valueForProperty:(NSString *)property {
    if ([property isEqualToString:KTOpacityProperty]) {
        return @(self.opacity);
    } else if ([property isEqualToString:KTBlendModeProperty]) {
        return @(self.blendMode);
    } else if ([property isEqualToString:KTShadowVisibleProperty]) {
        return @((self.shadow) ? YES : NO);
    } else if (self.shadow) {
        if ([property isEqualToString:KTShadowColorProperty]) {
            return self.shadow.color;
        } else if ([property isEqualToString:KTShadowOffsetProperty]) {
            return @(self.shadow.offset);
        } else if ([property isEqualToString:KTShadowRadiusProperty]) {
            return @(self.shadow.radius);
        } else if ([property isEqualToString:KTShadowAngleProperty]) {
            return @(self.shadow.angle);
        }
    }
    
    return nil;
}


- (NSSet *) inspectableProperties
{
    return [NSSet setWithObjects:KTOpacityProperty, KTBlendModeProperty, KTShadowVisibleProperty,
            KTShadowColorProperty, KTShadowAngleProperty, KTShadowRadiusProperty, KTShadowOffsetProperty,
            nil];
}

- (BOOL) canInspectProperty:(NSString *)property
{
    return [[self inspectableProperties] containsObject:property];
}

- (void)propertyChanged:(NSString *)property {
    if (self.drawing) {
        NSDictionary *userInfo = @{KTPropertyKey : property};;
        [[NSNotificationCenter defaultCenter] postNotificationName:KTPropertyChangedNotification object:self.drawing userInfo:userInfo];
    }
}

- (void)propertiesChanged:(NSSet *)properties {
    if (self.drawing) {
        NSDictionary *userInfo = @{KTPropertiesKey : properties};
        [[NSNotificationCenter defaultCenter] postNotificationName:KTPropertiesChangedNotification object:self.drawing userInfo:userInfo];
    }
}

- (id)pathPainterAtPoint:(CGPoint)pt {
    return [self valueForProperty:KTFillProperty];
}

- (BOOL)hasFill {
    return ![[self valueForProperty:KTFillProperty] isEqual:[NSNull null]];
}

- (BOOL)canMaskElements {
    return NO;
}

- (BOOL)hasEditableText {
    return NO;
}

- (BOOL)canPlaceText {
    return NO;
}

- (BOOL)isErasable {
    return NO;
}

- (BOOL)canAdjustColor {
    return self.shadow ? YES : NO;
}

- (BOOL)needsToSaveGState:(float)scale {
    if (self.opacity != 1) {
        return YES;
    }
    if (self.shadow && scale <= 3) {
        return YES;
    }
    if (self.blendMode != kCGBlendModeNormal) {
        return YES;
    }
    return NO;
}

- (BOOL)needsTransparencyLayer:(float)scale {
    return [self needsToSaveGState:scale];
}

- (void)beginTransparencyLayer:(CGContextRef)ctx metaData:(KTRenderingMetaData)metaData {
    if (![self needsToSaveGState:metaData.scale]) {
        return;
    }
    
    CGContextSaveGState(ctx);
    
    if (self.opacity != 1) {
        CGContextSetAlpha(ctx, self.opacity);
    }
    
    if (self.shadow && metaData.scale <= 3) {
        [self.shadow applyInContext:ctx metaData:metaData];
    }
    
    if (self.blendMode != kCGBlendModeNormal) {
        CGContextSetBlendMode(ctx, self.blendMode);
    }
    
    if (![self needsTransparencyLayer:metaData.scale]) {
        CGContextBeginTransparencyLayer(ctx, NULL);
    }
    
}

- (void)endTransparencyLayer:(CGContextRef)ctx metaData:(KTRenderingMetaData)metaData {
    if (![self needsToSaveGState:metaData.scale]) {
        return;
    }
    
    if (![self needsTransparencyLayer:metaData.scale]) {
        CGContextEndTransparencyLayer(ctx);
    }
    
    CGContextRestoreGState(ctx);
}


@end
