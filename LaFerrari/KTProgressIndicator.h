//
//  KTProgressIndicator.h
//  LaFerrari
//
//  Created by stanshen on 17/5/27.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface KTProgressIndicator : NSView

- (void)startAnimation:(id)sender withHintText:(NSString *)hintText;
- (void)stopAnimation:(id)sender;

@property (nonatomic, strong) NSString *hintText;

@end
