//
//  KTBezierSegment.h
//  LaFerrari
//
//  Created by stanshen on 17/6/9.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Foundation/Foundation.h>

extern const float kDefaultBezierSegmentFlatness;

@class KTBezierNode;



typedef struct {
    CGPoint a_, out_, in_, b_;
} KTBezierSegment;

KTBezierSegment KTBezierSegmentMake(KTBezierNode *a, KTBezierNode *b);


BOOL KTBezierSegmentIsDegenerate(KTBezierSegment seg); // 判断是否是有效bezier曲线
BOOL KTBezierSegmentIsStraight(KTBezierSegment seg); // 判断是否是直线
BOOL KTBezierSegmentIsFlat(KTBezierSegment seg, float tolerance); // 判断是否平坦, 在一定误差内
BOOL KTBezierSegmentFormCorner(KTBezierSegment segA, KTBezierSegment segB); // 判断两个曲线是否构成角点
BOOL KTBezierSegmentIntersectsRect(KTBezierSegment seg, CGRect rect); // 判断是否在矩形内
BOOL KTBezierSegmentGetIntersection(KTBezierSegment seg, CGPoint a, CGPoint b, float *tIntersect); // 判断相交并得到曲线与线段ab相交的那个点
BOOL KTBezierSegmentFindPointOnSegment(KTBezierSegment seg, CGPoint testPoint, float tolerance, CGPoint *nearestPoint, float *split); // 找到曲线上与testPoint最近的点
BOOL KTBezierSegmentPointDistantFromPoint(KTBezierSegment seg, float distance, CGPoint point, CGPoint *result, float *t); // 找到曲线上与point距离distance的点

void KTBezierSegmentFlatten(KTBezierSegment seg, CGPoint **vertices, NSUInteger *size, NSUInteger *index); // 叫曲线拉平

CGPoint KTBezierSegmentSplit(KTBezierSegment seg, KTBezierSegment *L, KTBezierSegment *R);
CGPoint KTBezierSegmentSplitAtT(KTBezierSegment seg, KTBezierSegment *L, KTBezierSegment *R, float t);
CGPoint KTBezierSegmentGetPointAtT(KTBezierSegment seg, float t);
CGPoint KTBezierSegmentGetTangentAtT(KTBezierSegment seg, float t);
CGPoint KTBezierSegmentGetPointAndTangentAtDistance(KTBezierSegment seg, float distance, CGPoint *tangent, float *curvature);
CGPoint KTBezierSegmentGetClosestPoint(KTBezierSegment seg, CGPoint testPoint, float *error, float *distance);
CGRect KTBezierSegmentGetBounds(KTBezierSegment seg);
CGRect KTBezierSegmentGetSimpleBounds(KTBezierSegment seg);

float KTBezierSegmentGetLength(KTBezierSegment seg);
float KtBezierSegmentGetOutAngle(KTBezierSegment seg);
float KTBezierSegmentGetCurvatureAtT(KTBezierSegment seg, float t);


