//
//  KTGLUtilities.h
//  LaFerrari
//
//  Created by stanshen on 17/6/10.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#else
#import <OpenGL/gl.h>
#endif

#import "KTBezierSegment.h"

void KTGLFillRect(CGRect rect);
void KTGLStrokeRect(CGRect rect);
void KTGLFillCircle(CGPoint center, float radius, int sides);
void KTGLStrokeCircle(CGPoint center, float radius, int sides);
void KTGLLineFromPointToPoint(CGPoint a, CGPoint b);
void KTGLFillDiamond(CGPoint center, float dimension);

void KTGLFlattenBezierSegment(KTBezierSegment seg, GLfloat **vertices, NSUInteger *size, NSUInteger *index);
void KTGLRenderBezierSegment(KTBezierSegment seg);
void KTGLRenderCGPathRef(CGPathRef pathRef);

void KTGLDrawLineStrip(GLfloat *vertices, NSUInteger count);

void KTCGDrawLineFromPointToPoint(CGContextRef ctx, CGPoint a, CGPoint b, CGFloat red, CGFloat green, CGFloat blue, CGFloat alpha);
void KTCGDrawRect(CGContextRef ctx, CGRect dest);
void KTCGDrawCircle(CGContextRef ctx, CGRect dest);

void KTCGDrawCheckersInRect(CGContextRef ctx, CGRect dest, int size);
void KTCGDrawTransparencyDiamondInRect(CGContextRef ctx, CGRect dest);
void KTCGDrawImageToFill(CGContextRef ctx, CGRect bounds, CGImageRef imageRef);
void KTCGDrawBrushWithPoints(CGContextRef ctx, NSArray *points, CGFloat brushWidth);
void KTCGDrawTransparencyDiamondInRect(CGContextRef ctx, CGRect dest);


CGPathRef KTCreateTransformedCGPathRef(CGPathRef pathRef, CGAffineTransform transform);
