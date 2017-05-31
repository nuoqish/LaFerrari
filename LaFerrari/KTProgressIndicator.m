//
//  KTProgressIndicator.m
//  LaFerrari
//
//  Created by stanshen on 17/5/27.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTProgressIndicator.h"

@interface KTProgressIndicator ()

@property (nonatomic, strong) NSProgressIndicator *smallProgressIndicator;
@property (nonatomic, strong) NSTextField *hintLabel;

@end

@implementation KTProgressIndicator

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self initSubViews];
    }
    return self;
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    [super resizeSubviewsWithOldSize:oldSize];
    [self layoutSubViews];
}

- (void)initSubViews {
    
    
    self.hintLabel = [[NSTextField alloc] init];
    [self addSubview:self.hintLabel];
    self.hintLabel.stringValue = @"      请稍等，正在进行抠图处理";
    self.hintLabel.font = [NSFont boldSystemFontOfSize:13.];
    self.hintLabel.textColor = [NSColor colorWithWhite:1. alpha:1.];//[NSColor colorWithRed:183 / 255. green:39. / 255. blue:18. / 250. alpha:0.8];
    self.hintLabel.editable = NO;
    self.hintLabel.backgroundColor = [NSColor colorWithRed:183 / 255. green:39. / 255. blue:18. / 250. alpha:1.];//[NSColor textBackgroundColor];
    self.hintLabel.bordered = NO;
    self.hintLabel.hidden = YES;
    
    self.smallProgressIndicator = [[NSProgressIndicator alloc] init];
    [self.hintLabel addSubview:self.smallProgressIndicator];
    self.smallProgressIndicator.style = NSProgressIndicatorSpinningStyle;
    self.smallProgressIndicator.displayedWhenStopped = NO;
}

- (void)layoutSubViews {
    
    self.smallProgressIndicator.frame = NSMakeRect(0, 0, 20, 20);
    self.hintLabel.frame = NSMakeRect(0, 0, self.bounds.size.width, 20);
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    
    //[[NSColor clearColor] set];
    //NSRectFill(dirtyRect);
    
    //CGContextRef contextRef = [[NSGraphicsContext currentContext] graphicsPort];
    //CGContextSetGrayFillColor(contextRef, 0.2, 0.5);
    //CGContextFillRect(contextRef, dirtyRect);
    
}

- (void)startAnimation:(id)sender withHintText:(NSString *)hintText{
    [self setHintText:hintText];
    self.hintLabel.hidden = NO;
    [self.smallProgressIndicator startAnimation:sender];
}

- (void)stopAnimation:(id)sender{
    self.hintLabel.hidden = YES;
    [self.smallProgressIndicator stopAnimation:sender];
}

- (void)setHintText:(NSString *)hintText {
    self.hintLabel.stringValue = [@"      " stringByAppendingString:hintText];
}

@end
