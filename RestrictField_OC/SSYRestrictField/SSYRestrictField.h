//
//  SSYRestrictField.h
//  RestrictField_OC
//
//  Created by sun on 2018/9/26.
//  Copyright © 2018年 ShuShangYun. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SSYRestrictField;
typedef BOOL(^SSYRestrictBlock)(NSString*);
typedef void(^SSYRestrictChangeBlock)(NSString*);
typedef void(^SSYRestrictOccur)(SSYRestrictField *);


@interface SSYRestrictField : UITextField
@property (nonatomic,weak) id<UITextFieldDelegate> outerDelegate;
@property (nonatomic,assign) NSInteger timeThreshold;

@property (nonatomic,copy) SSYRestrictChangeBlock txtChange;
@property (nonatomic,copy) SSYRestrictOccur txtRestricted;
@property (nonatomic,assign) NSInteger countLimit;

- (void)addVertifies:(NSArray<SSYRestrictBlock>*)blocks;
- (void)addRegExs:(NSArray<NSString *> *)regExs;

@end
