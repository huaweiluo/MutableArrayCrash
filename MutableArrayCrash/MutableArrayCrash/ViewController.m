//
//  ViewController.m
//  MutableArrayCrash
//
//  Created by jipengfei on 2019/7/1.
//  Copyright © 2019 jipengfei. All rights reserved.
//

#import "ViewController.h"

static NSInteger const kLogTaskQueueMaxWriteCount = 10;

@interface ViewController ()
@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, strong) NSMutableArray *muTaskArray;
@property (nonatomic, assign) BOOL isWriting;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor darkGrayColor];
}

- (void)writeJsonString:(NSString *)jsonString {
    if (jsonString.length <=0 || !jsonString) {
        return;
    }
    
    // 对muTaskArray操作添加保护锁
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __strong typeof(weakself) strongself = weakself;
        [strongself.lock lock];
        [strongself.muTaskArray addObject:jsonString];
        [strongself.lock unlock];
        [strongself doTask];
    });
}

//开启写入文件逻辑
- (void)doTask {
    if (self.muTaskArray.count >= kLogTaskQueueMaxWriteCount && !self.isWriting) {
        [self writeToFile];
    }
}

//写入文件操作
- (void)writeToFile {
    if (self.isWriting) {
        return;
    }
    NSArray *copyArray = [self.muTaskArray copy];
    NSInteger count = copyArray.count >= kLogTaskQueueMaxWriteCount? kLogTaskQueueMaxWriteCount: copyArray.count;
    if (count > 0) {
        self.isWriting = YES;
        NSArray *tempArray = [copyArray subarrayWithRange:NSMakeRange(0, count)];
        NSString *jsonStr = [[tempArray componentsJoinedByString:@"\n"] stringByAppendingString:@"\n"];
        __weak typeof(self) weakself = self;
//        [self.cFileManager writeFile:jsonStr finish:^{
//            __strong typeof(weakself) strongself = weakself;
//            [strongself removeObjectInRange:NSMakeRange(0, count)];
//        }];
    }
}

#pragma mark -
#pragma mark property
- (NSLock *)lock {
    if (!_lock) {
        _lock = [[NSLock alloc] init];
    }
    return _lock;
}

@end
