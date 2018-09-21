//
//  SSYLimitTextFieldExtension.swift
//
//  Created by kkkelicheng on 2018/8/21.
//  Copyright © 2018年 ShuShangYun. All rights reserved.
//

import Foundation

extension SSYLimitTextField {
    static func createPriceTF() -> SSYLimitTextField {
        let vertify = { (txt : String) -> Bool in
            let predicate = NSPredicate(format: "SELF MATCHES %@", SSYRegEx.ExZeroNumberBegin);
            let isZero = predicate.evaluate(with: txt)
            return !isZero;
        }
        let normalPriceRegEx = SSYRegEx.normalPriceRegEx();
        
        let priceTF = SSYLimitTextField.init(frame: .zero);
        priceTF.addRegExs(regExs: normalPriceRegEx);
        priceTF.addVertify(block: vertify);
        return priceTF;
    }
    
    static func createLetterNumberTF() -> SSYLimitTextField {
        let letterNumberRegEx = SSYRegEx.ExLetterAndNumber;
        let tf = SSYLimitTextField.init(frame: .zero);
        tf.addRegEx(regEx: letterNumberRegEx);
        return tf;
    }
    
    static func createChineseTF() -> SSYLimitTextField {
        let chineseReg = SSYRegEx.ExOnlyChinese;
        let tf = SSYLimitTextField.init(frame: .zero);
        tf.addRegEx(regEx: chineseReg);
        return tf;
    }
}
