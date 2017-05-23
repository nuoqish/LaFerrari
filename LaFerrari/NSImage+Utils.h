//
//  NSImage+Utils.h
//  MoguMattor
//
//  Created by longyan on 2017/1/3.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <opencv2/core.hpp>

@interface NSImage (Utils)

- (NSImage *)resizeTo:(NSSize)newSize;
- (void)saveToFile:(NSString *)filepath;

+(NSImage*)imageWithCVMat:(const cv::Mat&)cvMat;
-(id)initWithCVMat:(const cv::Mat&)cvMat;

@property(nonatomic, readonly) cv::Mat CVMat;
@property(nonatomic, readonly) cv::Mat CVMat2;
@property(nonatomic, readonly) cv::Mat CVGrayscaleMat;




@end
