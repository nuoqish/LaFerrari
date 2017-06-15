//
//  KTDrawing.h
//  LaFerrari
//
//  Created by stanshen on 17/6/9.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class KTColor;
@class KTElement;
@class KTGradient;
@class KTLayer;
@class KTPickResult;

@protocol KTPathPainter;


enum {
    KTRenderDefault     = 0x0,
    KTRenderOutlineOnly = 0x1,
    KTRenderThumbnail   = 0x1 << 1,
    KTRenderFlipped     = 0x1 << 2
};

typedef struct {
    float scale;
    UInt32 flags;
} KTRenderingMetaData;

KTRenderingMetaData KTRenderingMetaDataMake(float scale, UInt32 flags);
BOOL KTRenderingMetaDataOutlineOnly(KTRenderingMetaData metaData);

extern NSString *KTDrawingKey;

@interface KTDrawing : NSObject

@property (nonatomic, readonly) BOOL isSuppressingNotifications;
@property (nonatomic, strong) NSUndoManager *undoManager;

@end
