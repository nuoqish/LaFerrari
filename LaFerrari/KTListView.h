//
//  KTListView.h
//  MoguMattor
//
//  Created by longyan on 2017/5/9.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class KTListView;

@protocol KTListViewDelegate <NSObject>

- (void)listView:(KTListView *)listView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths;

@end

@interface KTListView : NSView

@property (nonatomic, weak) id<KTListViewDelegate> delegate;

@property (nonatomic, strong) NSArray<NSURL *> *fileUrls;

- (void)reloadData;

@end
