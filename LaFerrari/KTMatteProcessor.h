//
//  KTMatteProcessor.h
//  LaFerrari
//
//  Created by stanshen on 17/5/27.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MatteMode) {
    
    MatteModeInitRect,
    MatteModeInitMask,
    MatteModeEVal,
    MatteModeCF
};

typedef NS_ENUM(NSInteger, PixelMode) {
    PixelModeForeground,
    PixelModeBackground,
    PixelModeUnknown
};

@interface KTMatteProcessor : NSObject

@property (nonatomic, assign) CGRect cropRect;
@property (nonatomic, readonly) NSImage *foregroundImage;
@property (nonatomic, readonly) NSImage *alphaImage;
@property (nonatomic, readonly) BOOL completed;

- (void)processImage:(NSImage *)image andMode:(MatteMode)mode andRadius:(int)radius;
- (void)processImageWithUrl:(NSURL *)imageUrl andMode:(MatteMode)mode andRadius:(int)radius;
- (void)updateMaskWithImage:(NSImage *)drawImage andPixelMode:(PixelMode)pixelMode;
- (void)updateForegroundAndAlphaWithImage:(NSImage *)drawImage andPixelMode:(PixelMode)pixelMode;
- (void)reset;
- (void)undo;

@end
