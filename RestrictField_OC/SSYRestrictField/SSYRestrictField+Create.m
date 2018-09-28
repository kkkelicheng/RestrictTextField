//
//  SSYRestrictField+Create.m
//  RestrictField_OC
//
//  Created by sun on 2018/9/27.
//  Copyright © 2018年 ShuShangYun. All rights reserved.
//

#import "SSYRestrictField+Create.h"

@implementation SSYRestrictField (Create)

+(instancetype)createPriceTF
{
    SSYRestrictField * tf = [[SSYRestrictField alloc]initWithFrame:CGRectZero];

    SSYRestrictBlock myBlock = ^(NSString * txt){
        if (!txt || txt.length < 1) {
            return YES;
        }
        NSPredicate * predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",@"^([0]\\d+)"];
        BOOL isZero = [predicate evaluateWithObject:txt];
        if (isZero) {return NO;}
        else {return YES;}
    };
    
    [tf addVertifies:@[myBlock]];
    
    return tf;
}

+(instancetype)createLetterNumberTF
{
    SSYRestrictField * tf = [[SSYRestrictField alloc]initWithFrame:CGRectZero];
    [tf addRegExs:@[@"^[0-9A-Za-z]+$"]];
    return tf;
}

+(instancetype)createChineseTF
{
    SSYRestrictField * tf = [[SSYRestrictField alloc]initWithFrame:CGRectZero];
    [tf addRegExs:@[@"^[\\u4e00-\\u9fa5]{0,}$"]];
    return tf;
}


@end
