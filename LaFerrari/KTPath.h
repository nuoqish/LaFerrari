//
//  KTPath.h
//  LaFerrari
//
//  Created by stanshen on 17/6/11.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTAbstractPath.h"

#import "KTPickResult.h"

@class KTBezierNode;
@class KTColor;
@class KTFillTransform;
@class KTCompoundPath;

void KTPathApplyAccumulateElement(void *info, const CGPathElement *element);

@interface KTPath : KTAbstractPath <NSCoding, NSCopying>

@property (nonatomic, assign) BOOL closed;
@property (nonatomic, assign) BOOL reversed;
@property (nonatomic, strong) NSMutableArray *nodes;
@property (nonatomic, readonly, weak) NSMutableArray *reversedNodes;
@property (nonatomic, weak) KTCompoundPath *superpath;
@property (nonatomic, strong) NSMutableArray *displayNodes;
@property (nonatomic, strong) KTColor *displayColor;
@property (nonatomic, assign) BOOL displayClosed;

+ (KTPath *)pathWithRect:(CGRect)rect;
+ (KTPath *)pathWithRoundedRect:(CGRect)rect cornerRadius:(float)radius;
+ (KTPath *)pathWithOvalInRect:(CGRect)rect;
+ (KTPath *)pathWithStart:(CGPoint)start end:(CGPoint)end;

- (id)initWithRect:(CGRect)rect;
- (id)initWithRoundedRect:(CGRect)rect cornerRadius:(float)radius;
- (id)initWithOvalInRect:(CGRect)rect;
- (id)initWithStart:(CGPoint)start end:(CGPoint)end;
- (id)initWithNode:(KTBezierNode *)node;

- (void)invalidatePath;
- (void)reversePathDirection;

- (BOOL)canDeleteAnchors;
- (void)deleteAnchor:(KTBezierNode *)node;
- (NSArray *)selectedNodes;
- (BOOL)anyNodesSelected;
- (BOOL)allNodesSelected;

- (NSDictionary *)splitAtNode:(KTBezierNode *)node;
- (NSDictionary *)splitAtPoint:(CGPoint)pt viewScale:(float)viewScale;
- (KTBezierNode *)addAnchorAtPoint:(CGPoint)pt viewScale:(float)viewScale;
- (void)addAnchors;
- (void)appendPath:(KTPath *)path;

- (void)replaceFirstNodeWithNode:(KTBezierNode *)node;
- (void)replaceLastNodeWithNode:(KTBezierNode *)node;
- (BOOL)addNode:(KTBezierNode *)node scale:(float)scale;
- (void)addNode:(KTBezierNode *)node;

- (KTBezierNode *)firstNode;
- (KTBezierNode *)lastNode;
- (NSMutableArray *)reversedNodes;
- (NSSet *)nodesInRect:(CGRect)rect;

- (KTBezierNode *)convertNode:(KTBezierNode *)node whichPoint:(KTPickResultType)whichPoint;

- (CGRect)controlBounds;
- (void)computeBounds;

- (NSString *)nodeSVGRepresentation;

- (void)setClosedQuiet:(BOOL)closed;

- (KTStrokeStyle *)effectiveStrokeStyle;

@end
