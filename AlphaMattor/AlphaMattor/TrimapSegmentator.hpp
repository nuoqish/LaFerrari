//
//  TrimapSegmentator.hpp
//  AlphaMattor
//
//  Created by longyan on 2017/2/23.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#ifndef TrimapSegmentator_hpp
#define TrimapSegmentator_hpp

#include <stdio.h>

#include <opencv2/opencv.hpp>

using namespace std;
using namespace cv;




class TrimapSegmentator {
    
public:
    TrimapSegmentator();
    ~TrimapSegmentator();
    void process(vector<Vec4i>& dstSegRegions, Mat1b& srcTrimap, Mat1b &srcLabelMap);
    Vec4i calcRegionForLabel(Mat1b& srcLabelMap, int label);
    
};


#endif /* TrimapSegmentator_hpp */
