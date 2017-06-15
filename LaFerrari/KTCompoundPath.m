//
//  KTCompoundPath.m
//  LaFerrari
//
//  Created by stanshen on 17/6/11.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTCompoundPath.h"

#import "KTLayer.h"
#import "KTPath.h"
#import "KTColor.h"
#import "KTStrokeStyle.h"
#import "KTFillTransform.h"
#import "KTPathFinder.h"
#import "KTUtilities.h"

NSString *KTCompoundPathSubpathsKey = @"KTCompoundPathSubpathsKey";

@interface KTCompoundPath ()

@property (nonatomic, assign) CGMutablePathRef path;
@property (nonatomic, assign) CGMutablePathRef strokePath;

@end

@implementation KTCompoundPath

@synthesize path = _path;
@synthesize strokePath = _strokePath;

- (void)dealloc {
    if (_path) {
        CGPathRelease(_path);
        _path = NULL;
    }
    if (_strokePath) {
        CGPathRelease(_strokePath);
        _strokePath = NULL;
    }
}

- (id)copyWithZone:(NSZone *)zone {
    KTCompoundPath *compoundPath = [super copyWithZone:zone];
    // copy subpaths
    [compoundPath setSubpathsQuiet:_subpaths.copy];
    [compoundPath.subpaths makeObjectsPerformSelector:@selector(setSubpaths:) withObject:compoundPath];
    return compoundPath;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:_subpaths forKey:KTCompoundPathSubpathsKey];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    _subpaths = [aDecoder decodeObjectForKey:KTCompoundPathSubpathsKey];
    return self;
}

- (void)awakeFromEncoding {
    [super awakeFromEncoding];
    [_subpaths makeObjectsPerformSelector:@selector(awakeFromEncoding) withObject:nil];
}

- (void)setLayer:(KTLayer *)layer {
    [super setLayer:layer];
    for (KTPath *subpath in _subpaths) {
        [subpath setLayer:layer];
    }
}

- (void)setSubpaths:(NSMutableArray *)subpaths {
    [self cacheDirtyBounds];
    [[self.undoManager prepareWithInvocationTarget:self] setSubpaths:_subpaths];
    [self setSubpathsQuiet:subpaths];
    [self invalidatePath];
    [self postDirtyBoundsChange];
}

- (void)setSubpathsQuiet:(NSMutableArray *)subpaths {
    _subpaths = subpaths;
    [subpaths makeObjectsPerformSelector:@selector(setSubpaths:) withObject:self];
    [subpaths makeObjectsPerformSelector:@selector(setLayer:) withObject:self.layer];
}

- (void)addSubpath:(KTPath *)path {
    NSMutableArray *paths = @[].mutableCopy;
    [paths addObjectsFromArray:_subpaths];
    [paths addObject:path];
    self.subpaths = paths;
}

- (void)removeSubpath:(KTPath *)path {
    NSMutableArray *paths = @[].mutableCopy;
    [paths addObjectsFromArray:_subpaths];
    [paths removeLastObject];
    self.subpaths = paths;
}

- (NSUInteger)subpathCount {
    return _subpaths.count;
}

- (CGRect)bounds {
    CGRect bounds = CGRectNull;
    for (KTPath *path in _subpaths) {
        bounds = CGRectUnion([path bounds], bounds);
    }
    return bounds;
}

- (CGRect)controlBounds {
    CGRect bounds = CGRectNull;
    for (KTPath *path in _subpaths) {
        bounds = CGRectUnion([path controlBounds], bounds);
    }
    if (self.fillTransform) {
        bounds = KTExpandRectToPoint(bounds, self.fillTransform.transformedStart);
        bounds = KTExpandRectToPoint(bounds, self.fillTransform.transformedEnd);
    }
    return bounds;
}

- (CGRect)styleBounds {
    CGRect bounds = CGRectNull;
    for (KTPath *path in _subpaths) {
        bounds = CGRectUnion([path styleBounds], bounds);
    }
    return bounds;
}

- (KTShadow *)shadowForStyleBounds {
    return nil; // handled by subpaths
}

- (void)addElementsToOutlinedStroke:(CGMutablePathRef)outline {
    for (KTPath *path in _subpaths) {
        [path addElementsToOutlinedStroke:outline];
    }
}

- (NSSet *)transform:(CGAffineTransform)transform {
    [self cacheDirtyBounds];
    for (KTPath *path in _subpaths) {
        [path transform:transform];
    }
    // parent transforms masked elements and fill transform
    [super transform:transform];
    [self postDirtyBoundsChange];
    return nil;
}

- (BOOL)intersectsRect:(CGRect)rect {
    for (KTPath *path in [_subpaths reverseObjectEnumerator]) {
        if ([path intersectsRect:rect]) {
            return YES;
        }
    }
    return NO;
}

- (CGMutablePathRef)path {
    if (!_path) {
        _path = CGPathCreateMutable();
        for (KTPath *subpath in _subpaths) {
            CGPathAddPath(_path, NULL, subpath.path);
        }
    }
    return _path;
}

- (CGMutablePathRef)strokePath {
    if (!_strokePath) {
        _strokePath = CGPathCreateMutable();
        for (KTPath *subpath in _subpaths) {
            CGPathAddPath(_strokePath, NULL, subpath.path);
        }
    }
    return _strokePath;
}

- (KTPickResult *)hitResultForPoint:(CGPoint)point viewScale:(float)viewScale snapFlags:(int)flags {
    KTPickResult *result = [KTPickResult pickResult];
    CGRect pointRect = KTRectFromPoint(point, kNodeSelectionTolerance / viewScale, kNodeSelectionTolerance/ viewScale);
    if (!CGRectIntersectsRect(pointRect, [self controlBounds])) {
        return result;
    }
    if (flags & KTSnapNodes) {
        // look for fill control points
        if (self.fillTransform) {
            if (KTDistanceL2(self.fillTransform.transformedStart, point) < (kNodeSelectionTolerance / viewScale)) {
                result.element = self;
                result.type = KTFillStartPoint;
                return result;
            }
            else if (KTDistanceL2(self.fillTransform.transformedEnd, point) < (kNodeSelectionTolerance / viewScale)) {
                result.element = self;
                result.type = KTFillEndPoint;
                return result;
            }
        }
    }
    for (KTPath *path in [_subpaths reverseObjectEnumerator]) {
        KTPickResult *result = [path hitResultForPoint:point viewScale:viewScale snapFlags:KTSnapEdges];
        if (result.type != KTEther) {
            return result;
        }
    }
    if ((flags & KTSnapFills) && (self.fill || self.maskedElements)) {
        if (CGPathContainsPoint(self.path, NULL, point, self.fillRule)) {
            result.element = self;
            result.type = KTObjectFill;
            return result;
        }
    }
    
    return result;
}

- (KTPickResult *)snappedPoint:(CGPoint)pt viewScale:(float)viewScale snapFlags:(int)flags {
    for (KTPath *path in [_subpaths reverseObjectEnumerator]) {
        KTPickResult *result = [path snappedPoint:pt viewScale:viewScale snapFlags:flags];
        if (result.type != KTEther) {
            return result;
        }
    }
    return [KTPickResult pickResult];
}

- (void)invalidatePath {
    if (!_path) {
        CGPathRelease(_path);
        _path = NULL;
    }
    if (_strokePath) {
        CGPathRelease(_strokePath);
        _strokePath = NULL;
    }
}

// OpenGL-based selection rendering
- (void)drawOpenGLZoomOutlineWithViewTransform:(CGAffineTransform)viewTransform visibleRect:(CGRect)visibleRect {
    for (KTPath *subpath in _subpaths) {
        [subpath drawOpenGLZoomOutlineWithViewTransform:viewTransform visibleRect:visibleRect];
    }
}

- (void)drawOpenGLHighlightWithTransform:(CGAffineTransform)transform viewTransform:(CGAffineTransform)viewTransform {
    for (KTPath *subpath in _subpaths) {
        [subpath drawOpenGLHighlightWithTransform:transform viewTransform:viewTransform];
    }
}

- (void)drawOpenGLAnchorsWithViewTransform:(CGAffineTransform)transform {
    for (KTPath *subpath in _subpaths) {
        [subpath drawOpenGLAnchorsWithViewTransform:transform];
    }
}

- (void)drawOpenGLHandlesWithTransform:(CGAffineTransform)transform viewTransform:(CGAffineTransform)viewTransform {
    for (KTPath *subpath in _subpaths) {
        [subpath drawOpenGLHandlesWithTransform:transform viewTransform:viewTransform];
    }
}

- (void)addElementsToArray:(NSMutableArray *)array {
    [super addElementsToArray:array];
    [_subpaths makeObjectsPerformSelector:@selector(addElementsToArray:) withObject:array];
}

- (NSString *)nodeSVGRepresentation {
    NSMutableString *svg = @"".mutableCopy;
    for (KTPath *path in _subpaths) {
        [svg appendString:[path nodeSVGRepresentation]];
    }
    return svg;
}

- (void)addSVGArrowHeadsToGroup:(KTXMLElement *)group {
    for (KTPath *path in _subpaths) {
        [path addSVGArrowHeadsToGroup:group];
    }
}

- (NSArray *)erase:(KTAbstractPath *)erasePath {
    if (self.fill) {
        KTAbstractPath *erased = [KTPathFinder combinePaths:@[self, erasePath] operation:KTPathFinderOperationSubtract];
        if (erased) {
            [erased takeStylePropertiesFrom:self];
            return @[erased];
        }
    }
    else {
        NSMutableArray *result = @[].mutableCopy;
        for (KTPath *path in _subpaths) {
            [result addObjectsFromArray:[path erase:erasePath]];
        }
        if (result.count > 1) {
            KTCompoundPath *compoundPath = [[KTCompoundPath alloc] init];
            [compoundPath takeStylePropertiesFrom:self];
            compoundPath.subpaths = result;
            return @[compoundPath];
        }
        else if (result.count == 1) {
            KTPath *singlePath = [result lastObject];
            [singlePath takeStylePropertiesFrom:self];
            return @[singlePath];
        }
    }
    return @[];
}

- (void)simplify {
    [_subpaths makeObjectsPerformSelector:@selector(simplify)];
}

- (void)flatten {
    [_subpaths makeObjectsPerformSelector:@selector(flatten)];
}

- (KTAbstractPath *)pathByFlatteningPath {
    KTCompoundPath *compoundPath = [[KTCompoundPath alloc] init];
    NSMutableArray *flatPaths = @[].mutableCopy;
    for (KTPath *path in _subpaths) {
        [flatPaths addObject:[path pathByFlatteningPath]];
    }
    compoundPath.subpaths = flatPaths;
    return compoundPath;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@: subpaths: %@", [super description], _subpaths];
}

- (void)strokeStyleChanged {
    [_subpaths makeObjectsPerformSelector:@selector(strokeStyleChanged)];
}

- (void)renderStrokeInContext:(CGContextRef)ctx {
    if (![self.strokeStyle hasArrow]) {
        [super renderStrokeInContext:ctx];
        return;
    }
    for (KTPath *path in _subpaths) {
        [path renderStrokeInContext:ctx];
    }
}

@end
