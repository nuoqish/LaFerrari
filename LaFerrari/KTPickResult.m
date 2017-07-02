//
//  KTPickResult.m
//  LaFerrari
//
//  Created by stanshen on 17/6/9.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTPickResult.h"
#import "KTBezierSegment.h"
#import "KTUtilities.h"

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

KTPickResult *KTSnapToRectangle(CGRect rect, CGAffineTransform *transform, CGPoint point, float viewScale, int snapFlags) {
    KTPickResult *pickResult = [KTPickResult pickResult];
    
    CGPoint corner[4];
    corner[0] = CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect));
    corner[1] = CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect));
    corner[2] = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    corner[3] = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));
    
    if (transform) {
        for (int i = 0; i < 4; i++) {
            corner[i] = CGPointApplyAffineTransform(corner[i], *transform);
        }
    }
    
    if (snapFlags & KTSnapNodes) {
        for (int i = 0; i < 4; i++) {
            if (KTDistanceL2(corner[i], point) < (kNodeSelectionTolerance / viewScale)) {
                pickResult.snappedPoint = corner[i];
                pickResult.type = KTRectCorner;
                return pickResult;
            }
        }
    }
    
    if (snapFlags & KTSnapEdges) {
        KTBezierSegment segment;
        CGPoint nearest;
        
        for (int i = 0; i < 4; i++) {
            segment.a_ = segment.out_ = corner[i];
            segment.b_ = segment.in_ = corner[(i + 1) % 4];
            if (KTBezierSegmentFindPointOnSegment(segment, point, kNodeSelectionTolerance / viewScale, &nearest, NULL)) {
                pickResult.snappedPoint = nearest;
                pickResult.type = KTRectEdge;
                return pickResult;
            }
        }
        
    }
    
    return pickResult;
    
    
}