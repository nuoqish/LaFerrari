//
//  KTImageData.h
//  LaFerrari
//
//  Created by stanshen on 17/6/13.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, KTImageDataFormat) {
    KTImageDataJPEGFormat,
    KTImageDataPNGFormat
};

@interface KTImageData : NSObject <NSCopying, NSCoding>

@property (nonatomic, readonly) NSData *data;
@property (nonatomic, readonly) NSImage *image;
@property (nonatomic, readonly) NSImage *thumbnailImage;
@property (nonatomic, readonly) NSData *digest;
@property (nonatomic, readonly) NSString *mimeType;
@property (nonatomic, readonly) CGRect naturalBounds;
@property (nonatomic, readonly) KTImageDataFormat imageFormat;

+ (KTImageData *)imageDataWithNSImage:(NSImage *)image;
+ (KTImageData *)imageDataWithData:(NSData *)data;
- (id)initWithData:(NSData *)data;

@end
