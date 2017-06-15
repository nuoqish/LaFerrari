//
//  KTBezierNode.h
//  LaFerrari
//
//  Created by stanshen on 17/6/9.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KTPickResult.h"

typedef enum {
    KTBezierNodeReflectionReflect,
    KTBezierNodeReflectionIndependent,
    KTBezierNodeReflectionReflectIndependent
} KTBezierNodeReflectionMode;

typedef enum {
    KTBezierNodeRenderOpen,
    KTBezierNodeRenderClosed,
    KTBezierNodeRenderSelected
} KTBezierNodeRenderMode;

@class KTColor;
@class NSColor;

@interface KTBezierNode : NSObject <NSCoding, NSCopying>

@property (nonatomic, readonly) CGPoint inPoint;
@property (nonatomic, readonly) CGPoint anchorPoint;
@property (nonatomic, readonly) CGPoint outPoint;

@property (nonatomic, readonly) BOOL hasInPoint;
@property (nonatomic, readonly) BOOL hasOutPoint;
@property (nonatomic, readonly) BOOL isCorner;
@property (nonatomic, readonly) KTBezierNodeReflectionMode reflectionMode;
@property (nonatomic, assign) BOOL selected;

+ (KTBezierNode *) bezierNodeWithAnchorPoint:(CGPoint)anchorPoint;
+ (KTBezierNode *) bezierNodeWithInPoint:(CGPoint)inPoint anchorPoint:(CGPoint)anchorPoint outPoint:(CGPoint)outPoint;

- (id) initWithAnchorPoint:(CGPoint)anchorPoint;
- (id) initWithInPoint:(CGPoint)inPoint anchorPoint:(CGPoint)anchorPoint outPoint:(CGPoint)outPoint;

- (KTBezierNode *)flippedNode;
- (KTBezierNode *)chopHandles;
- (KTBezierNode *)chopOutHandle;
- (KTBezierNode *)chopInHandle;
- (KTBezierNode *)transform:(CGAffineTransform)transform;
- (KTBezierNode *)setInPoint:(CGPoint)inPoint reflectionMode:(KTBezierNodeReflectionMode)reflectionMode;
- (KTBezierNode *)moveControlHandle:(KTPickResultType)pointToTransform toPoint:(CGPoint)point reflectionMode:(KTBezierNodeReflectionMode)reflectioinMode;

- (void)getInPoint:(CGPoint *)inPoint anchorPoint:(CGPoint *)anchorPoint outPoint:(CGPoint *)outPoint selected:(BOOL *)selected;

- (void)drawGLWithViewTransform:(CGAffineTransform)transform color:(NSColor *)color mode:(KTBezierNodeRenderMode)renderMode;

@end
