//
//  FWAlertUtils.h
//  FileWatcher
//
//  Created by 周兴 on 2023/11/9.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface FWAlertUtils : NSObject

//展示弹窗
+ (NSAlert *)showAlertWithTitle:(NSString *)title;

//展示确认弹窗
+ (void)showConfirmAlert:(NSString *_Nullable)title
            confirmTitle:(NSString *)confirmTitle
                     msg:(NSString *_Nullable)msg
                complete:(void(^)(BOOL isConfirm))complete;

@end

NS_ASSUME_NONNULL_END
