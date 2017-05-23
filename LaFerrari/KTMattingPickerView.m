//
//  KTMattingPickerView.m
//  LaFerrari
//
//  Created by longyan on 2017/5/19.
//  Copyright © 2017年 longyan. All rights reserved.
//

#import "KTMattingPickerView.h"

@interface KTMattingPickerView ()

@property (nonatomic, strong) NSSegmentedControl *mattingModeControl;
@property (nonatomic, strong) NSSegmentedControl *markerTypeControl;
@property (nonatomic, strong) NSSegmentedControl *displayModeControl;
@property (nonatomic, strong) NSSlider *radiusSlider;



@end

@implementation KTMattingPickerView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self initSubViews];
        [self layoutSubViews];
        
        self.mattingMode = SelectModeForegroundTarget;
        self.previewMode = DisplayModeForeground;
        self.sliderValue = 5;
    }
    return self;
}

- (void)layout {
    [super layout];
    [self layoutSubViews];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    
    //[[NSColor colorWithWhite:0.2 alpha:0.5] set];
    [[NSColor lightGrayColor] set];
    NSRectFill(dirtyRect);
    
}

- (void) initSubViews {
    
    [self addSubview:self.mattingModeControl];
    [self addSubview:self.markerTypeControl];
    [self addSubview:self.displayModeControl];
    [self addSubview:self.radiusSlider];
    
}

- (void) layoutSubViews {
    self.mattingModeControl.frame = NSMakeRect(10, 0, 150, 30);
    self.markerTypeControl.frame = NSMakeRect(160, 0, 220, 30);
    self.radiusSlider.frame = NSMakeRect(400, 0, 100, 30);
    self.displayModeControl.frame = NSMakeRect(510, 0, 220, 30);
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

- (NSSegmentedControl *)mattingModeControl {
    if (!_mattingModeControl) {
        _mattingModeControl = [[NSSegmentedControl alloc] init];
        _mattingModeControl.segmentCount = 2;
        
        [_mattingModeControl setLabel:@"框选" forSegment:0];
        [_mattingModeControl setImage:[NSImage imageNamed:@"targetButton"] forSegment:0];
        [_mattingModeControl setImageScaling:NSImageScaleProportionallyDown forSegment:0];
        [_mattingModeControl setWidth:70 forSegment:0];
        
        [_mattingModeControl setLabel:@"精修" forSegment:1];
        [_mattingModeControl setImage:[NSImage imageNamed:@"fineTuningButton"] forSegment:1];
        [_mattingModeControl setImageScaling:NSImageScaleProportionallyDown forSegment:1];
        [_mattingModeControl setWidth:70 forSegment:1];
        
        [_mattingModeControl setTarget:self];
        [_mattingModeControl setAction:@selector(updateMattingMode:)];
    }
    return _mattingModeControl;
}

- (NSSegmentedControl *)markerTypeControl {
    if (!_markerTypeControl) {
        _markerTypeControl = [[NSSegmentedControl alloc] init];
        _markerTypeControl.segmentCount = 3;
        
        [_markerTypeControl setLabel:@"前景" forSegment:0];
        [_markerTypeControl setImage:[NSImage imageNamed:@"plusIcon"] forSegment:0];
        [_markerTypeControl setImageScaling:NSImageScaleProportionallyDown forSegment:0];
        [_markerTypeControl setWidth:70 forSegment:0];
        
        [_markerTypeControl setLabel:@"背景" forSegment:1];
        [_markerTypeControl setImage:[NSImage imageNamed:@"minusIcon"] forSegment:1];
        [_markerTypeControl setImageScaling:NSImageScaleProportionallyDown forSegment:1];
        [_markerTypeControl setWidth:70 forSegment:1];
        
        [_markerTypeControl setLabel:@"待定" forSegment:2];
        [_markerTypeControl setImage:[NSImage imageNamed:@"eraserIcon"] forSegment:2];
        [_markerTypeControl setImageScaling:NSImageScaleProportionallyDown forSegment:2];
        [_markerTypeControl setWidth:70 forSegment:2];
        
        [_markerTypeControl setTarget:self];
        [_markerTypeControl setAction:@selector(updateMattingMode:)];
    }
    return _markerTypeControl;
}

- (NSSegmentedControl *)displayModeControl {
    if (!_displayModeControl) {
        _displayModeControl = [[NSSegmentedControl alloc] init];
        _displayModeControl.segmentCount = 4;
        
        [_displayModeControl setLabel:@"编辑" forSegment:0];
        //[_displayModeControl setImage:[NSImage imageNamed:@"plusIcon"] forSegment:0];
        //[_displayModeControl setImageScaling:NSImageScaleProportionallyDown forSegment:0];
        [_displayModeControl setWidth:50 forSegment:0];
        
        [_displayModeControl setLabel:@"原图" forSegment:1];
        //[_displayModeControl setImage:[NSImage imageNamed:@"minusIcon"] forSegment:1];
        //[_displayModeControl setImageScaling:NSImageScaleProportionallyDown forSegment:1];
        [_displayModeControl setWidth:50 forSegment:1];
        
        [_displayModeControl setLabel:@"分割图" forSegment:2];
        //[_displayModeControl setImage:[NSImage imageNamed:@"eraserIcon"] forSegment:2];
        //[_displayModeControl setImageScaling:NSImageScaleProportionallyDown forSegment:2];
        [_displayModeControl setWidth:50 forSegment:2];
        
        [_displayModeControl setLabel:@"前景图" forSegment:3];
        //[_displayModeControl setImage:[NSImage imageNamed:@"eraserIcon"] forSegment:3];
        //[_displayModeControl setImageScaling:NSImageScaleProportionallyDown forSegment:3];
        [_displayModeControl setWidth:50 forSegment:3];

        
        [_displayModeControl setTarget:self];
        [_displayModeControl setAction:@selector(updatePreviewMode:)];
    }
    return _displayModeControl;
}

- (NSSlider *)radiusSlider {
    if (!_radiusSlider) {
        _radiusSlider = [[NSSlider alloc] init];
        _radiusSlider.maxValue = 20;
        _radiusSlider.minValue = 1;
        _radiusSlider.doubleValue = 10;
        _radiusSlider.target = self;
        _radiusSlider.action = @selector(sliderValueChanged:);
    }
    return _radiusSlider;
}

- (void)updateMattingMode:(id *)sender {
    
    NSInteger mattingModeIndex = self.mattingModeControl.selectedSegment;
    NSInteger markerTypeIndex = self.markerTypeControl.selectedSegment;
    
    if (mattingModeIndex == 0) {
        if (markerTypeIndex == 0) {
            _mattingMode = SelectModeForegroundTarget;
        }
        else if (markerTypeIndex == 1) {
            _mattingMode = SelectModeBackgroundTarget;
        }
        else {
            _mattingMode = SelectModeUnknownAreaTarget;
        }
    }
    else if (mattingModeIndex == 1) {
        if (markerTypeIndex == 0) {
            _mattingMode = SelectModeForegroundFineTuning;
        }
        else if (markerTypeIndex == 1) {
            _mattingMode = SelectModeBackgroundFineTuning;
        }
        else {
            _mattingMode = SelectModeUnknownAreaFineTuning;
        }
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(mattingPickerView:didSelectMattingMode:)]) {
        [self.delegate mattingPickerView:self didSelectMattingMode:self.mattingMode];
    }
}

- (void)updatePreviewMode:(DisplayMode)displayMode {
    NSInteger previewIndex = self.displayModeControl.selectedSegment;
    if (previewIndex == 0) {
        _previewMode = DisplayModeEditImage;
    }
    else if (previewIndex == 1) {
        _previewMode = DisplayModeSourceImage;
    }
    else if (previewIndex == 2) {
        _previewMode = DisplayModeSegmentImage;
    }
    else if (previewIndex == 3) {
        _previewMode = DisplayModeForeground;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(mattingPickerView:didSelectPreviewMode:)]) {
        [self.delegate mattingPickerView:self didSelectPreviewMode:_previewMode];
    }
}

- (void)sliderValueChanged:(NSSlider *)slider {
    _sliderValue = slider.floatValue;
    if (self.delegate && [self.delegate respondsToSelector:@selector(mattingPickerView:didChangeSlideValue:)]) {
        [self.delegate mattingPickerView:self didChangeSlideValue:slider.floatValue];
    }
}

- (void)setMattingMode:(SelectMode)mattingMode {
    _mattingMode = mattingMode;
    switch (mattingMode) {
        case SelectModeForegroundTarget:
            self.mattingModeControl.selectedSegment = 0;
            self.markerTypeControl.selectedSegment = 0;
            break;
        case SelectModeBackgroundTarget:
            self.mattingModeControl.selectedSegment = 0;
            self.markerTypeControl.selectedSegment = 1;
            break;
        case SelectModeUnknownAreaTarget:
            self.mattingModeControl.selectedSegment = 0;
            self.markerTypeControl.selectedSegment = 2;
            break;
        case SelectModeForegroundFineTuning:
            self.mattingModeControl.selectedSegment = 1;
            self.markerTypeControl.selectedSegment = 0;
            break;
        case SelectModeBackgroundFineTuning:
            self.mattingModeControl.selectedSegment = 1;
            self.markerTypeControl.selectedSegment = 1;
            break;
        case SelectModeUnknownAreaFineTuning:
            self.mattingModeControl.selectedSegment = 1;
            self.markerTypeControl.selectedSegment = 2;
            break;
        default:
            break;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(mattingPickerView:didSelectMattingMode:)]) {
        [self.delegate mattingPickerView:self didSelectMattingMode:_mattingMode];
    }
}

- (void)setPreviewMode:(DisplayMode)previewMode {
    _previewMode = previewMode;
    if (previewMode == DisplayModeEditImage) {
        self.displayModeControl.selectedSegment = 0;
    }
    else if (previewMode == DisplayModeSourceImage) {
        self.displayModeControl.selectedSegment = 1;
    }
    else if (previewMode == DisplayModeSegmentImage) {
        self.displayModeControl.selectedSegment = 2;
    }
    else if (previewMode == DisplayModeForeground) {
        self.displayModeControl.selectedSegment = 3;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(mattingPickerView:didSelectPreviewMode:)]) {
        [self.delegate mattingPickerView:self didSelectPreviewMode:_previewMode];
    }
}

- (void)setSliderValue:(CGFloat)sliderValue {
    _sliderValue = sliderValue;
    self.radiusSlider.floatValue = sliderValue;
    if (self.delegate && [self.delegate respondsToSelector:@selector(mattingPickerView:didChangeSlideValue:)]) {
        [self.delegate mattingPickerView:self didChangeSlideValue:sliderValue];
    }
}

@end
