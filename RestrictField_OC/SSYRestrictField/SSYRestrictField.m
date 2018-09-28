//
//  SSYRestrictField.m
//  RestrictField_OC
//
//  Created by sun on 2018/9/26.
//  Copyright © 2018年 ShuShangYun. All rights reserved.
//

#import "SSYRestrictField.h"

@interface SSYRestrictField()<UITextFieldDelegate>
@property (nonatomic, strong) NSMutableArray<NSString *> *  regExs;
@property (nonatomic, strong) NSMutableArray<SSYRestrictBlock> *  vertifyBlocks;
@property (nonatomic, strong) NSArray<NSString *> *  markedTextRangeLanguages;
@property (nonatomic,assign) NSInteger changeRecordTime;
@property (nonatomic,strong) UITextRange * previousRangeRecord;
@property (nonatomic,assign) NSRange changeRangeRecord;
@property (nonatomic,copy) NSString * originText;
@property (nonatomic,copy) NSString * changedNewText;
@end

@implementation SSYRestrictField

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [super setDelegate:self];
        [self registerTFChange];
        self.autocorrectionType = UITextAutocorrectionTypeNo;
        [self configDefaultValues];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [super setDelegate:self];
        [self registerTFChange];
        [self configDefaultValues];
        self.autocorrectionType = UITextAutocorrectionTypeNo;
    }
    return self;
}

- (void)configDefaultValues
{
    self.markedTextRangeLanguages = @[@"zh-Hans"];
    self.countLimit = MAX_INPUT;
}

- (void)setDelegate:(id<UITextFieldDelegate>)delegate
{
    self.outerDelegate = delegate;
    super.delegate = self;
}

- (id<UITextFieldDelegate>)delegate{
    return self.outerDelegate;
}

- (NSMutableArray<SSYRestrictBlock> *)vertifyBlocks
{
    if (!_vertifyBlocks) {
        _vertifyBlocks = [NSMutableArray array];
    }
    return _vertifyBlocks;
}

- (NSMutableArray<NSString *> *)regExs
{
    if (!_regExs) {
        _regExs = [NSMutableArray array];
    }
    return _regExs;
}

- (void)addVertifies:(NSArray<SSYRestrictBlock>*)blocks
{
    [self.vertifyBlocks addObjectsFromArray:blocks];
}

- (void)addRegExs:(NSArray<NSString *> *)regExs
{
    [self.regExs addObjectsFromArray:regExs];
}



#pragma mark - notification

- (void)sendText
{
    NSInteger currentTime =  (NSInteger)[[NSDate date]timeIntervalSince1970] * 1000 ;
    if (currentTime - self.changeRecordTime >= self.timeThreshold) {
        NSLog(@"send text :%@",self.text);
        if (self.txtChange) {
            self.txtChange(self.text);
        }
    }
}

- (void)delaySendText
{
    self.changeRecordTime =  (NSInteger)[[NSDate date]timeIntervalSince1970] * 1000 ;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.timeThreshold * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        [self sendText];
    });
}

- (void)registerTFChange
{
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(textFieldDidChangeNoti:) name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)unregisterTFChange
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSRange)fixUITextRangeToRange:(UITextRange *)txRange textField:(UITextField *)tf
{
    if (!txRange) {
        return NSMakeRange(0, 0);
    }
    
    NSInteger location = [tf offsetFromPosition:tf.beginningOfDocument toPosition:txRange.start];
    NSInteger length = [tf offsetFromPosition:txRange.start toPosition:txRange.end];
    return NSMakeRange(location, length);
}

- (void)textFieldDidChangeNoti:(NSNotification *)noti
{
    UITextField * tf = noti.object;
    if (![tf isMemberOfClass:[SSYRestrictField class]] || (SSYRestrictField *)tf != self || !tf.text) {
        return ;
    }
    
    NSLog(@"textFieldDidChangeNoti  markedTextRange:%@",tf.markedTextRange);
    
    NSString * currentString = tf.text;
    BOOL shouldRestrictInDidChange = [self checkShouldUseRestrictInDidChangeNoti:tf];
    BOOL restrictedInWillChange = [self checkShouldUseRestrictInShouldChangeCharactersMethod:tf];
    
    if (shouldRestrictInDidChange) {  //当前 markedTextRange == nil
        NSString * stringPrivious = currentString;
        // 限制合法
        if (![self checkStringIsValid:currentString]) {
            if (self.previousRangeRecord == nil){ //在有markedTextRange的语言的情况下,输入数字或者标点会进入下面方法
                stringPrivious = self.originText;
            }
            else {  //高亮subString直接插入导致限制,那么直接通过高亮的markedTextRange,remove掉插入的subString
                NSRange removeRange = [self fixUITextRangeToRange:self.previousRangeRecord textField:tf];
                stringPrivious = [stringPrivious stringByReplacingCharactersInRange:removeRange withString:@""];
            }
            tf.text = stringPrivious;
            if (self.txtRestricted) { self.txtRestricted(self);}
        }
        //之前的都没验证通过,是直接去掉了substring,长度应该是没问题. 能到这里之前一定是合法的
        else if(currentString.length > self.countLimit){
            //再次分两种情况 一种是高亮完毕了的 一种是数字等没有高亮
            if(self.previousRangeRecord != nil){ //必须采用当前的range,不能使用之前记录的
                //直接找到多出的部分,remove
                NSInteger overCount = currentString.length - self.countLimit;
                NSRange previousRangeRange = [self fixUITextRangeToRange:self.previousRangeRecord textField:tf];
                NSInteger location = previousRangeRange.location + (previousRangeRange.length - overCount);
                NSRange willReplaceRange = NSMakeRange(location , overCount);
                stringPrivious = [stringPrivious stringByReplacingCharactersInRange:willReplaceRange withString:@""];
                tf.text = stringPrivious;
            }
            else {
                [self trimExceedString:currentString textField:self];
            }
        }
        
    }
    else if(restrictedInWillChange){
        [self trimExceedString:currentString textField:self];
    }
    
    if (tf.markedTextRange == nil) {
        [self delaySendText];
    }
    
    self.previousRangeRecord = self.markedTextRange;
}

//解决超出的问题
- (void)trimExceedString:(NSString *)currentString textField:(UITextField *)tf
{
    if (currentString.length > self.countLimit) {
        if (self.txtRestricted) { self.txtRestricted(self);}
        NSInteger overCount = currentString.length - self.countLimit;
        NSString * originString = self.originText;
        //trim 新添的string
        NSString * trimedSubString = [self.changedNewText substringToIndex:self.changedNewText.length - overCount];
        NSString * resultString = [originString stringByReplacingCharactersInRange:self.changeRangeRecord withString:trimedSubString];
        tf.text = resultString;
    }
}



#pragma mark - check

- (BOOL)checkStringIsValid:(NSString *)checkString
{
    if (checkString == nil || checkString.length < 1) {
        return true;
    }
    
    if (self.regExs.count > 0) {
        for (NSString * regEx in self.regExs) {
            NSPredicate * predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regEx];
            BOOL isValid = [predicate evaluateWithObject:checkString];
            if (!isValid) {
                return false;
            }
        }
    }
    
    if (self.vertifyBlocks.count > 0) {
        for (SSYRestrictBlock block in self.vertifyBlocks) {
            BOOL isValid = block(checkString);
            if (!isValid) {
                return false;
            }
        }
    }
    
    return true;
}

- (BOOL)checkShouldUseRestrictInDidChangeNoti:(UITextField *)textField
{
    NSString * language = textField.textInputMode.primaryLanguage;
    NSLog(@"did change noti language :%@",language);
    if ([self.markedTextRangeLanguages containsObject:language] && textField.markedTextRange == nil) {
        return true;
    }
    return false;
}

- (BOOL)checkShouldUseRestrictInShouldChangeCharactersMethod:(UITextField *)textField
{
    NSString * language = textField.textInputMode.primaryLanguage;
    NSLog(@"did change characters :%@",language);
    if (![self.markedTextRangeLanguages containsObject:language]) {
        return true;
    }
    return false;
}


#pragma mark - textFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (self.outerDelegate && [self.outerDelegate respondsToSelector:@selector(textFieldShouldBeginEditing:)]) {
        BOOL shouldBeginEditing = [self.outerDelegate textFieldShouldBeginEditing:textField];
        if (!shouldBeginEditing) {
            return false;
        }
    }
    return true;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (self.outerDelegate && [self.outerDelegate respondsToSelector:@selector(textFieldDidBeginEditing:)]) {
        [self.outerDelegate textFieldDidBeginEditing:textField];
    }
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    if (self.outerDelegate && [self.outerDelegate respondsToSelector:@selector(textFieldShouldEndEditing:)]) {
        BOOL shouldEndEditing = [self.outerDelegate textFieldShouldEndEditing:textField];
        if (!shouldEndEditing) {
            return false;
        }
    }
    return true;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (self.outerDelegate && [self.outerDelegate respondsToSelector:@selector(textFieldDidEndEditing:)]) {
        [self.outerDelegate textFieldDidEndEditing:textField];
    }
}

//ios10 +
- (void)textFieldDidEndEditing:(UITextField *)textField reason:(UITextFieldDidEndEditingReason)reason
{
    if (self.outerDelegate && [self.outerDelegate respondsToSelector:@selector(textFieldDidEndEditing:reason:)]) {
        [self.outerDelegate textFieldDidEndEditing:textField reason:reason];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (self.outerDelegate && [self.outerDelegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
        BOOL shouldChange = [self.outerDelegate textField:textField shouldChangeCharactersInRange:range replacementString:string];
        if (!shouldChange) {
            return false;
        }
    }
    
    NSString * originString = textField.text;
    NSString * result = [originString stringByReplacingCharactersInRange:range withString:string];
    NSLog(@"shouldChangeCharactersInRange :%@ %@ \n result:%@", NSStringFromRange(range) ,string ,result);
    
    self.changeRangeRecord = range;
    self.originText = textField.text;
    self.changedNewText = string;
    
    if ([self checkShouldUseRestrictInShouldChangeCharactersMethod:textField]) {
        BOOL isValid = [self checkStringIsValid:result];
        if (!isValid) {
            if (self.txtRestricted) { self.txtRestricted(self);}
            return isValid;
        }
    }
    
    return true;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    if (self.outerDelegate && [self.outerDelegate respondsToSelector:@selector(textFieldShouldClear:)]) {
        BOOL shouldClear = [self.outerDelegate textFieldShouldClear:textField];
        if (!shouldClear) {
            return false;
        }
    }
    return true;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (self.outerDelegate && [self.outerDelegate respondsToSelector:@selector(textFieldShouldReturn:)]) {
        BOOL shouldReturn = [self.outerDelegate textFieldShouldReturn:textField];
        if (!shouldReturn) {
            return false;
        }
    }
    return true;
}



@end
