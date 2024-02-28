//
//  ViewController.m
//  StickerViewer
//
//  Created by 周兴 on 2024/2/26.
//

#import "ViewController.h"
#import "StickerCellItem.h"
#import "FWAlertUtils.h"
#import <SDWebImage/SDWebImage.h>
#import <AFNetworking/AFNetworking.h>

@interface ViewController ()<NSCollectionViewDataSource>

@property (nonatomic, strong) NSData *favData;
@property (nonatomic, strong) NSData *bookMarkData;
@property (nonatomic, strong) NSMutableArray<NSString *> *stickersArray;
@property (nonatomic, assign) CGFloat containerWidth;

@property (weak) IBOutlet NSTextField *errorLabel;
@property (weak) IBOutlet NSCollectionView *collectionView;
@property (weak) IBOutlet NSView *progressView;
@property (weak) IBOutlet NSProgressIndicator *progressBar;
@property (weak) IBOutlet NSTextField *progressLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.bookMarkData = [[NSUserDefaults standardUserDefaults] objectForKey:@"bookmarkdata"];
    self.stickersArray = @[].mutableCopy;
    
    //读取数据
    [self getStickerData];
}

- (IBAction)selectArchive:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setAllowedFileTypes:@[@"archive"]];

    [openPanel beginSheetModalForWindow:NSApp.mainWindow completionHandler:^(NSInteger result){
        if (result == NSModalResponseOK) {
            NSURL *selectedFileURL = [openPanel URLs].firstObject;
            NSString *filePath = [selectedFileURL path];
            
            //加载xml数据
            self.favData = [NSData dataWithContentsOfFile:filePath];
            [self parsePlistData];
        }
    }];
}

- (void)getStickerData {
    void(^getDataBlock)(void) = ^{
        NSString *username = NSUserName();
        NSString *basePath = [NSString stringWithFormat:@"/Users/%@/Library/Containers/com.tencent.xinWeChat/Data/Library/Application Support/com.tencent.xinWeChat/2.0b4.0.9", username];
        NSString *stickerComponent = @"Stickers";
        NSString *stickerPath = nil;
        
        NSError *error;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *contents = [fileManager contentsOfDirectoryAtPath:basePath error:&error];
        if (error) {
            self.errorLabel.hidden = NO;
            self.errorLabel.stringValue = @"未找到fav.archive文件，请手动选择";
        } else {
            if (!self.bookMarkData) {
                //保存bookmark
                NSURL *basePathUrl = [NSURL fileURLWithPath:basePath];
                NSError *bookMarkError = nil;
                NSData *bookmarkData =[basePathUrl bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:&bookMarkError];
                if (bookMarkError) {
                    NSLog(@"bookmark出错：%@", bookMarkError);
                } else {
                    [[NSUserDefaults standardUserDefaults] setObject:bookmarkData forKey:@"bookmarkdata"];
                    NSLog(@"bookmarkdata保存成功");
                }
            }
        }
        
        //开始解析
        for (NSString *item in contents) {
            NSString *currentPath = [[basePath stringByAppendingPathComponent:item] stringByAppendingPathComponent:stickerComponent];
            BOOL isDir;
            if ([fileManager fileExistsAtPath:currentPath isDirectory:&isDir] && isDir) {
                //找到路径
                stickerPath = [[basePath stringByAppendingPathComponent:item] stringByAppendingPathComponent:stickerComponent];
                break;
            }
        }
        
        if (stickerPath.length) {
            NSString *stickerFavPath = [stickerPath stringByAppendingPathComponent:@"fav.archive"];
            if ([fileManager fileExistsAtPath:stickerFavPath isDirectory:nil]) {
                //加载xml数据
                self.favData = [NSData dataWithContentsOfFile:stickerFavPath];
                [self parsePlistData];
            }
        } else {
            //未找到微信路径
            NSLog(@"未找到微信沙盒路径，请确保微信安装并登录");
        }
        
        [self feedBack];
    };
    
    if (self.bookMarkData) {
        //已授权
        BOOL bookmarkDataIsStale;
        NSURL *allowedUrl = [NSURL URLByResolvingBookmarkData:self.bookMarkData options:NSURLBookmarkResolutionWithSecurityScope|NSURLBookmarkResolutionWithoutUI relativeToURL:nil bookmarkDataIsStale:&bookmarkDataIsStale error:NULL];
        [allowedUrl startAccessingSecurityScopedResource];
     
        getDataBlock();
    } else {
        //未授权
        getDataBlock();
    }
}

- (void)feedBack {
}

- (void)parsePlistData {
    NSError *error;
    NSDictionary *plistObject = [NSPropertyListSerialization propertyListWithData:self.favData
                                                                          options:NSPropertyListImmutable
                                                                           format:NULL
                                                                            error:&error];
    if (plistObject) {
        self.errorLabel.hidden = YES;
        NSArray *stickersData = plistObject[@"$objects"];
        if (stickersData && [stickersData isKindOfClass:NSArray.class]) {
            //遍历数据
            for (id item in stickersData) {
                if ([item isKindOfClass:NSString.class] && [(NSString *)item hasPrefix:@"http"]) {
                    [self.stickersArray addObject:item];
                }
            }
        }
    } else {
        self.errorLabel.hidden = NO;
        self.errorLabel.stringValue = [NSString stringWithFormat:@"plist解析失败：%@", error.localizedDescription];
    }
    
    [self.collectionView reloadData];
    //获得所有数据
    NSLog(@"表情数据：%ld", self.stickersArray.count);
}

#pragma mark - NSCollectionViewDataSource
- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.stickersArray.count;
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath {
    NSString *imageUrl = self.stickersArray[indexPath.item];
    
    StickerCellItem *item = [collectionView makeItemWithIdentifier:@"StickerCellItem" forIndexPath:indexPath];
    [item updateImageUrl:imageUrl];
    return item;
}

//导出所有数据
- (IBAction)exportAction:(id)sender {
    if (self.stickersArray.count == 0) {
        [FWAlertUtils showAlertWithTitle:@"没有表情数据"];
        return;
    }
    
    //选择导出文件目录
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel beginSheetModalForWindow:NSApp.mainWindow completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            // 获取选择的目录
            NSURL *selectedURL = [openPanel URL];
            NSString *savePath = selectedURL.path;
            NSString *stickerPath = [savePath stringByAppendingPathComponent:@"stickers"];
            
            //创建子目录
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSError *createError = nil;
            BOOL createResult = [fileManager createDirectoryAtPath:stickerPath withIntermediateDirectories:YES attributes:nil error:&createError];
            if (!createResult) {
                //文件夹创建失败
                [FWAlertUtils showAlertWithTitle:[NSString stringWithFormat:@"文件夹创建失败：%@", createError.localizedDescription]];
                return;
            }
            
            //展示进度条
            self.progressView.wantsLayer = YES;
            self.progressView.layer.backgroundColor = [[NSColor whiteColor] colorWithAlphaComponent:0.95].CGColor;
            self.progressView.hidden = NO;
            self.progressLabel.stringValue = [NSString stringWithFormat:@"进度：0/%ld", self.stickersArray.count];;
            
            [self.progressBar setIndeterminate:NO]; // 设置为不确定进度条
            [self.progressBar setMinValue:0];
            [self.progressBar setMaxValue:self.stickersArray.count];
            [self.progressBar setDoubleValue:0];
            [self.progressBar startAnimation:nil];
            
            NSMutableArray<NSDictionary *> *unNormalStickers = @[].mutableCopy;
            //开始导出
            __block NSInteger finishCount = 0;
            __block NSInteger successCount = 0;
            for (NSInteger i = 0; i < self.stickersArray.count; i++) {
                NSString *imageUrlString = self.stickersArray[i];
                //先尝试从内存导出
                [[SDWebImageManager sharedManager] loadImageWithURL:[NSURL URLWithString:imageUrlString]
                                                            options:SDWebImageRetryFailed
                                                           progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
                    //下载进度
                } completed:^(NSImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {

                    //图片数据
                    NSData *imageData = data;
                    if (imageData) {
                        successCount += 1;
                        
                        //图片保存
                        NSString *fileName = [NSString stringWithFormat:@"%03ld.%@", i, image.sd_isAnimated ? @"gif" : @"png"];
                        NSString *imagePath = [stickerPath stringByAppendingPathComponent:fileName];
                        [imageData writeToFile:imagePath atomically:YES];
                        
                        //更新进度
                        [self.progressBar setDoubleValue:successCount];
                        self.progressLabel.stringValue = [NSString stringWithFormat:@"进度：%ld/%ld", successCount, self.stickersArray.count];
                    } else {
                        //添加到异常数据
                        [unNormalStickers addObject:@{@"url": imageUrlString ?: @"", @"index": @(i)}];
                    }
                    
                    finishCount += 1;
                    
                    if (finishCount == self.stickersArray.count) {
                        //正常表情导出完成，开始下载异常数据
                        [self downloadUnNormalData:unNormalStickers savePath:stickerPath];
                        NSLog(@"开始下载异常数据：%ld", unNormalStickers.count);
                    }
                }];
            }
        }
    }];
}

- (void)downloadUnNormalData:(NSArray<NSDictionary *> *)unNormalData savePath:(NSString *)savePath {
    if (unNormalData.count == 0) {
        //无异常数据
        self.progressView.hidden = YES;
        [FWAlertUtils showAlertWithTitle:@"导出完成"];
        
        //打开文件夹
        [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:savePath]];
        return;
    }
    
    __block NSInteger successCount = self.stickersArray.count - unNormalData.count;
    for (NSInteger i = 0; i < unNormalData.count; i++) {
        NSString *imageUrlString = unNormalData[i][@"url"];
        NSInteger index = [unNormalData[i][@"index"] integerValue];
        [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:imageUrlString]
                                                              options:SDWebImageDownloaderAllowInvalidSSLCertificates|SDWebImageDownloaderHighPriority
                                                             progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
            //下载进度
        }
                                                            completed:^(NSImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
            //图片数据
            NSData *imageData = data ?: [image TIFFRepresentation];
            
            //图片保存
            NSString *fileName = [NSString stringWithFormat:@"%03ld.%@", index, image.sd_isAnimated ? @"gif" : @"png"];
            NSString *imagePath = [savePath stringByAppendingPathComponent:fileName];
            [imageData writeToFile:imagePath atomically:YES];
            
            successCount += 1;
            
            //更新进度
            [self.progressBar setDoubleValue:successCount];
            self.progressLabel.stringValue = [NSString stringWithFormat:@"进度：%ld/%ld", successCount, self.stickersArray.count];
            
            if (successCount == self.stickersArray.count) {
                //导出完成
                self.progressView.hidden = YES;
                [FWAlertUtils showAlertWithTitle:@"导出完成"];
                
                //打开文件夹
                [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:savePath]];
            }
        }];
    }
}

@end
