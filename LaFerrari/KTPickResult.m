//
//  KTPickResult.m
//  LaFerrari
//
//  Created by stanshen on 17/6/9.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTPickResult.h"

@implementation KTPickResult

+ (KTPickResult *) pickResult
{
    KTPickResult *pickResult = [[KTPickResult alloc] init];
    
    return pickResult;
}

- (void) setSnappedPoint:(CGPoint)pt
{
    _snappedPoint = pt;
    _snapped = YES;
}


@end
