//
//  KTBackgroundPickerView.h
//  MoguMattor
//
//  Created by longyan on 2017/5/11.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class KTBackgroundPickerView;

@protocol KTBackgroundPickerViewDelegate <NSObject>

- (void)backgroundPickerView:(KTBackgroundPickerView *)backgroundPickerView didSelectBackgroundColor:(NSColor *)backColor;

- (void)backgroundPickerView:(KTBackgroundPickerView *)backgroundPickerView didSelectBackgroundImage:(NSImage *)backImage;

@end

@interface KTBackgroundPickerView : NSView

@property (nonatomic, weak) id<KTBackgroundPickerViewDelegate> delegate;

@end
