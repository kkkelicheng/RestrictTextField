# RestrictTextField
有限制输入功能的输入框,支持Swift 和 OC版本 `SSYLimitTextField.swift`&`SSYRestrictedFiled.h`

# 如何使用
1. 下载demo
2. 将SSYLimitTextField这个文件夹下的`SSYLimitTextField.swift`文件拖入你的项目即可(`OC`是`SSYRestrictedFiled`)


# 功能举例
请看demo中的 
- 金额输入(限制2位小数输入)
- 限制最大的输入长度
- 中文限制
- 禁止输入emoji(请看`OCDemo中`的`[SSYRestrictField createNOEmoji]`例子)
- 其他

# 特点
- 对复制粘贴也完全判断
- 对超出的长度不会进行尾部截断,而是截取当前插入的字符串
- 监控textfiled输入改变后的内容,使用`timeThreshold`设置监听改变的时间,使用`txtChange`这个block获取改变的内容
- 继承`UITextField`,外界也可以对`SSYLimitTextField`进行完全的`UITextField`代理监听.(这点受到[InputKit](https://github.com/tingxins/InputKit)启发)


# 原理
- 主要是通过外界传入的限制(block判断 , 正则表达式)
- 针对键盘的类型做出判断,对于有候选字的键盘当前就已知有`zh-Hans`,如果有其他的键盘,例如日文,请自行在`markedTextRangeLanguages`属性中加入


# 说明
- SSYLimitTextField这个文件夹下另外2个文件(SSYRegEx 和 SSYLimitTextField+Create)都是辅助文件,可以用可以不用.
- 有bug的话请反馈

# demo样式
![demoImage](https://github.com/kkkelicheng/RestrictTextField/blob/master/sampleImage.png)

