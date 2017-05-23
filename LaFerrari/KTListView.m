//
//  KTListView.m
//  MoguMattor
//
//  Created by longyan on 2017/5/9.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#import "KTListView.h"
#import "KTListViewItem.h"

@interface KTListView () <NSCollectionViewDataSource, NSCollectionViewDelegate>

@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) NSCollectionView *listView;

@end


@implementation KTListView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setupListView];
        
    }
    return self;
}

- (void)setupListView {
    NSCollectionViewFlowLayout *layout = [NSCollectionViewFlowLayout new];
    layout.itemSize = CGSizeMake(60, 80);
    layout.minimumLineSpacing = 5;
    layout.minimumInteritemSpacing = 5;
    layout.sectionInset = NSEdgeInsetsMake(5, 5, 5, 5);
    layout.scrollDirection = NSCollectionViewScrollDirectionVertical;
    self.listView = [[NSCollectionView alloc] initWithFrame:self.bounds];
    self.listView.collectionViewLayout = layout;
    self.listView.backgroundColors = @[[NSColor lightGrayColor]];
    self.listView.dataSource = self;
    self.listView.delegate = self;
    self.listView.selectable = YES;
    self.listView.allowsMultipleSelection = YES;
    [self.listView registerClass:[KTListViewItem class] forItemWithIdentifier:[KTListViewItem itemIndentifier]];
    
    self.scrollView = [[NSScrollView alloc] initWithFrame:self.bounds];
    [self addSubview:self.scrollView];
    self.scrollView.documentView = self.listView;
    
}


- (void)layout {
    self.scrollView.frame = self.bounds;
}

- (void)reloadData {
    [self.listView reloadData];
}


#pragma mark - NSCollectionViewDataSource, NSCollectionViewDelegate

- (NSInteger)numberOfSectionsInCollectionView:(NSCollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.fileUrls.count;
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath {
    
    NSURL *fileUrl = self.fileUrls[indexPath.item];
    NSImage *image = [[NSImage alloc] initWithContentsOfURL:fileUrl];
    
    KTListViewItem *cell = [collectionView makeItemWithIdentifier:[KTListViewItem itemIndentifier] forIndexPath:indexPath];
    
    cell.imageView.image = image;
    
    return cell;
}

- (void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(listView:didSelectItemsAtIndexPaths:)]) {
        [self.delegate listView:self didSelectItemsAtIndexPaths:indexPaths];
    }
    
}


@end
