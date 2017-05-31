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



@interface KTMatteProcessor ()

@property (nonatomic, strong) NSString *foregroundLocalPath;
@property (nonatomic, strong) NSString *alphaLocalPath;

@end

@implementation KTMatteProcessor {
    GCMattor mattor;
    Mat4b srcImageMat;
    Mat4b foregroundMat;
    Mat1b alphaMat;
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
    srcImageMat = [image CVMat2];
    if (mode == MatteModeInitRect) {
        mattor.reset();
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
    }
    
    NSString *cacheName = [self.class createRandomName];
    self.foregroundLocalPath = [NSString stringWithFormat:@"%@%@%@", NSTemporaryDirectory(), cacheName, @"-foreground.png"];
    self.alphaLocalPath = [NSString stringWithFormat:@"%@%@%@", NSTemporaryDirectory(), cacheName, @"-alpha.png"];
    NSImage *foregroundImage= [NSImage imageWithCVMat:foregroundMat];
    [foregroundImage saveToFile:self.foregroundLocalPath];
    NSImage *alphaImage = [NSImage imageWithCVMat:alphaMat];
    [alphaImage saveToFile:self.alphaLocalPath];
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






@end
