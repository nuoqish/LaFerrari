//
//  KTSVGHelper.h
//  LaFerrari
//
//  Created by stanshen on 17/6/9.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KTXMLElement;

@interface KTSVGHelper : NSObject

+ (KTSVGHelper *)sharedSVGHelper;

- (void)beginSVGGeneration;
- (void)endSVGGeneration;

- (NSString *)uniqueIDWithPrefix:(NSString *)prefix;
- (void)addDefinition:(KTXMLElement *)def;
- (KTXMLElement *)definitions;

- (void)setImageID:(NSString *)uniqueID forDigest:(NSData *)digest;
- (NSString *)imageIDForDigest:(NSData *)digest;
- (NSString *)displayNameForBlendMode:(CGBlendMode)blendMode;

@end
