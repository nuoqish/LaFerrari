//
//  KTUserFont.h
//  LaFerrari
//
//  Created by stanshen on 17/6/13.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KTUserFont : NSObject

@property (nonatomic, assign) CTFontRef fontRef;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) NSString *fullName;
@property (nonatomic, strong) NSString *familyName;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSData *digest;

+ (KTUserFont *)userFontWithFileName:(NSString *)fileName;
- (id)initWithFileName:(NSString *)fileName;
- (CTFontRef)newFontRefForSize:(CGFloat)size;

@end
