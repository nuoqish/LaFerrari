//
//  KTListViewItem.m
//  MoguMattor
//
//  Created by longyan on 2017/5/10.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#import "KTListViewItem.h"

@interface KTListViewItem ()

@end

@implementation KTListViewItem

+ (NSString *)itemIndentifier {
    return NSStringFromClass([self class]);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    //self.view.layer.cornerRadius = 5;
    //self.view.layer.borderWidth = 5;
}

- (void)viewDidLayout {
    [super viewDidLayout];
    self.imageView.frame = self.view.bounds;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    if (selected)
        self.view.layer.backgroundColor = [NSColor redColor].CGColor;
    else
        self.view.layer.backgroundColor = [NSColor clearColor].CGColor;
    [self.view setNeedsDisplay:YES];
    NSLog(@"sekected");
}


@end
