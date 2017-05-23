//
//  KTButton.m
//  MoguMattor
//
//  Created by longyan on 2017/5/18.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#import "KTButton.h"

@implementation KTButton

+ (id)ktButtonWithImage:(NSImage *)image target:(id)target action:(SEL)action {
    KTButton *button = [[KTButton alloc] initWithFrame:NSMakeRect(0, 0, 20, 20)];
    NSImageView *buttonImage = [[NSImageView alloc] initWithFrame:button.bounds];
    buttonImage.image = image;
    buttonImage.imageScaling = NSImageScaleProportionallyDown;
    [button addSubview:buttonImage];
    button.target = target;
    button.action = action;
    
    button.bordered = NO;
    return button;
    
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    //[[NSColor redColor] set];// 设置背景
    //NSRectFill(dirtyRect);
    
    // Drawing code here.
}

@end
