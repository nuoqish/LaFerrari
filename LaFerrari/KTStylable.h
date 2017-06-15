//
//  KTStylable.h
//  LaFerrari
//
//  Created by stanshen on 17/6/11.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTElement.h"

#import "KTPathPainter.h"

@class KTFillTransform;
@class KTStrokeStyle;
@class KTXMLElement;

@interface KTStylable : KTElement <NSCoding, NSCopying>

@property (nonatomic, strong) id<KTPathPainter> fill;
@property (nonatomic, strong) KTFillTransform *fillTransform;
@property (nonatomic, strong) KTStrokeStyle *strokeStyle;
@property (nonatomic, strong) NSArray *maskedElements;
@property (nonatomic, strong) KTFillTransform *displayFillTransform;
@property (nonatomic, strong) id initialFill;
@property (nonatomic, strong) KTStrokeStyle *initialStroke;
@property (nonatomic, readonly) BOOL isMasking;

- (NSSet *)changedStrokePropertiesFrom:(KTStrokeStyle *)from to:(KTStrokeStyle *)to;
- (void)strokeStyleChanged;
- (void)takeStylePropertiesFrom:(KTStylable *)stylable;
- (void)addSVGFillAndStrokeAttributes:(KTXMLElement *)element;
- (void)addSVGFillAttributes:(KTXMLElement *)element;
- (void)setFillQuiet:(id<KTPathPainter>)fill;
- (void)setStrokeStyleQuiet:(KTStrokeStyle *)srokeStyle;


@end
