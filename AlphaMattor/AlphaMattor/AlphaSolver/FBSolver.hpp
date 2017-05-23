//
//  FBSolver.hpp
//  AlphaMattor
//
//  Created by longyan on 2017/3/14.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#ifndef FBSolver_hpp
#define FBSolver_hpp

#include <stdio.h>

#include <opencv2/opencv.hpp>

using namespace std;
using namespace cv;

class FBSolver {
    
public:
    static void computeForeground(Mat4b& dstForegroundAlpha, Mat4b& srcImage, Mat1b& srcAlpha);
    static void computeForeground(Mat4b& dstForegroundAlpha, Mat3b& srcImage, Mat1b& srcAlpha);
    static void computeForeground(Mat4b& dstForegroundAlpha, Mat3d& srcImage, Mat1d& srcAlpha, double tolerance = 1.e-7, int maxIters = 1000);

};



#endif /* FBSolver_hpp */
