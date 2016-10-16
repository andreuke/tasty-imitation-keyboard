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
    
    //var predictSwitch: UISwitch = UISwitch()
    //var predictLabel: UILabel = UILabel()
    var predictButton: UIButton = UIButton()
    var outFunc: (String) -> ()
    
    required init(globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool, outputFunc: @escaping (String)->()) {
        
        self.outFunc = outputFunc //needs to be declared before the super.init
        
        super.init(globalColors: globalColors, darkMode: darkMode, solidColorMode: solidColorMode)
        
        self.addSubview(self.predictButton)
        self.predictButton.backgroundColor = UIColor.blue
        self.predictButton.setTitle("Hello", for: UIControlState())
        self.predictButton.frame = CGRect(x: 100, y: 100, width: 60, height: 40)
        //self.predictSwitch.on = NSUserDefaults.standardUserDefaults().boolForKey(predictionEnabled)
        //self.predictSwitch.transform = CGAffineTransformMakeScale(0.75, 0.75)
        //self.predictSwitch.addTarget(self, action: Selector("respondToSwitch"), forControlEvents: UIControlEvents.ValueChanged)
        self.predictButton.addTarget(self, action: #selector(runOutputFunc), for: .touchUpInside)
        //self.updateAppearance()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool) {
        fatalError("init(globalColors:darkMode:solidColorMode:) has not been implemented")
    }
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //self.predictSwitch.center = self.center
        //self.predictLabel.center = self.center
        //self.predictLabel.frame.origin = CGPointMake(self.predictSwitch.frame.origin.x + self.predictSwitch.frame.width + 20, self.predictLabel.frame.origin.y)
        var y = self.getMaxY()
        self.predictButton.center = self.center
        //self.predictButton.frame.origin = CGPointMake(self.predictSwitch.frame.origin.x + self.predictSwitch.frame.width + 8, self.predictButton.frame.origin.y)
    }
    
    func runOutputFunc(_ sender:UIButton) {
        
        self.outFunc(sender.titleLabel!.text!)
        if sender.titleLabel!.text! == "Hello"
        {
            sender.setTitle("my", for: UIControlState())
        }
        else if sender.titleLabel!.text! == "my"
        {
            sender.setTitle("name", for: UIControlState())
        }
        else if sender.titleLabel!.text! == "name"
        {
            sender.setTitle("is", for: UIControlState())
        }
        else
        {
            sender.setTitle("Jon", for: UIControlState())
        }
        
    }
    
    /*
    func respondToSwitch() {
        NSUserDefaults.standardUserDefaults().setBool(self.predictSwitch.on, forKey: predictionEnabled)
        //self.updateAppearance()
    }
    
    
    func updateAppearance() {
        if self.predictSwitch.on {
            self.predictLabel.text = "auto"
            self.predictLabel.alpha = 1
        }
        else {
            self.predictLabel.text = "🐱"
            self.predictLabel.alpha = 0.5
        }
        
        self.predictLabel.sizeToFit()
    }*/
    
}



