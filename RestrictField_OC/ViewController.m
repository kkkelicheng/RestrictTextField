//
//  ViewController.m
//  RestrictField_OC
//
//  Created by sun on 2018/9/26.
//  Copyright © 2018年 ShuShangYun. All rights reserved.
//

#import "ViewController.h"
#import "SSYRestrictField+Create.h"

#define SCREEN_WDITH [UIScreen mainScreen].bounds.size.width

@interface ViewController ()
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configSubviews];
}

- (void)configSubviews
{
    SSYRestrictField * chineseTF = [SSYRestrictField createChineseTF];
    chineseTF.frame = CGRectMake(10, 100, SCREEN_WDITH - 20, 30);
    chineseTF.placeholder = @"6位中文";
    [self.view addSubview:chineseTF];
    chineseTF.txtChange = ^(NSString * result) {
        NSLog(@"chineseTF txtChange:%@",result);
    };
    chineseTF.countLimit = 6;
    
    SSYRestrictField * priceTF = [SSYRestrictField createPriceTF];
    priceTF.frame = CGRectMake(10, 150, SCREEN_WDITH - 20, 30);
    priceTF.placeholder = @"6位金额";
    priceTF.countLimit = 6;
    [self.view addSubview:priceTF];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
