//
//  SingleJobQueue.h
//  SingleJobQueue
//
//  Created by hjw119 on 2017/7/24.
//  Copyright © 2017年 xincheng. All rights reserved.
//

#import <Foundation/Foundation.h>

//#ifndef SingleJobPipeDebug
//#define SingleJobPipeDebug NO
//#endif

typedef void(^JobBlock)();
typedef void(^JobCompetitionBlock)();

/**
 *  单工作项工作队列类
 *  主要的应用场景是多个线程之中的操作委托给一个线程排队来处理
 */
@interface SingleJobQueue : NSObject

/**
 *  获取单例对象
 */
+ (instancetype)shareInstance;

/**
 *  以block方式运行工作任务
 *
 *  @param jobBlock 工作任务block
 */
- (void)runWithJobBlock:(JobBlock)jobBlock;

/**
 *  以block方式异步运行工作任务
 *
 *  @param jobBlock 工作任务block
 *  @param competition 完成回调block
 */
- (void)runAsyncJobWithJobBlock:(JobBlock)jobBlock competition:(JobCompetitionBlock)competition;

@end
