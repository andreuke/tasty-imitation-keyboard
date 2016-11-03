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

    required init(globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool) {

        
        super.init(globalColors: globalColors, darkMode: darkMode, solidColorMode: solidColorMode)
        
        for _ in 0..<self.numButtons {
            let button: BannerButton = BannerButton()
            button.type = "ACButton"
            buttons.append(button)
            self.addSubview(button)
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.clear.cgColor
            button.titleLabel?.font = UIFont(name: "Helvetica", size: 22)
            button.addTarget(self, action: #selector(buttonClicked), for: .touchDown)
            button.addTarget(self, action: #selector(buttonClicked), for: .touchDragEnter)
            button.addTarget(self, action: #selector(buttonUnclicked), for: .touchDragExit)
            button.addTarget(self, action: #selector(buttonUnclicked), for: .touchUpInside)
        }
        
        //add profile selector button
        self.profileSelector.type = "SelectorButton"
        self.addSubview(self.profileSelector)
        self.profileSelector.layer.borderWidth = 1
        self.profileSelector.layer.cornerRadius = 5
        self.profileSelector.layer.borderColor = UIColor.clear.cgColor
        self.profileSelector.titleLabel?.font = UIFont(name: "Helvetica", size: 22)
        self.profileSelector.addTarget(self, action: #selector(buttonClicked), for: .touchDown)
        self.profileSelector.addTarget(self, action: #selector(buttonClicked), for: .touchDragEnter)
        self.profileSelector.addTarget(self, action: #selector(buttonUnclicked), for: .touchDragExit)
        self.profileSelector.addTarget(self, action: #selector(buttonUnclicked), for: .touchUpInside)
        
        
        updateAppearance()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //let yMax = self.getMaxY()
        //let yMin = self.getMinY()
        //let xMax = self.getMaxX()
        //let xMin = self.getMinX()
        
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
    }
    
    override func updateAppearance()
    {
        for button in buttons{
            button.backgroundColor = globalColors?.specialKey(darkMode, solidColorMode: solidColorMode)
            button.setTitleColor((self.globalColors?.darkModeTextColor), for: UIControlState.normal)
            button.setTitleColor((darkMode ? self.globalColors?.darkModeTextColor : self.globalColors?.lightModeTextColor), for: UIControlState.highlighted)
        }
        
        self.profileSelector.backgroundColor = globalColors?.regularKey(darkMode, solidColorMode: solidColorMode)
        self.profileSelector.titleLabel?.textColor = self.globalColors?.lightModeTextColor//(darkMode ? self.globalColors?.darkModeTextColor : self.globalColors?.lightModeTextColor)
        self.profileSelector.setTitleColor((darkMode ? self.globalColors?.darkModeTextColor : self.globalColors?.lightModeTextColor), for: UIControlState.normal)
        self.profileSelector.setTitleColor(self.globalColors?.darkModeTextColor, for: UIControlState.highlighted)
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



