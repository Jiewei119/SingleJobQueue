//
//  SingleJobQueue.m
//  SingleJobQueue
//
//  Created by hjw119 on 2017/7/24.
//  Copyright © 2017年 xincheng. All rights reserved.
//

#import "SingleJobQueue.h"

static long long currentSingleJobPipeJobCount = 0;
static BOOL singleJobPipeJobRunLoopStop = YES;


@interface SingleJobQueue () {
    NSThread* _tThread;
    NSRunLoop * _runLoop;
    CFRunLoopRef _runLoopRef;
    CFRunLoopSourceRef _runLoopSourceRef;
    CFRunLoopSourceContext _runLoopSourceContext;
}

@property (nonatomic) JobBlock jobBlock;  //当前工作任务block
@property (nonatomic) BOOL jobFinish;  //当前工作任务是否执行完成
@property (nonatomic) BOOL shouldStop;
@property (nonatomic) BOOL jobThreadStarted;

@end

@implementation SingleJobQueue

/**
 *  获取单例对象
 */
+ (instancetype)shareInstance {
    static SingleJobQueue* sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        //启动工作线程
        singleJobPipeJobRunLoopStop = NO;
        sharedInstance.shouldStop = NO;
        [sharedInstance startRunLoop];
    });
    return sharedInstance;
}

/**
 *  以block方式运行工作任务
 *
 *  @param jobBlock 工作任务block
 */
- (void)runWithJobBlock:(JobBlock)jobBlock {
    @synchronized (self) {
        if (SingleJobPipeDebug) {
            NSLog(@"current thread:%@",[NSThread currentThread]);
            currentSingleJobPipeJobCount ++;
            NSLog(@"工作项执行开始:%lld",currentSingleJobPipeJobCount);
        }
        _jobFinish = NO;
        _jobBlock = jobBlock;
        
        //执行工作任务
        [self triggerEvent];
        
        //等待工作任务执行完毕
        while (!_jobFinish) {
            [NSThread sleepForTimeInterval:1.0 / 1000];
        }
        if (SingleJobPipeDebug) {
            NSLog(@"工作项执行完毕:%ld",(long)currentSingleJobPipeJobCount);
        }
    }
}

/**
 *  以block方式异步运行工作任务
 *
 *  @param jobBlock 工作任务block
 *  @param competition 完成回调block
 */
- (void)runAsyncJobWithJobBlock:(JobBlock)jobBlock competition:(JobCompetitionBlock)competition  {
    dispatch_async(dispatch_queue_create("SingleJobQueue_AsyncQueue", NULL), ^{
        [self runWithJobBlock:jobBlock];
        if (competition) {
            competition();
        }
    });
}


- (void)startRunLoop {
    [self performSelectorInBackground:@selector(configRunLoop) withObject:nil];
}

- (void)stopRunloop{
    _shouldStop = YES;
    [self triggerEvent];
}

- (void)triggerEvent{
    while (!_jobThreadStarted) {
        [NSThread sleepForTimeInterval:0.1];
    }
    if (/*!_runLoopStop && */_runLoopRef) {
        //添加输入事件
        CFRunLoopSourceSignal(_runLoopSourceRef);
        //唤醒线程，线程唤醒后发现由事件需要处理，于是立即处理事件
        CFRunLoopWakeUp(_runLoopRef);
    }
}

//此输入源需要处理的后台事件
static void fire(void* info __unused){
    if (!singleJobPipeJobRunLoopStop) {
        if ([SingleJobQueue shareInstance].jobBlock) {
            if (SingleJobPipeDebug) {
                NSLog(@"执行工作项 start:%ld",(long)currentSingleJobPipeJobCount);
            }
            
            [SingleJobQueue shareInstance].jobBlock();
            [SingleJobQueue shareInstance].jobBlock = nil;
            
            if (SingleJobPipeDebug) {
                NSLog(@"执行工作项 end:%ld",(long)currentSingleJobPipeJobCount);
            }
        }
        else {
            if (SingleJobPipeDebug) {
                NSLog(@"没有jobBlock");
            }
        }
        //通知源线程工作任务执行完毕
        [SingleJobQueue shareInstance].jobFinish = YES;
    }
}

- (void)configRunLoop{
    //这里获取到的已经是某个子线程了哦，不是主线程哦
    _tThread = [NSThread currentThread];
    //这里也是这个子线程的RunLoop哦
    _runLoop = [NSRunLoop currentRunLoop];
    _runLoopRef = CFRunLoopGetCurrent();
    
    bzero(&_runLoopSourceContext, sizeof(_runLoopSourceContext));
    //这里创建了一个基于事件的源
    _runLoopSourceContext.perform = fire;
    _runLoopSourceRef = CFRunLoopSourceCreate(NULL, 0, &_runLoopSourceContext);
    //将源添加到当前RunLoop中去
    CFRunLoopAddSource(_runLoopRef, _runLoopSourceRef, kCFRunLoopCommonModes);
    
    _jobThreadStarted = YES;
    
    while (!_shouldStop) {
        if (SingleJobPipeDebug) {
            NSLog(@"RunLoop start");
        }
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        if (SingleJobPipeDebug) {
            NSLog(@"RunLoop end");
        }
    }
    _tThread = nil;
    singleJobPipeJobRunLoopStop = YES;
    if (SingleJobPipeDebug) {
        NSLog(@"RunLoop 停止运行");
    }
}

@end
