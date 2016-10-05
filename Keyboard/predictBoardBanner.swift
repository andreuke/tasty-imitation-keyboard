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
    var outFunc: () -> () = null
    
    required init(globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool, outputFunc: ()->()) {
        super.init(globalColors: globalColors, darkMode: darkMode, solidColorMode: solidColorMode)
        self.outFunc = outputFunc
        //self.addSubview(self.predictSwitch)
        //self.addSubview(self.predictLabel)
        self.addSubview(self.predictButton)
        self.predictButton.backgroundColor = UIColor.blueColor()
        self.predictButton.setTitle("AUTO", forState: .Normal)
        self.predictButton.frame = CGRectMake(100, 100, 60, 40)
        //self.predictSwitch.on = NSUserDefaults.standardUserDefaults().boolForKey(predictionEnabled)
        //self.predictSwitch.transform = CGAffineTransformMakeScale(0.75, 0.75)
        //self.predictSwitch.addTarget(self, action: Selector("respondToSwitch"), forControlEvents: UIControlEvents.ValueChanged)
        self.predictButton.addTarget(self, action: Selector("runOutputFunc"), forControlEvents: .TouchUpInside)
        //self.updateAppearance()
        self.outFunc()
        
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
        self.predictButton.center = self.center
        //self.predictButton.frame.origin = CGPointMake(self.predictSwitch.frame.origin.x + self.predictSwitch.frame.width + 8, self.predictButton.frame.origin.y)
    }
    
    func runOutputFunc() {
        self.outFunc()
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

func null() {
    return
}


