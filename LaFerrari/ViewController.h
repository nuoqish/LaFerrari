//
//  ViewController.h
//  MoguMattor
//
//  Created by longyan on 2016/12/30.
//  Copyright © 2016年 shenyanhao. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MGImageEditView;

@interface ViewController : NSViewController

- (void)openImageUrl:(NSURL *)imageUrl;
- (void)openImageUrls:(NSArray<NSURL *> *)imageUrls;
- (void)saveImageUrl:(NSURL *)imageUrl;
- (void)saveImagesToDir:(NSURL *)dirUrl;
- (void)undo;

@end
