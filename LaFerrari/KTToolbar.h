//
//  KTToolbar.h
//  MoguMattor
//
//  Created by longyan on 2017/5/11.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class KTToolbar;

@protocol KTToolbarDelegate <NSObject>

- (void)toolbar:(KTToolbar *)toolbar didOpenImageUrl:(NSURL *)imagePath;
- (void)toolbar:(KTToolbar *)toolbar didSaveImageUrl:(NSURL *)imagePath;
- (void)toolbar:(KTToolbar *)toolbar didOpenImageUrls:(NSArray<NSURL *> *)imageUrls;
- (void)undoButtonTappedForToolbar:(KTToolbar *)toolbar;
- (NSString *)fileNameForToolbar:(KTToolbar *)toolbar;

@end


@interface KTToolbar : NSToolbar

@property (nonatomic, weak) id<KTToolbarDelegate> ktDelegate;

@end
