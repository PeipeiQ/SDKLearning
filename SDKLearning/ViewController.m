//
//  ViewController.m
//  SDKLearning
//
//  Created by 沛沛 on 2018/6/23.
//  Copyright © 2018年 沛沛. All rights reserved.
//



#import "ViewController.h"
#import "Masonry.h"
typedef NSNumber* (^addBlcok)(int);

//nsnumber扩展
@interface NSNumber (num)
-(addBlcok)add;
@end

@implementation NSNumber (num)
-(addBlcok)add{
    addBlcok addblock = ^(int a){
        return @([self intValue]+a);
    };
    return addblock;
}

@end
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIView *pview = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 100, 100)];
    pview.backgroundColor = [UIColor redColor];
    pview.center = self.view.center;
    [self.view addSubview:pview];
    
    UIView *tview = [[UIView alloc]init];
    tview.backgroundColor = [UIColor greenColor];
    [self.view addSubview:tview];
    [tview mas_makeConstraints:^(MASConstraintMaker *make) {
        //先完整走完size方法，返回一个constraint实例
        make.size.equalTo(pview);
        make.center.equalTo(pview).with.offset(-100);
        
    }];
    MASConstraint *m = [[MASConstraint alloc]init];
    //链式语法
    NSNumber *num = @(20);
    NSNumber *res = num.add(120);
//    NSLog(@"%@" ,num.add(120).add(150));
    
}

@end




