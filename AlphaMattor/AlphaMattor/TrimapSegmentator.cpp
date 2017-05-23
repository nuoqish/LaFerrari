//
//  TrimapSegmentator.cpp
//  AlphaMattor
//
//  Created by longyan on 2017/2/23.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#include "TrimapSegmentator.hpp"

TrimapSegmentator::TrimapSegmentator() {
    
}

TrimapSegmentator::~TrimapSegmentator() {
    
}


Vec4i TrimapSegmentator::calcRegionForLabel(Mat1b &srcLabelMap, int label) {
    int rows = srcLabelMap.rows;
    int cols = srcLabelMap.cols;
    Vec4i rect(rows - 1, cols - 1, 0 , 0);
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            if (srcLabelMap(i, j) == label) {
                if (i < rect[0]) {
                    rect[0] = i;
                }
                else if (i > rect[2]) {
                    rect[2] = i;
                }
                if (j < rect[1]) {
                    rect[1] = j;
                }
                else if (j > rect[3]) {
                    rect[3] = j;
                }
            }
        }
    }
    return rect;
}

void TrimapSegmentator::process(vector<Vec4i>& dstSegRegions, Mat1b& srcTrimap, Mat1b &srcLabelMap) {
    map<int, int> labelMap;
    int rows = srcLabelMap.rows;
    int cols = srcLabelMap.cols;
    for (int i = 0, idx = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            int label = srcLabelMap(i, j);
            if (label != 0) {
                if (labelMap.find(label) == labelMap.end()) {
                    dstSegRegions.push_back(Vec4i(i, j, i, j));
                    labelMap.insert(make_pair(label, idx));
                    idx++;
                }
                else {
                    Vec4i rect = dstSegRegions[labelMap[label]];
                    if (i < rect[0]) {
                        rect[0] = i;
                    }
                    else if (i > rect[2]) {
                        rect[2] = i;
                    }
                    if (j < rect[1]) {
                        rect[1] = j;
                    }
                    else if (j > rect[3]) {
                        rect[3] = j;
                    }
                    dstSegRegions[labelMap[label]] = rect;
                }
            }
        }
    }

}

