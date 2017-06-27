//
//  KTUtilities.h
//  LaFerrari
//
//  Created by stanshen on 17/6/9.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KTUtilities : NSObject

@end

extern const float kNodeSelectionTolerance;
extern const CGFloat kKTAnchorRadius;
extern const CGFloat kKTControlPointRadius;
extern const CGFloat kKTTextMinWidth;
extern const CGFloat kKTDefaultFontSize;
extern const CGFloat kKTThumbnailSize;

static inline float KTRandomFloat() {
    return (random() % 10000) / 10000.0f;
}

static inline float KTClamp(float min, float max, float value) {
    return (value < min) ? min : (value > max ? max : value);
}


static inline float KTDistanceL2(CGPoint a, CGPoint b) {
    float xd = a.x - b.x;
    float yd = a.y - b.y;
    return sqrt(xd * xd + yd * yd);
}

static inline CGPoint KTRoundPoint(CGPoint point) {
    return CGPointMake(round(point.x), round(point.y));
}

static inline CGPoint KTFloorPoint(CGPoint point) {
    return CGPointMake(floor(point.x), floor(point.y));
}

static inline CGSize KTRoundSize(CGSize size) {
    return CGSizeMake(round(size.width), round(size.height));
}

static inline CGRect KTRoundRect(CGRect rect) {
    return CGRectMake(round(rect.origin.x), round(rect.origin.y), round(rect.size.width), round(rect.size.height));
}

static inline CGPoint KTAddPoints(CGPoint a, CGPoint b) {
    return CGPointMake(a.x + b.x, a.y + b.y);
}

static inline CGPoint KTSubtractPoints(CGPoint a, CGPoint b) {
    return CGPointMake(a.x - b.x, a.y - b.y);
}

static inline CGPoint KTMultiplyPointScalar(CGPoint p, float s) {
    return CGPointMake(p.x * s, p.y * s);
}

static inline CGPoint KTAveragePoints(CGPoint a, CGPoint b) {
    return CGPointMake((a.x + b.x) / 2., (a.y + b.y) / 2.);
}

static inline CGPoint KTBlendPoints(CGPoint a, CGPoint b, float ratio) {
    return CGPointMake(a.x * (1. - ratio) + b.x * ratio, a.y * (1. - ratio) + b.y * ratio);
}

static inline float KTMagnitudeVector(CGPoint vector) {
    return sqrt(vector.x * vector.x + vector.y * vector.y);
}

static inline CGPoint KTNormalizeVector(CGPoint point) {
    float distance = KTMagnitudeVector(point);
    if (distance == 0.0f) {
        return point;
    }
    return KTMultiplyPointScalar(point, 1.0f / distance);
}

static inline CGPoint KTScaleVector(CGPoint v, float toLength) {
    float fromLength = KTMagnitudeVector(v);
    float scale = (fromLength != 0 ? toLength / fromLength : 1.0);
    return KTMultiplyPointScalar(v, scale);
}

static inline double KTDotProductVectors(CGPoint a, CGPoint b) {
    return a.x * b.x + a.y * b.y;
}

static inline CGRect KTRectWithPoints(CGPoint a, CGPoint b) {
    float minx = MIN(a.x, b.x);
    float maxx = MAX(a.x, b.x);
    float miny = MIN(a.y, b.y);
    float maxy = MAX(a.y, b.y);
    
    return CGRectMake(minx, miny, maxx - minx, maxy - miny);
}

static inline CGRect KTRectFromPoint(CGPoint a, CGFloat width, CGFloat height) {
    return CGRectMake(a.x - width / 2., a.y - height / 2., width, height);
}

static inline CGRect KTExpandRectToPoint(CGRect rect, CGPoint point) {
    double minX, minY, maxX, maxY;
    
    minX = MIN(CGRectGetMinX(rect), point.x);
    minY = MIN(CGRectGetMinY(rect), point.y);
    maxX = MAX(CGRectGetMaxX(rect), point.x);
    maxY = MAX(CGRectGetMaxY(rect), point.y);
    
    return CGRectUnion(rect, CGRectMake(minX, minY, maxX - minX, maxY - minY));
}

static inline CGPoint KTCenterOfRect(CGRect rect) {
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

BOOL KTLineInRect(CGPoint a, CGPoint b, CGRect rect); // 判断线段ab是否在矩形内
BOOL KTCollinear(CGPoint a, CGPoint b, CGPoint c); // 判断a、b、c三点是否共线
BOOL KTLineSegmentsIntersect(CGPoint a, CGPoint b, CGPoint c, CGPoint d); // 判断线段ab和cd是否相交
BOOL KTLineSegmentsIntersectWithValues(CGPoint A, CGPoint B, CGPoint C, CGPoint D, float *rV, float *sV);// 同上



NSData* KTSHA1DigestForData(NSData *data);

NSString* KTSVGStringFromCGAffineTransform(CGAffineTransform transform);






















