//
//  KTCropView.m
//  MoguMattor
//
//  Created by longyan on 2017/4/28.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#import "KTCropView.h"

#import "KTButton.h"

@interface KTCropControlPointView : NSImageView

@end

@implementation KTCropControlPointView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        self.image = [NSImage imageNamed:@"blue_dot"];
        self.imageScaling = NSImageScaleProportionallyDown;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    //CGContextRef contextRef = [[NSGraphicsContext currentContext] graphicsPort];
    //CGContextClearRect(contextRef, dirtyRect);
    //CGContextSetRGBFillColor(contextRef, 18. / 255., 173. / 255., 251. / 255., 1.);
    //CGContextFillEllipseInRect(contextRef, dirtyRect);
}

@end


@interface KTCropView ()

@property(nonatomic, assign) CGPoint topLeftControlPoint;
@property(nonatomic, assign) CGPoint topRightControlPoint;
@property(nonatomic, assign) CGPoint bottomLeftControlPoint;
@property(nonatomic, assign) CGPoint bottomRightControlPoint;

@property(nonatomic, strong) KTCropControlPointView *topLeftPointView;
@property(nonatomic, strong) KTCropControlPointView *topRightPointView;
@property(nonatomic, strong) KTCropControlPointView *bottomLeftPointView;
@property(nonatomic, strong) KTCropControlPointView *bottomRightPointView;

@property(nonatomic, weak) KTCropControlPointView *dragView;
@property(nonatomic, strong) KTButton *confirmButton;
@property(nonatomic, strong) KTButton *closeButton;


@end


@implementation KTCropView


- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    
    if (self) {
        self.controlPointSize = 16;
        self.minControlPointDistance = 40;
        
        [self initSubViews];
    }
    
    return self;
}

- (void)initSubViews {
    self.autoresizesSubviews = YES;
    
    CGFloat initialCropAreaSize = 0.2;
    CGPoint centerPointInView = CGPointMake(0.5, 0.5);
    
    self.cropRect = CGRectMake(centerPointInView.x - initialCropAreaSize, centerPointInView.y - initialCropAreaSize, 2 * initialCropAreaSize, 2 * initialCropAreaSize);
    
    self.topLeftPointView = [KTCropControlPointView new];
    self.bottomLeftPointView = [KTCropControlPointView new];
    self.topRightPointView = [KTCropControlPointView new];
    self.bottomRightPointView = [KTCropControlPointView new];
    self.confirmButton = [KTButton ktButtonWithImage:[NSImage imageNamed:@"check_green"] target:self action:@selector(confirmButtonClicked:)];
    self.closeButton = [KTButton ktButtonWithImage:[NSImage imageNamed:@"close_black"] target:self action:@selector(closeButtonClicked:)];
    
    [self addSubview:self.topLeftPointView];
    [self addSubview:self.topRightPointView];
    [self addSubview:self.bottomLeftPointView];
    [self addSubview:self.bottomRightPointView];
    [self addSubview:self.confirmButton];
    [self addSubview:self.closeButton];
    
    NSPanGestureRecognizer *dragRecognizer = [[NSPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDrag:)];
    [self addGestureRecognizer:dragRecognizer];
    
}


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    CGContextRef contextRef = [[NSGraphicsContext currentContext] graphicsPort];
    CGRect cropRect = CGRectMake(self.bottomLeftControlPoint.x * self.frame.size.width, self.bottomLeftControlPoint.y * self.frame.size.height,
                                 fabs(self.topRightControlPoint.x - self.topLeftControlPoint.x) * self.frame.size.width,
                                 fabs(self.bottomLeftControlPoint.y - self.topLeftControlPoint.y) * self.frame.size.height);
    

    CGContextAddRect(contextRef, cropRect);
    CGContextAddRect(contextRef, dirtyRect);
    CGContextEOClip(contextRef);
    CGContextSetRGBFillColor(contextRef, 0., 0., 0., 0.4);
    CGContextFillRect(contextRef, dirtyRect);
    
    CGContextSetRGBStrokeColor(contextRef, 18. / 255., 173. / 255., 251. / 255., 0.7);
    CGContextSetLineWidth(contextRef, 1.0);
    CGContextBeginPath(contextRef);
    CGContextAddRect(contextRef, cropRect);
    CGContextDrawPath(contextRef, kCGPathStroke);
    
}

- (void)setNeedsLayout:(BOOL)needsLayout {
    [super setNeedsLayout:needsLayout];
    if (needsLayout) {
        [self layoutSubViews];
    }
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    //[super resizeSubviewsWithOldSize:oldSize];
    [self layoutSubViews];
}

- (void)layoutSubViews {
    CGFloat frameWidth = self.frame.size.width;
    CGFloat frameHeight = self.frame.size.height;
    self.topLeftPointView.frame = NSMakeRect(self.topLeftControlPoint.x * frameWidth - self.controlPointSize / 2, self.topLeftControlPoint.y * frameHeight - self.controlPointSize / 2, self.controlPointSize, self.controlPointSize);
    self.topRightPointView.frame = NSMakeRect(self.topRightControlPoint.x * frameWidth - self.controlPointSize / 2, self.topRightControlPoint.y * frameHeight - self.controlPointSize / 2, self.controlPointSize, self.controlPointSize);
    self.bottomLeftPointView.frame = NSMakeRect(self.bottomLeftControlPoint.x * frameWidth - self.controlPointSize / 2, self.bottomLeftControlPoint.y * frameHeight - self.controlPointSize / 2, self.controlPointSize, self.controlPointSize);
    self.bottomRightPointView.frame = NSMakeRect(self.bottomRightControlPoint.x * frameWidth - self.controlPointSize / 2, self.bottomRightControlPoint.y * frameHeight - self.controlPointSize / 2, self.controlPointSize, self.controlPointSize);
    if (self.bottomRightControlPoint.y * frameHeight >= 20) {
        self.confirmButton.frame = NSMakeRect(self.bottomRightControlPoint.x * frameWidth - 35, self.bottomRightControlPoint.y * frameHeight - 20, 20, 20);
        self.closeButton.frame = NSMakeRect(self.bottomRightControlPoint.x * frameWidth - 60, self.bottomRightControlPoint.y * frameHeight - 20, 20, 20);
    }
    else {
        self.confirmButton.frame = NSMakeRect(self.bottomRightControlPoint.x * frameWidth - 35, self.bottomRightControlPoint.y * frameHeight, 20, 20);
        self.closeButton.frame = NSMakeRect(self.bottomRightControlPoint.x * frameWidth - 60, self.bottomRightControlPoint.y * frameHeight, 20, 20);
    }
    
}

- (void)showCloseButton:(BOOL)isShow {
    self.closeButton.hidden = !isShow;
}

- (void)handleDrag:(NSPanGestureRecognizer *)dragRecognizer {
    
    NSPoint location = [dragRecognizer locationInView:self];
    
    if (dragRecognizer.state == NSGestureRecognizerStateBegan) {
        if ([self.topLeftPointView mouse:location inRect:self.topLeftPointView.frame]) {
            self.dragView = self.topLeftPointView;
        }
        else if ([self.topRightPointView mouse:location inRect:self.topRightPointView.frame]) {
            self.dragView = self.topRightPointView;
        }
        else if ([self.bottomLeftPointView mouse:location inRect:self.bottomLeftPointView.frame]) {
            self.dragView = self.bottomLeftPointView;
        }
        else if ([self.bottomRightPointView mouse:location inRect:self.bottomRightPointView.frame]) {
            self.dragView = self.bottomRightPointView;
            
        }
    }
    else if (dragRecognizer.state == NSGestureRecognizerStateEnded) {
        self.dragView = nil;
        return;
    }
    
    if (location.x < self.controlPointSize / 2 || location.x > (self.frame.size.width - self.controlPointSize / 2) ||
        location.y < self.controlPointSize / 2 || location.y > (self.frame.size.height - self.controlPointSize / 2)) {
        return;
    }
    
    location.x /= self.frame.size.width;
    location.y /= self.frame.size.height;
    
    if (self.dragView == self.topLeftPointView) {
        if (
            (self.topRightControlPoint.x - location.x) * self.frame.size.width > self.minControlPointDistance &&
            (location.y - self.bottomLeftControlPoint.y) * self.frame.size.height > self.minControlPointDistance) {
            self.topLeftControlPoint = location;
            self.topRightControlPoint = CGPointMake(self.topRightControlPoint.x, location.y);
            self.bottomLeftControlPoint = CGPointMake(location.x, self.bottomLeftControlPoint.y);
            [self setNeedsDisplay:YES];
            [self setNeedsLayout:YES];
        }
        
    }
    else if (self.dragView == self.topRightPointView) {
        if ((location.x - self.topLeftControlPoint.x) * self.frame.size.width > self.minControlPointDistance &&
            (location.y - self.bottomRightControlPoint.y) * self.frame.size.height > self.minControlPointDistance) {
            self.topRightControlPoint = location;
            self.topLeftControlPoint = CGPointMake(self.topLeftControlPoint.x, location.y);
            self.bottomRightControlPoint = CGPointMake(location.x, self.bottomRightControlPoint.y);
            [self setNeedsDisplay:YES];
            [self setNeedsLayout:YES];
        }
        
    }
    else if (self.dragView == self.bottomLeftPointView) {
        if ((self.bottomRightControlPoint.x - location.x) * self.frame.size.width > self.minControlPointDistance &&
            (self.topLeftControlPoint.y - location.y) * self.frame.size.height > self.minControlPointDistance) {
            self.bottomLeftControlPoint = location;
            self.bottomRightControlPoint = CGPointMake(self.bottomRightControlPoint.x, location.y);
            self.topLeftControlPoint = CGPointMake(location.x, self.topLeftControlPoint.y);
            [self setNeedsDisplay:YES];
            [self setNeedsLayout:YES];
        }
    }
    else if (self.dragView == self.bottomRightPointView) {
        if ((location.x - self.bottomLeftControlPoint.x) * self.frame.size.width > self.minControlPointDistance &&
            (self.topRightControlPoint.y - location.y) * self.frame.size.height > self.minControlPointDistance) {
            self.bottomRightControlPoint = location;
            self.bottomLeftControlPoint = CGPointMake(self.bottomLeftControlPoint.x, location.y);
            self.topRightControlPoint = CGPointMake(location.x, self.topRightControlPoint.y);
            [self setNeedsDisplay:YES];
            [self setNeedsLayout:YES];
        }
    }
    
}

- (void)confirmButtonClicked:(id)sender {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(confirmButtonTappedForCropView:)]) {
        [self.delegate confirmButtonTappedForCropView:self];
    }
}

- (void)closeButtonClicked:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(closeButtonTappedForCropView:)]) {
        [self.delegate closeButtonTappedForCropView:self];
    }
}

- (void)setCropRect:(CGRect)cropRect {
    
    self.topLeftControlPoint = CGPointMake(cropRect.origin.x, cropRect.origin.y + cropRect.size.height);
    self.topRightControlPoint = CGPointMake(cropRect.origin.x + cropRect.size.width, cropRect.origin.y + cropRect.size.height);
    self.bottomLeftControlPoint = CGPointMake(cropRect.origin.x, cropRect.origin.y);
    self.bottomRightControlPoint = CGPointMake(cropRect.origin.x + cropRect.size.width, cropRect.origin.y);
    
    [self setNeedsLayout:YES];
    [self setNeedsDisplay:YES];
}

- (CGRect)cropRect {
    return CGRectMake(self.bottomLeftControlPoint.x, self.bottomLeftControlPoint.y,
                      self.bottomRightControlPoint.x - self.bottomLeftControlPoint.x,
                      self.topLeftControlPoint.y - self.bottomLeftControlPoint.y);
}


@end


