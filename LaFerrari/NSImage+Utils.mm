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


- (void)drawToFillRect:(CGRect)bounds {
    float   wScale = CGRectGetWidth(bounds) / self.size.width;
    float   hScale = CGRectGetHeight(bounds) / self.size.height;
    float   scale = MAX(wScale, hScale);
    float   hOffset = 0.0f, vOffset = 0.0f;
    
    CGRect  rect = CGRectMake(CGRectGetMinX(bounds), CGRectGetMinY(bounds), self.size.width * scale, self.size.height * scale);
    
    if (CGRectGetWidth(rect) > CGRectGetWidth(bounds)) {
        hOffset = CGRectGetWidth(rect) - CGRectGetWidth(bounds);
        hOffset /= -2;
    }
    
    if (CGRectGetHeight(rect) > CGRectGetHeight(bounds)) {
        vOffset = CGRectGetHeight(rect) - CGRectGetHeight(bounds);
        vOffset /= -2;
    }
    
    rect = CGRectOffset(rect, hOffset, vOffset);
    
    [self drawInRect:rect];
}

- (NSImage *)rotatedImage:(int)rotation {
    CGSize size = self.size;
    CGSize rotatedSize = (rotation % 2 == 1 ? CGSizeMake(size.height, size.width) : size);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(NULL,                 // Pointer to backing data
                                                    rotatedSize.width,                      // Width of bitmap
                                                    rotatedSize.height,                     // Height of bitmap
                                                    8,                          // Bits per component
                                                    rotatedSize.width * 4,              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaPremultipliedLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    if (rotation == 1) {
        CGContextTranslateCTM(ctx, size.height, 0.0f);
    } else if (rotation == 2) {
        CGContextTranslateCTM(ctx, size.width, size.height);
    } else if (rotation == 3) {
        CGContextTranslateCTM(ctx, 0.0f, size.width);
    }
    
    CGContextRotateCTM(ctx, (M_PI / 2.0f) * rotation);
    
    [self drawInRect:NSMakeRect(0, 0, rotatedSize.width, rotatedSize.height)]; //?
    
    CGImageRef imageRef = CGBitmapContextCreateImage(ctx);
    NSImage *image = [[NSImage alloc] initWithCGImage:imageRef size: size];
    
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    
    return image;
}

- (NSImage *)downsampleWithMaxDimension:(float)constraint {
    CGSize newSize, size = self.size;
    
    if (size.width <= constraint && size.height <= constraint) {
        return self;
    }
    
    if (size.width > size.height) {
        newSize.height = size.height / size.width * constraint;
        newSize.width = constraint;
    } else {
        newSize.width = size.width / size.height * constraint;
        newSize.height = constraint;
    }
    
    newSize = CGSizeMake(round(size.width), size.height);
    
    return [self resizeTo:newSize];
}

- (NSImage *)downsampleWithMaxArea:(float)maxArea {
    CGSize  size = self.size;
    double  area = size.width * size.height;
    
    if (area > maxArea) {
        double scale = sqrt(maxArea) / sqrt(area);
        size = CGSizeMake(round(size.width * scale), round(size.height * scale));
        return [self resizeTo:size];
    }
    return self;
    
}

@end
