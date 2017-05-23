//
//  main.cpp
//  AlphaMatting
//

#include <iostream>
#include <string>
#include <time.h>
#include <stdio.h>

#include "AlphaSolver.hpp"

using namespace cv;
using namespace std;


#define DEBUG 1


int main(int argc, const char * argv[]) {
    
#if DEBUG
    
    std::string dir = "./testImage/";

    std::string inMap = dir + "15465-600-1400-1600-2000.png";
    std::string triMap = dir + "15465-trimap-600-1400-1600-2000.png";
    std::string alphaMap = dir + "15465-alpha-600-1400-1600-2000-as.png";
    

    Mat3b image = cv::imread(inMap,cv::IMREAD_COLOR);
    Mat1b trimap = cv::imread(triMap,cv::IMREAD_GRAYSCALE);
    Mat1d alpha;
    AlphaSolver::computeAlpha(alpha, image, trimap, 0,2);
    
    imwrite(alphaMap, alpha * 255);
    
    return 0;
    
#else
    
    if (argc == 1) {
        printf("使用方法: AlphaSolver -inputImage inputImagePath -inputTrimap inputTrimapPath -inputER inputER -inputLevel inputLevel -outputAlpha outputAlphaPath");
        return -1;
    }
    
    map<string, string> cmdParser;
    for (int i = 1; i < argc - 1; i += 2) {
        cmdParser[argv[i]] = argv[i + 1];
    }
    
    
    Mat3b image = cv::imread(cmdParser["-inputImage"],cv::IMREAD_COLOR);
    Mat1b trimap = cv::imread(cmdParser["-inputTrimap"],cv::IMREAD_GRAYSCALE);

    if (image.rows == 0 ) {
        printf("错误: 找不到输入图片： %s\n", cmdParser["-inputImage"].c_str());
        return -1;
    }
    if (trimap.rows == 0 ) {
        printf("错误: 找不到输入三值图： %s\n", cmdParser["-inputTrimap"].c_str());
        return -1;
    }
    
    int erodeTrimapRadius = atoi(cmdParser["-inputER"].c_str());
    int inputLevel = atoi(cmdParser["-inputLevel"].c_str());

    Mat1d alpha;
    AlphaSolver::computeAlpha(alpha, image, trimap, erodeTrimapRadius, inputLevel);

    if (cmdParser.find("-outputAlpha") != cmdParser.end()) {
        printf("outputAlpha:%s\n", cmdParser["-outputAlpha"].c_str());
        imwrite(cmdParser["-outputAlpha"], alpha * 255);
    }
    
    return 0;
    
#endif
}
