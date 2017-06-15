//
//  KTCanvas.h
//  LaFerrari
//
//  Created by stanshen on 17/6/14.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class KTDrawing;
@class KTDrawingController;
@class KTPath;

@interface KTCanvas : NSView


@property (nonatomic, readonly) CGAffineTransform canvasTransform;
@property (nonatomic, readonly) CGAffineTransform selectionTransform;

@property (nonatomic, readonly, weak) KTDrawingController *drawingController;
@property (nonatomic, readonly, weak) KTDrawing *drawing;

@property (nonatomic, strong) KTPath *shapeUnderConstruction;

@property (nonatomic, readonly) BOOL isZooming;
@property (nonatomic, assign) BOOL isTransforming;
@property (nonatomic, assign) BOOL isTransformingNode;



@end
