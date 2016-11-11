
//  TextInputBanner.swift
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

class TextInputBanner: ExtraView {
    
    let textInputView = PassThroughView()
    let textField = UITextField()
    let textFieldLabel = UILabel()
    let backButton = UIButton()
    let saveButton = UIButton()
    
    required init(globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool) {
        
        
        super.init(globalColors: globalColors, darkMode: darkMode, solidColorMode: solidColorMode)
        
        
        textInputView.frame = CGRect(x: self.getMinX(), y: self.getMinY(), width: self.frame.width, height: self.frame.height)
        self.addSubview(textInputView)
        textInputView.isHidden = true
        self.textField.isUserInteractionEnabled = true
        let fontSize = CGFloat(22)
        
        
        
        self.textField.placeholder = "Just Start Typing"
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
        //self.backButton.addTarget(self, action: #selector(selectDefaultView), for: .touchUpInside)
        self.textInputView.addSubview(self.backButton)
        
        
        self.saveButton.setTitle("Save", for: UIControlState())
        self.saveButton.layer.cornerRadius = 5
        self.saveButton.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
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
        var allButtons: [UIButton] = []
        allButtons.append(self.backButton)
        allButtons.append(self.saveButton)
        for button in allButtons{
            button.backgroundColor = globalColors?.specialKey(darkMode, solidColorMode: solidColorMode)
            button.setTitleColor((self.globalColors?.darkModeTextColor), for: UIControlState.normal)
            button.setTitleColor((darkMode ? self.globalColors?.darkModeTextColor : self.globalColors?.lightModeTextColor), for: UIControlState.highlighted)
        }
        
        self.textField.keyboardAppearance = (darkMode ? .dark : .light)
        
 
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
    
    
    
    
    
}



