//
//  SSYLimitTextField.swift
//
//  Created by kkkelicheng on 2018/8/21.
//  Copyright © 2018年 ShuShangYun. All rights reserved.
//

import UIKit

public class SSYLimitTextField: UITextField {
    
    //外界的代理
    weak var outerDelegate : UITextFieldDelegate?;
    
    //正则表达式容器
    private var regExs : [String]?;
    
    //外界用来判断结果的block容器
    private var vertifyBlocks : [(String)->Bool]?
    
    private var markedTextRangeLanguages = ["zh-Hans"];
    
    //延迟通知textfield内容已经改变的时间 , 毫秒
    var timeThreshold = 800;
    
    //辅助的记录时间
    var changeRecordTime : Int!
    
    //改变text的回调,外界可以监听
    var txtChange : ((String?) -> Void)?
    
    //发生限制时输入的回调
    var txtRestricted : ((SSYLimitTextField)-> Void)?
    
    //上一次变更的记录
    private var previousRangeRecord : NSRange?
    
    //最大输入量
    var countLimit : Int = Int(MAX_INPUT);
    
    /*
     下面三个属性主要是用来保存在没有markTextRange的情况下，
     在插入限制的情况下，恢复部分新增的数据，而不是单纯的保存新增而去截取掉之前的数据
     */
    private var changeRangeRecord : NSRange?
    private var originText        : String?
    private var changedNewText    : String = ""
    
    override init(frame: CGRect) {
        super.init(frame: frame);
        super.delegate = self;
        self.registerTFChange();
        autocorrectionType = .no
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!;
    }
    
    deinit {
        self.unregisterTFChange();
    }
    
    //将父类的代理设置为自己,外界的代理通过自己来调用,相当于hook UITextField的代理
    override weak public var delegate: UITextFieldDelegate?{
        set{
            self.outerDelegate = delegate;
            super.delegate = self;
        }
        get{
           return self.outerDelegate;
        }
    }
    
    public func addVertify(block:@escaping (String)->Bool){
        if self.vertifyBlocks == nil {
            self.vertifyBlocks = [];
        }
        self.vertifyBlocks!.append(block);
    }
    
    public func addVertifies(blocks:[(String)->Bool]){
        if self.vertifyBlocks == nil {
            self.vertifyBlocks = [];
        }
        self.vertifyBlocks!.append(contentsOf: blocks);
    }

    public func addRegExs(regExs:[String]){
        if self.regExs == nil {
            self.regExs = [];
        }
        self.regExs?.append(contentsOf: regExs);
    }
    
    public func addRegEx(regEx:String){
        if self.regExs == nil {
            self.regExs = [];
        }
        self.regExs?.append(regEx);
    }
}

// notification
extension SSYLimitTextField {  //private
    
    private func sendText(){
        let currentTime = Int(Date().timeIntervalSince1970 * 1000);
        if currentTime - self.changeRecordTime >= timeThreshold {
            print("sendText  : \(self.text ?? "")")
            txtChange?(self.text)
        }
    }
    
    private func delaySendText(){
        self.changeRecordTime = Int(Date().timeIntervalSince1970 * 1000);
        let dealLine = DispatchTime.now() + .milliseconds(self.timeThreshold);
        DispatchQueue.main.asyncAfter(deadline:dealLine) {
            self.sendText();
        }
    }
    
    private func registerTFChange(){
        NotificationCenter.default.addObserver(self, selector: #selector(textFieldDidChangeNoti(noti:)), name: Notification.Name.UITextFieldTextDidChange, object: nil);
    }
    
    private func unregisterTFChange(){
        NotificationCenter.default.removeObserver(self);
    }
    
    private func fixUITextRangeToRange(txRange:UITextRange?,tf:UITextField) -> NSRange?{
        guard let txRange = txRange else {
            return nil;
        }

        let location = tf.offset(from: tf.beginningOfDocument, to: txRange.start);
        let length = tf.offset(from: txRange.start, to: txRange.end);
        let range = NSRange(location: location, length: length);
        return range;
    }
    
    //这里面统一处理字符串的长度
    @objc private func textFieldDidChangeNoti(noti:Notification){
        guard
            let tf = noti.object as? UITextField ,
            tf == self,
            let currentString = tf.text
        else {
            return;
        }
        
        print("textFieldDidChangeNoti")
        print(tf.markedTextRange ?? "no MarkedRange")

        // first handle other restrict then handle text length then
        
        if self.checkShouldUseRestrictInDidChangeNoti(tf: tf) {
            // 这里self.markedTextRange 都是 nil
            var stringPrivious = currentString;
            //如果当前输入或者插入字不是合法的,直接移除,都不用判断长度了.否则再进行下一阶段长度判断
            if !self.checkStringIsValid(checkString: currentString)
            {
                //声明一个替换的range
                //在有markedTextRange的语言的情况下,输入数字或者标点会进入下面方法
                if self.changeRangeRecord != nil , self.previousRangeRecord == nil{
                    stringPrivious = self.originText ?? "";
                }
                else if self.previousRangeRecord != nil{
                    //subString直接插入导致限制,那么直接remove掉插入的subString
                    let stringRange = Range<String.Index>(self.previousRangeRecord!, in: stringPrivious);
                    if let stringRange = stringRange {
                        stringPrivious.removeSubrange(stringRange);
                    }
                }
                tf.text = stringPrivious;
                self.txtRestricted?(self);
            }
            //之前的都没验证通过,是直接去掉了substring,长度应该是没问题. 能到这里之前一定是合法的
            else if currentString.count > self.countLimit
            {
                //判断previousRangeRecord,如果有就是中文有markRange变动来带的长度过长
                if let previousRangeRecord = self.previousRangeRecord
                {
                    let overCount = currentString.count - self.countLimit ;  //超出的字符个数
                    let indent = previousRangeRecord.length - overCount; //int
                    let location = previousRangeRecord.location + indent; //int
                    let removeNSRange = NSRange(location: location, length: overCount);
                    var tempString = currentString;
                    if let removeRange = Range(removeNSRange, in: tempString){
                        tempString.removeSubrange(removeRange);
                    }
                    tf.text = tempString;
                    self.txtRestricted?(self);
                }
                else if let recordedRange = self.changeRangeRecord,
                        var recordedText  = self.originText
                {
                    //通知已经限制
                    self.txtRestricted?(self);
                    let overCount = currentString.count - self.countLimit ;
                    let endIndex = self.changedNewText.index(self.changedNewText.endIndex, offsetBy: -overCount);
                    let trimedNewString = self.changedNewText[..<endIndex];
                    if let replaceRange = Range<String.Index>(recordedRange, in: recordedText){
                        recordedText.replaceSubrange(replaceRange, with: trimedNewString);
                        tf.text = recordedText;
                    }
                }
            }
            
        }
        
        else if(self.checkShouldUseRestrictInShouldChangeCharactersMethod(tf: tf)){ //之前限制了的,在这里做长度判断
            //在这里解决length的超出
            if currentString.count > self.countLimit,
                let recordedRange = self.changeRangeRecord,
                var recordedText  = self.originText
            {
                //通知已经限制
                self.txtRestricted?(self);
                let overCount = currentString.count - self.countLimit ;
                let endIndex = self.changedNewText.index(self.changedNewText.endIndex, offsetBy: -overCount);
                let trimedNewString = self.changedNewText[..<endIndex];
                if let replaceRange = Range<String.Index>(recordedRange, in: recordedText){
                    recordedText.replaceSubrange(replaceRange, with: trimedNewString);
                    tf.text = recordedText;
                }
            }
        }
        
        //单独拿出来
        if (tf.markedTextRange == nil){
            self.delaySendText();
        }
        
        //记录上一次的选中状态
        previousRangeRecord = self.fixUITextRangeToRange(txRange: tf.markedTextRange, tf: tf);
    }
    
}

// check
extension SSYLimitTextField {
    
    func checkStringIsValid(checkString : String) -> Bool {
        
        if let regExpressions = self.regExs , regExpressions.count > 0 {
            for regExpression in regExpressions {
                let predicate = NSPredicate(format: "SELF MATCHES %@", regExpression);
                let isRegValid = predicate.evaluate(with:checkString)
                if !isRegValid {
                    return false;
                }
            }
        }
        
        if let vertifies = self.vertifyBlocks , vertifies.count > 0 {
            for vertify in vertifies{
                let isValid = vertify(checkString);
                if !isValid {
                    return false;
                }
            }
        }
        
        return true;
    }
    
    //为什么要放在两个地方进行限制操作?
    /*
        1. 假如英文,每次改变没有markedTextRange,只在DidChangeNoti中的话,只会得到前一次的text,和当前的text.没有其他的range来标记
    */
    
    /*
        现在直接通过键盘类型来判断吧,最早是通过输入的时候判断有没有候选标记,
        但是在初次的时候,是没有候选标记的,等到didChange后,才会有标记.
        然后后续的输入是有候选标记的
        为了减少从外面进行判断的逻辑,这里就采用键盘来判断了
        如果不在ChangeCharacters限制,那么就在DidChangeNoti限制
     */
    func checkShouldUseRestrictInShouldChangeCharactersMethod(tf:UITextField) -> Bool{
        //如果有markedRange直接过,不进行正则和block的限制
        let inputModel = tf.textInputMode?.primaryLanguage;
        print("当前键盘的语言为:\(inputModel!)")
        if let language = inputModel ,
            self.markedTextRangeLanguages.contains(language)
        {
            return false;
        }
        return true;
    }
    
    /*
     直接取反
     */
    func checkShouldUseRestrictInDidChangeNoti(tf:UITextField) -> Bool{
        //如果有markedRange直接过,不进行正则和block的限制
        let inputModel = tf.textInputMode?.primaryLanguage;
        print("当前键盘的语言为:\(inputModel!)")
        if  let language = inputModel ,
            self.markedTextRangeLanguages.contains(language),
            tf.markedTextRange == nil
        {
            return true;
        }
        return false;
    }

}


//hook TextField 代理
extension SSYLimitTextField : UITextFieldDelegate{
    
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool
    {
        if let outerDelegate = self.outerDelegate,
            let isShould = outerDelegate.textFieldShouldBeginEditing?(self){
            return isShould;
        }
        return true;
    }
    
    public func textFieldDidBeginEditing(_ textField: UITextField)
    {
        if let outerDelegate = self.outerDelegate{
            outerDelegate.textFieldDidBeginEditing?(self)
        }
    }
    
    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool
    {
        if let outerDelegate = self.outerDelegate,
            let isShould = outerDelegate.textFieldShouldEndEditing?(self){
            return isShould;
        }
        return true;
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField)
    {
        if let outerDelegate = self.outerDelegate{
            outerDelegate.textFieldDidEndEditing?(self)
        }
    }
    
    @available(iOS 10.0, *)
    public func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason)
    {
        if let outerDelegate = self.outerDelegate{
            outerDelegate.textFieldDidEndEditing?(self,reason:reason)
        }
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
    {
        
        if let outerDelegate = self.outerDelegate,
            let delegateShouldReplacement = outerDelegate.textField?(self, shouldChangeCharactersIn: range, replacementString: string){
            // 外面的代理如果不允许变化就直接不变了
            if !delegateShouldReplacement{
                return false;
            }
        }
        
        print("textField ~\(textField.text ?? "")~  range location:\(range.location) range length:\(range.length)");

        
        var willResultString = "";
        if var currentString = textField.text , let range : Range<String.Index> = Range(range, in: currentString) {
            currentString.replaceSubrange(range, with: string);
            willResultString = currentString;
            print("willResultString: |\(willResultString)|")
        }
        
        //判断一下在当前的shouldChangeCharactersIn方法中是否要处理这些限制逻辑
        
        let shouldRestrict = self.checkShouldUseRestrictInShouldChangeCharactersMethod(tf: textField);
        //记录一下
        self.changeRangeRecord = range;
        self.originText = textField.text;
        self.changedNewText = string;
        
        if shouldRestrict { //如果是在在当前方法限制,直接在这里处理了
            
            let isValid = self.checkStringIsValid(checkString: willResultString);
            if !isValid {self.txtRestricted?(self)}
            return isValid;
        }
        else {  //中文有选中的状态会直接不做处理,会放在textFieldDidChangeNoti方法中处理
            return true;
        }
    }
 
    public func textFieldShouldClear(_ textField: UITextField) -> Bool{
        if let outerDelegate = self.outerDelegate,
            let shouldClear = outerDelegate.textFieldShouldClear?(self){
            return shouldClear;
        }
        return true;
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        if let outerDelegate = self.outerDelegate,
            let shouldReturn = outerDelegate.textFieldShouldReturn?(self){
            return shouldReturn;
        }
        return true;
    }

}
