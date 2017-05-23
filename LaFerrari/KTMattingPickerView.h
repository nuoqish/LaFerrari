//
//  KTMattingPickerView.h
//  LaFerrari
//
//  Created by longyan on 2017/5/19.
//  Copyright © 2017年 longyan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class KTMattingPickerView;


typedef NS_ENUM(NSInteger, SelectMode) {
    
    SelectModeForegroundFineTuning,
    SelectModeBackgroundFineTuning,
    SelectModeUnknownAreaFineTuning,
    
    SelectModeForegroundTarget,
    SelectModeBackgroundTarget,
    SelectModeUnknownAreaTarget
    
    
};


typedef NS_ENUM(NSInteger, DisplayMode) {
    DisplayModeEditImage,
    DisplayModeSourceImage,
    DisplayModeSegmentImage,
    DisplayModeForeground
};


@protocol KTMattingPickerViewDelegate <NSObject>

- (void)mattingPickerView:(KTMattingPickerView *)pickerView didSelectMattingMode:(SelectMode)mattingMode;
- (void)mattingPickerView:(KTMattingPickerView *)pickerView didSelectPreviewMode:(DisplayMode)previewMode;
- (void)mattingPickerView:(KTMattingPickerView *)pickerView didChangeSlideValue:(CGFloat)sliderValue;

@end

@interface KTMattingPickerView : NSView

@property (nonatomic, weak) id<KTMattingPickerViewDelegate> delegate;


@property (nonatomic, assign) SelectMode mattingMode;
@property (nonatomic, assign) DisplayMode previewMode;
@property (nonatomic, assign) CGFloat sliderValue;

@end
