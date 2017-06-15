//
//  NSColor+Utils.m
//  LaFerrari
//
//  Created by stanshen on 17/6/10.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "NSColor+Utils.h"

#if TARGET_OS_IPHONE
#import <OpenGLES/ES1/gl.h>
#else
#import <OpenGL/gl.h>
#endif

@implementation NSColor (Utils)
- (void)openGLSet {
    CGFloat r,g,b,a;
    [self getRed:&r green:&g blue:&b alpha:&a];
    glColor4f(r, g, b, a);
}
@end
