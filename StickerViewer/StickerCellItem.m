//
//  StickerCellItem.m
//  StickerViewer
//
//  Created by 周兴 on 2024/2/26.
//

#import "StickerCellItem.h"
#import <SDWebImage/SDWebImage.h>

@interface StickerCellItem ()

@property (weak) IBOutlet NSImageView *stickerImageView;

@end

@implementation StickerCellItem

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)updateImageUrl:(NSString *)urlString {
    [self.stickerImageView sd_setImageWithURL:[NSURL URLWithString:urlString]
                             placeholderImage:[NSImage imageNamed:@"sticker_holder"]
                                    completed:^(NSImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        //图片加载完毕
    }];
}

@end
