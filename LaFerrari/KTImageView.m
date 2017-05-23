//
//  KTImageView.m
//  MoguMattor
//
//  Created by longyan on 2017/5/10.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#import "KTImageView.h"

@interface KTImageView ()

@property (nonatomic, strong) NSImageView *imageView;

@end


@implementation KTImageView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        self.hasHorizontalScroller = YES;
        self.hasVerticalScroller = YES;
        self.borderType = NSNoBorder;
        //self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        self.drawsBackground = NO;
        self.minMagnification = 0.1;
        self.maxMagnification = 10;
        self.magnification = 1.0;
        self.imageView = [[NSImageView alloc] initWithFrame:self.bounds];
        self.imageView.imageScaling = NSImageScaleProportionallyUpOrDown;
        self.documentView = self.imageView;
        self.maxFrameSize = frameRect.size;
        self.bkColor = nil;
    }
    return self;
}


- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    [super resizeSubviewsWithOldSize:oldSize];
    [self layoutSubViews];
}

- (void)setNeedsLayout:(BOOL)needsLayout {
    [super setNeedsLayout:needsLayout];
    if (needsLayout) {
        [self layoutSubViews];
    }
}


- (void)layoutSubViews {
    
    if (!_image || _maxFrameSize.height == 0.) {
        return;
    }
    
    CGFloat viewRatio = self.maxFrameSize.width / self.maxFrameSize.height;
    CGFloat imageRatio = self.image.size.width / self.image.size.height;
    CGFloat resizeImageWidth, resizeImageHeight;
    if (imageRatio > viewRatio) {
        resizeImageWidth = self.maxFrameSize.width;
        resizeImageHeight = resizeImageWidth / imageRatio;
    }
    else {
        resizeImageHeight = self.maxFrameSize.height;
        resizeImageWidth = resizeImageHeight * imageRatio;
    }
    self.imageView.frame = NSMakeRect(0, 0, resizeImageWidth, resizeImageHeight);
    
}

// https://developer.apple.com/library/content/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_patterns/dq_patterns.html#//apple_ref/doc/uid/TP30001066-CH206-BBCGHGAG
#define H_PATTERN_SIZE 20
#define V_PATTERN_SIZE 20
void MyDrawColoredPattern (void *info, CGContextRef myContext)
{
    CGFloat subunit = 10; // the pattern cell itself is H_PATTERN_SIZE x V_PATTERN_SIZE, with 4 rect area
    
    CGRect  myRect1 = {{0,0}, {subunit, subunit}},
    myRect2 = {{subunit, subunit}, {subunit, subunit}},
    myRect3 = {{0,subunit}, {subunit, subunit}},
    myRect4 = {{subunit,0}, {subunit, subunit}};
    
    CGContextSetRGBFillColor (myContext, 1, 1, 1, 0.5);
    CGContextFillRect (myContext, myRect1);
    CGContextSetRGBFillColor (myContext, 1, 1, 1, 0.5);
    CGContextFillRect (myContext, myRect2);
    CGContextSetRGBFillColor (myContext, 0.5, 0.5, 0.5, 0.5);
    CGContextFillRect (myContext, myRect3);
    CGContextSetRGBFillColor (myContext, 0.5, 0.5, 0.5, 0.5);
    CGContextFillRect (myContext, myRect4);
}

- (void)drawMaskPatternWithContext:(CGContextRef)myContext andRect:(NSRect)rect {
    CGPatternRef    pattern;
    CGColorSpaceRef patternSpace;
    CGFloat         alpha = 1;
    static const    CGPatternCallbacks callbacks = {0, &MyDrawColoredPattern, NULL};
    
    CGContextSaveGState (myContext);
    patternSpace = CGColorSpaceCreatePattern (NULL);
    CGContextSetFillColorSpace (myContext, patternSpace);
    CGColorSpaceRelease (patternSpace);
    
    pattern = CGPatternCreate (NULL,
                               CGRectMake (0, 0, H_PATTERN_SIZE, V_PATTERN_SIZE),
                               CGAffineTransformMake (1, 0, 0, 1, 0, 0),
                               H_PATTERN_SIZE,
                               V_PATTERN_SIZE,
                               kCGPatternTilingConstantSpacing,
                               true,
                               &callbacks);
    
    CGContextSetFillPattern (myContext, pattern, &alpha);
    CGPatternRelease (pattern);
    CGContextFillRect (myContext, rect);
    CGContextRestoreGState (myContext);
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    
    if (self.bkColor) {
        [self.bkColor set];// 设置背景
        NSRectFill(dirtyRect);
        
    }
    else {
        
        CGContextRef myContext = [[NSGraphicsContext currentContext] graphicsPort];
        [self drawMaskPatternWithContext:myContext andRect:dirtyRect];
        
        
    }
    
    
}


- (void)setMaxFrameSize:(CGSize)maxFrameSize {
    _maxFrameSize = maxFrameSize;
    [self setNeedsLayout:YES];
}

- (void)setImage:(NSImage *)image {
    _image = image;
    self.imageView.image = image;
    
    [self setNeedsLayout:YES];
}

- (void)addCustomView:(NSView *)customView {
    [self.imageView addSubview:customView];
}

- (CGRect)imageFrame {
    return self.imageView.bounds;
}

@end
