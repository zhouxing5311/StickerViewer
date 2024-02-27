//
//  FWAlertUtils.m
//  FileWatcher
//
//  Created by 周兴 on 2023/11/9.
//

#import "FWAlertUtils.h"

@implementation FWAlertUtils

//展示弹窗
+ (NSAlert *)showAlertWithTitle:(NSString *)title {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"确定"];
    [alert setMessageText:title];
//    [alert setInformativeText:msg.length ? msg : @""];
    [alert setAlertStyle:NSAlertStyleInformational];
    [alert runModal];
    return alert;
}

//展示确认弹窗
+ (void)showConfirmAlert:(NSString *_Nullable)title
            confirmTitle:(NSString *)confirmTitle
                     msg:(NSString *_Nullable)msg
                complete:(void(^)(BOOL isConfirm))complete {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:confirmTitle];
//    [alert addButtonWithTitle:@"取消"];
    [alert setMessageText:title];
    [alert setInformativeText:msg.length ? msg : @""];
    [alert setAlertStyle:NSAlertStyleInformational];
    NSModalResponse response = [alert runModal];
    if (response == 1000) {
        !complete ?: complete(YES);
    }
}

@end
