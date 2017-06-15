//
//  KTImage.h
//  LaFerrari
//
//  Created by stanshen on 17/6/14.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTElement.h"

@class KTImageData;
@class KTDrawing;

@interface KTImage : KTElement <NSCoding, NSCopying>

@property (nonatomic, assign) CGAffineTransform transform;
@property (nonatomic, readonly) KTImageData *imageData;

+ (KTImage *)imageWithNSImage:(NSImage *)image inDrawing:(KTDrawing *)drawing;
- (id)initWithNSImage:(NSImage *)image inDrawing:(KTDrawing *)drawing;

- (CGRect)naturalBounds;
- (void)useTrackedImageData;

@end
