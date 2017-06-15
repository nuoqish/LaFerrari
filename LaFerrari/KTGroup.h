//
//  KTGroup.h
//  LaFerrari
//
//  Created by stanshen on 17/6/9.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KTElement.h"

@interface KTGroup : KTElement <NSCoding, NSCopying>

@property (nonatomic, strong) NSMutableArray *elements;

@end
