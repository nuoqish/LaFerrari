//
//  KTPath.m
//  LaFerrari
//
//  Created by stanshen on 17/6/11.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTPath.h"

#import "KTStrokeStyle.h"
#import "KTArrowhead.h"
#import "KTBezierNode.h"
#import "KTBezierSegment.h"

#import "KTCompoundPath.h"
#import "KTShadow.h"
#import "KTLayer.h"
#import "KTFillTransform.h"
#import "KTColor.h"
#import "KTPropertyManager.h"
#import "KTPathFinder.h"
#import "KTXMLElement.h"
#import "KTUtilities.h"
#import "KTGLUtilities.h"
#import "NSColor+Utils.h"

void KTPathApplyAccumulateElement(void *info, const CGPathElement *element)
{
    NSMutableArray  *subpaths = (__bridge NSMutableArray *)info;
    KTPath          *path = [subpaths lastObject];
    KTBezierNode    *prev, *node;
    
    switch (element->type) {
        case kCGPathElementMoveToPoint:
            path = [[KTPath alloc] init];
            
            node = [[KTBezierNode alloc] initWithAnchorPoint:element->points[0]];
            [path.nodes addObject:node];
            
            [subpaths addObject:path];
            break;
        case kCGPathElementAddLineToPoint:
            node = [[KTBezierNode alloc] initWithAnchorPoint:element->points[0]];
            [path.nodes addObject:node];
            break;
        case kCGPathElementAddQuadCurveToPoint:
            prev = [path lastNode];
            
            // convert quadratic to cubic: http://fontforge.sourceforge.net/bezier.html
            CGPoint outPoint = KTAddPoints(prev.anchorPoint, KTMultiplyPointScalar(KTSubtractPoints(element->points[0], prev.anchorPoint), 2.0f / 3));
            CGPoint inPoint = KTAddPoints(element->points[1], KTMultiplyPointScalar(KTSubtractPoints(element->points[0], element->points[1]), 2.0f / 3));
            
            // update and replace previous node
            node = [[KTBezierNode alloc] initWithInPoint:prev.inPoint anchorPoint:prev.anchorPoint outPoint:outPoint];
            [path.nodes removeLastObject];
            [path.nodes addObject:node];
            
            node = [[KTBezierNode alloc] initWithInPoint:inPoint anchorPoint:element->points[1] outPoint:element->points[1]];
            [path.nodes addObject:node];
            break;
        case kCGPathElementAddCurveToPoint:
            prev = [path lastNode];
            
            // update and replace previous node
            node = [[KTBezierNode alloc] initWithInPoint:prev.inPoint anchorPoint:prev.anchorPoint outPoint:element->points[0]];
            [path.nodes removeLastObject];
            [path.nodes addObject:node];
            
            node = [[KTBezierNode alloc] initWithInPoint:element->points[1] anchorPoint:element->points[2] outPoint:element->points[2]];
            [path.nodes addObject:node];
            break;
        case kCGPathElementCloseSubpath:
            [path setClosedQuiet:YES];
            break;
    }
}

const float kMiterLimit = 10;
const float kCircleFactor = 0.5522847498307936;

NSString *KTPathClosedKey = @"KTClosedKey";
NSString *KTPathNodesKey = @"KTPathNodesKey";
NSString *KTPathSuperPathKey = @"KTPathSuperPathKey";
NSString *KTPathReversedPathKey = @"KTPathReversedPathKey";

@interface KTPath ()

@property (nonatomic, assign) BOOL boundsIsDirty;

@property (nonatomic, assign) CGMutablePathRef path;
@property (nonatomic, assign) CGMutablePathRef strokePath;


@end

@implementation KTPath {
    BOOL canFitStartArrow_;
    CGPoint arrowStartAttachment_;
    float arrowStartAngle_;
    
    BOOL canFitEndArrow_;
    CGPoint arrowEndAttachment_;
    float arrowEndAngle_;
    
    CGRect bounds_;
}

@synthesize path = _path;
@synthesize strokePath = _strokePath;

- (void)dealloc {
    if (_path) {
        CGPathRelease(_path);
    }
    if (_strokePath) {
        CGPathRelease(_strokePath);
    }
}

+ (KTPath *)pathWithRect:(CGRect)rect {
    return [[KTPath alloc] initWithRect:rect];
}

+ (KTPath *)pathWithRoundedRect:(CGRect)rect cornerRadius:(float)radius {
    return [[KTPath alloc] initWithRoundedRect:rect cornerRadius:radius];
}

+ (KTPath *)pathWithOvalInRect:(CGRect)rect {
    return [[KTPath alloc] initWithOvalInRect:rect];
}

+ (KTPath *)pathWithStart:(CGPoint)start end:(CGPoint)end {
    return [[KTPath alloc] initWithStart:start end:end];
}


- (instancetype)init {
    self = [super init];
    
    if (self) {
        _nodes = @[].mutableCopy;
        _boundsIsDirty = YES;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    _nodes = [aDecoder decodeObjectForKey:KTPathNodesKey];
    _closed = [aDecoder decodeBoolForKey:KTPathClosedKey];
    _reversed = [aDecoder decodeBoolForKey:KTPathReversedPathKey];
    _superpath = [aDecoder decodeObjectForKey:KTPathSuperPathKey];
    _boundsIsDirty = YES;
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:_nodes forKey:KTPathNodesKey];
    [aCoder encodeBool:_closed forKey:KTPathClosedKey];
    [aCoder encodeBool:_reversed forKey:KTPathReversedPathKey];
    if (_superpath) {
        [aCoder encodeObject:_superpath forKey:KTPathSuperPathKey];
    }
}

- (id) copyWithZone:(NSZone *)zone
{
    KTPath *path = [super copyWithZone:zone];
    
    path.nodes = [_nodes mutableCopy];
    path.closed = _closed;
    path.reversed = _reversed;
    path.boundsIsDirty = YES;
    
    return path;
}

- (id)initWithNode:(KTBezierNode *)node {
    self = [super init];
    
    if (self) {
        _nodes = @[node].mutableCopy;
        _boundsIsDirty = YES;
    }
    
    return self;
}

- (id)initWithRect:(CGRect)rect {
    self = [self init];
    
    if (self) {
        [_nodes addObject:[KTBezierNode bezierNodeWithAnchorPoint:CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect))]];
        [_nodes addObject:[KTBezierNode bezierNodeWithAnchorPoint:CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect))]];
        [_nodes addObject:[KTBezierNode bezierNodeWithAnchorPoint:CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect))]];
        [_nodes addObject:[KTBezierNode bezierNodeWithAnchorPoint:CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect))]];
        
        self.closed = YES;
        bounds_ = rect;
    }
    
    return self;
}

- (id)initWithRoundedRect:(CGRect)rect cornerRadius:(float)radius {
    radius = MIN(radius, MIN(CGRectGetHeight(rect) * 0.5f, CGRectGetWidth(rect) * 0.5f));
    
    if (radius <= 0.0f) {
        return [self initWithRect:rect];
    }
    
    self = [self init];
    
    if (!self) {
        return nil;
    }
    
    CGPoint     ul, ur, lr, ll;
    CGPoint     hInset = CGPointMake(radius, 0.0f);
    CGPoint     vInset = CGPointMake(0.0f, radius);
    CGPoint     current;
    CGPoint     xDelta =  CGPointMake(radius * kCircleFactor, 0);
    CGPoint     yDelta =  CGPointMake(0, radius * kCircleFactor);
    
    ul = rect.origin;
    ur = CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect));
    lr = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    ll = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));
    
    // top edge
    current = KTAddPoints(ul, hInset);
    KTBezierNode *node = [KTBezierNode bezierNodeWithInPoint:KTSubtractPoints(current, xDelta) anchorPoint:current outPoint:current];
    [_nodes addObject:node];
    
    current = KTSubtractPoints(ur, hInset);
    node = [KTBezierNode bezierNodeWithInPoint:current anchorPoint:current outPoint:KTAddPoints(current, xDelta)];
    [_nodes addObject:node];
    
    // right edge
    current = KTAddPoints(ur, vInset);
    node = [KTBezierNode bezierNodeWithInPoint:KTSubtractPoints(current, yDelta) anchorPoint:current outPoint:current];
    [_nodes addObject:node];
    
    current = KTSubtractPoints(lr, vInset);
    node = [KTBezierNode bezierNodeWithInPoint:current anchorPoint:current outPoint:KTAddPoints(current, yDelta)];
    [_nodes addObject:node];
    
    // bottom edge
    current = KTSubtractPoints(lr, hInset);
    node = [KTBezierNode bezierNodeWithInPoint:KTAddPoints(current, xDelta) anchorPoint:current outPoint:current];
    [_nodes addObject:node];
    
    current = KTAddPoints(ll, hInset);
    node = [KTBezierNode bezierNodeWithInPoint:current anchorPoint:current outPoint:KTSubtractPoints(current, xDelta)];
    [_nodes addObject:node];
    
    // left edge
    current = KTSubtractPoints(ll, vInset);
    node = [KTBezierNode bezierNodeWithInPoint:KTAddPoints(current, yDelta) anchorPoint:current outPoint:current];
    [_nodes addObject:node];
    
    current = KTAddPoints(ul, vInset);
    node = [KTBezierNode bezierNodeWithInPoint:current anchorPoint:current outPoint:KTSubtractPoints(current, yDelta)];
    [_nodes addObject:node];
    
    self.closed = YES;
    bounds_ = rect;
    
    return self;
}

- (id)initWithOvalInRect:(CGRect)rect {
    
    self = [self init];
    
    if (!self) {
        return nil;
    }
    
    // instantiate nodes for each corner
    float minX = CGRectGetMinX(rect);
    float midX = CGRectGetMidX(rect);
    float maxX = CGRectGetMaxX(rect);
    
    float minY = CGRectGetMinY(rect);
    float midY = CGRectGetMidY(rect);
    float maxY = CGRectGetMaxY(rect);
    
    CGPoint xDelta =  CGPointMake((maxX - midX) * kCircleFactor, 0);
    CGPoint yDelta =  CGPointMake(0, (maxY - midY) * kCircleFactor);
    
    CGPoint anchor = CGPointMake(minX, midY);
    KTBezierNode *node = [KTBezierNode bezierNodeWithInPoint:KTAddPoints(anchor, yDelta) anchorPoint:anchor outPoint:KTSubtractPoints(anchor, yDelta)];
    [_nodes addObject:node];
    
    anchor = CGPointMake(midX, minY);
    node = [KTBezierNode bezierNodeWithInPoint:KTSubtractPoints(anchor, xDelta) anchorPoint:anchor outPoint:KTAddPoints(anchor, xDelta)];
    [_nodes addObject:node];
    
    anchor = CGPointMake(maxX, midY);
    node = [KTBezierNode bezierNodeWithInPoint:KTSubtractPoints(anchor, yDelta) anchorPoint:anchor outPoint:KTAddPoints(anchor, yDelta)];
    [_nodes addObject:node];
    
    anchor = CGPointMake(midX, maxY);
    node = [KTBezierNode bezierNodeWithInPoint:KTAddPoints(anchor, xDelta) anchorPoint:anchor outPoint:KTSubtractPoints(anchor, xDelta)];
    [_nodes addObject:node];
    
    self.closed = YES;
    bounds_ = rect;
    
    return self;
    
}

- (id) initWithStart:(CGPoint)start end:(CGPoint)end
{
    self = [self init];
    
    if (!self) {
        return nil;
    }
    
    [_nodes addObject:[KTBezierNode bezierNodeWithAnchorPoint:start]];
    [_nodes addObject:[KTBezierNode bezierNodeWithAnchorPoint:end]];
    
    _boundsIsDirty = YES;
    
    return self;
}

- (NSMutableArray *)reversedNodes {
    NSMutableArray *reversed = @[].mutableCopy;
    for (KTBezierNode *node in [_nodes reverseObjectEnumerator]) {
        [reversed addObject:[node flippedNode]];
    }
    return reversed;
}

- (void)strokeStyleChanged {
    [self invalidatePath];
}

- (void)computePath {
    NSArray *nodes = _reversed ? [self reversedNodes] : _nodes;
    
    KTBezierNode * prevNode = nil;
    BOOL firstTime = YES;
    
    _path = CGPathCreateMutable();
    
    for (KTBezierNode *node in nodes) {
        if (firstTime) {
            CGPathMoveToPoint(_path, NULL, node.anchorPoint.x, node.anchorPoint.y);
            firstTime = NO;
        }
        else if ([prevNode hasOutPoint] || [node hasInPoint]) {
            CGPathAddCurveToPoint(_path, NULL, prevNode.outPoint.x, prevNode.outPoint.y, node.inPoint.x, node.inPoint.y, node.anchorPoint.x, node.anchorPoint.y);
        }
        else {
            CGPathAddLineToPoint(_path, NULL, node.anchorPoint.x, node.anchorPoint.y);
        }
        prevNode = node;
    }
    
    if (_closed && prevNode) {
        KTBezierNode *node = nodes[0];
        CGPathAddCurveToPoint(_path, NULL, prevNode.outPoint.x, prevNode.outPoint.y, node.inPoint.x, node.inPoint.y, node.anchorPoint.x, node.anchorPoint.y);
    }
    
    CGPathCloseSubpath(_path);
}

- (CGMutablePathRef)path {
    if (_nodes.count == 0) {
        return NULL;
    }
    if (!_path) {
        [self computePath];
    }
    
    return _path;
}

- (NSArray *) insetForArrowhead:(KTArrowhead *)arrowhead nodes:(NSArray *)nodes attachment:(CGPoint *)attachment angle:(float *)angle
{
    NSMutableArray  *newNodes = [NSMutableArray array];
    NSInteger       numNodes = nodes.count;
    KTBezierNode    *firstNode = nodes[0];
    CGPoint         arrowTip = firstNode.anchorPoint;
    CGPoint         result;
    KTStrokeStyle   *stroke = [self effectiveStrokeStyle];
    float           t, scale = stroke.width;
    BOOL            butt = (stroke.cap == kCGLineCapButt) ? YES : NO;
    
    for (int i = 0; i < numNodes-1; i++) {
        KTBezierNode    *a = nodes[i];
        KTBezierNode    *b = nodes[i+1];
        KTBezierSegment segment = KTBezierSegmentMake(a, b);
        KTBezierSegment L, R;
        
        if (KTBezierSegmentPointDistantFromPoint(segment, [arrowhead insetLength:butt] * scale, arrowTip, &result, &t)) {
            KTBezierSegmentSplitAtT(segment, &L, &R, t);
            [newNodes addObject:[KTBezierNode bezierNodeWithInPoint:result anchorPoint:result outPoint:R.out_]];
            [newNodes addObject:[KTBezierNode bezierNodeWithInPoint:R.in_ anchorPoint:b.anchorPoint outPoint:b.outPoint]];
            
            for (int n = i+2; n < numNodes; n++) {
                [newNodes addObject:nodes[n % numNodes]];
            }
            
            *attachment = result;
            CGPoint delta = KTSubtractPoints(arrowTip, result);
            *angle = atan2(delta.y, delta.x);
            
            break;
        }
    }
    
    return newNodes;
}

- (void)computeStrokePath {
    if (_strokePath) {
        CGPathRelease(_strokePath);
    }
    
    KTStrokeStyle *stroke = [self effectiveStrokeStyle];
    
    if (![stroke hasArrow]) {
        // since we don't have arrowheads, the stroke path is the same as the fill path
        _strokePath = (CGMutablePathRef)CGPathRetain(self.path);
        return;
    }
    
    // need to calculate arrowhead postion and inset the path appropriately
    NSArray *nodes = _nodes.copy;
    if (_closed) {
        nodes = [nodes arrayByAddingObject:nodes[0]];
    }
    
    // by default, we can fit an arrow
    canFitStartArrow_ = canFitEndArrow_ = YES;
    
    // start arrow ?
    KTArrowhead *startArrowhead = [KTArrowhead arrowheads][stroke.startArrow];
    if (startArrowhead) {
        nodes = [self insetForArrowhead:startArrowhead nodes:nodes attachment:&arrowStartAttachment_ angle:&arrowStartAngle_];
        canFitStartArrow_ = nodes.count > 0;
    }
    
    // end arrow
    KTArrowhead *endArrowhead = [KTArrowhead arrowheads][stroke.endArrow];
    if (endArrowhead && nodes.count > 0) {
        NSMutableArray *reversed = @[].mutableCopy;
        for (KTBezierNode *node in [nodes reverseObjectEnumerator]) {
            [reversed addObject:[node flippedNode]];
        }
        NSArray *result = [self insetForArrowhead:endArrowhead nodes:reversed attachment:&arrowEndAttachment_ angle:&arrowEndAngle_];
        canFitEndArrow_ = result.count > 0;
        
        if (canFitEndArrow_) {
            nodes = result;
        }
    }
    
    if (!canFitStartArrow_ || !canFitEndArrow_) {
        // we either fit both arrows or no arrows
        canFitStartArrow_ = canFitEndArrow_ = NO;
        _strokePath = (CGMutablePathRef)CGPathRetain(_path);
        return;
    }
    
    // construct the path ref from the remaining node list
    KTBezierNode    *prevNode = nil;
    BOOL            firstTime = YES;
    
    _strokePath = CGPathCreateMutable();
    for (KTBezierNode *node in nodes) {
        if (firstTime) {
            CGPathMoveToPoint(_strokePath, NULL, node.anchorPoint.x, node.anchorPoint.y);
            firstTime = NO;
        } else if ([prevNode hasOutPoint] || [node hasInPoint]) {
            CGPathAddCurveToPoint(_strokePath, NULL, prevNode.outPoint.x, prevNode.outPoint.y,
                                  node.inPoint.x, node.inPoint.y, node.anchorPoint.x, node.anchorPoint.y);
        } else {
            CGPathAddLineToPoint(_strokePath, NULL, node.anchorPoint.x, node.anchorPoint.y);
        }
        prevNode = node;
    }
    
}

- (CGMutablePathRef)strokePath {
    if (_nodes.count == 0) {
        return NULL;
    }
    if (!_strokePath) {
        [self computeStrokePath];
    }
    return _strokePath;
}

- (void)setClosedQuiet:(BOOL)closed {
    if (closed && _nodes.count < 2) {
        // need at least 2 nodes to close a path
        return;
    }
    
    if (closed) {
        // if the first and last node are sufficiently close to each other, one is redundant
        KTBezierNode *first = [self firstNode];
        KTBezierNode *last = [self lastNode];
        
        if (KTDistanceL2(first.anchorPoint, last.anchorPoint) < 1.0e-4) {
            KTBezierNode *closedNode = [KTBezierNode bezierNodeWithInPoint:last.inPoint anchorPoint:first.anchorPoint outPoint:first.outPoint];
            
            NSMutableArray *newNodes = [NSMutableArray arrayWithArray:_nodes];
            newNodes[0] = closedNode;
            [newNodes removeLastObject];
            
            // set directly so that we don't notify
            _nodes = newNodes;
        }
    }
    
    _closed = closed;
}

- (void)setClosed:(BOOL)closed {
    if (closed && _nodes.count < 2) {
        // need at least 2 nodes to close a path
        return;
    }
    
    [self cacheDirtyBounds];
    [[self.undoManager prepareWithInvocationTarget:self] setClosed:_closed];
    
    [self setClosedQuiet:closed];
    
    [self invalidatePath];
    [self postDirtyBoundsChange];
}

- (BOOL)addNode:(KTBezierNode *)node scale:(float)scale {
    [self cacheDirtyBounds];
    
    if (_nodes.count && KTDistanceL2(node.anchorPoint, ((KTBezierNode *) _nodes[0]).anchorPoint) < (kNodeSelectionTolerance / scale)) {
        self.closed = YES;
    } else {
        NSMutableArray *newNodes = _nodes.mutableCopy;
        [newNodes addObject:node];
        self.nodes = newNodes;
    }
    
    [self postDirtyBoundsChange];
    
    return _closed;
}

- (void)addNode:(KTBezierNode *)node {
    NSMutableArray *newNodes = _nodes.mutableCopy;
    [newNodes addObject:node];
    self.nodes = newNodes;
}

- (void)replaceFirstNodeWithNode:(KTBezierNode *)node {
    NSMutableArray *newNodes = _nodes.mutableCopy;
    newNodes[0] = node;
    self.nodes = newNodes;
}

- (void)replaceLastNodeWithNode:(KTBezierNode *)node {
    NSMutableArray *newNodes = _nodes.mutableCopy;
    [newNodes removeLastObject];
    [newNodes addObject:node];
    self.nodes = newNodes;
}

- (KTBezierNode *)firstNode {
    return _nodes[0];
}

- (KTBezierNode *)lastNode {
    return _closed ? _nodes[0] : [_nodes lastObject];
}

- (void)reversePathDirection {
    [self cacheDirtyBounds];
    
    [[self.undoManager prepareWithInvocationTarget:self] reversePathDirection];
    
    if (self.strokeStyle && [self.strokeStyle hasArrow]) {
        KTStrokeStyle *flippedArrows = [self.strokeStyle strokeStyleWithSwappedArrows];
        NSSet *changedProperties = [self changedStrokePropertiesFrom:self.strokeStyle to:flippedArrows];
        
        if (changedProperties.count) {
            [self setStrokeStyleQuiet:flippedArrows];
            [self strokeStyleChanged];
            [self propertiesChanged:changedProperties];
        }
    }
    
    _reversed = !_reversed;
    [self invalidatePath];
    
    [self postDirtyBoundsChange];
}

- (void)invalidatePath {
    if (_path) {
        CGPathRelease(_path);
        _path = NULL;
    }
    if (_strokePath) {
        CGPathRelease(_strokePath);
        _strokePath = NULL;
    }
    if (self.superpath) {
        [self.superpath invalidatePath];
    }
    
    _boundsIsDirty = YES;
}

- (void)computeBounds {
    bounds_ = CGPathGetPathBoundingBox(self.path);
    _boundsIsDirty = NO;
}

- (CGRect)bounds {
    if (_boundsIsDirty) {
        [self computeBounds];
    }
    return bounds_;
}

- (CGRect)controlBounds {
    KTBezierNode     *initial = [_nodes lastObject];
    float           minX, maxX, minY, maxY;
    
    minX = maxX = initial.anchorPoint.x;
    minY = maxY = initial.anchorPoint.y;
    
    for (KTBezierNode *node in _nodes) {
        minX = MIN(minX, node.anchorPoint.x);
        maxX = MAX(maxX, node.anchorPoint.x);
        minY = MIN(minY, node.anchorPoint.y);
        maxY = MAX(maxY, node.anchorPoint.y);
        
        minX = MIN(minX, node.inPoint.x);
        maxX = MAX(maxX, node.inPoint.x);
        minY = MIN(minY, node.inPoint.y);
        maxY = MAX(maxY, node.inPoint.y);
        
        minX = MIN(minX, node.outPoint.x);
        maxX = MAX(maxX, node.outPoint.x);
        minY = MIN(minY, node.outPoint.y);
        maxY = MAX(maxY, node.outPoint.y);
    }
    
    CGRect bbox = CGRectMake(minX, minY, maxX - minX, maxY - minY);
    
    if (self.fillTransform) {
        bbox = KTExpandRectToPoint(bbox, self.fillTransform.transformedStart);
        bbox = KTExpandRectToPoint(bbox, self.fillTransform.transformedEnd);
    }
    
    return bbox;
}

- (CGRect)subselectionBounds {
    if (![self anyNodesSelected]) {
        return [self bounds];
    }
    
    NSArray *selected = [self selectedNodes];
    KTBezierNode *initial = [selected lastObject];
    float   minX, maxX, minY, maxY;
    
    minX = maxX = initial.anchorPoint.x;
    minY = maxY = initial.anchorPoint.y;
    
    for (KTBezierNode *node in selected) {
        minX = MIN(minX, node.anchorPoint.x);
        maxX = MAX(maxX, node.anchorPoint.x);
        minY = MIN(minY, node.anchorPoint.y);
        maxY = MAX(maxY, node.anchorPoint.y);
    }
    
    return CGRectMake(minX, minY, maxX - minX, maxY - minY);
}

- (KTShadow *)shadowForStyleBounds {
    return self.superpath ? self.superpath.shadow : self.shadow;
}

- (CGRect)styleBounds {
    KTStrokeStyle *strokeStyle = [self effectiveStrokeStyle];
    
    if (![strokeStyle willRender]) {
        return [self expandStyleBounds:self.bounds];
    }
    
    float halfWidth =  strokeStyle.width / 2.0f;
    float outset = sqrt((halfWidth * halfWidth) * 2);
    
    // expand by half the stroke width to find the basic bounding box
    CGRect styleBounds = CGRectInset(self.bounds, -outset, -outset);
    
    // include miter joins on corners
    if (_nodes.count > 2 && strokeStyle.join == kCGLineJoinMiter) {
        NSInteger       nodeCount = _closed ? _nodes.count + 1 : _nodes.count;
        KTBezierNode    *prev = _nodes[0];
        KTBezierNode    *curr = _nodes[1];
        KTBezierNode    *next;
        CGPoint         inPoint, outPoint, inVec, outVec;
        float           miterLength, angle;
        
        for (int i = 1; i < nodeCount; i++) {
            next = _nodes[(i+1) % _nodes.count];
            
            inPoint = [curr hasInPoint] ? curr.inPoint : prev.outPoint;
            outPoint = [curr hasOutPoint] ? curr.outPoint : next.inPoint;
            
            inVec = KTSubtractPoints(inPoint, curr.anchorPoint);
            outVec = KTSubtractPoints(outPoint, curr.anchorPoint);
            
            inVec = KTNormalizeVector(inVec);
            outVec = KTNormalizeVector(outVec);
            
            angle = acos(inVec.x * outVec.x + inVec.y * outVec.y);
            miterLength = strokeStyle.width / sin(angle / 2.0f);
            
            if ((miterLength / strokeStyle.width) < kMiterLimit) {
                CGPoint avg = KTAveragePoints(inVec, outVec);
                CGPoint directed = KTMultiplyPointScalar(KTNormalizeVector(avg), -miterLength / 2.0f);
                
                styleBounds = KTExpandRectToPoint(styleBounds, KTAddPoints(curr.anchorPoint, directed));
            }
            
            prev = curr;
            curr = next;
        }
    }
    
    // add in arrowheads, if any
    if ([strokeStyle hasArrow] && self.nodes && self.nodes.count) {
        float               scale = strokeStyle.width;
        CGRect              arrowBounds;
        KTArrowhead         *arrow;
        
        // make sure this computed
        [self strokePath];
        
        // start arrow
        if ([strokeStyle hasStartArrow]) {
            arrow = [KTArrowhead arrowheads][strokeStyle.startArrow];
            arrowBounds = [arrow boundingBoxAtPosition:arrowStartAttachment_ scale:scale angle:arrowStartAngle_
                                         useAdjustment:(strokeStyle.cap == kCGLineCapButt)];
            styleBounds = CGRectUnion(styleBounds, arrowBounds);
        }
        
        // end arrow
        if ([strokeStyle hasEndArrow]) {
            arrow = [KTArrowhead arrowheads][strokeStyle.endArrow];
            arrowBounds = [arrow boundingBoxAtPosition:arrowEndAttachment_ scale:scale angle:arrowEndAngle_
                                         useAdjustment:(strokeStyle.cap == kCGLineCapButt)];
            styleBounds = CGRectUnion(styleBounds, arrowBounds);
        }
    }
    
    return [self expandStyleBounds:styleBounds];
}

- (BOOL)intersectsRect:(CGRect)rect {
    KTBezierNode 		*prev = nil;
    KTBezierSegment 	seg;
    
    if (_nodes.count == 1) {
        return CGRectContainsPoint(rect, [self firstNode].anchorPoint);
    }
    
    if (!CGRectIntersectsRect(self.bounds, rect)) {
        return NO;
    }
    
    for (KTBezierNode *node in _nodes) {
        if (!prev) {
            prev = node;
            continue;
        }
        
        seg = KTBezierSegmentMake(prev, node);
        if (KTBezierSegmentIntersectsRect(seg, rect)) {
            return YES;
        }
        
        prev = node;
    }
    
    if (self.closed) {
        seg = KTBezierSegmentMake([_nodes lastObject], _nodes[0]);
        if (KTBezierSegmentIntersectsRect(seg, rect)) {
            return YES;
        }
    }
    
    return NO;
}

- (NSSet *)nodesInRect:(CGRect)rect {
    NSMutableSet *nodesInRect = [NSMutableSet set];
    
    for (KTBezierNode *node in _nodes) {
        if (CGRectContainsPoint(rect, node.anchorPoint)) {
            [nodesInRect addObject:node];
        }
    }
    
    return nodesInRect;
}

// optimized version of -drawOpenGLHighlightWithTransform:viewTransform:

- (void)drawOpenGLHighlightWithTransform:(CGAffineTransform)transform viewTransform:(CGAffineTransform)viewTransform {
    NSArray             *nodes = _displayNodes ? _displayNodes : _nodes;
    
    if (!nodes || nodes.count == 0) {
        return;
    }
    
    BOOL                transformAll = ![self anyNodesSelected];
    BOOL                closed = _displayNodes ? _displayClosed : _closed;
    NSInteger           numNodes = closed ? nodes.count : nodes.count - 1;
    CGAffineTransform   combined = CGAffineTransformConcat(transform, viewTransform);
    CGPoint             prevIn, prevAnchor, prevOut;
    CGPoint             currIn, currAnchor, currOut;
    BOOL                prevSelected, currSelected;
    CGAffineTransform   prevTx, currTx;
    KTBezierSegment     segment;
    
    static GLfloat      *vertices = NULL;
    static NSUInteger   size = 128;
    NSUInteger          index = 0;
    
    if (!vertices) {
        vertices = calloc(sizeof(GLfloat), size);
    }
    
    // pre-condition
    KTBezierNode *prev = nodes[0];
    [prev getInPoint:&prevIn anchorPoint:&prevAnchor outPoint:&prevOut selected:&prevSelected];
    
    prevTx = (prevSelected || transformAll) ? combined : viewTransform;
    
    // segment.a_ = CGPointApplyAffineTransform(prevAnchor, (prevSelected || transformAll) ? combined : viewTransform);
    segment.a_.x = prevTx.a * prevAnchor.x + prevTx.c * prevAnchor.y + prevTx.tx;
    segment.a_.y = prevTx.b * prevAnchor.x + prevTx.d * prevAnchor.y + prevTx.ty;
    
    for (int i = 1; i <= numNodes; i++) {
        KTBezierNode *curr = nodes[i % nodes.count];
        [curr getInPoint:&currIn anchorPoint:&currAnchor outPoint:&currOut selected:&currSelected];
        
        // segment.out_ = CGPointApplyAffineTransform(prevOut, (prevSelected || transformAll) ? combined : viewTransform);
        segment.out_.x = prevTx.a * prevOut.x + prevTx.c * prevOut.y + prevTx.tx;
        segment.out_.y = prevTx.b * prevOut.x + prevTx.d * prevOut.y + prevTx.ty;
        
        currTx = (currSelected || transformAll) ? combined : viewTransform;
        
        // segment.in_ = CGPointApplyAffineTransform(currIn, (currSelected || transformAll) ? combined : viewTransform);
        segment.in_.x = currTx.a * currIn.x + currTx.c * currIn.y + currTx.tx;
        segment.in_.y = currTx.b * currIn.x + currTx.d * currIn.y + currTx.ty;
        
        //segment.b_ = CGPointApplyAffineTransform(currAnchor, (currSelected || transformAll) ? combined : viewTransform);
        segment.b_.x = currTx.a * currAnchor.x + currTx.c * currAnchor.y + currTx.tx;
        segment.b_.y = currTx.b * currAnchor.x + currTx.d * currAnchor.y + currTx.ty;
        
        KTGLFlattenBezierSegment(segment, &vertices, &size, &index);
        
        // set up for the next iteration
        prevSelected = currSelected;
        prevOut = currOut;
        prevTx = currTx;
        segment.a_ = segment.b_;
    }
    
    _displayColor ? [_displayColor.color openGLSet]: [self.layer.highlightColor openGLSet];
    KTGLDrawLineStrip(vertices, index);
}

- (void)drawOpenGLZoomOutlineWithViewTransform:(CGAffineTransform)viewTransform visibleRect:(CGRect)visibleRect {
    if (!CGRectIntersectsRect(self.bounds, visibleRect)) {
        return;
    }
    
    if (!_nodes || _nodes.count == 0) {
        return;
    }
    
    NSArray             *nodes = _nodes;
    NSInteger           numNodes = _closed ? nodes.count : nodes.count - 1;
    CGPoint             prevIn, prevAnchor, prevOut;
    CGPoint             currIn, currAnchor, currOut;
    KTBezierSegment     segment;
    
    static GLfloat      *vertices = NULL;
    static NSUInteger   size = 128;
    NSUInteger          index = 0;
    
    if (!vertices) {
        vertices = calloc(sizeof(GLfloat), size);
    }
    
    // pre-condition
    KTBezierNode *prev = nodes[0];
    [prev getInPoint:&prevIn anchorPoint:&prevAnchor outPoint:&prevOut selected:NULL];
    
    segment.a_.x = viewTransform.a * prevAnchor.x + viewTransform.c * prevAnchor.y + viewTransform.tx;
    segment.a_.y = viewTransform.b * prevAnchor.x + viewTransform.d * prevAnchor.y + viewTransform.ty;
    
    for (int i = 1; i <= numNodes; i++) {
        KTBezierNode *curr = nodes[i % nodes.count];
        [curr getInPoint:&currIn anchorPoint:&currAnchor outPoint:&currOut selected:NULL];
        
        segment.out_.x = viewTransform.a * prevOut.x + viewTransform.c * prevOut.y + viewTransform.tx;
        segment.out_.y = viewTransform.b * prevOut.x + viewTransform.d * prevOut.y + viewTransform.ty;
        
        segment.in_.x = viewTransform.a * currIn.x + viewTransform.c * currIn.y + viewTransform.tx;
        segment.in_.y = viewTransform.b * currIn.x + viewTransform.d * currIn.y + viewTransform.ty;
        
        segment.b_.x = viewTransform.a * currAnchor.x + viewTransform.c * currAnchor.y + viewTransform.tx;
        segment.b_.y = viewTransform.b * currAnchor.x + viewTransform.d * currAnchor.y + viewTransform.ty;
        
        KTGLFlattenBezierSegment(segment, &vertices, &size, &index);
        
        // set up for the next iteration
        prevOut = currOut;
        segment.a_ = segment.b_;
    }
    
    // assumes proper color set by caller
    KTGLDrawLineStrip(vertices, index);

}

- (void)drawOpenGLAnchorsWithViewTransform:(CGAffineTransform)transform {
    NSColor *color = _displayColor ? _displayColor.color : self.layer.highlightColor;
    NSArray *nodes = _displayNodes ? _displayNodes : _nodes;
    for (KTBezierNode *node in nodes) {
        [node drawGLWithViewTransform:transform color:color mode:KTBezierNodeRenderClosed];
    }
}

- (void)drawOpenGLHandlesWithTransform:(CGAffineTransform)transform viewTransform:(CGAffineTransform)viewTransform {
    CGAffineTransform   combined = CGAffineTransformConcat(transform, viewTransform);
    NSColor             *color = _displayColor ? _displayColor.color : self.layer.highlightColor;
    NSArray             *nodes = _displayNodes ? _displayNodes : _nodes;
    
    for (KTBezierNode *node in nodes) {
        if (node.selected) {
            [node drawGLWithViewTransform:combined color:color mode:KTBezierNodeRenderSelected];
        } else {
            [node drawGLWithViewTransform:viewTransform color:color mode:KTBezierNodeRenderOpen];
        }
    }
}

- (BOOL)anyNodesSelected {
    for (KTBezierNode *node in _nodes) {
        if (node.selected) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)allNodesSelected {
    for (KTBezierNode *node in _nodes) {
        if (!node.selected) {
            return NO;
        }
    }
    return YES;
}

- (NSSet *)alignToRect:(CGRect)rect alignment:(KTAlignment)align {
    if (![self anyNodesSelected]) {
        return [super alignToRect:rect alignment:align];
    }
    
    CGPoint             topLeft = rect.origin;
    CGPoint             rectCenter = KTCenterOfRect(rect);
    CGPoint             bottomRight = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    CGAffineTransform   translate = CGAffineTransformIdentity;
    NSMutableArray      *newNodes = [NSMutableArray array];
    NSMutableSet        *exchangedNodes = [NSMutableSet set];
    
    for (KTBezierNode *node in _nodes) {
        if (node.selected) {
            switch(align) {
                case KTAlignLeft:
                    translate = CGAffineTransformMakeTranslation(topLeft.x - node.anchorPoint.x, 0.0f);
                    break;
                case KTAlignCenter:
                    translate = CGAffineTransformMakeTranslation(rectCenter.x - node.anchorPoint.x, 0.0f);
                    break;
                case KTAlignRight:
                    translate = CGAffineTransformMakeTranslation(bottomRight.x - node.anchorPoint.x, 0.0f);
                    break;
                case KTAlignTop:
                    translate = CGAffineTransformMakeTranslation(0.0f, topLeft.y - node.anchorPoint.y);
                    break;
                case KTAlignMiddle:
                    translate = CGAffineTransformMakeTranslation(0.0f, rectCenter.y - node.anchorPoint.y);
                    break;
                case KTAlignBottom:
                    translate = CGAffineTransformMakeTranslation(0.0f, bottomRight.y - node.anchorPoint.y);
                    break;
            }
            
            KTBezierNode *alignedNode = [node transform:translate];
            [newNodes addObject:alignedNode];
            [exchangedNodes addObject:alignedNode];
        } else {
            [newNodes addObject:node];
        }
    }
    
    self.nodes = newNodes;
    
    return exchangedNodes;
}

- (void)setNodes:(NSMutableArray *)nodes {
    if ([_nodes isEqualToArray:nodes]) {
        return;
    }
    
    [self cacheDirtyBounds];
    
    [[self.undoManager prepareWithInvocationTarget:self] setNodes:_nodes];
    
    _nodes = nodes;
    
    [self invalidatePath];
    
    [self postDirtyBoundsChange];
}

- (NSSet *)transform:(CGAffineTransform)transform {
    NSMutableArray      *newNodes = [[NSMutableArray alloc] init];
    BOOL                transformAll = [self anyNodesSelected] ? NO : YES;
    NSMutableSet        *exchangedNodes = [NSMutableSet set];
    
    for (KTBezierNode *node in _nodes) {
        if (transformAll || node.selected) {
            KTBezierNode *transformed = [node transform:transform];
            [newNodes addObject:transformed];
            
            if (node.selected) {
                [exchangedNodes addObject:transformed];
            }
        } else {
            [newNodes addObject:node];
        }
    }
    
    self.nodes = newNodes;
    
    if (transformAll) {
        // parent transforms masked elements and fill transform
        [super transform:transform];
    }
    
    return exchangedNodes;
}

- (NSArray *)selectedNodes {
    NSMutableArray *selected = [NSMutableArray array];
    
    for (KTBezierNode *node in _nodes) {
        if (node.selected) {
            [selected addObject:node];
        }
    }
    
    return selected;
}

// when splitting a path, there are two cases:
// splitting a close path (reopen it) and splitting an open path (breaking it in to)

- (NSDictionary *)splitAtNode:(KTBezierNode *)node {
    NSMutableDictionary *whatToSelect = [NSMutableDictionary dictionary];
    NSUInteger          i, startIx = [_nodes indexOfObject:node];
    
    if (self.closed) {
        NSMutableArray  *newNodes = [NSMutableArray array];
        
        for (i = startIx; i < _nodes.count; i++) {
            [newNodes addObject:_nodes[i]];
        }
        
        for (i = 0; i < startIx; i++) {
            [newNodes addObject:_nodes[i]];
        }
        
        [newNodes addObject:[node copy]]; // copy this node since it would otherwise be shared
        
        self.nodes = newNodes;
        self.closed = NO; // can't be closed now
        
        whatToSelect[@"path"] = self;
        whatToSelect[@"node"] = [newNodes lastObject];
    } else {
        // the original path gets the first half of the original nodes
        NSMutableArray  *newNodes = [NSMutableArray array];
        for (i = 0; i < startIx; i++) {
            [newNodes addObject:_nodes[i]];
        }
        [newNodes addObject:[node copy]]; // copy this node since it would otherwise be shared
        
        // create a new path to take the rest of the nodes
        KTPath *sibling = [[KTPath alloc] init];
        NSMutableArray  *siblingNodes = [NSMutableArray array];
        for (i = startIx; i < _nodes.count; i++) {
            [siblingNodes addObject:_nodes[i]];
        }
        
        // set this after building siblingNodes so that nodes_ doesn't go away
        self.nodes = newNodes;
        
        sibling.nodes = siblingNodes;
        sibling.fill = self.fill;
        sibling.fillTransform = self.fillTransform;
        sibling.strokeStyle = self.strokeStyle;
        sibling.opacity = self.opacity;
        sibling.shadow = self.shadow;
        
        if (self.reversed) {
            [sibling reversePathDirection];
        }
        
        if (self.superpath) {
            [self.superpath addSubpath:sibling];
        } else {
            [self.layer insertObject:sibling above:self];
        }
        
        whatToSelect[@"path"] = sibling;
        whatToSelect[@"node"] = siblingNodes[0];
    }
    
    return whatToSelect;
}

- (NSDictionary *)splitAtPoint:(CGPoint)pt viewScale:(float)viewScale {
    KTBezierNode *node = [self addAnchorAtPoint:pt viewScale:viewScale];
    return [self splitAtNode:node];
}

- (KTBezierNode *)addAnchorAtPoint:(CGPoint)pt viewScale:(float)viewScale {
    NSMutableArray      *newNodes = [NSMutableArray array];
    NSInteger           numNodes = _closed ? (_nodes.count + 1) : _nodes.count;
    NSInteger           numSegments = numNodes; // includes an extra one for the one that gets split
    KTBezierSegment     segments[numSegments];
    KTBezierSegment     segment;
    KTBezierNode        *prev, *curr, *node, *newestNode = nil;
    NSUInteger          newestNodeSegmentIx = 0, segmentIndex = 0;
    float               t;
    BOOL                added = NO;
    
    prev = _nodes[0];
    for (int i = 1; i < numNodes; i++, segmentIndex ++) {
        curr = _nodes[(i % _nodes.count)];
        
        segment = KTBezierSegmentMake(prev, curr);
        
        if (!added && KTBezierSegmentFindPointOnSegment(segment, pt, kNodeSelectionTolerance / viewScale, NULL, &t)) {
            KTBezierSegmentSplitAtT(segment,  &segments[segmentIndex], &segments[segmentIndex+1], t);
            segmentIndex++;
            newestNodeSegmentIx = segmentIndex;
            added = YES;
        } else {
            segments[segmentIndex] = segment;
        }
        
        prev = curr;
    }
    
    // convert the segments back to nodes
    for (int i = 0; i < numSegments; i++) {
        if (i == 0) {
            CGPoint inPoint = _closed ? segments[numSegments - 1].in_ : [self firstNode].inPoint;
            node = [KTBezierNode bezierNodeWithInPoint:inPoint anchorPoint:segments[i].a_ outPoint:segments[i].out_];
        } else {
            node = [KTBezierNode bezierNodeWithInPoint:segments[i-1].in_ anchorPoint:segments[i].a_ outPoint:segments[i].out_];
        }
        
        [newNodes addObject:node];
        
        if (i == newestNodeSegmentIx) {
            newestNode = node;
        }
        
        if (i == (numSegments - 1) && !_closed) {
            node = [KTBezierNode bezierNodeWithInPoint:segments[i].in_ anchorPoint:segments[i].b_ outPoint:[self lastNode].outPoint];
            [newNodes addObject:node];
        }
    }
    
    self.nodes = newNodes;
    
    return newestNode;
}

- (void)addAnchors {
    NSMutableArray      *newNodes = [NSMutableArray array];
    NSInteger           numNodes = _closed ? (_nodes.count + 1) : _nodes.count;
    NSInteger           numSegments = (numNodes - 1) * 2;
    KTBezierSegment     segments[numSegments];
    KTBezierSegment     segment;
    KTBezierNode        *prev, *curr, *node;
    NSUInteger          segmentIndex = 0;
    
    prev = _nodes[0];
    for (int i = 1; i < numNodes; i++, segmentIndex += 2) {
        curr = _nodes[(i % _nodes.count)];
        
        segment = KTBezierSegmentMake(prev, curr);
        KTBezierSegmentSplit(segment, &segments[segmentIndex], &segments[segmentIndex+1]);
        
        prev = curr;
    }
    
    // convert the segments back to nodes
    for (int i = 0; i < numSegments; i++) {
        if (i == 0) {
            CGPoint inPoint = _closed ? segments[numSegments - 1].in_ : [self firstNode].inPoint;
            node = [KTBezierNode bezierNodeWithInPoint:inPoint anchorPoint:segments[i].a_ outPoint:segments[i].out_];
        } else {
            node = [KTBezierNode bezierNodeWithInPoint:segments[i-1].in_ anchorPoint:segments[i].a_ outPoint:segments[i].out_];
        }
        
        [newNodes addObject:node];
        
        if (i == (numSegments - 1) && !_closed) {
            node = [KTBezierNode bezierNodeWithInPoint:segments[i].in_ anchorPoint:segments[i].b_ outPoint:[self lastNode].outPoint];
            [newNodes addObject:node];
        }
    }
    
    self.nodes = newNodes;
}

- (BOOL)canDeleteAnchors {
    NSUInteger unselectedCount = 0;
    NSUInteger selectedCount = 0;
    
    for (KTBezierNode *node in _nodes) {
        if (!node.selected) {
            unselectedCount++;
        } else {
            selectedCount++;
        }
        
        if (unselectedCount >= 2 && selectedCount > 0) {
            return YES;
        }
    }
    
    return NO;
}

- (void)deleteAnchor:(KTBezierNode *)node {
    if (_nodes.count > 2) {
        NSMutableArray *newNodes = _nodes.mutableCopy;
        [newNodes removeObject:node];
        self.nodes = newNodes;
    }
}

- (void)deleteAnchors {
    NSMutableArray *newNodes = _nodes.mutableCopy;
    [newNodes removeObjectsInArray:[self selectedNodes]];
    self.nodes = newNodes;
}

- (void)appendPath:(KTPath *)path {
    NSArray     *baseNodes, *nodesToAdd;
    CGPoint     delta;
    BOOL        reverseMyNodes = YES;
    BOOL        reverseIncomingNodes = NO;
    float       distance, minDistance = KTDistanceL2([self firstNode].anchorPoint, [path firstNode].anchorPoint);
    
    // find the closest pair of end points
    distance = KTDistanceL2([self firstNode].anchorPoint, [path lastNode].anchorPoint);
    if (distance < minDistance) {
        minDistance = distance;
        reverseIncomingNodes = YES;
    }
    
    distance = KTDistanceL2([path firstNode].anchorPoint, [self lastNode].anchorPoint);
    if (distance < minDistance) {
        minDistance = distance;
        reverseMyNodes = NO;
        reverseIncomingNodes = NO;
    }
    
    distance = KTDistanceL2([path lastNode].anchorPoint, [self lastNode].anchorPoint);
    if (distance < minDistance) {
        reverseMyNodes = NO;
        reverseIncomingNodes = YES;
    }
    
    baseNodes = reverseMyNodes ? self.reversedNodes : self.nodes;
    nodesToAdd = reverseIncomingNodes ? path.reversedNodes : path.nodes;
    
    // add the base nodes (up to the shared node) to the new nodes
    NSMutableArray *newNodes = [NSMutableArray array];
    for (int i = 0; i < baseNodes.count - 1; i++) {
        [newNodes addObject:baseNodes[i]];
    }
    
    // compute the translation necessary to align the incoming path
    KTBezierNode *lastNode = [baseNodes lastObject];
    KTBezierNode *firstNode = nodesToAdd[0];
    delta = KTSubtractPoints(lastNode.anchorPoint, firstNode.anchorPoint);
    CGAffineTransform transform = CGAffineTransformMakeTranslation(delta.x, delta.y);
    
    // add the shared node (combine the handles appropriately)
    firstNode = [firstNode transform:transform];
    [newNodes addObject:[KTBezierNode bezierNodeWithInPoint:lastNode.inPoint anchorPoint:firstNode.anchorPoint outPoint:firstNode.outPoint]];
    
    // add the incoming path's nodes
    for (int i = 1; i < nodesToAdd.count; i++) {
        [newNodes addObject:[nodesToAdd[i] transform:transform]];
    }
    
    // see if the last node is the same as the first node
    firstNode = newNodes[0];
    lastNode = [newNodes lastObject];
    
    if (KTDistanceL2(firstNode.anchorPoint, lastNode.anchorPoint) < 0.5f) {
        KTBezierNode *closedNode = [KTBezierNode bezierNodeWithInPoint:lastNode.inPoint anchorPoint:firstNode.anchorPoint outPoint:firstNode.outPoint];
        newNodes[0] = closedNode;
        [newNodes removeLastObject];
        self.closed = YES;
    }
    
    self.nodes = newNodes;
}

- (KTBezierNode *)convertNode:(KTBezierNode *)node whichPoint:(KTPickResultType)whichPoint {
    KTBezierNode     *newNode = nil;
    
    if (whichPoint == KTInPoint) {
        newNode = [node chopInHandle];
    } else if (whichPoint == KTOutPoint) {
        newNode = [node chopOutHandle];
    } else {
        if (node.hasInPoint || node.hasOutPoint) {
            newNode = [node chopHandles];
        } else {
            NSInteger ix = [_nodes indexOfObject:node];
            NSInteger pix, nix;
            KTBezierNode *prev = nil, *next = nil;
            
            pix = ix - 1;
            if (pix >= 0) {
                prev = _nodes[pix];
            } else if (_closed && _nodes.count > 2) {
                prev = [_nodes lastObject];
            }
            
            nix = ix + 1;
            if (nix < _nodes.count) {
                next = _nodes[nix];
            } else if (_closed && _nodes.count > 2) {
                next = _nodes[0];
            }
            
            if (!prev) {
                prev = node;
            }
            
            if (!next) {
                next = node;
            }
            
            if (prev && next) {
                CGPoint    vector = KTSubtractPoints(next.anchorPoint, prev.anchorPoint);
                float      magnitude = KTDistanceL2(vector, CGPointZero);
                
                vector = KTNormalizeVector(vector);
                vector = KTMultiplyPointScalar(vector, magnitude / 4.0f);
                
                newNode = [KTBezierNode bezierNodeWithInPoint:KTSubtractPoints(node.anchorPoint, vector) anchorPoint:node.anchorPoint outPoint:KTAddPoints(node.anchorPoint, vector)];
            }
        }
    }
    
    NSMutableArray *newNodes = [NSMutableArray array];
    for (KTBezierNode *oldNode in _nodes) {
        if (node == oldNode) {
            [newNodes addObject:newNode];
        } else {
            [newNodes addObject:oldNode];
        }
    }
    
    self.nodes = newNodes;
    
    return newNode;
}

- (BOOL)hasFill {
    return [super hasFill] || self.maskedElements;
}

- (KTPickResult *)hitResultForPoint:(CGPoint)point viewScale:(float)viewScale snapFlags:(int)flags {
    KTPickResult        *result = [KTPickResult pickResult];
    CGRect              pointRect = KTRectFromPoint(point, kNodeSelectionTolerance / viewScale, kNodeSelectionTolerance / viewScale);
    float               distance, minDistance = MAXFLOAT;
    float               tolerance = kNodeSelectionTolerance / viewScale;
    
    if (!CGRectIntersectsRect(pointRect, [self controlBounds])) {
        return result;
    }
    
    if (flags & KTSnapNodes) {
        // look for fill control points
        if (self.fillTransform) {
            distance = KTDistanceL2([self.fillTransform transformedStart], point);
            if (distance < MIN(tolerance, minDistance)) {
                result.type = KTFillStartPoint;
                minDistance = distance;
            }
            
            distance = KTDistanceL2([self.fillTransform transformedEnd], point);
            if (distance < MIN(tolerance, minDistance)) {
                result.type = KTFillEndPoint;
                minDistance = distance;
            }
        }
        
        // pre-existing selected node gets first crack
        for (KTBezierNode *selectedNode in [self selectedNodes]) {
            distance = KTDistanceL2(selectedNode.anchorPoint, point);
            if (distance < MIN(tolerance, minDistance)) {
                result.node = selectedNode;
                result.type = KTAnchorPoint;
                minDistance = distance;
            }
            
            distance = KTDistanceL2(selectedNode.outPoint, point);
            if (distance < MIN(tolerance, minDistance)) {
                result.node = selectedNode;
                result.type = KTOutPoint;
                minDistance = distance;
            }
            
            distance = KTDistanceL2(selectedNode.inPoint, point);
            if (distance < MIN(tolerance, minDistance)) {
                result.node = selectedNode;
                result.type = KTInPoint;
                minDistance = distance;
            }
        }
        
        for (KTBezierNode *node in _nodes) {
            distance = KTDistanceL2(node.anchorPoint, point);
            if (distance < MIN(tolerance, minDistance)) {
                result.node = node;
                result.type = KTAnchorPoint;
                minDistance = distance;
            }
        }
        
        if (result.type != KTEther) {
            result.element = self;
            return result;
        }
    }
    
    if (flags & KTSnapEdges) {
        // check path edges
        NSInteger           numNodes = _closed ? _nodes.count : _nodes.count - 1;
        KTBezierSegment     segment;
        
        for (int i = 0; i < numNodes; i++) {
            KTBezierNode    *a = _nodes[i];
            KTBezierNode    *b = _nodes[(i+1) % _nodes.count];
            CGPoint         nearest;
            
            segment.a_ = a.anchorPoint;
            segment.out_ = a.outPoint;
            segment.in_ = b.inPoint;
            segment.b_ = b.anchorPoint;
            
            if (KTBezierSegmentFindPointOnSegment(segment, point, kNodeSelectionTolerance / viewScale, &nearest, NULL)) {
                result.element = self;
                result.type = KTEdge;
                result.snappedPoint = nearest;
                
                return result;
            }
        }
    }
    
    if ((flags & KTSnapFills) && ([self hasFill])) {
        if (CGPathContainsPoint(self.path, NULL, point, self.fillRule)) {
            result.element = self;
            result.type = KTObjectFill;
            return result;
        }
    }
    
    return result;
}

- (KTPickResult *)snappedPoint:(CGPoint)point viewScale:(float)viewScale snapFlags:(int)flags {
    KTPickResult        *result = [KTPickResult pickResult];
    CGRect              pointRect = KTRectFromPoint(point, kNodeSelectionTolerance / viewScale, kNodeSelectionTolerance / viewScale);
    
    if (!CGRectIntersectsRect(pointRect, [self controlBounds])) {
        return result;
    }
    
    if (flags & KTSnapNodes) {
        for (KTBezierNode *node in _nodes) {
            if (KTDistanceL2(node.anchorPoint, point) < (kNodeSelectionTolerance / viewScale)) {
                result.element = self;
                result.node = node;
                result.type = KTAnchorPoint;
                result.nodePosition = KTMiddleNode;
                result.snappedPoint = node.anchorPoint;
                
                if (!_closed) {
                    if (node == _nodes[0]) {
                        result.nodePosition = KTFirstNode;
                    } else if (node == [_nodes lastObject]) {
                        result.nodePosition = KTLastNode;
                    }
                }
                
                return result;
            }
        }
    }
    
    if (flags & KTSnapEdges) {
        // check path edges
        NSInteger           numNodes = _closed ? _nodes.count : _nodes.count - 1;
        KTBezierSegment     segment;
        
        
        for (int i = 0; i < numNodes; i++) {
            KTBezierNode    *a = _nodes[i];
            KTBezierNode    *b = _nodes[(i+1) % _nodes.count];
            CGPoint         nearest;
            
            segment.a_ = a.anchorPoint;
            segment.out_ = a.outPoint;
            segment.in_ = b.inPoint;
            segment.b_ = b.anchorPoint;
            
            if (KTBezierSegmentFindPointOnSegment(segment, point, kNodeSelectionTolerance / viewScale, &nearest, NULL)) {
                result.element = self;
                result.type = KTEdge;
                result.snappedPoint = nearest;
                
                return result;
            }
        }
    }
    
    return result;
}

- (void)setSuperpath:(KTCompoundPath *)superpath {
    [[self.undoManager prepareWithInvocationTarget:self] setSuperpath:_superpath];
    
    _superpath = superpath;
    
    if (superpath) {
        self.fill = nil;
        self.strokeStyle = nil;
        self.fillTransform = nil;
        self.shadow = nil;
    }
}

- (void)setValue:(id)value forProperty:(NSString *)property propertyManager:(KTPropertyManager *)propertyManager {
    if (self.superpath) {
        [self.superpath setValue:value forProperty:property propertyManager:propertyManager];
        return;
    }
    
    return [super setValue:value forProperty:property propertyManager:propertyManager];
}

- (id)valueForProperty:(NSString *)property {
    if (self.superpath) {
        return [self.superpath valueForProperty:property];
    }
    
    return [super valueForProperty:property];
}

- (BOOL)canPlaceText {
    return (!self.superpath && !self.maskedElements);
}

- (NSArray *)erase:(KTAbstractPath *)erasePath {
    if (self.closed) {
        KTAbstractPath *result = [KTPathFinder combinePaths:@[self, erasePath] operation:KTPathFinderOperationSubtract];
        
        if (!result) {
            return @[];
        }
        
        [result takeStylePropertiesFrom:self];
        
        if (self.superpath && [result isKindOfClass:[KTCompoundPath class]]) {
            KTCompoundPath *cp = (KTCompoundPath *)result;
            [[cp subpaths] makeObjectsPerformSelector:@selector(setSuperpath:) withObject:nil];
            return cp.subpaths;
        }
        
        return @[result];
    } else {
        if (!CGRectIntersectsRect(self.bounds, erasePath.bounds)) {
            KTPath *clone = [[KTPath alloc] init];
            [clone takeStylePropertiesFrom:self];
            NSMutableArray *nodes = [self.nodes mutableCopy];
            clone.nodes = nodes;
            
            NSArray *result = @[clone];
            return result;
        }
        
        // break down path
        NSArray             *nodes = _reversed ? [self reversedNodes] : _nodes;
        NSInteger           segmentCount = nodes.count - 1;
        KTBezierSegment     segments[segmentCount];
        
        KTBezierSegment     *splitSegments;
        NSUInteger          splitSegmentSize = 256;
        int                 splitSegmentIx = 0;
        
        KTBezierNode        *prev, *curr;
        
        // this might need to grow, so dynamically allocate it
        splitSegments = calloc(sizeof(KTBezierSegment), splitSegmentSize);
        
        prev = nodes[0];
        for (int i = 1; i < nodes.count; i++, prev = curr) {
            curr = nodes[i];
            segments[i-1] = KTBezierSegmentMake(prev, curr);
        }
        
        erasePath = [erasePath pathByFlatteningPath];
        
        KTBezierSegment     L, R;
        NSArray             *subpaths = [erasePath isKindOfClass:[KTPath class]] ? @[erasePath] : [(KTCompoundPath *)erasePath subpaths];
        float               smallestT, t;
        BOOL                intersected;
        
        for (int i = 0; i < segmentCount; i++) {
            smallestT = MAXFLOAT;
            intersected = NO;
            
            // split the segments into more segments at every intersection with the erasing path
            for (KTPath *subpath in subpaths) {
                prev = (subpath.nodes)[0];
                
                for (int n = 1; n < subpath.nodes.count; n++, prev = curr) {
                    curr = (subpath.nodes)[n];
                    
                    if (KTBezierSegmentGetIntersection(segments[i], prev.anchorPoint, curr.anchorPoint, &t)) {
                        if (t < smallestT && (fabs(t) > 0.001)) {
                            smallestT = t;
                            intersected = YES;
                        }
                    }
                }
            }
            
            if (!intersected || fabs(1 - smallestT) < 0.001) {
                splitSegments[splitSegmentIx++] = segments[i];
            } else {
                KTBezierSegmentSplitAtT(segments[i], &L, &R, smallestT);
                
                splitSegments[splitSegmentIx++] = L;
                segments[i] = R;
                i--;
            }
            
            if (splitSegmentIx >= splitSegmentSize) {
                splitSegmentSize *= 2;
                splitSegments = realloc(splitSegments, sizeof(KTBezierSegment) * splitSegmentSize);
            }
        }
        
        // toss out any segment that's inside the erase path
        KTBezierSegment newSegments[splitSegmentIx];
        int             newSegmentIx = 0;
        
        for (int i = 0; i < splitSegmentIx; i++) {
            CGPoint midPoint = KTBezierSegmentSplitAtT(splitSegments[i], NULL, NULL, 0.5);
            
            if (![erasePath containsPoint:midPoint]) {
                newSegments[newSegmentIx++] = splitSegments[i];
            }
        }
        
        // clean up
        free(splitSegments);
        
        if (newSegmentIx == 0) {
            return @[];
        }
        
        // reassemble segments
        NSMutableArray  *array = [NSMutableArray array];
        KTPath          *currentPath = [[KTPath alloc] init];
        
        [currentPath takeStylePropertiesFrom:self];
        [array addObject:currentPath];
        
        for (int i = 0; i < newSegmentIx; i++) {
            KTBezierNode *lastNode = [currentPath lastNode];
            
            if (!lastNode) {
                [currentPath addNode:[KTBezierNode bezierNodeWithInPoint:newSegments[i].a_ anchorPoint:newSegments[i].a_ outPoint:newSegments[i].out_]];
            } else if (CGPointEqualToPoint(lastNode.anchorPoint, newSegments[i].a_)) {
                [currentPath replaceLastNodeWithNode:[KTBezierNode bezierNodeWithInPoint:lastNode.inPoint anchorPoint:lastNode.anchorPoint outPoint:newSegments[i].out_]];
            } else {
                currentPath = [[KTPath alloc] init];
                [currentPath takeStylePropertiesFrom:self];
                [array addObject:currentPath];
                
                [currentPath addNode:[KTBezierNode bezierNodeWithInPoint:newSegments[i].a_ anchorPoint:newSegments[i].a_ outPoint:newSegments[i].out_]];
            }
            
            [currentPath addNode:[KTBezierNode bezierNodeWithInPoint:newSegments[i].in_ anchorPoint:newSegments[i].b_ outPoint:newSegments[i].b_]];
        }
        
        return array;
    }
}

- (void)simplify {
    // strip collinear anchors
    
    if (_nodes.count < 3) {
        return;
    }
    
    NSMutableArray  *newNodes = [NSMutableArray array];
    KTBezierNode    *current, *next, *nextnext;
    NSInteger       nodeCount = _closed ? _nodes.count + 1 : _nodes.count;
    NSInteger       ix = 0;
    
    current = _nodes[ix++];
    next = _nodes[ix++];
    nextnext = _nodes[ix++];
    
    [newNodes addObject:current];
    
    while (nextnext) {
        if (!KTCollinear(current.anchorPoint, current.outPoint, next.inPoint) ||
            !KTCollinear(current.anchorPoint, next.inPoint, next.anchorPoint) ||
            !KTCollinear(current.anchorPoint, next.anchorPoint, next.outPoint) ||
            !KTCollinear(current.anchorPoint, next.anchorPoint, nextnext.inPoint) ||
            !KTCollinear(current.anchorPoint, next.anchorPoint, nextnext.anchorPoint))
        {
            // can't remove the node since it's nonlinear, add it and move on
            [newNodes addObject:next];
            current = next;
        }
        
        next = nextnext;
        nextnext = (ix < nodeCount) ? _nodes[ix % _nodes.count] : nil;
        ix++;
    }
    
    if (!_closed) {
        [newNodes addObject:next];
    }
    
    if (_closed) {
        // see if we should remove the first node
        current = [newNodes lastObject];
        next = newNodes[0];
        nextnext = newNodes[1];
        
        if (KTCollinear(current.anchorPoint, current.outPoint, next.inPoint) &&
            KTCollinear(current.anchorPoint, next.inPoint, next.anchorPoint) &&
            KTCollinear(current.anchorPoint, next.anchorPoint, next.outPoint) &&
            KTCollinear(current.anchorPoint, next.anchorPoint, nextnext.inPoint) &&
            KTCollinear(current.anchorPoint, next.anchorPoint, nextnext.anchorPoint))
        {
            [newNodes removeObjectAtIndex:0];
        }
    }
    
    self.nodes = newNodes;
}

- (NSMutableArray *) flattenedNodes
{
    NSMutableArray      *flatNodes = [NSMutableArray array];
    NSInteger           numNodes = _closed ? _nodes.count : _nodes.count - 1;
    KTBezierSegment     segment;
    static CGPoint      *vertices = NULL;
    static NSUInteger   size = 128;
    NSUInteger          index = 0;
    
    if (!vertices) {
        vertices = calloc(sizeof(CGPoint), size);
    }
    
    for (int i = 0; i < numNodes; i++) {
        KTBezierNode *a = _nodes[i];
        KTBezierNode *b = _nodes[(i+1) % _nodes.count];
        
        // reset the index for the current segment
        index = 0;
        
        segment.a_ = a.anchorPoint;
        segment.out_ = a.outPoint;
        segment.in_ = b.inPoint;
        segment.b_ = b.anchorPoint;
        
        KTBezierSegmentFlatten(segment, &vertices, &size, &index);
        for (int v = 0; v < index; v++) {
            [flatNodes addObject:[KTBezierNode bezierNodeWithAnchorPoint:vertices[v]]];
        }
    }
    
    return flatNodes;
}

- (void)flatten {
    self.nodes = [self flattenedNodes];
}

- (KTAbstractPath *)pathByFlatteningPath {
    KTPath *flatPath = [[KTPath alloc] init];
    flatPath.nodes = [self flattenedNodes];
    return flatPath;
}

- (NSString *)nodeSVGRepresentation {
    NSArray         *nodes = _reversed ? [self reversedNodes] : _nodes;
    KTBezierNode    *node;
    NSInteger       numNodes = _closed ? nodes.count + 1 : nodes.count;
    CGPoint         pt, prev_pt, in_pt, prev_out;
    NSMutableString *svg = [NSMutableString string];
    
    for(int i = 0; i < numNodes; i++) {
        node = nodes[(i % nodes.count)];
        
        if (i == 0) {
            pt = node.anchorPoint;
            [svg appendString:[NSString stringWithFormat:@"M%g%+g", pt.x, pt.y]];
        } else {
            pt = node.anchorPoint;
            in_pt = node.inPoint;
            
            if (prev_pt.x == prev_out.x && prev_pt.y == prev_out.y && in_pt.x == pt.x && in_pt.y == pt.y) {
                [svg appendString:[NSString stringWithFormat:@"L%g%+g", pt.x, pt.y]];
            } else {
                [svg appendString:[NSString stringWithFormat:@"C%g%+g%+g%+g%+g%+g",
                                   prev_out.x, prev_out.y, in_pt.x, in_pt.y, pt.x, pt.y]];
            }
        }
        
        prev_out = node.outPoint;
        prev_pt = pt;
    }
    
    if (_closed) {
        [svg appendString:@"Z"];
    }
    
    return svg;
}

- (void) addSVGArrowheadPath:(CGPathRef)pathRef toGroup:(KTXMLElement *)group
{
    KTAbstractPath  *inkpadPath = [KTAbstractPath pathWithCGPathRef:pathRef];
    KTStrokeStyle   *stroke = [self effectiveStrokeStyle];
    
    KTXMLElement *arrowPath = [KTXMLElement elementWithName:@"path"];
    [arrowPath setAttribute:@"d" value:[inkpadPath nodeSVGRepresentation]];
    [arrowPath setAttribute:@"fill" value:[stroke.color hexValue]];
    [group addChild:arrowPath];
}

- (void) addSVGArrowheadsToGroup:(KTXMLElement *)group
{
    KTStrokeStyle *stroke = [self effectiveStrokeStyle];
    
    KTArrowhead *arrow = [KTArrowhead arrowheads][stroke.startArrow];
    if (arrow) {
        CGMutablePathRef pathRef = CGPathCreateMutable();
        [arrow addToMutablePath:pathRef position:arrowStartAttachment_ scale:stroke.width angle:arrowStartAngle_
                  useAdjustment:(stroke.cap == kCGLineCapButt)];
        [self addSVGArrowheadPath:pathRef toGroup:group];
        CGPathRelease(pathRef);
    }
    
    arrow = [KTArrowhead arrowheads][stroke.endArrow];
    if (arrow) {
        CGMutablePathRef pathRef = CGPathCreateMutable();
        [arrow addToMutablePath:pathRef position:arrowEndAttachment_ scale:stroke.width angle:arrowEndAngle_
                  useAdjustment:(stroke.cap == kCGLineCapButt)];
        [self addSVGArrowheadPath:pathRef toGroup:group];
        CGPathRelease(pathRef);
    }
}


- (KTStrokeStyle *)effectiveStrokeStyle {
    return self.superpath ? self.superpath.strokeStyle : self.strokeStyle;
}

- (void)renderStrokeInContext:(CGContextRef)ctx {
    KTStrokeStyle *stroke = [self effectiveStrokeStyle];
    
    if (!stroke.hasArrow) {
        [super renderStrokeInContext:ctx];
        return;
    }
    
#ifdef DEBUG_ATTACHMENTS
    // this will show the arrowhead overlapping the stroke if the stroke color is semi-transparent
    [super renderStrokeInContext:ctx];
#else
    // normally we want the stroke and arrowhead to appear unified, even with a semi-transparent stroke color
    CGContextAddPath(ctx, self.strokePath);
    [stroke applyInContext:ctx];
    
    CGContextReplacePathWithStrokedPath(ctx);
#endif
    CGContextSetFillColorWithColor(ctx, stroke.color.CGColor);
    
    KTArrowhead *arrow = [KTArrowhead arrowheads][stroke.startArrow];
    if (canFitStartArrow_ && arrow) {
        [arrow addArrowInContext:ctx position:arrowStartAttachment_ scale:stroke.width angle:arrowStartAngle_
                   useAdjustment:(stroke.cap == kCGLineCapButt)];
    }
    
    arrow = [KTArrowhead arrowheads][stroke.endArrow];
    if (canFitEndArrow_ && arrow) {
        [arrow addArrowInContext:ctx position:arrowEndAttachment_ scale:stroke.width angle:arrowEndAngle_
                   useAdjustment:(stroke.cap == kCGLineCapButt)];
    }
    
    CGContextFillPath(ctx);
}

- (void)addElementsToOutlinedStroke:(CGMutablePathRef)outline {
    KTStrokeStyle   *stroke = [self effectiveStrokeStyle];
    KTArrowhead     *arrow;
    
    if (![stroke hasArrow]) {
        // no arrows...
        return;
    }
    
    if ([stroke hasStartArrow]) {
        arrow = [KTArrowhead arrowheads][stroke.startArrow];
        [arrow addToMutablePath:outline position:arrowStartAttachment_ scale:stroke.width angle:arrowStartAngle_
                  useAdjustment:(stroke.cap == kCGLineCapButt)];
    }
    
    if ([stroke hasEndArrow]) {
        arrow = [KTArrowhead arrowheads][stroke.endArrow];
        [arrow addToMutablePath:outline position:arrowEndAttachment_ scale:stroke.width angle:arrowEndAngle_
                  useAdjustment:(stroke.cap == kCGLineCapButt)];
    }

}


@end
