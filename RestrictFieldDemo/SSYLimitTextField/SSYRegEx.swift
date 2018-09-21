//
//  SSYRegEx.swift
//
//  Created by kkkelicheng on 2018/8/21.
//  Copyright © 2018年 ShuShangYun. All rights reserved.
//

import Foundation

public struct SSYRegEx {
    static let  ExOnlyNumber =  "^[0-9]+$"
    
    static let  ExOnlyChinese = "^[\\u4e00-\\u9fa5]{0,}$"
    
    static let  ExOnlyLetter =  "^[A-Za-z]+$"
    
    static let  ExLetterAndNumber = "^[0-9A-Za-z]+$"
    
    ///不能是0d开头的
    static let  ExZeroNumberBegin = "^([0]\\d+)"

    static func normalPriceRegEx() -> [String]{
        // 有两位小数点的
        let normalDigit = "^\\d{0,10}([.][0-9]{0,2})?$";
        return [normalDigit];
    }
}



