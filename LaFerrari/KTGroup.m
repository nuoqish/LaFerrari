//
//  KTGroup.m
//  LaFerrari
//
//  Created by stanshen on 17/6/9.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTGroup.h"

#import "KTPickResult.h"
#import "KTXMLElement.h"

NSString *KTGroupElementsKey = @"KTGroupElementsKey";

@implementation KTGroup

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    _elements = [aDecoder decodeObjectForKey:KTGroupElementsKey];
    [_elements makeObjectsPerformSelector:@selector(setGroup:) withObject:self];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:_elements forKey:KTGroupElementsKey];
}


- (id) copyWithZone:(NSZone *)zone
{
    KTGroup *group = [super copyWithZone:zone];
    
    group.elements = [[NSMutableArray alloc] initWithArray:_elements copyItems:YES];
    [group.elements makeObjectsPerformSelector:@selector(setGroup:) withObject:group];
    
    return group;
}


- (void)tossCachedColorAdjustmentData {
    [super tossCachedColorAdjustmentData];
    [self.elements makeObjectsPerformSelector:@selector(tossCachedColorAdjustmentData)];
}


- (void) restoreCachedColorAdjustmentData
{
    [super restoreCachedColorAdjustmentData];
    [self.elements makeObjectsPerformSelector:@selector(restoreCachedColorAdjustmentData)];
}

- (void) registerUndoWithCachedColorAdjustmentData
{
    [super registerUndoWithCachedColorAdjustmentData];
    [self.elements makeObjectsPerformSelector:@selector(registerUndoWithCachedColorAdjustmentData)];
}

- (BOOL) canAdjustColor
{
    for (KTElement *element in _elements) {
        if ([element canAdjustColor]) {
            return YES;
        }
    }
    
    return [super canAdjustColor];
}

- (void) adjustColor:(KTColor * (^)(KTColor *color))adjustment scope:(KTColorAdjustmentScope)scope
{
    for (KTElement *element in _elements) {
        [element adjustColor:adjustment scope:scope];
    }
}

- (NSSet *) transform:(CGAffineTransform)transform
{
    [self cacheDirtyBounds];
    
    for (KTElement *element in _elements) {
        [element transform:transform];
    }
    
    [self postDirtyBoundsChange];
    return nil;
}

- (void) setElements:(NSMutableArray *)elements
{
    _elements = elements;
    
    [_elements makeObjectsPerformSelector:@selector(setGroup:) withObject:self];
    [_elements makeObjectsPerformSelector:@selector(setLayer:) withObject:self.layer];
}

- (void) awakeFromEncoding
{
    [super awakeFromEncoding];
    [_elements makeObjectsPerformSelector:@selector(awakeFromEncoding) withObject:nil];
}

- (void) setLayer:(KTLayer *)layer
{
    [super setLayer:layer];
    [_elements makeObjectsPerformSelector:@selector(setLayer:) withObject:layer];
}

- (void) renderInContext:(CGContextRef)ctx metaData:(KTRenderingMetaData)metaData
{
    if (!KTRenderingMetaDataOutlineOnly(metaData)) {
        [self beginTransparencyLayer:ctx metaData:metaData];
    }
    
    for (KTElement *element in _elements) {
        [element renderInContext:ctx metaData:metaData];
    }
    
    if (!KTRenderingMetaDataOutlineOnly(metaData)) {
        [self endTransparencyLayer:ctx metaData:metaData];
    }
}

- (CGRect) bounds
{
    CGRect bounds = CGRectNull;
    
    for (KTElement *element in _elements) {
        bounds = CGRectUnion([element bounds], bounds);
    }
    
    return bounds;
}

- (CGRect) styleBounds
{
    CGRect bounds = CGRectNull;
    
    for (KTElement *element in _elements) {
        bounds = CGRectUnion([element styleBounds], bounds);
    }
    
    return [self expandStyleBounds:bounds];
}

- (BOOL) intersectsRect:(CGRect)rect
{
    for (KTElement *element in [_elements reverseObjectEnumerator]) {
        if ([element intersectsRect:rect]) {
            return YES;
        }
    }
    
    return NO;
}

// OpenGL-based selection rendering

- (void) drawOpenGLZoomOutlineWithViewTransform:(CGAffineTransform)viewTransform visibleRect:(CGRect)visibleRect
{
    for (KTElement *element in _elements) {
        [element drawOpenGLZoomOutlineWithViewTransform:viewTransform visibleRect:visibleRect];
    }
}

- (void) drawOpenGLHighlightWithTransform:(CGAffineTransform)transform viewTransform:(CGAffineTransform)viewTransform
{
    for (KTElement *element in _elements) {
        [element drawOpenGLHighlightWithTransform:transform viewTransform:viewTransform];
    }
}

- (void) drawOpenGLHandlesWithTransform:(CGAffineTransform)transform viewTransform:(CGAffineTransform)viewTransform
{
    for (KTElement *element in _elements) {
        [element drawOpenGLAnchorsWithViewTransform:viewTransform];
    }
}

- (void) drawOpenGLAnchorsWithViewTransform:(CGAffineTransform)transform
{
    for (KTElement *element in _elements) {
        [element drawOpenGLAnchorsWithViewTransform:transform];
    }
}


- (KTPickResult *) hitResultForPoint:(CGPoint)pt viewScale:(float)viewScale snapFlags:(int)flags
{
    flags = flags | KTSnapEdges;
    
    for (KTElement *element in [_elements reverseObjectEnumerator]) {
        KTPickResult *result = [element hitResultForPoint:pt viewScale:viewScale snapFlags:flags];
        
        if (result.type != KTEther) {
            if (!(flags & KTSnapSubelement)) {
                result.element = self;
            }
            return result;
        }
    }
    
    return [KTPickResult pickResult];
}


- (KTPickResult *) snappedPoint:(CGPoint)pt viewScale:(float)viewScale snapFlags:(int)flags
{
    if (flags & KTSnapSubelement) {
        for (KTElement *element in [_elements reverseObjectEnumerator]) {
            KTPickResult *result = [element snappedPoint:pt viewScale:viewScale snapFlags:flags];
            
            if (result.type != KTEther) {
                return result;
            }
        }
    }
    
    return [KTPickResult pickResult];
}


- (void) addElementsToArray:(NSMutableArray *)array
{
    [super addElementsToArray:array];
    [_elements makeObjectsPerformSelector:@selector(addElementsToArray:) withObject:array];
}

- (void) addBlendablesToArray:(NSMutableArray *)array
{
    [_elements makeObjectsPerformSelector:@selector(addBlendablesToArray:) withObject:array];
}

- (NSSet *) inspectableProperties
{
    NSMutableSet *properties = [NSMutableSet set];
    
    // we can inspect anything one of our sub-elements can inspect
    for (KTElement *element in _elements) {
        [properties unionSet:element.inspectableProperties];
    }
    
    return properties;
}


- (void) setValue:(id)value forProperty:(NSString *)property propertyManager:(KTPropertyManager *)propertyManager
{
    if ([[super inspectableProperties] containsObject:property]) {
        [super setValue:value forProperty:property propertyManager:propertyManager];
    } else {
        for (KTElement *element in _elements) {
            [element setValue:value forProperty:property propertyManager:propertyManager];
        }
    }
}

- (id) valueForProperty:(NSString *)property
{
    id value = nil;
    
    if ([[super inspectableProperties] containsObject:property]) {
        return [super valueForProperty:property];
    }
    
    // return the value for the top most object that can inspect it
    for (KTElement *element in [_elements reverseObjectEnumerator]) {
        value = [element valueForProperty:property];
        if (value) {
            break;
        }
    }
    
    return value;
}


- (KTXMLElement *) SVGElement
{
    KTXMLElement *group = [KTXMLElement elementWithName:@"g"];
    [self addSVGOpacityAndShadowAttributes:group];
    
    for (KTElement *element in _elements) {
        [group addChild:[element SVGElement]];
    }
    
    return group;
}

@end
