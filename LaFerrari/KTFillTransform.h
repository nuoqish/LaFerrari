//
//  KTFillTransform.h
//  LaFerrari
//
//  Created by stanshen on 17/6/11.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KTFillTransform : NSObject <NSCoding, NSCopying>

@property (nonatomic, readonly) CGPoint start;
@property (nonatomic, readonly) CGPoint end;
@property (nonatomic, readonly) CGAffineTransform transform;
@property (nonatomic, readonly) CGPoint transformedStart;
@property (nonatomic, readonly) CGPoint transformedEnd;

+ (KTFillTransform *)fillTransformWithRect:(CGRect)rect centered:(BOOL)centered;
- (id)initWithTransform:(CGAffineTransform)transform start:(CGPoint)start end:(CGPoint)end;

- (BOOL) isDefaultInRect:(CGRect)rect centered:(BOOL)centered;

- (KTFillTransform *)transform:(CGAffineTransform)transform;
- (KTFillTransform *)transformWithTransformedStart:(CGPoint)pt;
- (KTFillTransform *)transformWithTransformedEnd:(CGPoint)pt;


@end
