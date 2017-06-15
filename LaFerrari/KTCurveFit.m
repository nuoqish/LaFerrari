//
//  KTCurveFit.m
//  LaFerrari
//
//  Created by stanshen on 17/6/8.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTCurveFit.h"

#import "KTBezierNode.h"
#import "KTBezierSegment.h"
#import "KTPath.h"

#import "KTUtilities.h"

typedef struct {
    CGPoint pts[4];
} KTBezierCurve;


static CGPoint ComputeLeftTangent(CGPoint *d, int end) {
    CGPoint tHat1 = KTSubtractPoints(d[end + 1], d[end]);
    return KTNormalizeVector(tHat1);
}

static CGPoint ComputeRightTangent(CGPoint *d, int end) {
    CGPoint tHat2 = KTSubtractPoints(d[end - 1], d[end]);
    return KTNormalizeVector(tHat2);
}

static CGPoint ComputeCenterTangent(CGPoint *d, int center) {
    CGPoint v1 = KTSubtractPoints(d[center - 1], d[center]);
    CGPoint v2 = KTSubtractPoints(d[center], d[center + 1]);
    CGPoint tHatCenter = KTAveragePoints(v1, v2);
    return KTNormalizeVector(tHatCenter);
}

static void AddBezierSegment(KTBezierSegment *segments, KTBezierCurve curve, int idx) {
    segments[idx].a_ = curve.pts[0];
    segments[idx].out_ = curve.pts[1];
    segments[idx].in_ = curve.pts[2];
    segments[idx].b_ = curve.pts[3];
}

static double *ChordLengthParameterize(CGPoint *d, int first, int last) {
    double *u = calloc((last - first + 1), sizeof(double)); // malloc and init to 0
    
    for (int i = first + 1; i <= last; i++) {
        u[i - first] = u[i - first - 1] + KTDistanceL2(d[i], d[i - 1]);
    }
    
    for (int i = first + 1; i <= last; i++) {
        u[i - first] /= u[last - first];
    }
    
    return u;
}

// B0,B1,B2,B3: Bezier multipliers
static double B0(double u) {
    double tmp = 1. - u;
    return tmp * tmp * tmp;
}
static double B1(double u) {
    double tmp = 1.0 - u;
    return 3 * u * tmp * tmp;
}
static double B2(double u) {
    return 3 * u * u * (1.0 - u);
}
static double B3(double u) {
    return u * u * u;
}

// use least-squares method to find Bezier control points for region
static KTBezierCurve GenerateBezierCurve(CGPoint *d, int first, int last, double *uPrime, CGPoint tHat1, CGPoint tHat2) {
    
    // compute A's
    CGPoint A[last - first + 1][2];
    double C[2][2] = {0};
    double X[2] = {0};
    int nPts = last - first + 1;
    for (int i = 0; i < nPts; i++) {
        A[i][0] = KTScaleVector(tHat1, B1(uPrime[i]));
        A[i][1] = KTScaleVector(tHat2, B2(uPrime[i]));
    }
    for (int i = 0; i < nPts; i++) {
        C[0][0] += KTDotProductVectors(A[i][0], A[i][0]);
        C[0][1] += KTDotProductVectors(A[i][0], A[i][1]);
        C[1][0] = C[0][1];
        C[1][1] += KTDotProductVectors(A[i][1], A[i][1]);
        
        CGPoint tmp = KTMultiplyPointScalar(d[last], B3(uPrime[i]));
        tmp = KTAddPoints(KTMultiplyPointScalar(d[last], B2(uPrime[i])), tmp);
        tmp = KTAddPoints(KTMultiplyPointScalar(d[last], B1(uPrime[i])), tmp);
        tmp = KTAddPoints(KTMultiplyPointScalar(d[last], B0(uPrime[i])), tmp);
        
        X[0] += KTDotProductVectors(A[i][0], tmp);
        X[1] += KTDotProductVectors(A[i][1], tmp);
    }
    
    // compute the determinants of C and X
    double det_C0_C1 = C[0][0] * C[1][1] - C[1][0] * C[0][1];
    double det_C0_X  = C[0][0] * X[1]    - C[1][0] * X[0];
    double det_X_C1  = X[0]    * C[1][1] - X[1]    * C[0][1];
    
    // finally, derive alpha values
    double alpha_l = (det_C0_C1 == 0.0) ? 0.0 : det_X_C1 / det_C0_C1;
    double alpha_r = (det_C0_C1 == 0.0) ? 0.0 : det_C0_X / det_C0_C1;
    
    // If alpha is negative, use the Wu/Barsky heuristic,
    // If alpha is 0, you get coincident control points that lead to divide by zero in any subsequent NewtonRaphsonRootFind() call
    double segLength = KTDistanceL2(d[last], d[first]);
    double epsilon = 1.e-6 * segLength;
    KTBezierCurve bezCurve;
    if (alpha_l < epsilon || alpha_r < epsilon) {
        // fall back on standard formula and subdivide further if needed
        double dist = segLength / 3.;
        bezCurve.pts[0] = d[first];
        bezCurve.pts[3] = d[last];
        bezCurve.pts[1] = KTAddPoints(bezCurve.pts[0], KTScaleVector(tHat1, dist));
        bezCurve.pts[2] = KTAddPoints(bezCurve.pts[3], KTScaleVector(tHat2, dist));
        return bezCurve;
    }
    
    // first and last control points of the Bezier Curve are positioned exactly at the first and last data points
    // control points 1 and 2 are positioned an alpha distance out on the tangent vectors, left and right respectively
    bezCurve.pts[0] = d[first];
    bezCurve.pts[3] = d[last];
    bezCurve.pts[1] = KTAddPoints(bezCurve.pts[0], KTScaleVector(tHat1, alpha_l));
    bezCurve.pts[2] = KTAddPoints(bezCurve.pts[3], KTScaleVector(tHat2, alpha_r));
    
    return bezCurve;
}

// evaluate a Bezier Curve at a particular parameter value
static CGPoint BezierII(int degree, CGPoint *V, double t) {
    CGPoint Vtemp[degree + 1];
    
    for (int i = 0; i <= degree; i++) {
        Vtemp[i] = V[i];
    }
    
    // triangle computation
    for (int i = 1; i <= degree; i++) {
        for (int j = 0; j <= degree - i; j++) {
            Vtemp[j].x = (1.0 - t) * Vtemp[j].x + t * Vtemp[j + 1].x;
            Vtemp[j].y = (1.0 - t) * Vtemp[j].y + t * Vtemp[j + 1].y;
        }
    }
    
    return Vtemp[0];
}

// find the maximum squared distance of digitized points to fitted curve
static double ComputeMaxError(CGPoint *d, int first, int last, KTBezierCurve bezCurve, double *u, int *splitPoint) {
    double maxDist = 0.0;
    
    *splitPoint = (last - first + 1) / 2;
    CGPoint P, v;
    for (int i = first + 1; i < last; i++) {
        P = BezierII(3, bezCurve.pts, u[i - first]);
        v = KTSubtractPoints(P, d[i]);
        double dist = v.x * v.x + v.y * v.y;
        if (dist >= maxDist) {
            maxDist = dist;
            *splitPoint = i;
        }
    }
    return maxDist;
}

// use newton-raphson iteration to find better root
static double NewtonRaphsonRootFind(KTBezierCurve Q, CGPoint P, double u) {
    
    // Compute Q(u)
    CGPoint Q_u = BezierII(3, Q.pts, u);
    
    // Generate control vertices for Q'
    CGPoint Q1[3], Q2[2];       // Q' and Q''
    for (int i = 0; i <= 2; i++) {
        Q1[i].x = (Q.pts[i+1].x - Q.pts[i].x) * 3.0;
        Q1[i].y = (Q.pts[i+1].y - Q.pts[i].y) * 3.0;
    }
    // Generate control vertices for Q''
    for (int i = 0; i <= 1; i++) {
        Q2[i].x = (Q1[i+1].x - Q1[i].x) * 2.0;
        Q2[i].y = (Q1[i+1].y - Q1[i].y) * 2.0;
    }
    
    // Compute Q'(u) and Q''(u)
    CGPoint Q1_u = BezierII(2, Q1, u);
    CGPoint Q2_u = BezierII(1, Q2, u);
    
    // Compute f(u)/f'(u)
    double numerator = (Q_u.x - P.x) * (Q1_u.x) + (Q_u.y - P.y) * (Q1_u.y);
    double denominator = (Q1_u.x) * (Q1_u.x) + (Q1_u.y) * (Q1_u.y) +
    (Q_u.x - P.x) * (Q2_u.x) + (Q_u.y - P.y) * (Q2_u.y);
    
    if (denominator == 0.0f) {
        return u;
    }
    
    // u = u - f(u)/f'(u)
    double uPrime = u - (numerator / denominator);
    return uPrime;

}

// given set of points adn their parameterization, try to find a better parameterization
static double* Reparameterize(CGPoint *d, int first, int last, double *u, KTBezierCurve bezCurve) {
    int nPts = last - first + 1;
    double *uPrime = malloc(nPts * sizeof(double));
    for (int i = first; i <= last; i++) {
        uPrime[i - first] = NewtonRaphsonRootFind(bezCurve, d[i], u[i - first]);
    }
    
    return uPrime;
}

// https://github.com/erich666/GraphicsGems/blob/master/gems/FitCurves.c
static int FitCubic(KTBezierSegment *segments, CGPoint *d, int first, int last, CGPoint tHat1, CGPoint tHat2, double error, int segCount) {
    
    int nPts = last - first + 1;
    double iterationError = error * error;
    int maxIterations = 5;
    
    
    // use heuristic if region only has two points in it
    if (nPts == 2) {
        double dist = KTDistanceL2(d[last], d[first]) / 3.0;
        KTBezierCurve bezCurve;
        bezCurve.pts[0] = d[first];
        bezCurve.pts[3] = d[last];
        bezCurve.pts[1] = KTAddPoints(bezCurve.pts[0], KTScaleVector(tHat1, dist));
        bezCurve.pts[2] = KTAddPoints(bezCurve.pts[3], KTScaleVector(tHat2, dist));
        AddBezierSegment(segments, bezCurve, segCount++);
        return segCount;
    }
    
    // parameterize points, and attempt to fit curve
    double *u = ChordLengthParameterize(d, first, last);
    KTBezierCurve bezCurve = GenerateBezierCurve(d, first, last, u, tHat1, tHat2);
    
    // find max deviation of points to fitted curve
    int splitPoint;
    double maxError = ComputeMaxError(d, first, last, bezCurve, u, &splitPoint);
    if (maxError < error) {
        AddBezierSegment(segments, bezCurve, segCount++);
        free(u);
        return segCount;
    }
    
    // if error not too large, try some reparmeterization and iteration
    if (maxError < iterationError) {
        for (int i = 0; i < maxIterations; i++) {
            double *uPrime = Reparameterize(d, first, last, u, bezCurve);
            bezCurve = GenerateBezierCurve(d, first, last, uPrime, tHat1, tHat2);
            maxError = ComputeMaxError(d, first, last, bezCurve, uPrime, &splitPoint);
            if (maxError < error) {
                AddBezierSegment(segments, bezCurve, segCount++);
                free(u);
                free(uPrime);
                return segCount;
            }
            free(u);
            u = uPrime;
        }
    }
    
    // fitting failed -- split at max error point and fit recursively
    free(u);
    CGPoint tHatCenter = ComputeCenterTangent(d, splitPoint);
    segCount = FitCubic(segments, d, first, splitPoint, tHat1, tHatCenter, error, segCount);
    tHatCenter = KTMultiplyPointScalar(tHatCenter, -1);
    segCount = FitCubic(segments, d, splitPoint, last, tHatCenter, tHat2, error, segCount);
    
    return segCount;
}

int FitCurve(KTBezierSegment *segments, CGPoint *d, int nPtrs, double error) {
    CGPoint tHat1, tHat2;
    tHat1 = ComputeLeftTangent(d, 0);
    tHat2 = ComputeRightTangent(d, nPtrs - 1);
    return FitCubic(segments, d, 0, nPtrs - 1, tHat1, tHat2, error, 0);
}




@implementation KTCurveFit


+ (KTPath *)smoothPathForPoints:(NSArray *)inPoints error:(float)epsilon attemptToClose:(BOOL)shouldClose {
    
    NSMutableArray *points = inPoints.mutableCopy;
    CGPoint unboxedPts[points.count];
    BOOL closePath = NO;
    int ix = 0;
    
    // transfer the wrapped CGPoints to an unboxed array
    for (NSValue *value in points) {
        unboxedPts[ix++] = [value pointValue];
    }
    
    // see if this path should be closed, and if so, average the first and last points
    if (shouldClose && points.count > 3) {
        CGPoint first = unboxedPts[0];
        CGPoint last = unboxedPts[points.count - 1];
        
        if (KTDistanceL2(first, last) < (epsilon * 2)) {
            closePath = YES;
            unboxedPts[0] = KTAveragePoints(first, last);
            unboxedPts[points.count - 1] = unboxedPts[0];
        }
    }
    
    // do the actual curve fitting
    KTBezierSegment segments[points.count];
    int numSegments = FitCurve(segments, unboxedPts, (int)points.count, epsilon);
    
    return [KTCurveFit pathFromSegments:segments numSegments:numSegments closePath:closePath];
    
}

+ (KTPath *)pathFromSegments:(KTBezierSegment *)segments numSegments:(NSUInteger)numSegments closePath:(BOOL)closePath {
    
    NSMutableArray *nodes = @{}.mutableCopy;
    
    KTBezierNode *node;
    for (int i = 0; i < numSegments; i++) {
        if (i == 0) {
            // need to take the last node's in control handle if we are closed
            node = [KTBezierNode bezierNodeWithInPoint:(closePath ? segments[numSegments - 1].in_ : segments[0].a_)
                                           anchorPoint:segments[0].a_
                                              outPoint:segments[0].out_];
        }
        else {
            node = [KTBezierNode bezierNodeWithInPoint:segments[i - 1].in_ anchorPoint:segments[i].a_ outPoint:segments[i].out_];
        }
        [nodes addObject:node];
        
        if (i == (numSegments - 1) && !closePath) {
            node = [KTBezierNode bezierNodeWithInPoint:segments[i].in_ anchorPoint:segments[i].b_ outPoint:segments[i].b_];
            [nodes addObject:node];
        }
    }
    
    if (nodes.count < 2) {
        return nil;
    }
    
    if (closePath) {
        node = nodes[0];
        
        // fix up the control handles on the start/end node...
        // we want them to be collinear but preserve the original magnitudes
        
        CGPoint outDelta = KTSubtractPoints(node.outPoint, node.anchorPoint);
        CGPoint inDelta = KTSubtractPoints(node.inPoint, node.anchorPoint);
        
        CGPoint newIn = KTAveragePoints(inDelta, KTMultiplyPointScalar(outDelta, -1));
        newIn = KTScaleVector(newIn, KTMagnitudeVector(inDelta));
        
        CGPoint newOut = KTAveragePoints(outDelta, KTMultiplyPointScalar(inDelta, -1));
        newOut = KTScaleVector(newOut, KTMagnitudeVector(outDelta));
        
        nodes[0] = [KTBezierNode bezierNodeWithInPoint:KTAddPoints(node.anchorPoint, newIn)
                                           anchorPoint:node.anchorPoint
                                              outPoint:KTAddPoints(node.anchorPoint, newOut)];
        
    }
    
    KTPath *path = [[KTPath alloc] init];
    path.nodes = nodes;
    path.closed = closePath;
    
    return path;
}


@end
