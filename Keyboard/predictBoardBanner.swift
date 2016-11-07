//
//  predictboardBanner.swift
//  TastyImitationKeyboard
//
//  Created by Alexei Baboulevitch on 10/5/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import UIKit

/*
 This is the demo banner. The banner is needed so that the top row popups have somewhere to go. Might as well fill it
 with something (or leave it blank if you like.)
 */

class predictboardBanner: ExtraView {
    
    let numButtons = UserDefaults.standard.integer(forKey: "numberACSbuttons")
    let allButtons = UserDefaults.standard.integer(forKey: "numberACSbuttons") + 1
    let numRows = UserDefaults.standard.integer(forKey: "numberACSrows")
    var buttons = [BannerButton]()
    let profileSelector = BannerButton()
    let defaultView = PassThroughView()
    let textInputView = PassThroughView()
    let textField = UITextField()
    let textFieldLabel = UILabel()
    let backButton = UIButton()
    let saveButton = UIButton()
    
    required init(globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool) {

        
        super.init(globalColors: globalColors, darkMode: darkMode, solidColorMode: solidColorMode)
        
        defaultView.frame = CGRect(x: self.getMinX(), y: self.getMinY(), width: self.frame.width, height: self.frame.height)
        self.addSubview(defaultView)
        
        textInputView.frame = CGRect(x: self.getMinX(), y: self.getMinY(), width: self.frame.width, height: self.frame.height)
        self.addSubview(textInputView)
        textInputView.isHidden = true
        
        let fontSize = CGFloat(22)
        
        for _ in 0..<self.numButtons {
            let button: BannerButton = BannerButton()
            button.type = "ACButton"
            buttons.append(button)
            defaultView.addSubview(button)
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.clear.cgColor
            button.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
            button.addTarget(self, action: #selector(buttonClicked), for: .touchDown)
            button.addTarget(self, action: #selector(buttonClicked), for: .touchDragEnter)
            button.addTarget(self, action: #selector(buttonUnclicked), for: .touchDragExit)
            button.addTarget(self, action: #selector(buttonUnclicked), for: .touchUpInside)
        }
        
        //add profile selector button
        self.profileSelector.type = "SelectorButton"
        defaultView.addSubview(self.profileSelector)
        self.profileSelector.layer.borderWidth = 1
        self.profileSelector.layer.cornerRadius = 5
        self.profileSelector.layer.borderColor = UIColor.clear.cgColor
        self.profileSelector.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
        self.profileSelector.addTarget(self, action: #selector(buttonClicked), for: .touchDown)
        self.profileSelector.addTarget(self, action: #selector(buttonClicked), for: .touchDragEnter)
        self.profileSelector.addTarget(self, action: #selector(buttonUnclicked), for: .touchDragExit)
        self.profileSelector.addTarget(self, action: #selector(buttonUnclicked), for: .touchUpInside)
        
        
        self.textField.placeholder = "Enter new profile name"
        self.textField.font = UIFont.systemFont(ofSize: fontSize)
        self.textField.borderStyle = UITextBorderStyle.roundedRect
        self.textField.autocorrectionType = UITextAutocorrectionType.no
        self.textField.returnKeyType = UIReturnKeyType.done
        self.textField.clearButtonMode = UITextFieldViewMode.whileEditing;
        self.textField.contentVerticalAlignment = UIControlContentVerticalAlignment.center
        self.textInputView.addSubview(self.textField)
        
        self.textFieldLabel.text = "Profile Name:"
        self.textFieldLabel.textAlignment = .right
        self.textFieldLabel.font = UIFont.systemFont(ofSize: fontSize)
        self.textInputView.addSubview(self.textFieldLabel)
        
        self.backButton.setTitle("Back", for: UIControlState())
        self.backButton.layer.cornerRadius = 5
        self.backButton.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
        self.backButton.addTarget(self, action: #selector(selectDefaultView), for: .touchUpInside)
        self.textInputView.addSubview(self.backButton)
        
        
        self.saveButton.setTitle("Save", for: UIControlState())
        self.saveButton.layer.cornerRadius = 5
        self.saveButton.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
        self.saveButton.addTarget(self, action: #selector(selectDefaultView), for: .touchUpInside)
        self.textInputView.addSubview(self.saveButton)
        
        updateAppearance()
        
        UserDefaults.standard.register(defaults: ["keyboardInputToApp": true])
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        switchView()
        
        let widthBut = (self.getMaxX() - self.getMinX()) / CGFloat(self.allButtons) * CGFloat(self.numRows)
        let heightBut = (self.getMaxY() - self.getMinY()) / CGFloat(self.numRows)
        //let halfWidth = widthBut / CGFloat(2)
        
        var x_offset = CGFloat(0)
        var y_offset = CGFloat(0)
        for index in 0..<self.numButtons {
            buttons[index].frame = CGRect(x: (self.getMinX() + x_offset), y: self.getMinY() + y_offset, width: widthBut - 1, height: heightBut - 1)
            x_offset += widthBut
            if (index + 1) % (self.allButtons / self.numRows) == 0 {
                y_offset += heightBut
                x_offset = CGFloat(0)
            }
        }
        self.profileSelector.frame = CGRect(x: (self.getMinX() + x_offset), y: self.getMinY() + y_offset, width: widthBut - 1, height: heightBut - 1)
        
        let textWidth:CGFloat = 300
        let textHeight:CGFloat = 40
        self.textField.frame = CGRect(x: self.getMidX() - textWidth / CGFloat(3), y: self.getMidY() - textHeight / CGFloat(2), width: textWidth, height: textHeight)
        
        
        let labelWidth:CGFloat = 150
        let buttonSpacing:CGFloat = 8
        self.textFieldLabel.frame = CGRect(x: self.textField.frame.origin.x - labelWidth - buttonSpacing, y:self.textField.frame.origin.y, width: labelWidth, height: textHeight)

        self.backButton.frame = CGRect(x: 0, y: self.textField.frame.origin.y, width: 60, height: 40)
        self.saveButton.frame = CGRect(x: self.getMaxX() - 60, y: self.textField.frame.origin.y, width: 60, height: 40)
        
    }
    
    override func updateAppearance()
    {
        var allButtons: [UIButton] = self.buttons
        allButtons.append(self.backButton)
        allButtons.append(self.saveButton)
        for button in allButtons{
            button.backgroundColor = globalColors?.specialKey(darkMode, solidColorMode: solidColorMode)
            button.setTitleColor((self.globalColors?.darkModeTextColor), for: UIControlState.normal)
            button.setTitleColor((darkMode ? self.globalColors?.darkModeTextColor : self.globalColors?.lightModeTextColor), for: UIControlState.highlighted)
        }
        
        self.textField.keyboardAppearance = (darkMode ? .dark : .light)
        
        self.profileSelector.backgroundColor = globalColors?.regularKey(darkMode, solidColorMode: solidColorMode)
        //self.profileSelector.titleLabel?.textColor = self.globalColors?.lightModeTextColor
        self.profileSelector.setTitleColor((darkMode ? self.globalColors?.darkModeTextColor : self.globalColors?.lightModeTextColor), for: UIControlState.normal)
        self.profileSelector.setTitleColor(self.globalColors?.darkModeTextColor, for: UIControlState.highlighted)
        
        self.textFieldLabel.textColor = (darkMode ? self.globalColors?.darkModeTextColor : self.globalColors?.lightModeTextColor)
    }
    
    func buttonClicked(_ sender:BannerButton){
        if sender.type == "ACButton" {
            sender.backgroundColor = globalColors?.regularKey(darkMode, solidColorMode: solidColorMode)
        }
        else if sender.type == "SelectorButton" {
            sender.backgroundColor = globalColors?.specialKey(darkMode, solidColorMode: solidColorMode)
        }
    }
    
    func buttonUnclicked(_ sender:BannerButton){
        if sender.type == "ACButton" {
            sender.backgroundColor = globalColors?.specialKey(darkMode, solidColorMode: solidColorMode)
        }
        else if sender.type == "SelectorButton" {
            sender.backgroundColor = globalColors?.regularKey(darkMode, solidColorMode: solidColorMode)
        }
    }
    
    func selectDefaultView() {
        self.textField.text = ""
        UserDefaults.standard.register(defaults: ["keyboardInputToApp": true])
        switchView()
    }
    
    func selectTextView() {
        UserDefaults.standard.register(defaults: ["keyboardInputToApp": false])
        switchView()
    }
    
    
    func switchView(){
        if UserDefaults.standard.bool(forKey: "keyboardInputToApp") == true {
            self.bringSubview(toFront: self.defaultView)
            self.defaultView.isHidden = false
            self.defaultView.isUserInteractionEnabled = true
            self.textInputView.isHidden = true
            self.textInputView.isUserInteractionEnabled = false
        }
        else {
            self.bringSubview(toFront: self.textInputView)
            self.textInputView.isHidden = false
            self.textInputView.isUserInteractionEnabled = true
            self.defaultView.isHidden = true
            self.defaultView.isUserInteractionEnabled = false
        }
    }
    

}



