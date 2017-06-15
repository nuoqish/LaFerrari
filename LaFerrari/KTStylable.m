//
//  KTStylable.m
//  LaFerrari
//
//  Created by stanshen on 17/6/11.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTStylable.h"

#import "KTStrokeStyle.h"
#import "KTXMLElement.h"
#import "KTFillTransform.h"
#import "KTGradient.h"
#import "KTLayer.h"
#import "KTColor.h"
#import "KTInspectableProperties.h"
#import "KTPropertyManager.h"
#import "KTSVGHelper.h"
#import "KTUtilities.h"
#import "KTGLUtilities.h"
#import "NSColor+Utils.h"

NSString *KTMaskedElementsKey = @"KTMaskedElementsKey";

const CGFloat KTDiamondSize = 7;

@implementation KTStylable

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    
    if (self.strokeStyle) {
        // If there's an initial stroke, we should save that, the user hasn't committed to the color shift yet
        KTStrokeStyle *strokeStyleToSave = self.initialStroke ?: self.strokeStyle;
        [aCoder encodeObject:strokeStyleToSave forKey:KTStrokeKey];
    }
    
    // If there's an initial fill, we should save that, the user hasn't committed to the color shift yet
    [aCoder encodeObject:(self.initialFill ?: self.fill) forKey:KTFillKey];
    
    if (self.fillTransform) {
        [aCoder encodeObject:self.fillTransform forKey:KTFillTransformKey];
    }
    
    [aCoder encodeObject:self.maskedElements forKey:KTMaskedElementsKey];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    self.fill = [aDecoder decodeObjectForKey:KTFillKey];
    self.fillTransform = [aDecoder decodeObjectForKey:KTFillTransformKey];
    self.strokeStyle = [aDecoder decodeObjectForKey:KTStrokeKey];
    self.maskedElements = [aDecoder decodeObjectForKey:KTMaskedElementsKey];
    if (self.maskedElements.count == 0) {
        self.maskedElements = nil;
    }
    if ([self.fill transformable] && !self.fillTransform) {
        // this object was created before gradient fills were supported on text,
        // for fidelity, convert the fill to a color to simulate the original rendering behavior
        KTColor *color = [(KTGradient *)self.fill colorAtRatio:0];
        self.fill = color;
    }
    if (self.strokeStyle && [self.strokeStyle isNullStroke]) {
        self.strokeStyle = nil;
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    KTStylable *stylable = [super copyWithZone:zone];
    
    stylable.fill = [(id)self.fill copy];
    stylable.fillTransform = self.fillTransform.copy;
    stylable.strokeStyle = self.strokeStyle.copy;
    
    if (self.maskedElements) {
        stylable.maskedElements = self.maskedElements.copy;
    }
    return stylable;
}

- (BOOL)isMasking {
    if (!self.maskedElements) {
        return NO;
    }
    return self.maskedElements.count > 0;
}

- (void)setMaskedElements:(NSArray *)maskedElements {
    [self cacheDirtyBounds];
    [[self.undoManager prepareWithInvocationTarget:self] setMaskedElements:self.maskedElements];
    _maskedElements = maskedElements;
    [self postDirtyBoundsChange];
}

- (NSSet *)transform:(CGAffineTransform)transform {
    self.fillTransform = [self.fillTransform transform:transform];
    for (KTElement *element in self.maskedElements) {
        [element transform:transform];
    }
    return nil; //?
}

- (void) addElementsToArray:(NSMutableArray *)array
{
    [super addElementsToArray:array];
    [self.maskedElements makeObjectsPerformSelector:@selector(addElementsToArray:) withObject:array];
}

- (void) addBlendablesToArray:(NSMutableArray *)array
{
    if (self.fill) {
        [array addObject:self];
    }
    
    [self.maskedElements makeObjectsPerformSelector:@selector(addBlendablesToArray:) withObject:array];
}

- (void) awakeFromEncoding
{
    [super awakeFromEncoding];
    [self.maskedElements makeObjectsPerformSelector:@selector(awakeFromEncoding) withObject:nil];
}

- (void) setLayer:(KTLayer *)layer
{
    [super setLayer:layer];
    [self.maskedElements makeObjectsPerformSelector:@selector(setLayer:) withObject:layer];
}

- (void) drawGradientControlsWithViewTransform:(CGAffineTransform)transform
{
    if (![self fillTransform]) {
        return;
    }
    
    KTFillTransform *fT = self.displayFillTransform ?: self.fillTransform;
    
    CGPoint start = fT.start;
    start = CGPointApplyAffineTransform(start, fT.transform);
    start = KTRoundPoint(CGPointApplyAffineTransform(start, transform));
    
    CGPoint end = fT.end;
    end = CGPointApplyAffineTransform(end, fT.transform);
    end = KTRoundPoint(CGPointApplyAffineTransform(end, transform));
    
    [self.layer.highlightColor openGLSet];
    KTGLLineFromPointToPoint(start, end);
    
    KTGLFillDiamond(start, KTDiamondSize);
    KTGLFillDiamond(end, KTDiamondSize);
    
    glColor4f(1, 1, 1, 1);
    KTGLFillDiamond(start, KTDiamondSize - 1);
    KTGLFillDiamond(end, KTDiamondSize - 1);
}

- (NSSet *) inspectableProperties
{
    static NSMutableSet *inspectableProperties = nil;
    
    if (!inspectableProperties) {
        inspectableProperties = [NSMutableSet setWithObjects:KTFillProperty, KTStrokeColorProperty,
                                 KTStrokeCapProperty, KTStrokeJoinProperty, KTStrokeWidthProperty,
                                 KTStrokeVisibleProperty, KTStrokeDashPatternProperty,
                                 KTStartArrowProperty, KTEndArrowProperty, nil];
        [inspectableProperties unionSet:[super inspectableProperties]];
    }
    
    return inspectableProperties;
}

- (NSSet *) changedStrokePropertiesFrom:(KTStrokeStyle *)from to:(KTStrokeStyle *)to
{
    NSMutableSet *changedProperties = [NSMutableSet set];
    
    if ((!from && to) || (!to && from)) {
        [changedProperties addObject:KTStrokeVisibleProperty];
    }
    
    if (![from.color isEqual:to.color]) {
        [changedProperties addObject:KTStrokeColorProperty];
    }
    if (from.cap != to.cap) {
        [changedProperties addObject:KTStrokeCapProperty];
    }
    if (from.join != to.join) {
        [changedProperties addObject:KTStrokeJoinProperty];
    }
    if (from.width != to.width) {
        [changedProperties addObject:KTStrokeWidthProperty];
    }
    if (![from.dashPattern isEqualToArray:to.dashPattern]) {
        [changedProperties addObject:KTStrokeDashPatternProperty];
    }
    if (![from.startArrow isEqualToString:to.startArrow]) {
        [changedProperties addObject:KTStartArrowProperty];
    }
    if (![from.endArrow isEqualToString:to.endArrow]) {
        [changedProperties addObject:KTEndArrowProperty];
    }
    
    return changedProperties;
}

- (void) strokeStyleChanged
{
    // can be overriden by subclasses
    // useful when caching style bounds
}

- (void) setStrokeStyleQuiet:(KTStrokeStyle *)strokeStyle
{
    _strokeStyle = strokeStyle;
}

- (void) setStrokeStyle:(KTStrokeStyle *)strokeStyle
{
    if ([strokeStyle isEqual:_strokeStyle]) {
        return;
    }
    
    [self cacheDirtyBounds];
    [[self.undoManager prepareWithInvocationTarget:self] setStrokeStyle:_strokeStyle];
    
    NSSet *changedProperties = [self changedStrokePropertiesFrom:_strokeStyle to:strokeStyle];
    
    [self setStrokeStyleQuiet:strokeStyle];
    
    [self strokeStyleChanged];
    
    [self postDirtyBoundsChange];
    [self propertiesChanged:changedProperties];
}

- (void) setFillQuiet:(id<KTPathPainter>)fill
{
    BOOL wasDefaultFillTransform = NO;
    
    if ([_fill isKindOfClass:[KTGradient class]]) {
        // see if the fill transform was the default
        wasDefaultFillTransform = [self.fillTransform isDefaultInRect:self.bounds centered:[_fill wantsCenteredFillTransform]];
    }
    
    _fill = fill;
    
    if ([fill transformable]) {
        if (!self.fillTransform || wasDefaultFillTransform) {
            self.fillTransform = [KTFillTransform fillTransformWithRect:self.bounds centered:[fill wantsCenteredFillTransform]];
        }
    } else {
        self.fillTransform = nil;
    }
}

- (void) setFill:(id<KTPathPainter>)fill
{
    if ([fill isEqual:_fill]) {
        return;
    }
    
    [self cacheDirtyBounds];
    
    [[self.undoManager prepareWithInvocationTarget:self] setFill:_fill];
    
    [self setFillQuiet:fill];
    
    [self postDirtyBoundsChange];
    [self propertyChanged:KTFillProperty];
}

- (void) setFillTransform:(KTFillTransform *)fillTransform
{
    // handle nil cases
    if (self.fillTransform == fillTransform) {
        return;
    }
    
    if (self.fillTransform && [self.fillTransform isEqual:fillTransform]) {
        return;
    }
    
    [self cacheDirtyBounds];
    [[self.undoManager prepareWithInvocationTarget:self] setFillTransform:_fillTransform];
    
    _fillTransform = fillTransform;
    
    [self postDirtyBoundsChange];
}

- (void) setValue:(id)value forProperty:(NSString *)property propertyManager:(KTPropertyManager *)propertyManager
{
    if (!value) {
        return;
    }
    
    KTStrokeStyle *strokeStyle = self.strokeStyle;
    
    static NSSet *strokeProperties = nil;
    if (!strokeProperties) {
        strokeProperties = [[NSSet alloc] initWithObjects:KTStrokeColorProperty, KTStrokeCapProperty, KTStrokeJoinProperty,
                            KTStrokeWidthProperty, KTStrokeDashPatternProperty, KTStartArrowProperty, KTEndArrowProperty, nil];
    }
    
    if ([property isEqualToString:KTFillProperty]) {
        if ([value isEqual:[NSNull null]]) {
            self.fill = nil;
        } else {
            self.fill = value;
        }
    } else if ([property isEqualToString:KTStrokeVisibleProperty]) {
        if ([value boolValue] && !strokeStyle) { // stroke enabled
            // stroke turned on and we don't have one so attach the default stroke
            self.strokeStyle = [propertyManager defaultStrokeStyle];
        } else if (![value boolValue] && strokeStyle) {
            self.strokeStyle = nil;
        }
    } else if ([strokeProperties containsObject:property]) {
        if (!self.strokeStyle) {
            strokeStyle = [propertyManager defaultStrokeStyle];
        }
        
        float width = [property isEqualToString:KTStrokeWidthProperty] ? [value floatValue] : strokeStyle.width;
        CGLineCap cap = [property isEqualToString:KTStrokeCapProperty]? [value intValue] : strokeStyle.cap;
        CGLineJoin join = [property isEqualToString:KTStrokeJoinProperty] ? [value intValue] : strokeStyle.join;
        KTColor *color = [property isEqualToString:KTStrokeColorProperty] ? value : strokeStyle.color;
        NSArray *dashPattern = [property isEqualToString:KTStrokeDashPatternProperty] ? value : strokeStyle.dashPattern;
        NSString *startArrow = [property isEqualToString:KTStartArrowProperty] ? value : strokeStyle.startArrow;
        NSString *endArrow = [property isEqualToString:KTEndArrowProperty] ? value : strokeStyle.endArrow;
        
        self.strokeStyle = [KTStrokeStyle strokeStyleWithWidth:width cap:cap join:join color:color
                                                   dashPattern:dashPattern startArrow:startArrow endArrow:endArrow];
    } else {
        [super setValue:value forProperty:property propertyManager:propertyManager];
    }
}

- (id) valueForProperty:(NSString *)property
{
    if (![[self inspectableProperties] containsObject:property]) {
        // we don't care about this property, let's bail
        return nil;
    }
    
    else if ([property isEqualToString:KTFillProperty]) {
        if (!self.fill) {
            return [NSNull null];
        } else {
            return self.fill;
        }
    } else if ([property isEqualToString:KTStrokeVisibleProperty]) {
        if (self.strokeStyle) {
            return @YES;
        } else {
            return @NO;
        }
    } else if (self.strokeStyle) {
        if ([property isEqualToString:KTStrokeColorProperty]) {
            return self.strokeStyle.color;
        } else if ([property isEqualToString:KTStrokeCapProperty]) {
            return @(self.strokeStyle.cap);
        } else if ([property isEqualToString:KTStrokeJoinProperty]) {
            return @(self.strokeStyle.join);
        } else if ([property isEqualToString:KTStrokeWidthProperty]) {
            return @(self.strokeStyle.width);
        } else if ([property isEqualToString:KTStrokeDashPatternProperty]) {
            return self.strokeStyle.dashPattern ?: @[];
        } else if ([property isEqualToString:KTStartArrowProperty]) {
            return self.strokeStyle.startArrow ?: KTStrokeArrowNone;
        } else if ([property isEqualToString:KTEndArrowProperty]) {
            return self.strokeStyle.endArrow ?: KTStrokeArrowNone;
        }
    }
    
    return [super valueForProperty:property];
}

- (id)pathPainterAtPoint:(CGPoint)pt {
    id fill = [self valueForProperty:KTFillProperty];
    
    if (!fill || [fill isEqual:[NSNull null]]) {
        return [self valueForProperty:KTStrokeColorProperty];
    }
    else {
        return fill;
    }
}

- (void)tossCachedColorAdjustmentData {
    self.initialStroke = nil;
    self.initialFill = nil;
    [self.maskedElements makeObjectsPerformSelector:@selector(tossCachedColorAdjustmentData)];
    [super tossCachedColorAdjustmentData];
}

- (void)restoreCachedColorAdjustmentData {
    if (self.initialStroke) {
        self.strokeStyle = self.initialStroke;
    }
    if (self.initialFill) {
        self.fill = self.initialFill;
    }
    [super restoreCachedColorAdjustmentData];
    [self.maskedElements makeObjectsPerformSelector:@selector(restoreCachedColorAdjustmentData)];
    [self tossCachedColorAdjustmentData];
}

- (void)registerUndoWithCachedColorAdjustmentData {
    if (self.initialStroke) {
        [[self.undoManager prepareWithInvocationTarget:self] setStrokeStyle:self.initialStroke];
    }
    if (self.initialFill) {
        [[self.undoManager prepareWithInvocationTarget:self] setFill:self.initialFill];
    }
    
    [super registerUndoWithCachedColorAdjustmentData];
    [self.maskedElements makeObjectsPerformSelector:@selector(registerUndoWithCachedColorAdjustmentData)];
    [self tossCachedColorAdjustmentData];
}

- (BOOL)canAdjustColor {
    if (self.fill || self.strokeStyle) {
        return YES;
    }
    for (KTElement *element in self.maskedElements) {
        if ([element canAdjustColor]) {
            return YES;
        }
    }
    
    return [super canAdjustColor];
}

- (void)adjustColor:(KTColor *(^)(KTColor *))adjustment scope:(KTColorAdjustmentScope)scope {
    if (self.fill && scope & KTColorAdjustFill) {
        if (!self.initialFill) {
            self.initialFill = self.fill;
        }
        self.fill = [self.initialFill adjustColor:adjustment];
    }
    
    if (self.strokeStyle && scope & KTColorAdjustStroke) {
        if (!self.initialStroke) {
            self.initialStroke = self.strokeStyle;
        }
        self.strokeStyle = [self.initialStroke adjustColor:adjustment];
    }
    
    for (KTElement *element in self.maskedElements) {
        [element adjustColor:adjustment scope:scope];
    }
    
    [super adjustColor:adjustment scope:scope];
}

- (void) addSVGFillAndStrokeAttributes:(KTXMLElement *)element
{
    [self addSVGFillAttributes:element];
    
    if (self.strokeStyle) {
        [self.strokeStyle addSVGAttributes:element];
    }
}

- (void) addSVGFillAttributes:(KTXMLElement *)element
{
    if (!_fill) {
        [element setAttribute:@"fill" value:@"none"];
        return;
    }
    
    if ([_fill isKindOfClass:[KTColor class]]) {
        KTColor *color = (KTColor *) _fill;
        
        [element setAttribute:@"fill" value:[color hexValue]];
        
        if (color.alpha != 1) {
            [element setAttribute:@"fill-opacity" floatValue:color.alpha];
        }
    } else if ([_fill isKindOfClass:[KTGradient class]]) {
        KTGradient *gradient = (KTGradient *)_fill;
        NSString *uniqueID = [[KTSVGHelper sharedSVGHelper] uniqueIDWithPrefix:(gradient.type == KTGradientTypeRadial ? @"RadialGradient" : @"LinearGradient")];
        
        [[KTSVGHelper sharedSVGHelper] addDefinition:[gradient SVGElementWithID:uniqueID fillTransform:self.fillTransform]];
        
        [element setAttribute:@"fill" value:[NSString stringWithFormat:@"url(#%@)", uniqueID]];
    }
}

- (BOOL)canMaskElements {
    return YES;
}

- (void)takeStylePropertiesFrom:(KTStylable *)stylable {
    self.fill = stylable.fill;
    self.fillTransform = stylable.fillTransform;
    self.strokeStyle = stylable.strokeStyle;
    self.opacity = stylable.opacity;
    self.shadow = stylable.shadow;
    self.maskedElements = stylable.maskedElements;
}

- (BOOL)needsTransparencyLayer:(float)scale {
    if (self.maskedElements) {
        return YES;
    }
    
    if (self.fill && self.strokeStyle) {
        return YES;
    }
    
    if ([self.fill isKindOfClass:[KTGradient class]] && self.shadow) {
        return YES;
    }
    
    return NO;
}


@end
