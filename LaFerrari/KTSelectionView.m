//
//  KTSelectionView.m
//  LaFerrari
//
//  Created by stanshen on 17/6/14.
//  Copyright © 2017年 stanshen. All rights reserved.
//
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import "KTSelectionView.h"

#import "KTElement.h"
#import "KTDrawing.h"
#import "KTDrawingController.h"
#import "KTCanvas.h"

@implementation KTSelectionView {
    // pixel dimension of the backbuffer
    GLint backingWidth, backingHeight;
    // opengl renderbuffer and framebuffer used to render to this view
    GLuint colorRenderbuffer, defaultFramebuffer;
}

- (instancetype)init {
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    NSOpenGLPixelFormatAttribute attrs[] = {
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFADepthSize, 24,
        NSOpenGLPFAOpenGLProfile,
        NSOpenGLProfileVersion3_2Core,
        0
    };
    
    NSOpenGLPixelFormat *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
    if (!pixelFormat) {
        NSLog(@"No OpenGL pixel format");
    }
    
    NSOpenGLContext *context = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:nil];
    // When we're using a CoreProfile context, crash if we call a legacy OpenGL function
    // This will make it much more obvious where and when such a function call is made so
    // that we can remove such calls.
    // Without this we'd simply get GL_INVALID_OPERATION error for calling legacy functions
    // but it would be more difficult to see where that function was called.
    CGLEnable([context CGLContextObj], kCGLCECrashOnRemovedFunctions);
    [self setPixelFormat:pixelFormat];
    [self setOpenGLContext:context];
    [self setWantsBestResolutionOpenGLSurface:YES];

    // Create system framebuffer object
    glGenFramebuffers(1, &defaultFramebuffer);
    glGenRenderbuffers(1, &colorRenderbuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    
    glClearColor(0, 0, 0, 0);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnableClientState(GL_VERTEX_ARRAY);
    
    return self;
}

- (void)prepareOpenGL {
    [super prepareOpenGL];
    // The reshape function may have changed the thread to which our OpenGL
    // context is attached before prepareOpenGL and initGL are called.  So call
    // makeCurrentContext to ensure that our OpenGL context current to this
    // thread (i.e. makeCurrentContext directs all OpenGL calls on this thread
    // to [self openGLContext])
    [[self openGLContext] makeCurrentContext];
    
    // Synchroize buffer swaps with vertical refresh rate
    GLint swapInt = 1;
    [[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
}

- (void)reshape {
    [super reshape];
    // We draw on a secondary thread through the display link. However, when
    // resizing the view, -drawRect is called on the main thread.
    // Add a mutex around to avoid the threads accessing the context
    // simultaneously when resizing.
    CGLLockContext([[self openGLContext] CGLContextObj]);
    
    // Get the view size in Points
    NSRect viewRectPoints = [self bounds];
    
    // Rendering at retina resolutions will reduce aliasing, but at the potential
    // cost of framerate and battery life due to the GPU needing to render more
    // pixels.
    
    // Any calculations the renderer does which use pixel dimentions, must be
    // in "retina" space.  [NSView convertRectToBacking] converts point sizes
    // to pixel sizes.  Thus the renderer gets the size in pixels, not points,
    // so that it can set it's viewport and perform and other pixel based
    // calculations appropriately.
    // viewRectPixels will be larger than viewRectPoints for retina displays.
    // viewRectPixels will be the same as viewRectPoints for non-retina displays
    NSRect viewRectPixels = [self convertRectToBacking:viewRectPoints];
    
    backingWidth = (GLint)viewRectPixels.size.width;
    backingHeight = (GLint)viewRectPixels.size.height;
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, backingWidth, backingHeight);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
    glViewport(0, 0, backingWidth, backingHeight);
    
    CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    [self drawView];
}

- (void)drawView {
    [[self openGLContext] makeCurrentContext];
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    glOrtho(0, backingWidth, 0, backingHeight, -1, 1); //?
    glClear(GL_COLOR_BUFFER_BIT);
    
    // draw the selection highlights
    CGAffineTransform flip = CGAffineTransformMakeTranslation(0, self.bounds.size.height);
    flip = CGAffineTransformScale(flip, 1.0, -1.0);
    CGAffineTransform effective = _canvas.canvasTransform;
    effective = CGAffineTransformConcat(effective, flip);
    
    KTDrawingController *drawController = _canvas.drawingController;
    for (KTElement *element in drawController.selectedObjects) {
        [element drawOpenGLHighlightWithTransform:_canvas.selectionTransform viewTransform:effective];
        [element drawOpenGLHandlesWithTransform:_canvas.selectionTransform viewTransform:effective];
    }
    
}

@end
