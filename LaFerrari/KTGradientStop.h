//
//  KTGradientStop.h
//  LaFerrari
//
//  Created by stanshen on 17/6/11.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KTColor;
@class KTXMLElement;

@interface KTGradientStop : NSObject <NSCoding, NSCopying>

@property (nonatomic, readonly) float ratio;
@property (nonatomic, readonly) KTColor *color;

+ (KTGradientStop *)stopWithColor:(KTColor *)color andRatio:(float)ratio;
- (id)initWithColor:(KTColor *)color andRatio:(float)ratio;

- (KTGradientStop *)stopWithRatio:(float)ratio;
- (KTGradientStop *)stopWithColor:(KTColor *)color;

- (KTXMLElement *)SVGXMLElement;

@end
