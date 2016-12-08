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

class PredictboardBanner: ExtraView {
    
    let numButtons = UserDefaults.standard.integer(forKey: "numberACSbuttons")
    let allButtons = UserDefaults.standard.integer(forKey: "numberACSbuttons") + 2
    let numRows = UserDefaults.standard.integer(forKey: "numberACSrows")
    var buttons = [BannerButton]()
    let profileSelector = BannerButton()
    let phraseSelector = BannerButton()
    let defaultView = PassThroughView()
    let textInputView = PassThroughView()
    let loadingView = PassThroughView()
    let textField = UITextField()
    let textFieldLabel = UILabel()
    let backButton = UIButton()
    let saveButton = UIButton()
    let pasteButton = UIButton()
    let clearButton = UIButton()
    let loadingLabel = UILabel()
    
    let warningView = UIView()
    let warningTitle = UILabel()
    let warningMessage = UILabel()
    let warningButton = UIButton()
    
    let progressBar = UIProgressView()
    var counter:Int = 0 {
        didSet {
            let fractionalProgress = Float(counter) / 100.0
            let animated = counter != 0
            
            self.progressBar.setProgress(fractionalProgress, animated: animated)
        }
    }
    
    required init(globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool) {
        let defaults = UserDefaults.standard
        
        super.init(globalColors: globalColors, darkMode: darkMode, solidColorMode: solidColorMode)
        
        defaultView.frame = CGRect(x: self.getMinX(), y: self.getMinY(), width: self.frame.width, height: self.frame.height)
        self.addSubview(defaultView)
        defaultView.isHidden = true
        
        textInputView.frame = CGRect(x: self.getMinX(), y: self.getMinY(), width: self.frame.width, height: self.frame.height)
        self.addSubview(textInputView)
        textInputView.isHidden = true
        
        loadingView.frame = CGRect(x: self.getMinX(), y: self.getMinY(), width: self.frame.width, height: self.frame.height)
        self.addSubview(loadingView)
        loadingView.isHidden = false
        
        //if textField is selected, we cant type on the main app anymore
        self.textField.isUserInteractionEnabled = false
        
        let largeFont = CGFloat(30)
        let fontSize = CGFloat(22)
        
        for _ in 0..<self.numButtons {
            let button: BannerButton = BannerButton()
            button.type = "ACButton"
            buttons.append(button)
            defaultView.addSubview(button)
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.clear.cgColor
            button.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.addTarget(self, action: #selector(buttonClicked), for: .touchDown)
            button.addTarget(self, action: #selector(buttonClicked), for: .touchDragEnter)
            button.addTarget(self, action: #selector(buttonUnclicked), for: .touchDragExit)
            button.addTarget(self, action: #selector(buttonUnclicked), for: .touchUpInside)
        }
        
        //add profile selector button
        self.profileSelector.type = "SelectorButton"
        defaultView.addSubview(self.profileSelector)
        self.profileSelector.titleLabel?.adjustsFontSizeToFitWidth = true
        self.profileSelector.layer.borderWidth = 1
        self.profileSelector.layer.cornerRadius = 5
        self.profileSelector.layer.borderColor = UIColor.clear.cgColor
        self.profileSelector.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
        self.profileSelector.addTarget(self, action: #selector(buttonClicked), for: .touchDown)
        self.profileSelector.addTarget(self, action: #selector(buttonClicked), for: .touchDragEnter)
        self.profileSelector.addTarget(self, action: #selector(buttonUnclicked), for: .touchDragExit)
        self.profileSelector.addTarget(self, action: #selector(buttonUnclicked), for: .touchUpInside)
        
        self.phraseSelector.type = "SelectorButton"
        defaultView.addSubview(self.phraseSelector)
        self.phraseSelector.titleLabel?.adjustsFontSizeToFitWidth = true
        self.phraseSelector.layer.borderWidth = 1
        self.phraseSelector.layer.cornerRadius = 5
        self.phraseSelector.layer.borderColor = UIColor.clear.cgColor
        self.phraseSelector.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
        self.phraseSelector.addTarget(self, action: #selector(buttonClicked), for: .touchDown)
        self.phraseSelector.addTarget(self, action: #selector(buttonClicked), for: .touchDragEnter)
        self.phraseSelector.addTarget(self, action: #selector(buttonUnclicked), for: .touchDragExit)
        self.phraseSelector.addTarget(self, action: #selector(buttonUnclicked), for: .touchUpInside)
        self.phraseSelector.setTitle("Phrases", for: .normal)
        
        self.textField.placeholder = "Just Start Typing"
        self.textField.font = UIFont.systemFont(ofSize: fontSize)
        self.textField.borderStyle = UITextBorderStyle.roundedRect
        self.textField.autocorrectionType = UITextAutocorrectionType.no
        self.textField.returnKeyType = UIReturnKeyType.done
        self.textField.clearButtonMode = UITextFieldViewMode.whileEditing;
        self.textField.contentVerticalAlignment = UIControlContentVerticalAlignment.center
        self.textField.adjustsFontSizeToFitWidth = true
        self.textInputView.addSubview(self.textField)
        
        //self.textFieldLabel.text = "Profile Name:"
        self.textFieldLabel.textAlignment = .right
        self.textFieldLabel.font = UIFont.systemFont(ofSize: fontSize)
        self.textInputView.addSubview(self.textFieldLabel)
        
        self.backButton.setTitle("Cancel", for: UIControlState())
        self.backButton.layer.cornerRadius = 5
        self.backButton.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
        self.textInputView.addSubview(self.backButton)
        
        
        self.saveButton.setTitle("Save", for: UIControlState())
        self.saveButton.layer.cornerRadius = 5
        self.saveButton.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
        self.textInputView.addSubview(self.saveButton)
        
        self.pasteButton.setTitle("Paste", for: UIControlState())
        self.pasteButton.layer.cornerRadius = 5
        self.pasteButton.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
        self.textInputView.addSubview(self.pasteButton)
        self.pasteButton.addTarget(self, action: #selector(pasteInTextbox), for: .touchUpInside)
        
        self.clearButton.setTitle("Clear", for: UIControlState())
        self.clearButton.layer.cornerRadius = 5
        self.clearButton.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
        self.textInputView.addSubview(self.clearButton)
        self.clearButton.addTarget(self, action: #selector(clearTextbox), for: .touchUpInside)
        
        self.warningView.layer.cornerRadius = 20
        self.warningView.backgroundColor = UIColor.white
        self.warningView.layer.borderColor = UIColor.gray.cgColor
        self.warningView.layer.borderWidth = 1
        self.textInputView.addSubview(self.warningView)
        
        self.warningTitle.font = UIFont.boldSystemFont(ofSize: largeFont)
        self.warningTitle.adjustsFontSizeToFitWidth = true
        self.warningTitle.textAlignment = .center
        self.warningView.addSubview(self.warningTitle)
        
        
        self.warningMessage.font = UIFont.systemFont(ofSize: fontSize)
        self.warningMessage.textAlignment = .center
        self.warningTitle.adjustsFontSizeToFitWidth = true
        self.warningMessage.numberOfLines = 0
        self.warningView.addSubview(self.warningMessage)
        
        
        self.warningButton.setTitle("OK", for: .normal)
        self.warningButton.setTitleColor(UIColor.init(red: 20/255, green: 123/255, blue: 255/255, alpha: 1), for: UIControlState.normal)
        self.warningButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: largeFont)
        self.warningView.addSubview(self.warningButton)
        self.warningButton.addTarget(self, action: #selector(hideWarningView), for: .touchUpInside)
        
        self.loadingLabel.text = "Loading Predictions (may take several minutes)"
        self.loadingLabel.textAlignment = .center
        self.loadingLabel.font = UIFont.systemFont(ofSize: fontSize)
        self.loadingView.addSubview(self.loadingLabel)
        
        self.loadingView.addSubview(progressBar)
        
        hideWarningView()
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
        
        
        
        let widthBut = (self.getMaxX() - self.getMinX()) / CGFloat(self.allButtons) * CGFloat(self.numRows)
        let heightBut = (self.getMaxY() - self.getMinY()) / CGFloat(self.numRows)
        //let halfWidth = widthBut / CGFloat(2)
        
        var x_offset = CGFloat(0)
        var y_offset = CGFloat(0)
        var row = 0
        var buttonIndex = 0
        for index in 0..<self.allButtons {
            if row == 0 && index + 1 == self.allButtons / self.numRows {
                self.profileSelector.frame = CGRect(x: (self.getMinX() + x_offset), y: self.getMinY() + y_offset, width: widthBut - 1, height: heightBut - 1)
            }
            else if row == 0 && index == 0 {
                self.phraseSelector.frame = CGRect(x: (self.getMinX() + x_offset), y: self.getMinY() + y_offset, width: widthBut - 1, height: heightBut - 1)
            }
            else{
                buttons[buttonIndex].frame = CGRect(x: (self.getMinX() + x_offset), y: self.getMinY() + y_offset, width: widthBut - 1, height: heightBut - 1)
                buttonIndex += 1
            }
            x_offset += widthBut
            if (index + 1) % (self.allButtons / self.numRows) == 0 {
                y_offset += heightBut
                x_offset = CGFloat(0)
                row += 1
            }
        }
        
        let textWidth:CGFloat = 300
        let textHeight:CGFloat = 40
        self.textField.frame = CGRect(x: self.getMidX() - textWidth / CGFloat(3), y: self.getMidY() - textHeight / CGFloat(2), width: textWidth, height: textHeight)
        
        
        let labelWidth:CGFloat = 150
        let buttonSpacing:CGFloat = 8
        self.textFieldLabel.frame = CGRect(x: self.textField.frame.origin.x - labelWidth - buttonSpacing, y:self.textField.frame.origin.y, width: labelWidth, height: textHeight)
        
        let butWidth:CGFloat = 75
        let backButtonX = (self.textFieldLabel.frame.origin.x - butWidth) / 2
        let saveButtonX = (self.getMaxX() - self.textField.frame.maxX - butWidth) / 2 + self.textField.frame.maxX
        
        
        self.backButton.frame = CGRect(x: backButtonX, y: self.textField.frame.origin.y, width: butWidth, height: 40)
        self.saveButton.frame = CGRect(x: saveButtonX , y: self.textField.frame.origin.y, width: butWidth, height: 40)
        self.pasteButton.frame = CGRect(x: backButtonX, y: self.textField.frame.origin.y - 50, width: butWidth, height: 40)
        self.clearButton.frame = CGRect(x: saveButtonX, y: self.textField.frame.origin.y - 50, width: butWidth, height: 40)
        
        let warningViewWidth = (self.getMaxX() - self.getMinX()) * CGFloat(0.75)
        let warningViewHeight = (self.getMaxY() - self.getMinY()) * CGFloat(0.9)
        self.warningView.frame = CGRect(x: self.getMidX() - warningViewWidth / CGFloat(2), y: self.getMidY() - warningViewHeight / CGFloat(2), width: warningViewWidth, height: warningViewHeight)
        
        self.warningTitle.frame = CGRect(x: 0, y: 0, width: warningViewWidth, height: warningViewHeight / CGFloat(3))
        
        self.warningMessage.frame = CGRect(x: 0, y: self.warningTitle.frame.maxY, width: warningViewWidth, height: warningViewHeight / CGFloat(3))
        self.warningButton.frame = CGRect(x: 0, y: self.warningMessage.frame.maxY, width: warningViewWidth, height: warningViewHeight / CGFloat(3))
        
        self.loadingLabel.frame = CGRect(x: self.getMidX() - textWidth, y: self.getMidY() - textHeight / CGFloat(2), width: 2 * textWidth, height: textHeight)
        
        self.progressBar.setProgress(0, animated: true)
        self.progressBar.frame = CGRect(x: self.getMidX() - textWidth, y: self.getMidY() + CGFloat(2.5) * textHeight / CGFloat(2), width: 2 * textWidth, height: textHeight)

    }
    
    override func updateAppearance()
    {
        var allButtons: [UIButton] = self.buttons
        allButtons.append(self.backButton)
        allButtons.append(self.saveButton)
        allButtons.append(self.pasteButton)
        allButtons.append(self.clearButton)
        for button in allButtons{
            button.backgroundColor = globalColors?.specialKey(darkMode, solidColorMode: solidColorMode)
            button.setTitleColor((self.globalColors?.darkModeTextColor), for: UIControlState.normal)
            button.setTitleColor((darkMode ? self.globalColors?.darkModeTextColor : self.globalColors?.lightModeTextColor), for: UIControlState.highlighted)
        }
        
        self.textField.keyboardAppearance = (darkMode ? .dark : .light)
        
        self.profileSelector.backgroundColor = globalColors?.regularKey(darkMode, solidColorMode: solidColorMode)
        self.profileSelector.setTitleColor((darkMode ? self.globalColors?.darkModeTextColor : self.globalColors?.lightModeTextColor), for: UIControlState.normal)
        self.profileSelector.setTitleColor(self.globalColors?.darkModeTextColor, for: UIControlState.highlighted)
        
        self.phraseSelector.backgroundColor = globalColors?.regularKey(darkMode, solidColorMode: solidColorMode)
        self.phraseSelector.setTitleColor((darkMode ? self.globalColors?.darkModeTextColor : self.globalColors?.lightModeTextColor), for: UIControlState.normal)
        self.phraseSelector.setTitleColor(self.globalColors?.darkModeTextColor, for: UIControlState.highlighted)
        
        self.textFieldLabel.textColor = (darkMode ? self.globalColors?.darkModeTextColor : self.globalColors?.lightModeTextColor)
        self.loadingLabel.textColor = (darkMode ? self.globalColors?.darkModeTextColor : self.globalColors?.lightModeTextColor)
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
        UserDefaults.standard.register(defaults: ["keyboardInputToApp": true])
        switchView()
    }
    
    func selectTextView() {
        self.textField.text = ""
        self.enableSaveButton(enable: false)
        UserDefaults.standard.register(defaults: ["keyboardInputToApp": false])
        switchView()
    }
    
    func showLoadingScreen(toShow: Bool) {
        self.loadingView.isHidden = !toShow
        self.defaultView.isHidden = toShow
        self.defaultView.isUserInteractionEnabled = !toShow
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
    
    func pasteInTextbox() {
        if let pasteString = UIPasteboard.general.string {
            self.enableSaveButton(enable: true)
            self.textField.text? += String(pasteString)

        }
        
    }
    
    func enableSaveButton(enable:Bool) {
        self.saveButton.isEnabled = enable
        /*if enable {
            self.saveButton.backgroundColor = globalColors?.regularKey(darkMode, solidColorMode: solidColorMode)
        }
        else {
            self.saveButton.backgroundColor?.withAlphaComponent(0.1)
        }*/
    }
    
    func clearTextbox() {
        self.textField.text = ""
        self.enableSaveButton(enable: false)
    }
    
    func hideWarningView() {
        self.warningView.isUserInteractionEnabled = false
        self.warningView.isHidden = true
    }
    
    func showWarningView(title: String, message: String) {
        self.warningTitle.text = title
        self.warningMessage.text = message
        self.warningView.isUserInteractionEnabled = true
        self.warningView.isHidden = false
    }
    
}



