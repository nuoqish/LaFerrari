//
//  KTCurveFit.h
//  LaFerrari
//
//  Created by stanshen on 17/6/8.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KTPath;
@class KTBezierNode;
@interface KTCurveFit : NSObject

+ (KTPath *)smoothPathForPoints:(NSArray *)points error:(float)epsilon attemptToClose:(BOOL)shouldClose;
+ (NSArray<KTBezierNode *> *)bezierNodesFromPoints:(NSArray *)points error:(float)epsilon attempToClose:(BOOL)shouldClose;

@end
