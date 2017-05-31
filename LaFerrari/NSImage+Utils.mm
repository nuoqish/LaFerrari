//
//  NSImage+Utils.m
//  MoguMattor
//
//  Created by longyan on 2017/1/3.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#import "NSImage+Utils.h"


static void ProviderReleaseDataNOP(void *info, const void *data, size_t size)
{
    return;
}


@implementation NSImage (Utils)

- (NSImage *)resizeTo:(NSSize)newSize {
    
    // Report an error if the source isn't a valid image
    if (![self isValid]){
        NSLog(@"Invalid Image");
    } else {
        NSImage *smallImage = [[NSImage alloc] initWithSize: newSize];
        [smallImage lockFocus];
        [self setSize: newSize];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        [self drawAtPoint:NSZeroPoint fromRect:CGRectMake(0, 0, newSize.width, newSize.height) operation:NSCompositeCopy fraction:1.0];
        [smallImage unlockFocus];
        return smallImage;
    }
    return nil;
}

- (void)saveToFile:(NSString *)filePath {
    
    NSData *imageData = [self TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    imageData = [imageRep representationUsingType:NSPNGFileType properties:imageProps];
    [imageData writeToFile:filePath atomically:NO];
    
}


-(CGImageRef)CGImage
{
    CGContextRef bitmapCtx = CGBitmapContextCreate(NULL/*data - pass NULL to let CG allocate the memory*/,
                                                   [self size].width,
                                                   [self size].height,
                                                   8 /*bitsPerComponent*/,
                                                   0 /*bytesPerRow - CG will calculate it for you if it's allocating the data.  This might get padded out a bit for better alignment*/,
                                                   [[NSColorSpace genericRGBColorSpace] CGColorSpace],
                                                   kCGBitmapByteOrder32Host|kCGImageAlphaPremultipliedFirst);
    
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:bitmapCtx flipped:NO]];
    [self drawInRect:NSMakeRect(0,0, [self size].width, [self size].height) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
    [NSGraphicsContext restoreGraphicsState];
    
    CGImageRef cgImage = CGBitmapContextCreateImage(bitmapCtx);
    CGContextRelease(bitmapCtx);
    
    return cgImage;
}

-(cv::Mat)CVMat
{
    CGImageRef imageRef = [self CGImage];
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
    CGFloat cols = self.size.width;
    CGFloat rows = self.size.height;
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    memset(cvMat.data, 0, cvMat.total() * cvMat.elemSize());
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to backing data
                                                    cols,                      // Width of bitmap
                                                    rows,                     // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), imageRef);
    CGContextRelease(contextRef);
    CGImageRelease(imageRef);
    return cvMat;
}

-(cv::Mat)CVMat2
{
    CGImageRef imageRef = [self CGImageForProposedRect:NULL context:nil hints:nil];
    // https://stackoverflow.com/questions/28519274/ios-unsupported-color-space-error
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();//CGImageGetColorSpace(imageRef);
    CGFloat cols = CGImageGetWidth(imageRef);
    CGFloat rows = CGImageGetHeight(imageRef);
    cv::Mat4b cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    memset(cvMat.data, 0, cvMat.total() * cvMat.elemSize());
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to backing data
                                                    cols,                      // Width of bitmap
                                                    rows,                     // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaPremultipliedLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), imageRef);
    CGContextRelease(contextRef);
    //CGImageRelease(imageRef);
    
    return cvMat;
}

-(cv::Mat)CVGrayscaleMat
{
    CGImageRef imageRef = [self CGImage];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGFloat cols = self.size.width;
    CGFloat rows = self.size.height;
    cv::Mat cvMat = cv::Mat(rows, cols, CV_8UC1); // 8 bits per component, 1 channel
    memset(cvMat.data, 0, cvMat.total() * cvMat.elemSize());
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to backing data
                                                    cols,                      // Width of bitmap
                                                    rows,                     // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNone |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), imageRef);
    
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(imageRef);
    
    
    
    return cvMat;
}


+ (NSImage *)imageWithCVMat:(const cv::Mat&)cvMat
{
    return [[NSImage alloc] initWithCVMat:cvMat];
}

- (id)initWithCVMat:(const cv::Mat&)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize() * cvMat.total()];
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
    
    CGColorSpaceRef colorSpace;
    CGImageRef imageRef;
    if (cvMat.elemSize() == 1)
    {
        colorSpace = CGColorSpaceCreateDeviceGray();
        imageRef = CGImageCreate(cvMat.cols,                                     // Width
                                 cvMat.rows,                                     // Height
                                 8,                                              // Bits per component
                                 8 * cvMat.elemSize(),                           // Bits per pixel
                                 cvMat.step[0],                                  // Bytes per row
                                 colorSpace,                                     // Colorspace
                                 kCGImageAlphaNone | kCGBitmapByteOrderDefault,  // Bitmap info flags
                                 provider,                                       // CGDataProviderRef
                                 NULL,                                           // Decode
                                 false,                                          // Should interpolate
                                 kCGRenderingIntentDefault);                     // Intent
        

    }
    else
    {
        colorSpace = CGColorSpaceCreateDeviceRGB();
        imageRef = CGImageCreate(cvMat.cols,                                     // Width
                                 cvMat.rows,                                     // Height
                                 8,                                              // Bits per component
                                 8 * cvMat.elemSize(),                           // Bits per pixel
                                 cvMat.step[0],                                  // Bytes per row
                                 colorSpace,                                     // Colorspace
                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault,  // Bitmap info flags
                                 provider,                                       // CGDataProviderRef
                                 NULL,                                           // Decode
                                 false,                                          // Should interpolate
                                 kCGRenderingIntentDefault);                     // Intent
        

    }
    
    
    
    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:imageRef];
    NSImage *image = [[NSImage alloc] init];
    [image addRepresentation:bitmapRep];
    
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return image;
}

- (CGSize)sizeInPixels {
    CGImageRef imageRef = [self CGImageForProposedRect:NULL context:nil hints:nil];
    CGFloat width = CGImageGetWidth(imageRef);
    CGFloat height = CGImageGetHeight(imageRef);
    return CGSizeMake(width, height);
}


@end
