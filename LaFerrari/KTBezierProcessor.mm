//
//  KTBezierProcessor.m
//  LaFerrari
//
//  Created by stanshen on 17/6/29.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <opencv2/opencv.hpp>

#import "KTBezierProcessor.h"

#import "KTBezierNode.h"
#import "KTCurveFit.h"
#import "NSImage+Utils.h"

using namespace cv;

@implementation KTBezierProcessor

+ (NSArray<NSArray<KTBezierNode *> *> *)processImage:(NSImage *)image {
    
    Mat1b gray = [image CVGrayscaleMat];
    float maxError = 10;
    int thresh = 127;
    Mat binaryOut;
    
    threshold(gray, binaryOut, thresh, 255, THRESH_BINARY_INV + THRESH_OTSU);

    vector<vector<Point2i> > contours;
    vector<Vec4i> hierarchy;
    findContours(binaryOut, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, Point2i(0,0));
    NSMutableArray *result = @[].mutableCopy;
    for (int idx = 0; idx < contours.size(); idx++) {
        vector<Point2i> contour = contours[idx];
        NSMutableArray *points = @[].mutableCopy;
        for (int i = 0; i < contour.size(); i++) {
            [points addObject:[NSValue valueWithPoint:NSMakePoint(contour[i].x, gray.rows - contour[i].y)]];
        }
        NSArray<KTBezierNode *> *path = [KTCurveFit bezierNodesFromPoints:points error:maxError attempToClose:YES];
        if (path && path.count > 4) {
            [result addObject:path];
        }
        
    }
    
    return result;

    
}

@end
