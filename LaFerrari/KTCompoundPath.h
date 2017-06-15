//
//  KTCompoundPath.h
//  LaFerrari
//
//  Created by stanshen on 17/6/11.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTAbstractPath.h"

@class KTPath;

@interface KTCompoundPath : KTAbstractPath <NSCoding, NSCopying>

@property (nonatomic, strong) NSMutableArray *subpaths;

- (void) invalidatePath;
- (void) addSubpath:(KTPath *)path;
- (void) removeSubpath:(KTPath *)path;

- (void) setSubpathsQuiet:(NSMutableArray *)subpaths;

@end
