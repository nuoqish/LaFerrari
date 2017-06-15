//
//  KTPathFinder.h
//  LaFerrari
//
//  Created by stanshen on 17/6/11.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    KTPathFinderOperationUnite,
    KTPathFinderOperationIntersect,
    KTPathFinderOperationSubtract,
    KTPathFinderOperationExclude,
    KTPathFinderOperationDivide
} KTPathFinderOperation;


@class KTAbstractPath;

@interface KTPathFinder : NSObject

+ (KTAbstractPath *)combinePaths:(NSArray *)paths operation:(KTPathFinderOperation)operation;

@end
