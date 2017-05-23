//
//  SSMattor.hpp
//  AlphaMattor
//
//  Created by longyan on 2017/4/24.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#ifndef SSMattor_hpp
#define SSMattor_hpp

#include <stdio.h>

#include <opencv2/opencv.hpp>

using namespace std;
using namespace cv;


class SSMattor {
    
public:
    static void solveAlphaAndForeground(cv::Mat1b& dstAlpha, cv::Mat4b& dstForegroundAlpha,
                                 const cv::Mat3b& srcImage, const cv::Mat1b& srcTrimap,
                                 unsigned int kT = 0,
                                 int kI = 10, double kC = 5.0, double kG = 4);

    static bool stopFlag;
    
private:
    static void _expansionOfKnownRegions(Mat1b& dstTrimap, vector<Point2i>& uT, const Mat1b& srcTrimap, const Mat3b& srcImage, const int kT = 0, const int kI = 10, const double kC = 4.0);
    static void _sampleAndGatherFB(vector<struct Tuple>& tuples, Mat1i& unknownIndex,
                            vector<Point2i>& uT,
                            const Mat3b& srcImage, const Mat1b& srcTrimap,
                            const int kG = 4);
    static void _refineSample(vector<struct Ftuple>& ftuples,
                       const Mat3b& srcImage, const Mat1b& srcTrimap,
                       vector<Point2i> &uT, vector<struct Tuple>& tuples, Mat1i& unknownIndex,
                       const int radius = 5);
    static void _localSmooth(Mat1b& dstAlpha, Mat4b& dstForeground, const Mat3b& srcImage, const Mat1b& srcTrimap, vector<Point2i>& uT, vector<struct Ftuple>& ftuples, Mat1i& unknownIndex, double m = 100.0);
    
    
};



#endif /* SSMattor_hpp */
