//
//  KTBezierSegment.m
//  LaFerrari
//
//  Created by stanshen on 17/6/9.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTBezierSegment.h"

#import "KTBezierNode.h"
#import "KTUtilities.h"

const float kDefaultBezierSegmentFlatness = 6;

KTBezierSegment KTBezierSegmentMake(KTBezierNode *a, KTBezierNode *b) {
    KTBezierSegment segment;
    segment.a_ = a.anchorPoint;
    segment.out_ = a.outPoint;
    segment.in_ = b.inPoint;
    segment.b_ = b.anchorPoint;
    
    return segment;
}

BOOL KTBezierSegmentIsDegenerate(KTBezierSegment seg) {
    if (isnan(seg.a_.x) || isnan(seg.out_.x) || isnan(seg.in_.x) || isnan(seg.b_.x) ||
        isnan(seg.a_.y) || isnan(seg.out_.y) || isnan(seg.in_.y) || isnan(seg.b_.y))
    {
        return YES;
    }
    
    return NO;
}

BOOL KTBezierSegmentIsStraight(KTBezierSegment seg) {
    return KTCollinear(seg.a_, seg.out_, seg.b_) && KTCollinear(seg.a_, seg.in_, seg.b_);
}

BOOL KTBezierSegmentIsFlat(KTBezierSegment seg, float tolerance) {
    
    if (CGPointEqualToPoint(seg.a_, seg.out_) && CGPointEqualToPoint(seg.in_, seg.b_)) {
        return YES;
    }
    
    float dx = seg.b_.x - seg.a_.x;
    float dy = seg.b_.y - seg.a_.y;
    
    float d2 = fabs((seg.out_.x - seg.b_.x) * dy - (seg.out_.y - seg.b_.y) * dx);
    float d3 = fabs((seg.in_.x - seg.b_.x) * dy - (seg.in_.y - seg.b_.y) * dx);
    
    if ((d2 + d3) * (d2 + d3) <= tolerance * (dx * dx + dy * dy)) {
        return YES;
    }
    
    return NO;
}

BOOL KTBezierSegmentFormCorner(KTBezierSegment a, KTBezierSegment b) {
    CGPoint p, q, r;
    
    if (!CGPointEqualToPoint(a.b_, a.in_)) {
        p = a.in_;
    } else {
        p = a.out_;
    }
    
    if (!CGPointEqualToPoint(b.a_, b.out_)) {
        r = b.out_;
    } else {
        r = b.in_;
    }
    
    q = b.a_;
    
    return !KTCollinear(p, q, r);
}

BOOL KTBezierSegmentIntersectsRect(KTBezierSegment seg, CGRect rect) {
    KTBezierSegment L, R;
    
    if(KTBezierSegmentIsFlat(seg, kDefaultBezierSegmentFlatness)) {
        return KTLineInRect(seg.a_, seg.b_, rect);
    } else {
        KTBezierSegmentSplit(seg, &L, &R);
        
        if(KTBezierSegmentIntersectsRect(L, rect)) {
            return YES;
        }
        if(KTBezierSegmentIntersectsRect(R, rect)) {
            return YES;
        }
    }
    
    return NO;
}

BOOL KTBezierSegmentGetIntersection(KTBezierSegment seg, CGPoint a, CGPoint b, float *tIntersect) {
    
    if (!CGRectIntersectsRect(KTBezierSegmentGetSimpleBounds(seg), KTRectWithPoints(a, b))) {
        return NO;
    }
    
    float       r, delta = 0.01f;
    CGPoint     current, last = seg.a_;
    
    for (float t = 0; t < (1.0f + delta); t += delta) {
        current = KTBezierSegmentGetPointAtT(seg, t);
        
        if (KTLineSegmentsIntersectWithValues(last, current, a, b, &r, NULL)) {
            *tIntersect = KTClamp(0, 1, (t-delta) + delta * r);
            return YES;
        }
        
        last = current;
    }
    
    return NO;
}



CGPoint KTBezierSegmentSplit(KTBezierSegment seg, KTBezierSegment *L, KTBezierSegment *R) {
    return KTBezierSegmentSplitAtT(seg, L, R, 0.5f);
}

CGPoint KTBezierSegmentSplitAtT(KTBezierSegment seg, KTBezierSegment *L, KTBezierSegment *R, float t) {
    if (KTBezierSegmentIsStraight(seg)) {
        CGPoint point = KTMultiplyPointScalar(KTSubtractPoints(seg.b_, seg.a_), t);
        point = KTAddPoints(seg.a_, point);
        
        if (L) {
            L->a_ = seg.a_;
            L->out_ = seg.a_;
            L->in_ = point;
            L->b_ = point;
        }
        
        if (R) {
            R->a_ = point;
            R->out_ = point;
            R->in_ = seg.b_;
            R->b_ = seg.b_;
        }
        
        return point;
    }
    
    CGPoint A, B, C, D, E, F;
    A.x = seg.a_.x + (seg.out_.x - seg.a_.x) * t;
    A.y = seg.a_.y + (seg.out_.y - seg.a_.y) * t;
    
    B.x = seg.out_.x + (seg.in_.x - seg.out_.x) * t;
    B.y = seg.out_.y + (seg.in_.y - seg.out_.y) * t;
    
    C.x = seg.in_.x + (seg.b_.x - seg.in_.x) * t;
    C.y = seg.in_.y + (seg.b_.y - seg.in_.y) * t;
    
    D.x = A.x + (B.x - A.x) * t;
    D.y = A.y + (B.y - A.y) * t;
    
    E.x = B.x + (C.x - B.x) * t;
    E.y = B.y + (C.y - B.y) * t;
    
    F.x = D.x + (E.x - D.x) * t;
    F.y = D.y + (E.y - D.y) * t;
    
    if (L) {
        L->a_ = seg.a_;
        L->out_ = A;
        L->in_ = D;
        L->b_ = F;
    }
    
    if (R) {
        R->a_ = F;
        R->out_ = E;
        R->in_ = C;
        R->b_ = seg.b_;
    }
    
    return F;

}


/*
 * KTBezierSegmentFindPointOnSegment_R()
 *
 * Performs a binary search on the path, subdividing it until a
 * sufficiently small section is found that contains the test point.
 */
BOOL KTBezierSegmentFindPointOnSegment_R(KTBezierSegment seg, CGPoint testPoint, float tolerance,
                                         CGPoint *nearestPoint, float *split, double depth)
{
    CGRect  bbox = CGRectInset(KTBezierSegmentGetSimpleBounds(seg), -tolerance / 2, -tolerance / 2);
    
    if (!CGRectContainsPoint(bbox, testPoint)) {
        return NO;
    } else if (KTBezierSegmentIsStraight(seg)) {
        CGPoint s = KTSubtractPoints(seg.b_, seg.a_);
        CGPoint v = KTSubtractPoints(testPoint, seg.a_);
        float   n = v.x * s.x + v.y * s.y;
        float   d = s.x * s.x + s.y * s.y;
        float   t = n/d;
        BOOL    onSegment = NO;
        
        if (0.0f <= t && t <= 1.0f) {
            CGPoint delta = KTSubtractPoints(seg.b_, seg.a_);
            CGPoint p = KTAddPoints(seg.a_, KTMultiplyPointScalar(delta, t));
            
            if (KTDistanceL2(p, testPoint) < tolerance) {
                if (nearestPoint) {
                    *nearestPoint = p;
                }
                if (split) {
                    *split += (t * depth);
                }
                onSegment = YES;
            }
        }
        
        return onSegment;
    } else if((CGRectGetWidth(bbox) < tolerance * 1.1) || (CGRectGetHeight(bbox) < tolerance * 1.1)) {
        // Close enough! This should be more or less a straight line now...
        CGPoint s = KTSubtractPoints(seg.b_, seg.a_);
        CGPoint v = KTSubtractPoints(testPoint, seg.a_);
        float n = v.x * s.x + v.y * s.y;
        float d = s.x * s.x + s.y * s.y;
        float t = KTClamp(0.0f, 1.0f, n/d);
        
        if (nearestPoint) {
            // make sure the found point is on the path and not just near it
            *nearestPoint = KTBezierSegmentSplitAtT(seg, NULL, NULL, t);
        }
        if (split) {
            *split += (t * depth);
        }
        
        return YES;
    }
    
    // We know the point is inside our bounding box, but our bounding box is not yet
    // small enough to consider it a hit. So, subdivide the path and recurse...
    
    KTBezierSegment L, R;
    BOOL            foundLeft = NO, foundRight = NO;
    CGPoint         nearestLeftPoint, nearestRightPoint;
    float           leftSplit = 0.0f, rightSplit = 0.0f;
    
    KTBezierSegmentSplit(seg, &L, &R);
    
    // look both ways before crossing
    if (KTBezierSegmentFindPointOnSegment_R(L, testPoint, tolerance, &nearestLeftPoint, &leftSplit, depth / 2.0f)) {
        foundLeft = YES;
    }
    if (KTBezierSegmentFindPointOnSegment_R(R, testPoint, tolerance, &nearestRightPoint, &rightSplit, depth / 2.0f)) {
        foundRight = YES;
    }
    
    if (foundLeft && foundRight) {
        // since both halves found the point, choose the one that's actually closest
        float leftDistance = KTDistanceL2(nearestLeftPoint, testPoint);
        float rightDistance = KTDistanceL2(nearestRightPoint, testPoint);
        
        foundLeft = (leftDistance <= rightDistance) ? YES : NO;
        foundRight = !foundLeft;
    }
    
    if (foundLeft) {
        if (nearestPoint) {
            *nearestPoint = nearestLeftPoint;
        }
        if (split) {
            *split += leftSplit;
        }
    } else if (foundRight) {
        if (nearestPoint) {
            *nearestPoint = nearestRightPoint;
        }
        if (split) {
            *split += 0.5 * depth + rightSplit;
        }
    }
    
    return (foundLeft || foundRight);
}

BOOL KTBezierSegmentFindPointOnSegment(KTBezierSegment seg, CGPoint testPoint, float tolerance, CGPoint *nearestPoint, float *split)
{
    if (split) {
        *split = 0.0f;
    }
    
    return KTBezierSegmentFindPointOnSegment_R(seg, testPoint, tolerance, nearestPoint, split, 1.0);
}

BOOL KTBezierSegmentPointDistantFromPoint(KTBezierSegment seg, float distance, CGPoint point, CGPoint *result, float *tResult) {
    CGPoint     current, last = seg.a_;
    float       start = 0.0f, end = 1.0f, step = 0.1f;
    
    for (float t = start; t < (end + step); t += step) {
        current = KTBezierSegmentGetPointAtT(seg, t);
        
        if (KTDistanceL2(current, point) >= distance) {
            start = (t - step); // back up one iteration
            end = t;
            
            // it's between the last and current point, let's get more precise
            step = 0.0001f;
            
            for (float t = start; t < (end + step); t += step) {
                current = KTBezierSegmentGetPointAtT(seg, t);
                
                if (KTDistanceL2(current, point) >= distance) {
                    *tResult = t - (step / 2);
                    *result = KTBezierSegmentGetPointAtT(seg, t);
                    return YES;
                }
            }
        }
        
        last = current;
    }
    
    return NO;
}


void KTBezierSegmentFlatten(KTBezierSegment seg, CGPoint **vertices, NSUInteger *size, NSUInteger *index) {
    if (*size < *index + 4) {
        *size *= 2;
        *vertices = realloc(*vertices, sizeof(CGPoint) * *size);
    }
    
    if (KTBezierSegmentIsFlat(seg, kDefaultBezierSegmentFlatness)) {
        if (*index == 0) {
            (*vertices)[*index] = seg.a_;
            *index += 1;
        }
        
        (*vertices)[*index] = seg.b_;
        *index += 1;
    } else {
        KTBezierSegment L, R;
        KTBezierSegmentSplit(seg, &L, &R);
        
        KTBezierSegmentFlatten(L, vertices, size, index);
        KTBezierSegmentFlatten(R, vertices, size, index);
    }
}


CGPoint KTBezierSegmentGetPointAtT(KTBezierSegment seg, float t) {
    float   t2 ,t3, td2, td3;
    CGPoint result;
    
    t2 = t * t;
    t3 = t2 * t;
    
    td2 = (1-t) * (1-t);
    td3 = td2 * (1-t);
    
    result.x = td3 * seg.a_.x +
    3 * t * td2 * seg.out_.x +
    3 * t2 * (1-t) * seg.in_.x +
    t3 * seg.b_.x;
    
    result.y = td3 * seg.a_.y +
    3 * t * td2 * seg.out_.y +
    3 * t2 * (1-t) * seg.in_.y +
    t3 * seg.b_.y;
    
    return result;
}

/*
 http://www.planetclegg.com/projects/WarpingTextToSplines.html
 
 coefficients:
 
 A = x3 - 3 * x2 + 3 * x1 - x0
 B = 3 * x2 - 6 * x1 + 3 * x0
 C = 3 * x1 - 3 * x0
 D = x0
 
 E = y3 - 3 * y2 + 3 * y1 - y0
 F = 3 * y2 - 6 * y1 + 3 * y0
 G = 3 * y1 - 3 * y0
 H = y0
 
 tangent:
 
 Vx = 3At2 + 2Bt + C
 Vy = 3Et2 + 2Ft + G
 
 */
CGPoint KTBezierSegmentGetTangentAtT(KTBezierSegment seg, float t) {
    float A, B, C, E, F, G;
    
    A = seg.b_.x - 3 * seg.in_.x + 3 * seg.out_.x - seg.a_.x;
    B = 3 * seg.in_.x - 6 * seg.out_.x + 3 * seg.a_.x;
    C = 3 * seg.out_.x - 3 * seg.a_.x;
    
    E = seg.b_.y - 3 * seg.in_.y + 3 * seg.out_.y - seg.a_.y;
    F = 3 * seg.in_.y - 6 * seg.out_.y + 3 * seg.a_.y;
    G = 3 * seg.out_.y - 3 * seg.a_.y;
    
    float x = 3 * A * t * t + 2 * B * t + C;
    float y = 3 * E * t * t + 2 * F * t + G;
    
    return CGPointMake(x,y);
}

CGPoint KTBezierSegmentGetPointAndTangentAtDistance(KTBezierSegment seg, float distance, CGPoint *tangent, float *curvature) {
    if (KTBezierSegmentIsStraight(seg)) {
        float t = distance / KTDistanceL2(seg.a_, seg.b_);
        CGPoint point = KTMultiplyPointScalar(KTSubtractPoints(seg.b_, seg.a_), t);
        point = KTAddPoints(seg.a_, point);
        
        if (tangent) {
            *tangent = KTBezierSegmentGetTangentAtT(seg, t);
        }
        
        if (curvature) {
            *curvature = 0.0;
        }
        return KTBezierSegmentSplitAtT(seg, NULL, NULL, t);
    }
    
    CGPoint     current, last = seg.a_;
    float       delta = 1.0f / 200.0f;
    float       step, progress = 0;
    
    for (float t = 0; t < (1.0f + delta); t += delta) {
        current = KTBezierSegmentGetPointAtT(seg, t);
        step = KTDistanceL2(last, current);
        
        if (progress + step >= distance) {
            // it's between the current and last set of points
            float factor = (distance - progress) / step;
            t = (t - delta) + factor * delta;
            
            if (tangent) {
                *tangent = KTBezierSegmentGetTangentAtT(seg, t);
            }
            
            if (curvature) {
                *curvature = KTBezierSegmentGetCurvatureAtT(seg, t);
            }
            
            return KTBezierSegmentSplitAtT(seg, NULL, NULL, t);
        }
        
        progress += step;
        last = current;
    }
    
    return CGPointZero;
}

CGPoint KTBezierSegmentGetClosestPoint(KTBezierSegment seg, CGPoint testPoint, float *error, float *distance) {
    float       delta = 0.001f;
    float       sum = 0.0f;
    float       smallestDistance = MAXFLOAT;
    CGPoint     current, last = seg.a_;
    
    CGPoint     closest = seg.a_;
    for (float t = 0; t < (1.0f + delta); t += delta) {
        current = KTBezierSegmentGetPointAtT(seg, t);
        sum += KTDistanceL2(last, current);
        
        float testDistance = KTDistanceL2(current, testPoint);
        if (testDistance < smallestDistance) {
            smallestDistance = testDistance;
            *error = testDistance;
            *distance = sum;
            closest = current;
        }
        
        last = current;
    }
    
    return closest;
}

CGRect KTBezierSegmentGetBounds(KTBezierSegment seg) {
    NSUInteger  index = 0;
    static NSUInteger size = 128;
    static CGPoint *vertices = NULL;
    if (!vertices) {
        vertices = calloc(sizeof(CGPoint), size);
    }
    
    KTBezierSegmentFlatten(seg, &vertices, &size, &index);
    
    float   minX, maxX, minY, maxY;
    
    minX = maxX = vertices[0].x;
    minY = maxY = vertices[0].y;
    
    for (int i = 1; i < index; i++) {
        minX = MIN(minX, vertices[i].x);
        maxX = MAX(maxX, vertices[i].x);
        minY = MIN(minY, vertices[i].y);
        maxY = MAX(maxY, vertices[i].y);
    }
    
    return CGRectMake(minX, minY, maxX - minX, maxY - minY);
}

CGRect KTBezierSegmentGetSimpleBounds(KTBezierSegment seg) {
    CGRect rect = KTRectWithPoints(seg.a_, seg.b_);
    rect = KTExpandRectToPoint(rect, seg.out_);
    rect = KTExpandRectToPoint(rect, seg.in_);
    return rect;
}


float base3(double t, double p1, double p2, double p3, double p4)
{
    float t1 = -3*p1 + 9*p2 - 9*p3 + 3*p4;
    float t2 = t*t1 + 6*p1 - 12*p2 + 6*p3;
    return t*t2 - 3*p1 + 3*p2;
}

float cubicF(double t, KTBezierSegment seg)
{
    float xbase = base3(t, seg.a_.x, seg.out_.x, seg.in_.x, seg.b_.x);
    float ybase = base3(t, seg.a_.y, seg.out_.y, seg.in_.y, seg.b_.y);
    float combined = xbase*xbase + ybase*ybase;
    return sqrt(combined);
}
/**
 * Gauss quadrature for cubic Bezier curves
 * http://processingjs.nihongoresources.com/bezierinfo/
 *
 */
float KTBezierSegmentGetLength(KTBezierSegment seg) {
    if (KTBezierSegmentIsStraight(seg)) {
        return KTDistanceL2(seg.a_, seg.b_);
    }
    
    float  z = 1.0f;
    float  z2 = z / 2.0f;
    float  sum = 0.0f;
    
    // Legendre-Gauss abscissae (xi values, defined at i=n as the roots of the nth order Legendre polynomial Pn(x))
    static float Tvalues[] = {
        -0.06405689286260562997910028570913709, 0.06405689286260562997910028570913709,
        -0.19111886747361631067043674647720763, 0.19111886747361631067043674647720763,
        -0.31504267969616339684080230654217302, 0.31504267969616339684080230654217302,
        -0.43379350762604512725673089335032273, 0.43379350762604512725673089335032273,
        -0.54542147138883956269950203932239674, 0.54542147138883956269950203932239674,
        -0.64809365193697554552443307329667732, 0.64809365193697554552443307329667732,
        -0.74012419157855435791759646235732361, 0.74012419157855435791759646235732361,
        -0.82000198597390294708020519465208053, 0.82000198597390294708020519465208053,
        -0.88641552700440107148693869021371938, 0.88641552700440107148693869021371938,
        -0.93827455200273279789513480864115990, 0.93827455200273279789513480864115990,
        -0.97472855597130947380435372906504198, 0.97472855597130947380435372906504198,
        -0.99518721999702131064680088456952944, 0.99518721999702131064680088456952944
    };
    
    // Legendre-Gauss weights (wi values, defined by a function linked to in the Bezier primer article)
    static float Cvalues[] = {
        0.12793819534675215932040259758650790, 0.12793819534675215932040259758650790,
        0.12583745634682830250028473528800532, 0.12583745634682830250028473528800532,
        0.12167047292780339140527701147220795, 0.12167047292780339140527701147220795,
        0.11550566805372559919806718653489951, 0.11550566805372559919806718653489951,
        0.10744427011596563437123563744535204, 0.10744427011596563437123563744535204,
        0.09761865210411388438238589060347294, 0.09761865210411388438238589060347294,
        0.08619016153195327434310968328645685, 0.08619016153195327434310968328645685,
        0.07334648141108029983925575834291521, 0.07334648141108029983925575834291521,
        0.05929858491543678333801636881617014, 0.05929858491543678333801636881617014,
        0.04427743881741980774835454326421313, 0.04427743881741980774835454326421313,
        0.02853138862893366337059042336932179, 0.02853138862893366337059042336932179,
        0.01234122979998720018302016399047715, 0.01234122979998720018302016399047715
    };
    
    for (int i = 0; i < 24; i++) {
        float corrected_t = z2 * Tvalues[i] + z2;
        sum += Cvalues[i] * cubicF(corrected_t, seg);
    }
    
    return z2 * sum;
}

float KtBezierSegmentGetOutAngle(KTBezierSegment seg) {
    CGPoint a;
    
    if (!CGPointEqualToPoint(seg.b_, seg.in_)) {
        a = seg.in_;
    } else {
        a = seg.out_;
    }
    
    CGPoint delta = KTSubtractPoints(seg.b_, a);
    
    return atan2f(delta.y, delta.x);
}

float firstDerivative(float A, float B, float C, float D, float t)
{
    return -3*A*(1-t)*(1-t) + 3*B*(1-t)*(1-t) - 6*B*(1-t)*t + 6*C*(1-t)*t - 3*C*t*t + 3*D*t*t;
}

float secondDerivative(float A, float B, float C, float D, float t)
{
    return 6*A*(1-t) - 12*B*(1-t) + 6*C*(1-t) + 6*B*t - 12*C*t + 6*D*t;
}
float KTBezierSegmentGetCurvatureAtT(KTBezierSegment seg, float t) {
    if (KTBezierSegmentIsStraight(seg)) {
        return 0.0f;
    }
    
    float xPrime = firstDerivative(seg.a_.x, seg.out_.x, seg.in_.x, seg.b_.x, t);
    float yPrime = firstDerivative(seg.a_.y, seg.out_.y, seg.in_.y, seg.b_.y, t);
    
    float xPrime2 = secondDerivative(seg.a_.x, seg.out_.x, seg.in_.x, seg.b_.x, t);
    float yPrime2 = secondDerivative(seg.a_.y, seg.out_.y, seg.in_.y, seg.b_.y, t);
    
    float num = xPrime * yPrime2 - yPrime * xPrime2;
    float denom =  pow(xPrime * xPrime + yPrime * yPrime, 3.0f / 2);
    
    return -num/denom;
}
