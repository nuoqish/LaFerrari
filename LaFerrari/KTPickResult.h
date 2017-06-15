//
//  KTPickResult.h
//  LaFerrari
//
//  Created by stanshen on 17/6/9.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    KTSnapNodes            = 1 << 0,
    KTSnapEdges            = 1 << 1,
    KTSnapGrid             = 1 << 2,
    KTSnapFills            = 1 << 3,
    KTSnapLocked           = 1 << 4,
    KTSnapSelectedOnly     = 1 << 5,
    KTSnapSubelement       = 1 << 6,
    KTSnapDynamicGuides    = 1 << 7
} KTSnapType;

typedef enum {
    KTEther,
    KTInPoint,
    KTAnchorPoint,
    KTOutPoint,
    KTObjectFill,
    KTEdge,
    KTLeftTextKnob,
    KTRightTextKnob,
    KTFillStartPoint,
    KTFillEndPoint,
    KTRectCorner,
    KTRectEdge,
    KTTextPathStartKnob
} KTPickResultType;

typedef enum {
    KTMiddleNode,
    KTFirstNode,
    KTLastNode
} KTNodeType;

@class KTElement;
@class KTBezierNode;

@interface KTPickResult : NSObject

@property (nonatomic, weak) KTElement *element;         // the element in which the tap occurred
@property (nonatomic, weak) KTBezierNode *node;         // the node hit by the tap -- could be nil
@property (nonatomic, assign) CGPoint snappedPoint;
@property (nonatomic, assign) KTPickResultType type;
@property (nonatomic, assign) NSUInteger nodePosition;
@property (nonatomic, readonly) BOOL snapped;

+ (KTPickResult *) pickResult;

@end
