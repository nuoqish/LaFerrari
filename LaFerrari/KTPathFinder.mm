//
//  KTPathFinder.m
//  LaFerrari
//
//  Created by stanshen on 17/6/11.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTPathFinder.h"

#include "Path.h"
#include "Shape.h"

#import "KTBezierNode.h"
#import "KTPath.h"
#import "KTCompoundPath.h"
#import "KTUtilities.h"


@interface KTPath (Livarot)
- (Path *)convertToLivarotPath;
@end


@implementation KTPathFinder

+ (KTAbstractPath *)combinePaths:(NSArray *)abstractPaths operation:(KTPathFinderOperation)operation {
    int     pathCount = 0;
    
    for (KTAbstractPath *ap in abstractPaths) {
        pathCount += [ap subpathCount];
    }
    
    Path   *paths[pathCount];
    Shape  *temp = new Shape();
    Shape   *shapes[pathCount];
    Shape   *result = NULL;
    int     i = 0, shapeIx = 0;
    
    for (KTAbstractPath *ap in abstractPaths) {
        if (ap.subpathCount == 1) {
            paths[i] = [((KTPath *) ap) convertToLivarotPath];
            
            temp->Reset();
            paths[i]->Fill(temp, i);
            shapes[shapeIx] = new Shape();
            shapes[shapeIx]->ConvertToShape(temp, fill_nonZero);
            i++;
            shapeIx++;
            
        } else {
            KTCompoundPath *cp = (KTCompoundPath *) ap;
            
            temp->Reset();
            
            for (KTPath *sp in cp.subpaths) {
                paths[i] = [sp convertToLivarotPath];
                paths[i]->Fill(temp, i, true);
                i++;
            }
            
            shapes[shapeIx] = new Shape();
            shapes[shapeIx]->ConvertToShape(temp, fill_nonZero);
            
            shapeIx++;
        }
    }
    
    Shape *prev = shapes[0];
    for (int i = 1; i < shapeIx; i++) {
        result = new Shape();
        result->Booleen(prev, shapes[i], (BooleanOp) operation);
        
        if (i != 1) {
            delete prev;
        }
        prev = result;
    }
    
    Path *dest = new Path();
    result->ConvertToForme(dest, pathCount, paths);
    KTAbstractPath *finalResult = [KTPathFinder fromLivarotPath:dest];
    delete dest;
    delete result;
    
    for (i = 0; i < shapeIx; i++) {
        delete shapes[i];
    }
    for (i = 0; i < pathCount; i++) {
        delete paths[i];
    }
    delete temp;
    
    return finalResult;

}

+ (KTAbstractPath *) fromLivarotPath:(Path *)path
{
    NSMutableArray  *subpaths = [NSMutableArray array];
    KTPath          *currentPath = [[KTPath alloc] init];
    NSMutableArray  *nodes = [NSMutableArray array];
    
    for (int i = 0; i <path->descr_nb; i++) {
        int ty=(path->descr_data+i)->flags&descr_type_mask;
        if ( ty == descr_moveto ) {
            [nodes addObject:[KTBezierNode bezierNodeWithAnchorPoint:CGPointMake((path->descr_data+i)->d.m.x,(path->descr_data+i)->d.m.y)]];
        } else if ( ty == descr_lineto ) {
            [nodes addObject:[KTBezierNode bezierNodeWithAnchorPoint:CGPointMake((path->descr_data+i)->d.l.x,(path->descr_data+i)->d.l.y)]];
        } else if ( ty == descr_cubicto ) {
            KTBezierNode *lastObject = [nodes lastObject];
            [nodes removeLastObject];
            
            CGPoint outPoint = CGPointMake((path->descr_data+i)->d.c.stDx,(path->descr_data+i)->d.c.stDy);
            outPoint = KTMultiplyPointScalar(outPoint, (1.0f / 3));
            [nodes addObject:[KTBezierNode bezierNodeWithInPoint:lastObject.inPoint
                                                     anchorPoint:lastObject.anchorPoint
                                                        outPoint:KTAddPoints(lastObject.anchorPoint, outPoint)]];
            
            CGPoint anchorPoint = CGPointMake((path->descr_data+i)->d.c.x,(path->descr_data+i)->d.c.y);
            CGPoint inPoint = CGPointMake((path->descr_data+i)->d.c.enDx,(path->descr_data+i)->d.c.enDy);
            inPoint = KTMultiplyPointScalar(inPoint, (1.0f / -3));
            [nodes addObject:[KTBezierNode bezierNodeWithInPoint:KTAddPoints(anchorPoint, inPoint)
                                                     anchorPoint:anchorPoint
                                                        outPoint:anchorPoint]];
        } else if ( ty == descr_close ) {
            currentPath.nodes = nodes;
            currentPath.closed = YES;
            nodes = [NSMutableArray array];
            
            [subpaths addObject:currentPath];
            currentPath = [[KTPath alloc] init];
        }
    }
    
    
    if (subpaths.count > 1) {
        KTCompoundPath  *compoundPath = [[KTCompoundPath alloc] init];
        compoundPath.subpaths = subpaths;
        return compoundPath;
    } else {
        return [subpaths lastObject];
    }
}


@end

@implementation KTPath (Livarot)

- (Path *)convertToLivarotPath {
    NSArray         *nodes = self.reversed ? [self reversedNodes] : self.nodes;
    KTBezierNode    *node;
    NSInteger       numNodes = self.closed ? nodes.count + 1 : nodes.count;
    CGPoint         pt, prev_pt, in_pt, prev_out;
    
    Path* thePath=new Path();
    
    for(int i = 0; i < numNodes; i++) {
        node = nodes[(i % nodes.count)];
        
        if (i == 0) {
            pt = node.anchorPoint;
            thePath->MoveTo(pt.x, pt.y);
        } else {
            pt = node.anchorPoint;
            in_pt = node.inPoint;
            
            if (prev_pt.x == prev_out.x && prev_pt.y == prev_out.y && in_pt.x == pt.x && in_pt.y == pt.y) {
                thePath->LineTo(pt.x, pt.y);
            } else {
                prev_out = KTMultiplyPointScalar(KTSubtractPoints(prev_out, prev_pt), 3);
                in_pt = KTMultiplyPointScalar(KTSubtractPoints(in_pt, pt), -3);
                
                thePath->CubicTo(pt.x, pt.y, prev_out.x, prev_out.y, in_pt.x, in_pt.y);
            }
        }
        
        prev_out = node.outPoint;
        prev_pt = pt;
    }
    
    if (self.closed) {
        thePath->Close();
    }
    
    thePath->ConvertWithBackData(1);
    
    return thePath;
}

@end
