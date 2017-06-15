//
//  KTCanvas.m
//  LaFerrari
//
//  Created by stanshen on 17/6/14.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTCanvas.h"

#import "KTSelectionView.h"

@interface KTCanvas ()

@property (nonatomic, strong) KTSelectionView *selectionView;

@end

@implementation KTCanvas

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (!self) {
        return nil;
    }
    
    _selectionView = [[KTSelectionView alloc] initWithFrame:frameRect];
    _selectionView.canvas = self;
    [self addSubview:_selectionView];
    
    _canvasTransform = CGAffineTransformIdentity;
    _selectionTransform = CGAffineTransformIdentity;
    
    
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)mouseDown:(NSEvent *)theEvent {
    
}

- (void)mouseDragged:(NSEvent *)theEvent {
    
}

- (void)mouseUp:(NSEvent *)theEvent {
    
}










@end
