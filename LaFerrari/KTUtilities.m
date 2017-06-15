//
//  KTUtilities.m
//  LaFerrari
//
//  Created by stanshen on 17/6/9.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTUtilities.h"

#include <CommonCrypto/CommonHMAC.h>

@implementation KTUtilities

@end

const float kNodeSelectionTolerance = 25;
const CGFloat kKTAnchorRadius = 4;
const CGFloat kKTControlPointRadius = 3.5;
const CGFloat kKTTextMinWidth = 20;
const CGFloat kKTDefaultFontSize = 12;
const CGFloat kKTThumbnailSize = 128;

enum {
    TOP = 0x1,
    BOTTOM = 0x2,
    RIGHT = 0x4,
    LEFT = 0x8
};

BOOL KTLineInRect(CGPoint a, CGPoint b, CGRect rect) {
    int acode = 0, bcode = 0;
    float xmin, xmax, ymin, ymax;
    xmin = CGRectGetMinX(rect);
    xmax = CGRectGetMaxX(rect);
    ymin = CGRectGetMinY(rect);
    ymax = CGRectGetMaxY(rect);
    
    if (a.y > ymax) {
        acode |= TOP;
    }
    else if (a.y < ymin) {
        acode |= BOTTOM;
    }
    if (a.x > xmax) {
        acode |= RIGHT;
    }
    else if (a.x < xmin) {
        acode |= LEFT;
    }
    if (b.y > ymax) {
        bcode |= TOP;
    }
    else if (b.y < ymin) {
        bcode |= BOTTOM;
    }
    if (b.x > xmax) {
        bcode |= RIGHT;
    }
    else if (b.x < xmin) {
        bcode |= LEFT;
    }
    
    if (acode == 0 || bcode == 0) { // one or both endpoints with rect
        return YES;
    }
    else if (acode & bcode) { // completely outside of rectangle
        return NO;
    }
    
    CGPoint middle = KTAveragePoints(a, b);
    if (KTLineInRect(a, middle, rect)) {
        return YES;
    }
    if (KTLineInRect(middle, b, rect)) {
        return YES;
    }
    return NO;
}

BOOL KTCollinear(CGPoint a, CGPoint b, CGPoint c) {
    float temp, distances[3];
    
    distances[0] = KTDistanceL2(a, b);
    distances[1] = KTDistanceL2(b, c);
    distances[2] = KTDistanceL2(a, c);
    
    // 对边长排序
    if (distances[0] > distances[1]) {
        temp = distances[1];
        distances[1] = distances[0];
        distances[0] = temp;
    }
    
    if (distances[1] > distances[2]) {
        temp = distances[2];
        distances[2] = distances[1];
        distances[1] = temp;
    }
    
    // 如果三点共线，那么最长边等于最短两边之和
    float shortestSum = distances[0] + distances[1];
    float difference = fabs(shortestSum - distances[2]);
    
    return (difference < 1.0e-4);
}


BOOL KTLineSegmentsIntersectWithValues(CGPoint A, CGPoint B, CGPoint C, CGPoint D, float *rV, float *sV) {
    float denom = (B.x - A.x) * (D.y - C.y) - (B.y - A.y) * (D.x - C.x);
    
    if (denom == 0) {
        return NO;
    }
    
    float r = (A.y - C.y) * (D.x - C.x) - (A.x - C.x) * (D.y - C.y);
    r /= denom;
    
    float s = (A.y - C.y) * (B.x - A.x) - (A.x - C.x) * (B.y - A.y);
    s /= denom;
    
    if (rV) {
        *rV = r;
    }
    
    if (sV) {
        *sV = s;
    }
    
    return (r < 0 || r > 1 || s < 0 || s > 1) ? NO : YES;
}
BOOL KTLineSegmentsIntersect(CGPoint a, CGPoint b, CGPoint c, CGPoint d) {
    return KTLineSegmentsIntersectWithValues(a, b, c, d, NULL, NULL);
}

NSData* KTSHA1DigestForData(NSData *data) {
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, NULL, 0, [data bytes], [data length], cHMAC);
    return [NSData dataWithBytes:cHMAC length:sizeof(cHMAC)];
}

NSString* KTSVGStringFromCGAffineTransform(CGAffineTransform transform) {
    return [NSString stringWithFormat:@"affineMatrix(%g %g %g %g %g %g)", transform.a, transform.b, transform.c, transform.d, transform.tx, transform.ty];
}











































