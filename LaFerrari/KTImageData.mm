//
//  KTImageData.m
//  LaFerrari
//
//  Created by stanshen on 17/6/13.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTImageData.h"

#import "KTUtilities.h"
#import "NSImage+Utils.h"

NSString *KTImageDataDataKey = @"KTImageDataKey";

@interface KTImageData ()

@property (nonatomic, strong) NSData *data;
@property (nonatomic, assign) CGRect naturalBounds;
@property (nonatomic, strong) NSImage *image;
@property (nonatomic, strong) NSImage *thumbnailImage;

@end


@implementation KTImageData

+ (KTImageData *)imageDataWithNSImage:(NSImage *)image {
    
    NSData *data = [image TIFFRepresentation];
    //NSData *digest = KTSHA1DigestForData(data);
    KTImageData *imageData = [KTImageData imageDataWithData:data];
    
    return imageData;
}

+ (KTImageData *)imageDataWithData:(NSData *)data {
    return [[KTImageData alloc] initWithData:data];
}

- (id)initWithData:(NSData *)data {
    self = [super init];
    if (self) {
        _data = data;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    _data = [aDecoder decodeObjectForKey:KTImageDataDataKey];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_data forKey:KTImageDataDataKey];
}

-(id)copyWithZone:(NSZone *)zone {
    return self;
}

- (NSString *)mimeType {
    if (self.imageFormat == KTImageDataJPEGFormat) {
        return @"image/jpeg";
    }
    else if (self.imageFormat == KTImageDataPNGFormat) {
        return @"image/png";
    }
    return @"image/unknown type";
}

- (KTImageDataFormat)imageFormat {
    UInt8 buffer[4];
    [_data getBytes:buffer length:4];
    if (buffer[0] == 0xFF && buffer[1] == 0xD8 && buffer[2] == 0xFF && buffer[3] == 0xE0) {
        return KTImageDataJPEGFormat;
    }
    return KTImageDataPNGFormat;
}

- (NSImage *)image {
    if (!_image) {
        _image = [[NSImage alloc] initWithData:_data];
        _naturalBounds = CGRectMake(0, 0, _image.size.width, _image.size.height);
        if (!_thumbnailImage) {
            _thumbnailImage = [_image downsampleWithMaxDimension:kKTThumbnailSize];
        }
    }
    
    return _image;
}

- (NSImage *)thumbnailImage {
    if (!_thumbnailImage) {
        [self image];
    }
    return _thumbnailImage;
}

- (NSData *)digest {
    return _data;//? KTSHA1DigestForData(_data);
}


@end
