//
//  KTButton.h
//  MoguMattor
//
//  Created by longyan on 2017/5/18.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface KTButton : NSButton

+ (id)ktButtonWithImage:(NSImage *)image target:(id)target action:(SEL)action; // 10.11以前不支持该API

@end
