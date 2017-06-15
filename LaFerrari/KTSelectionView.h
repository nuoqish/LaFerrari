//
//  KTSelectionView.h
//  LaFerrari
//
//  Created by stanshen on 17/6/14.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class KTCanvas;
@class KTDrawing;

@interface KTSelectionView : NSOpenGLView

@property (nonatomic, weak) KTCanvas *canvas;
@property (nonatomic, weak, readonly) KTDrawing *drawing;

- (void)drawView;

@end
