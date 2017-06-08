//
//  KTMatteProcessor.m
//  LaFerrari
//
//  Created by stanshen on 17/5/27.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTMatteProcessor.h"
#import "NSImage+Utils.h"
#include "GCMattor.hpp"
#include "AlphaSolver.hpp"

@implementation KTMatteProcessor {
    GCMattor mattor;
    Mat4b srcImageMat;
    Mat4b foregroundMat;
    Mat1b alphaMat;
    Mat4b foregroundMatLast;
    Mat1b alphaMatLast;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

+ (NSString *)createRandomName
{
    NSTimeInterval timeStamp = [ [ NSDate date ] timeIntervalSince1970 ];
    NSString *randomName = [ NSString stringWithFormat:@"M%f", timeStamp];
    randomName = [ randomName stringByReplacingOccurrencesOfString:@"." withString:@"" ];
    return randomName;
}

- (void)processImage:(NSImage *)image andMode:(MatteMode)mode andRadius:(int)radius {
    
    [self saveToCacheIfNeeded];
    
    srcImageMat = [image CVMat2];
    if (mode == MatteModeInitRect) {
        mattor.process(foregroundMat, alphaMat, srcImageMat, radius, GC_INIT_WITH_RECT);
    }
    else if (mode == MatteModeInitMask) {
        mattor.process(foregroundMat, alphaMat, srcImageMat, radius, GC_INIT_WITH_MASK);
    }
    else if (mode == MatteModeEVal) {
        mattor.process(foregroundMat, alphaMat, srcImageMat, radius, GC_EVAL);
    }
    else if (mode == MatteModeCF) {
        Mat3b image2;
        cv::cvtColor(srcImageMat, image2, cv::COLOR_RGBA2RGB);
        AlphaSolver::computeAlpha(alphaMat, image2, alphaMat);
        
        for (int i = 0; i < alphaMat.rows; i++) {
            for (int j = 0; j < alphaMat.cols; j++) {
                uint8_t alpha = alphaMat(i,j);
                if (alpha > 250) {
                    foregroundMat(i,j) = srcImageMat(i,j);
                }
                else if (alpha < 5) {
                    foregroundMat(i,j)[3] = 0;
                }
                else {
                    double _alpha = alpha / 255.;
                    foregroundMat(i,j)[0] = uint8_t(srcImageMat(i,j)[0] * _alpha);
                    foregroundMat(i,j)[1] = uint8_t(srcImageMat(i,j)[1] * _alpha);
                    foregroundMat(i,j)[2] = uint8_t(srcImageMat(i,j)[2] * _alpha);
                    foregroundMat(i,j)[3] = alpha;
                }
            }
        }
        
    }
}

- (void)processImageWithUrl:(NSURL *)imageUrl andMode:(MatteMode)mode andRadius:(int)radius{
    NSImage *srcImage = [[NSImage alloc] initWithContentsOfURL:imageUrl];
    
    [self processImage:srcImage andMode:mode andRadius:radius];
}

- (void)setCropRect:(CGRect)cropRect {
    cv::Rect_<int> rect = Rect_<int>(int(cropRect.origin.x * srcImageMat.cols),
                                     int((1. - cropRect.origin.y - cropRect.size.height) * srcImageMat.rows),
                                     int(cropRect.size.width * srcImageMat.cols),
                                     int(cropRect.size.height * srcImageMat.rows));
    mattor.setCropRect(rect);

    
}

- (CGRect)cropRect {
    
    cv::Rect croprect = mattor.getCropRect();
    CGRect rect = CGRectMake((CGFloat)croprect.x / srcImageMat.cols,
                          1. - (CGFloat)(croprect.y + croprect.height) / srcImageMat.rows,
                          (CGFloat)croprect.width / srcImageMat.cols,
                          (CGFloat)croprect.height / srcImageMat.rows);
    
    return rect;
}

- (BOOL)completed {
    return mattor.isFinished();
}

- (void)updateMaskWithImage:(NSImage *)drawImage andPixelMode:(PixelMode)pixelMode {
    
    Mat1b drawMat = [drawImage CVGrayscaleMat];
    
    if (pixelMode == PixelModeForeground) {
        for (int i = 0; i < drawMat.rows; i++) {
            for (int j = 0; j < drawMat.cols; j++) {
                uint8 value = drawMat(i,j);
                if (value >= 127) {
                    mattor.setValue(i, j, GC_PR_FGD);
                }
            }
        }
    }
    else if (pixelMode == PixelModeBackground) {
        for (int i = 0; i < drawMat.rows; i++) {
            for (int j = 0; j < drawMat.cols; j++) {
                uint8 value = drawMat(i,j);
                if (value >= 127) {
                    mattor.setValue(i, j, GC_BGD);
                }
            }
        }
    }
    
}


- (void)updateForegroundAndAlphaWithImage:(NSImage *)drawImage andPixelMode:(PixelMode)pixelMode{
    
    [self saveToCacheIfNeeded];
    
    Mat1b drawMat = [drawImage CVGrayscaleMat];
    if (pixelMode == PixelModeForeground) {
        for (int i = 0; i < drawMat.rows; i++) {
            for (int j = 0; j < drawMat.cols; j++) {
                uint8_t value = drawMat(i, j);
                if (value >= 127) {
                    foregroundMat(i, j) = srcImageMat(i, j);
                    alphaMat(i, j) = 255;
                }
            }
        }

    }
    else if (pixelMode == PixelModeBackground) {
        for (int i = 0; i < drawMat.rows; i++) {
            for (int j = 0; j < drawMat.cols; j++) {
                uint8_t value = drawMat(i, j);
                if (value >= 127) {
                    foregroundMat(i, j)[3] = 0;
                    alphaMat(i, j) = 0;
                }
            }
        }

    }
    else if (pixelMode == PixelModeUnknown) {
        for (int i = 0; i < drawMat.rows; i++) {
            for (int j = 0; j < drawMat.cols; j++) {
                uint8_t value = drawMat(i, j);
                if (value >= 127) {
                    foregroundMat(i, j) = srcImageMat(i, j);
                    alphaMat(i, j) = 127;
                }
            }
        }
    }
    
}


- (NSImage *)foregroundImage {
    if (foregroundMat.cols == 0 || foregroundMat.cols == 0) {
        return nil;
    }
    return [NSImage imageWithCVMat:foregroundMat];
}

- (NSImage *)alphaImage {
    if (alphaMat.cols == 0 || alphaMat.rows == 0) {
        return nil;
    }
    return [NSImage imageWithCVMat:alphaMat];
}

- (void)reset {
    mattor.reset();
    srcImageMat = Mat4b(0,0);
    foregroundMat = Mat4b(0,0);
    alphaMat = Mat1b(0,0);
    foregroundMatLast = Mat4b(0,0);
    alphaMatLast = Mat1b(0,0);
    
}

- (void)saveToCacheIfNeeded {
    if (foregroundMat.rows > 0 && foregroundMat.cols > 0) {
        foregroundMat.copyTo(foregroundMatLast);
    }
    if (alphaMat.rows > 0 && alphaMat.cols > 0) {
        alphaMat.copyTo(alphaMatLast);
    }

}

- (void)undo {
    if (foregroundMatLast.rows > 0 && foregroundMatLast.cols > 0) {
        foregroundMatLast.copyTo(foregroundMat);
    }
    if (alphaMatLast.rows > 0 && alphaMatLast.cols > 0) {
        alphaMatLast.copyTo(alphaMat);
    }
}

@end
