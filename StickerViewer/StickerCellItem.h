//
//  StickerCellItem.h
//  StickerViewer
//
//  Created by 周兴 on 2024/2/26.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface StickerCellItem : NSCollectionViewItem

- (void)updateImageUrl:(NSString *)urlString;

@end

NS_ASSUME_NONNULL_END
