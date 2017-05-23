//
//  KTBackgroundPickerView.m
//  MoguMattor
//
//  Created by longyan on 2017/5/11.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#import "KTBackgroundPickerView.h"
#import "KTButton.h"

@interface KTBackgroundPickerView ()

@property (nonatomic, strong) KTButton *clearColorButton;
@property (nonatomic, strong) KTButton *colorPickerButton;
@property (nonatomic, strong) KTButton *imagePickerButton;

@end

@implementation KTBackgroundPickerView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self initSubViews];
        [self layoutSubViews];
    }
    return self;
}

- (void)initSubViews {
    
    self.clearColorButton = [KTButton ktButtonWithImage:[NSImage imageNamed:@"chessboard"] target:self action:@selector(clearColorButtonTapped:)];
    self.colorPickerButton = [KTButton ktButtonWithImage:[NSImage imageNamed:@"color_picker"] target:self action:@selector(colorPickerButtonTapped:)];
    //self.imagePickerButton = [KTButton ktButtonWithImage:[NSImage imageNamed:@"image_icon"] target:self action:@selector(imagePickerButtonTapped:)];
    
    [self addSubview:self.clearColorButton];
    [self addSubview:self.colorPickerButton];
    //[self addSubview:self.imagePickerButton];
    
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    //[super resizeSubviewsWithOldSize:oldSize];
    [self layoutSubViews];
}

- (void)setNeedsLayout:(BOOL)needsLayout {
    [super setNeedsLayout:needsLayout];
    if (needsLayout) {
        [self layoutSubViews];
    }
}

- (void)layoutSubViews {
    self.frame = NSMakeRect(0, 0, 50, 20);
    self.clearColorButton.frame = NSMakeRect(0, 0, 20, 20);
    self.colorPickerButton.frame = NSMakeRect(30, 0, 20, 20);
    //self.imagePickerButton.frame = NSMakeRect(60, 0, 20, 20);
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    [[NSColor colorWithWhite:0.4 alpha:0.5] set];
    NSRectFillUsingOperation(dirtyRect, NSCompositeSourceOver);
    
}


#pragma mark - button actions

- (void)clearColorButtonTapped:(id)sender {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(backgroundPickerView:didSelectBackgroundColor:)]) {
        [self.delegate backgroundPickerView:self didSelectBackgroundColor:nil];
    }
    
}

- (void)colorPickerButtonTapped:(id)sender {
    NSColorPanel *colorPanel = [NSColorPanel sharedColorPanel];
    colorPanel.mode = NSWheelModeColorPanel;
    [colorPanel setTarget:self];
    [colorPanel setAction:@selector(colorUpdate:)];
    [colorPanel orderFrontRegardless];
}


- (void)colorUpdate:(NSColorPanel *)colorPanel {
    NSColor *theColor = colorPanel.color;
    if (self.delegate && [self.delegate respondsToSelector:@selector(backgroundPickerView:didSelectBackgroundColor:)]) {
        [self.delegate backgroundPickerView:self didSelectBackgroundColor:theColor];
    }
    
}

- (void)imagePickerButtonTapped:(id)sender {
    
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.allowsMultipleSelection = NO;
    NSInteger modalType = [openPanel runModal];
    if (modalType == NSFileHandlingPanelOKButton) {
        NSArray<NSURL *> *fileUrls = [openPanel URLs];
        NSURL *imageUrl = fileUrls[0];
        NSImage *bckImage = [[NSImage alloc] initWithContentsOfURL:imageUrl];
        if (self.delegate && [self.delegate respondsToSelector:@selector(backgroundPickerView:didSelectBackgroundColor:)]) {
            [self.delegate backgroundPickerView:self didSelectBackgroundImage:bckImage];
        }
        
    }
    
    
}



@end
