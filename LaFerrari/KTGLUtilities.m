//
//  KTGLUtilities.m
//  LaFerrari
//
//  Created by stanshen on 17/6/10.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "KTGLUtilities.h"

#import "KTUtilities.h"


typedef struct {
    GLfloat *vertices;
    NSUInteger size;
    NSUInteger index;
} glPathRenderData;

void renderPathElement(void *info, const CGPathElement *elements);

inline void KTGLFillRect(CGRect rect) {
    
    rect = KTRoundRect(rect);
    
    const GLfloat quadVertices[] = {
        CGRectGetMinX(rect), CGRectGetMinY(rect),
        CGRectGetMaxX(rect), CGRectGetMinY(rect),
        CGRectGetMinX(rect), CGRectGetMaxY(rect),
        CGRectGetMaxX(rect), CGRectGetMaxY(rect)
    };
    
#if TARGET_OS_IPHONE
    glVertexPointer(2, GL_FLOAT, 0, quadVertices);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
#else
    glBegin(GL_QUADS);
    glVertex2d(quadVertices[0], quadVertices[1]);
    glVertex2d(quadVertices[2], quadVertices[3]);
    glVertex2d(quadVertices[6], quadVertices[7]);
    glVertex2d(quadVertices[4], quadVertices[5]);
    glEnd();
#endif
    
}

inline void KTGLStrokeRect(CGRect rect) {
    
    rect = KTRoundRect(rect);
    
    const GLfloat lineVertices[] = {
        CGRectGetMinX(rect), CGRectGetMinY(rect),
        CGRectGetMaxX(rect), CGRectGetMinY(rect),
        
        CGRectGetMinX(rect), CGRectGetMaxY(rect),
        CGRectGetMaxX(rect), CGRectGetMaxY(rect),
        
        CGRectGetMinX(rect), CGRectGetMinY(rect),
        
#if TARGET_OS_IPHONE
        CGRectGetMinX(rect), CGRectGetMaxY(rect) + 1 / [UIScreen mainScreen].scale,
#else
        CGRectGetMinX(rect), CGRectGetMaxY(rect),
#endif
        
        CGRectGetMaxX(rect), CGRectGetMinY(rect),
        CGRectGetMaxX(rect), CGRectGetMaxY(rect)
    };
    
#if TARGET_OS_IPHONE
    glVertexPointer(2, GL_FLOAT, 0, lineVertices);
    glDrawArrays(GL_LINES, 0, 8);
#else
    glBegin(GL_LINES);
    for (int i = 0; i < 8; i++) {
        glVertex2f(lineVertices[i*2], lineVertices[i*2+1]);
    }
    glEnd();
    
#endif

}

inline void KTGLFillCircle(CGPoint center, float radius, int sides) {
    
    GLfloat *vertices = calloc(sizeof(GLfloat), (sides + 1) * 4);
    float step = M_PI * 2 / sides;
    
    for (int i = 0; i <= sides; i++) {
        float angle = i * step;
        vertices[i * 4] = center.x + cos(angle) * radius;
        vertices[i * 4 + 1] = center.y + sin(angle) * radius;
        vertices[i * 4 + 2] = center.x;
        vertices[i * 4 + 3] = center.y;
    }
    
#if TARGET_OS_IPHONE
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (sides+1)*2);
#else
    glBegin(GL_TRIANGLE_STRIP);
    for (int i = 0; i < (sides+1)*4; i+=2) {
        glVertex2f(vertices[i], vertices[i+1]);
    }
    glEnd();
#endif
    
    free(vertices);
}

inline void KTGLStrokeCircle(CGPoint center, float radius, int sides) {
    GLfloat *vertices = calloc(sizeof(GLfloat), (sides + 1) * 2);
    float step = M_PI * 2 / sides;
    
    for (int i = 0; i <= sides; i++) {
        float angle = i * step;
        vertices[i * 2] = center.x + cos(angle) * radius;
        vertices[i * 2 + 1] = center.y + sin(angle) * radius;
    }
    
#if TARGET_OS_IPHONE
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (sides+1)*2);
#else
    glBegin(GL_TRIANGLE_STRIP);
    for (int i = 0; i < (sides+1)*2; i+=2) {
        glVertex2f(vertices[i], vertices[i+1]);
    }
    glEnd();
#endif
    
    free(vertices);
    
}

inline void KTGLFillDiamond(CGPoint center, float dimension)
{
    const GLfloat vertices[] = {
        center.x, center.y + dimension,
        center.x + dimension, center.y,
        center.x, center.y - dimension,
        center.x, center.y + dimension,
        center.x - dimension, center.y
    };
    
#if TARGET_OS_IPHONE
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 5);
#else
    glBegin(GL_TRIANGLE_STRIP);
    for (int i = 0; i < 5; i++) {
        glVertex2f(vertices[i*2], vertices[i*2+1]);
    }
    glEnd();
#endif
}

inline void KTGLLineFromPointToPoint(CGPoint a, CGPoint b) {
    const GLfloat lineVertices[] = {a.x, a.y, b.x, b.y};
    
#if TARGET_OS_IPHONE
    glVertexPointer(2, GL_FLOAT, 0, lineVertices);
    glDrawArrays(GL_LINE_STRIP, 0, 2);
#else
    glBegin(GL_LINE_STRIP);
    glVertex2f(lineVertices[0], lineVertices[1]);
    glVertex2f(lineVertices[2], lineVertices[3]);
    glEnd();
#endif
    
    
}


void KTGLFlattenBezierSegment(KTBezierSegment seg, GLfloat **vertices, NSUInteger *size, NSUInteger *index) {
    
    if ((*size) < (*index) + 4) {
        *size *= 2;
        *vertices = realloc(*vertices, sizeof(GLfloat) * (*size));
    }
    
    if (KTBezierSegmentIsFlat(seg, kDefaultBezierSegmentFlatness)) {
        if (*index == 0) {
            (*vertices)[*index] = seg.a_.x;
            (*vertices)[*index + 1] = seg.a_.y;
            *index += 2;
        }
        
        (*vertices)[*index] = seg.b_.x;
        (*vertices)[*index + 1] = seg.b_.y;
        *index += 2;
    } else {
        KTBezierSegment L, R;
        KTBezierSegmentSplit(seg, &L, &R);
        
        KTGLFlattenBezierSegment(L, vertices, size, index);
        KTGLFlattenBezierSegment(R, vertices, size, index);
    }
    
}


void KTGLRenderBezierSegment(KTBezierSegment seg) {
    static GLfloat      *vertices = NULL;
    static NSUInteger   size = 128;
    NSUInteger          index = 0;
    
    if (!vertices) {
        vertices = calloc(sizeof(GLfloat), size);
    }
    
    KTGLFlattenBezierSegment(seg, &vertices, &size, &index);
    KTGLDrawLineStrip(vertices, index);
}


void renderPathElement(void *info, const CGPathElement *element)
{
    glPathRenderData    *renderData = (glPathRenderData *) info;
    KTBezierSegment     segment;
    CGPoint             inPoint, outPoint;
    static CGPoint      prevPt, moveTo;
    
    switch (element->type) {
        case kCGPathElementMoveToPoint:
            if (renderData->index) {
                // starting a new subpath, so draw the current one
                KTGLDrawLineStrip(renderData->vertices, renderData->index);
                renderData->index = 0;
            }
            
            prevPt = moveTo = element->points[0];
            break;
        case kCGPathElementAddLineToPoint:
            if (renderData->index == 0) {
                // index is 0, so we need to add the original moveTo
                (renderData->vertices)[0] = prevPt.x;
                (renderData->vertices)[1] = prevPt.y;
                renderData->index = 2;
            }
            
            // make sure we're not over-running the buffer
            if (renderData->size < renderData->index + 2) {
                renderData->size *= 2;
                renderData->vertices = realloc(renderData->vertices, sizeof(GLfloat) * renderData->size);
            }
            
            prevPt = element->points[0];
            (renderData->vertices)[renderData->index] = prevPt.x;
            (renderData->vertices)[renderData->index + 1] = prevPt.y;
            renderData->index += 2;
            break;
        case kCGPathElementAddQuadCurveToPoint:
            // convert quadratic to cubic: http://fontforge.sourceforge.net/bezier.html
            outPoint.x = prevPt.x + (element->points[0].x - prevPt.x) * (2.0f / 3);
            outPoint.y = prevPt.y + (element->points[0].y - prevPt.y) * (2.0f / 3);
            
            inPoint.x = element->points[1].x + (element->points[0].x - element->points[1].x) * (2.0f / 3);
            inPoint.y = element->points[1].y + (element->points[0].y - element->points[1].y) * (2.0f / 3);
            
            segment.a_ = prevPt;
            segment.out_ = outPoint;
            segment.in_ = inPoint;
            segment.b_ = element->points[1];
            
            KTGLFlattenBezierSegment(segment, &(renderData->vertices), &(renderData->size), &(renderData->index));
            prevPt = element->points[1];
            break;
        case kCGPathElementAddCurveToPoint:
            segment.a_ = prevPt;
            segment.out_ = element->points[0];
            segment.in_ = element->points[1];
            segment.b_ = element->points[2];
            
            KTGLFlattenBezierSegment(segment, &(renderData->vertices), &(renderData->size), &(renderData->index));
            prevPt = element->points[2];
            break;
        case kCGPathElementCloseSubpath:
            // make sure we're not over-running the buffer
            if (renderData->size < renderData->index + 2) {
                renderData->size *= 2;
                renderData->vertices = realloc(renderData->vertices, sizeof(GLfloat) * renderData->size);
            }
            
            (renderData->vertices)[renderData->index] = moveTo.x;
            (renderData->vertices)[renderData->index + 1] = moveTo.y;
            renderData->index += 2;
            break;
    }
}

void KTGLRenderCGPathRef(CGPathRef pathRef) {
    static glPathRenderData renderData = { NULL, 128, 0 };
    
    if (renderData.vertices == NULL) {
        renderData.vertices = calloc(sizeof(GLfloat), renderData.size);
    }
    
    renderData.index = 0;
    CGPathApply(pathRef, &renderData, &renderPathElement);
    
    KTGLDrawLineStrip(renderData.vertices, renderData.index);
}

void KTGLDrawLineStrip(GLfloat *vertices, NSUInteger count) {
#if TARGET_OS_IPHONE
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glDrawArrays(GL_LINE_STRIP, 0, (int) count / 2);
#else
    glBegin(GL_LINE_STRIP);
    for (int i = 0; i < count; i+=2) {
        glVertex2d(vertices[i], vertices[i+1]);
    }
    glEnd();
#endif
}


void KTCGDrawLineFromPointToPoint(CGContextRef ctx, CGPoint a, CGPoint b, CGFloat red, CGFloat green, CGFloat blue, CGFloat alpha) {
    
    CGContextSaveGState(ctx);
    
    CGContextSetRGBStrokeColor(ctx, red, green, blue, alpha);
    CGContextSetLineWidth(ctx, 1);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, a.x, a.y);
    CGPathAddLineToPoint(path, NULL, b.x, b.y);
    CGPathCloseSubpath(path);
    
    CGContextAddPath(ctx, path);
    CGContextStrokePath(ctx);
    
    CGContextRestoreGState(ctx);
}

void KTCGDrawRect(CGContextRef ctx, CGRect dest) {
    CGContextSaveGState(ctx);
    
    CGContextSetGrayFillColor(ctx, 1.0, 1.0);
    CGContextFillRect(ctx, dest);
    
    CGContextSetGrayFillColor(ctx, 0.5, 1.0);
    CGContextStrokeRect(ctx, dest);
    
    CGContextRestoreGState(ctx);
}

void KTCGDrawCircle(CGContextRef ctx, CGRect dest) {
    
    CGContextSaveGState(ctx);
    
    CGContextSetGrayFillColor(ctx, 0.5, 1.0);
    CGContextFillEllipseInRect(ctx, dest);

    CGContextRestoreGState(ctx);
}


void KTCGDrawBrushWithPoints(CGContextRef ctx, NSArray *points, CGFloat brushWidth) {
    
    CGFloat red = 1.0, green = 1., blue = 1., alpha = 1.0;
    CGContextSetRGBStrokeColor(ctx, red, green, blue, alpha);
    CGContextSetLineWidth(ctx, brushWidth);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);
    NSPoint point = [[points objectAtIndex:0] pointValue];
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, point.x, point.y);
    for (NSUInteger i = 1; i < points.count; i++) {
        point = [[points objectAtIndex:i] pointValue];
        CGContextAddLineToPoint(ctx, point.x, point.y);
    }
    CGContextDrawPath(ctx, kCGPathStroke);
    
}

void KTCGDrawTransparencyDiamondInRect(CGContextRef ctx, CGRect dest) {
    float minX = CGRectGetMinX(dest);
    float maxX = CGRectGetMaxX(dest);
    float minY = CGRectGetMinY(dest);
    float maxY = CGRectGetMaxY(dest);
    
    // preserve the existing color
    CGContextSaveGState(ctx);
    [[NSColor whiteColor] set];
    CGContextFillRect(ctx, dest);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, minX, minY);
    CGPathAddLineToPoint(path, NULL, maxX, minY);
    CGPathAddLineToPoint(path, NULL, minX, maxY);
    CGPathCloseSubpath(path);
    
    [[NSColor blackColor] set];
    CGContextAddPath(ctx, path);
    CGContextFillPath(ctx);
    CGContextRestoreGState(ctx);
    
    CGPathRelease(path);
}


void KTCGDrawCheckersInRect(CGContextRef ctx, CGRect dest, int size) {
    CGRect  square = CGRectMake(0, 0, size, size);
    float   startx = CGRectGetMinX(dest);
    float   starty = CGRectGetMinY(dest);
    
    CGContextSaveGState(ctx);
    CGContextClipToRect(ctx, dest);
    
    CGContextSetGrayFillColor(ctx, 0.9f, 1.0f);
    CGContextFillRect(ctx, dest);
    
    CGContextSetGrayFillColor(ctx, 0.78f, 1.0f);
    for (int y = 0; y * size < CGRectGetHeight(dest); y++) {
        for (int x = 0; x * size < CGRectGetWidth(dest); x++) {
            if ((y + x) % 2) {
                square.origin.x = startx + x * size;
                square.origin.y = starty + y * size;
                CGContextFillRect(ctx, square);
            }
        }
    }
    
    CGContextRestoreGState(ctx);
}

typedef struct {
    CGMutablePathRef mutablePath;
    CGAffineTransform transform;
} KTPathAndTransform;

void transformPathElement(void *info, const CGPathElement *element)
{
    KTPathAndTransform  pathAndTransform = *((KTPathAndTransform *) info);
    CGAffineTransform   transform = pathAndTransform.transform;
    CGMutablePathRef    pathRef = pathAndTransform.mutablePath;
    
    switch (element->type) {
        case kCGPathElementMoveToPoint:
            CGPathMoveToPoint(pathRef, &transform, element->points[0].x, element->points[0].y);
            break;
        case kCGPathElementAddLineToPoint:
            CGPathAddLineToPoint(pathRef, &transform, element->points[0].x, element->points[0].y);
            break;
        case kCGPathElementAddQuadCurveToPoint:
            CGPathAddQuadCurveToPoint(pathRef, &transform, element->points[0].x, element->points[0].y, element->points[1].x, element->points[1].y);
            break;
        case kCGPathElementAddCurveToPoint:
            CGPathAddCurveToPoint(pathRef, &transform, element->points[0].x, element->points[0].y, element->points[1].x, element->points[1].y, element->points[2].x, element->points[2].y);
            break;
        case kCGPathElementCloseSubpath:
            CGPathCloseSubpath(pathRef);
            break;
            
    }
}

CGPathRef KTCreateTransformedCGPathRef(CGPathRef pathRef, CGAffineTransform transform) {
    
    CGMutablePathRef    transformedPath = CGPathCreateMutable();
    KTPathAndTransform  pathAndTransform = {transformedPath, transform};
    
    CGPathApply(pathRef, &pathAndTransform, &transformPathElement);
    
    return transformedPath;
}






















































