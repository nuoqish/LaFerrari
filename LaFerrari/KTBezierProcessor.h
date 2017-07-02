//
//  KTBezierProcessor.h
//  LaFerrari
//
//  Created by stanshen on 17/6/29.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Foundation/Foundation.h>
@class KTBezierNode;

@interface KTBezierProcessor : NSObject

+ (NSArray<NSArray<KTBezierNode *> *> *)processImage:(NSImage *)image;

@end
