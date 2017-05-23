//
//  AlphaSolver.hpp
//  AlphaMattor
//
//  Created by longyan on 2017/3/23.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#ifndef AlphaSolver_hpp
#define AlphaSolver_hpp

#include <stdio.h>

#include <opencv2/opencv.hpp>
using namespace cv;
using namespace std;

class AlphaSolver {
public:
    static void computeAlpha(Mat1d& dstAlpha, Mat3b& srcImage, Mat1b& srcTrimap, int erodeRadius = 20,
                             int level = 3, int winRadius = 1, float lamda = 1000, double tolerance = 1.e-7, int maxIters = 1000);
    static void computeAlpha(Mat1b& dstAlpha, Mat3b& srcImage, Mat1b& srcTrimap, int erodeRadius = 20,
                             int level = 3, int winRadius = 1, float lamda = 1000, double tolerance = 1.e-7, int maxIters = 1000);
    
    
};


#endif /* AlphaSolver_hpp */
