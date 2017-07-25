//
//  ViewController.m
//  SingleJobQueue
//
//  Created by hjw119 on 2017/7/24.
//  Copyright © 2017年 xincheng. All rights reserved.
//

#import "ViewController.h"
#import "SingleJobQueue.h"

@interface ViewController () {
    NSInteger clickCount;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onButton:(UIButton*)sender {
    clickCount++;
    [sender setTitle:[NSString stringWithFormat:@"Click:%ld",(long)clickCount] forState:UIControlStateNormal];
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(onRunJob:) object:nil];
    [thread start];
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        [self onRunJob:sender];
//    });
//    dispatch_sync(dispatch_queue_create("myQueue", DISPATCH_QUEUE_SERIAL), ^{
//        NSLog(@"currentThread:%@",[NSThread currentThread]);
//        [self onRunJob:sender];
//    });
}

- (void)onRunJob:(id)sender {
    [[SingleJobQueue shareInstance] runWithJobBlock:^{
        NSLog(@"runWithJobBlock");
        [NSThread sleepForTimeInterval:0.2];
    }];
}

@end
