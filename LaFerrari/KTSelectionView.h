//
//  KTSelectionView.h
//  LaFerrari
//
//  Created by stanshen on 17/6/14.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class KTCanvas;
@class KTLayer;

@interface KTSelectionView : NSOpenGLView

@property (nonatomic, strong) KTCanvas *canvas;
@property (nonatomic, strong) KTLayer *activeLayer;

- (void)drawView;

@end
