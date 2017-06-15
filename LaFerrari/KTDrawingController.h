//
//  KTDrawingController.h
//  LaFerrari
//
//  Created by stanshen on 17/6/13.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KTDrawing;
@class KTPath;
@class KTBezierNode;

@interface KTDrawingController : NSObject

@property (nonatomic, strong) KTDrawing *drawing;
@property (nonatomic, readonly) NSMutableSet *selectedObjects;
@property (nonatomic, readonly) NSMutableSet *selectedPaths;
@property (nonatomic, readonly) NSMutableSet *selectedNodes;

@property (nonatomic, strong) KTPath *activePath;
@property (nonatomic, strong) KTBezierNode *tempDisplayNode;


// node selection
- (void)selectNode:(KTBezierNode *)node;
- (void)deselectNode:(KTBezierNode *)node;
- (void)deselectAllNodes;
- (BOOL)isNodeSelected:(KTBezierNode *)node;



@end
