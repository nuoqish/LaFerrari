//
//  KTDrawing.m
//  LaFerrari
//
//  Created by stanshen on 17/6/9.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTDrawing.h"

NSString *KTDrawingKey = @"KTDrawingKey";

KTRenderingMetaData KTRenderingMetaDataMake(float scale, UInt32 flags) {
    KTRenderingMetaData metaData;
    metaData.scale = scale;
    metaData.flags = flags;
    return metaData;
}

BOOL KTRenderingMetaDataOutlineOnly(KTRenderingMetaData metaData) {
    return (metaData.flags & KTRenderOutlineOnly) ? YES : NO;
}

@implementation KTDrawing

@end
