//
//  ViewController.swift
//  RestrictFieldDemo
//
//  Created by sun on 2018/9/19.
//  Copyright © 2018年 ShuShangYun. All rights reserved.
//

import UIKit

let SCREEN_WIDTH = UIScreen.main.bounds.width;
let SCREEN_HEIGHT = UIScreen.main.bounds.height;

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addUI();
    }
    
    func addUI(){
        let countLimitTF = SSYLimitTextField.init(frame:CGRect.init(x: 20, y: 100, width: SCREEN_WIDTH - 40, height: 38));
        do{
            countLimitTF.borderStyle = .line
            countLimitTF.placeholder = "限制输入6位"
            countLimitTF.countLimit = 6;
            countLimitTF.timeThreshold = 1000;  //1s
            self.view.addSubview(countLimitTF);
        }
        
        let letterAndNumberTF = SSYLimitTextField.init(frame:CGRect.init(x: 20, y: 150, width: SCREEN_WIDTH - 40, height: 38));
        do{
            letterAndNumberTF.borderStyle = .line
            letterAndNumberTF.placeholder = "请输入字母或者数字"
            letterAndNumberTF.addRegEx(regEx: SSYRegEx.ExLetterAndNumber);
            self.view.addSubview(letterAndNumberTF);
        }
        
        let chineseTF = SSYLimitTextField.init(frame:CGRect.init(x: 20, y: 200, width: SCREEN_WIDTH - 40, height: 38));
        do{
            chineseTF.borderStyle = .line
            chineseTF.placeholder = "请输入中文名进行搜索"
            chineseTF.addRegEx(regEx: SSYRegEx.ExOnlyChinese);
            chineseTF.timeThreshold = 1000;  //1s
            chineseTF.txtChange = {
                if let string = $0{
                    print("搜索\(string)")
                }
            }
            self.view.addSubview(chineseTF);
        }
        
        let priceTF = SSYLimitTextField.createPriceTF()
        priceTF.frame  = CGRect(x: 20, y: 250, width: SCREEN_WIDTH - 40, height: 38);
        do{
            priceTF.borderStyle = .line
            priceTF.placeholder = "金额输入框"
            self.view.addSubview(priceTF);
        }
        
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}

