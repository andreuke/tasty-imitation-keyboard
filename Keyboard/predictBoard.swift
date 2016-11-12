//
//  predictboard.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 9/24/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import UIKit
import SQLite

/*
 This is the demo keyboard. If you're implementing your own keyboard, simply follow the example here and then
 set the name of your KeyboardViewController subclass in the Info.plist file.
 */

class PredictBoard: KeyboardViewController, UIPopoverPresentationControllerDelegate {
    
    var banner: PredictboardBanner? = nil
    let recommendationEngine = WordList()
    var editProfilesView: ExtraView?
    var profileView: ExtraView?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        UserDefaults.standard.register(defaults: ["profile": "Default"])
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func keyPressed(_ key: Key) {
        
        
        var keyOutput = ""
        if key.type != .backspace {
            keyOutput = key.outputForCase(self.shiftState.uppercase())
        }
        //type in main app
        if true//UserDefaults.standard.bool(forKey: "keyboardInputToApp") == true
        {
            let textDocumentProxy = self.textDocumentProxy
            if key.type != .backspace {
                textDocumentProxy.insertText(keyOutput)
            }
            else {
                textDocumentProxy.deleteBackward()
            }
            //let lastWord = getLastWord(delete: false)
            self.updateButtons()
        }
        //type in in-keyboard textbox
        else {
            if key.type != .backspace {
                self.banner?.textField.text? += keyOutput
            }
            else{
                let oldText = (self.banner?.textField.text)!
                if oldText.characters.count > 0 {
                    var endIndex = oldText.endIndex
                    
                    self.banner?.textField.text? = oldText.substring(to: oldText.index(before: endIndex))
                }
                //self.banner?.textField.text? += keyOutput
            }
        }
    }
    
    override func setupKeys() {
        super.setupKeys()
    }
    
    override func createBanner() -> ExtraView? {
        self.banner = PredictboardBanner(globalColors: type(of: self).globalColors, darkMode: self.darkMode(), solidColorMode: self.solidColorMode())
        self.layout?.darkMode
        self.banner?.isHidden = true
        //set up profile selector
        self.banner?.profileSelector.addTarget(self, action: #selector(showPopover), for: .touchUpInside)
         self.banner?.profileSelector.setTitle(UserDefaults.standard.string(forKey: "profile")!, for: UIControlState())
        
        //setup autocomplete buttons
        for button in (self.banner?.buttons)! {
            button.addTarget(self, action: #selector(autocompleteClicked), for: .touchUpInside)
            //button.addTarget(self, action: #selector(KeyboardViewController.playKeySound), for: .touchDown)

        }
        
        
        //populate buttons
        updateButtons()
        
        return self.banner
    }
    
    
    
    ///autocomplete code
    func autoComplete(_ word:String) -> () {
        let textDocumentProxy = self.textDocumentProxy
        
        _ = getLastWord(delete: true)
        var insertionWord = word
        if let postContext = textDocumentProxy.documentContextAfterInput
        {
            let postIndex = postContext.startIndex
            if postContext[postIndex] != " " //add space if next word doesnt begin with space
            {
                insertionWord = word + " "
            }
        }
        else //add space if you are the last added word.
        {
            insertionWord = word + " "
        }
        // update database with insertion word
        textDocumentProxy.insertText(insertionWord)
    }
    
    func getLastWord(delete: Bool) ->String {
        let textDocumentProxy = self.textDocumentProxy
        var prevWord = ""
        if let context = textDocumentProxy.documentContextBeforeInput
        {
            if context.characters.count > 0
            {
                var index = context.endIndex
                index = context.index(before: index)
                
                while index > context.startIndex && context[index] != " "
                {
                    prevWord.insert(context[index], at: prevWord.startIndex)
                    //prevWord += String(context[index])
                    index = context.index(before: index)
                    if delete{
                        textDocumentProxy.deleteBackward()
                    }
                }
                if index == context.startIndex && context[index] != " "
                {
                    prevWord.insert(context[index], at: prevWord.startIndex)
                    //prevWord += String(context[index])
                    if delete {
                        textDocumentProxy.deleteBackward()
                    }
                }
            }
        }
        return prevWord
    }
    
    func autocompleteClicked(_ sender:UIButton) {
        let wordToAdd = sender.titleLabel!.text!
        if wordToAdd != " "
        {
            self.autoComplete(wordToAdd)
            // increment frequency of word in database
            do {
                let db_path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
                let db = try Connection("\(db_path)/db.sqlite3")
                let containers = Table("Containers")
                let ngram = Expression<String>("ngram")
                let profile = Expression<String>("profile")
                let frequency = Expression<Int64>("frequency")
                try db.run(containers.filter(ngram == wordToAdd).filter(profile == "Default").update(frequency++))
            }
            catch {
                print("Incrementing word frequency failed")
            }
            updateButtons()
        }
    }
    
    func updateButtons() {
        let prevWord = self.getLastWord(delete: false)
        var recommendations = recommendationEngine.recommendWords(input: prevWord)
        //filter away any blank values, because it causes problems
        recommendations = recommendations.filter() { $0 != "" }
        
        var index = 0
        for button in (self.banner?.buttons)! {
            if index < recommendations.count {
                button.setTitle(recommendations[index], for: UIControlState())
                button.addTarget(self, action: #selector(KeyboardViewController.playKeySound), for: .touchDown)
            }
            else {
                button.setTitle(" ", for: UIControlState())
                button.removeTarget(self, action: #selector(KeyboardViewController.playKeySound), for: .touchDown)
            }
            index += 1
        }
    }
    
        
    
    //Pop ups
    @IBAction func showPopover(sender: UIButton) {
        
        
        let popUpViewController = PopUpViewController(selector: sender as UIButton!, callBack: updateButtons)
        popUpViewController.modalPresentationStyle = UIModalPresentationStyle.popover
        popUpViewController.addButton.addTarget(self, action: #selector(switchToAddTextMode), for: .touchUpInside)
        popUpViewController.editButton.addTarget(self, action: #selector(toggleEditProfile), for: .touchUpInside)

        present(popUpViewController, animated: true, completion: nil)
        
        let popoverPresentationController = popUpViewController.popoverPresentationController
        popoverPresentationController?.sourceView = sender
        let height = Int(sender.frame.height)
        let width = Int(sender.frame.height) / 2
        
        
        popoverPresentationController?.sourceRect = CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: width, height: height))
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func switchToAddTextMode(){
        self.banner?.selectTextView()
        self.banner?.saveButton.addTarget(self, action: #selector(saveProfile), for: .touchUpInside)
        self.banner?.backButton.addTarget(self, action: #selector(completedAddTextMode), for: .touchUpInside)
    }
        
    func completedAddTextMode(){
        self.banner?.selectDefaultView()
        self.banner?.saveButton.removeTarget(self, action: #selector(saveProfile), for: .touchUpInside)
        self.banner?.backButton.removeTarget(self, action: #selector(completedAddTextMode), for: .touchUpInside)
        self.banner?.textField.resignFirstResponder()
        dismissKeyboard()
    }

    func saveProfile() {
        self.recommendationEngine.addProfile(profileName: (self.banner?.textField.text)!)
        //completedAddTextMode()
        showForwardingView(toShow: false)
        showBanner(toShow: false)
        let profile = createProfile() as! Profiles
        profileView = profile
        showView(viewToShow: profileView!, toShow: true)
        profile.NavBar.title = self.banner?.textField.text
        
        //remove old target of back button set in createProfile since we want different behavior here
        profile.backButton?.removeTarget(self, action: #selector(toggleProfile), for: UIControlEvents.touchUpInside)
        
        profile.backButton?.addTarget(self, action: #selector(dismissKeyboardApp), for: UIControlEvents.touchUpInside)
        
    }
    
    func dismissKeyboardApp() {
        dismissKeyboard()
    }
    
    func showView(viewToShow: ExtraView, toShow: Bool) {
        if toShow {
            viewToShow.darkMode = self.darkMode()
            viewToShow.isHidden = true
            self.view.addSubview(viewToShow)
            
            viewToShow.translatesAutoresizingMaskIntoConstraints = false
            
            let widthConstraint = NSLayoutConstraint(item: viewToShow, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.width, multiplier: 1, constant: 0)
            let heightConstraint = NSLayoutConstraint(item: viewToShow, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.height, multiplier: 1, constant: 0)
            let centerXConstraint = NSLayoutConstraint(item: viewToShow, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0)
            let centerYConstraint = NSLayoutConstraint(item: viewToShow, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0)
            
            self.view.addConstraint(widthConstraint)
            self.view.addConstraint(heightConstraint)
            self.view.addConstraint(centerXConstraint)
            self.view.addConstraint(centerYConstraint)
        }
        viewToShow.isHidden = !toShow
        viewToShow.isUserInteractionEnabled = toShow

    }
    
    func showBanner(toShow: Bool) {
        self.banner?.isHidden = !toShow
        self.banner?.isUserInteractionEnabled = toShow
    }
    
    func showForwardingView(toShow: Bool) {
        self.forwardingView.isHidden = !toShow
        self.forwardingView.isUserInteractionEnabled = toShow
    }
    
    @IBAction func toggleEditProfile() {
        let toShow = self.forwardingView.isHidden
        showForwardingView(toShow: toShow)
        showBanner(toShow: toShow)
        if (!toShow) {
            editProfilesView = createEditProfiles()
        }
        showView(viewToShow: editProfilesView!, toShow: !toShow)

    }
    
    func toggleProfile() {
        let toShow = (editProfilesView?.isHidden)!
        if toShow {
            editProfilesView = createEditProfiles()
        }
        else {
            profileView = createProfile()
        }
        showView(viewToShow: editProfilesView!, toShow: toShow)
        showView(viewToShow: profileView!, toShow: !toShow)
    }
    
    func createEditProfiles() -> ExtraView? {
        let editProfile = EditProfiles(globalColors: type(of: self).globalColors, darkMode: false, solidColorMode: self.solidColorMode())
        
        editProfile.backButton?.addTarget(self, action: #selector(toggleEditProfile), for: UIControlEvents.touchUpInside)
        editProfile.callBack = openProfile
        return editProfile
    }
    
    func createProfile() -> ExtraView? {
        // note that dark mode is not yet valid here, so we just put false for clarity
        let profileView = Profiles(globalColors: type(of: self).globalColors, darkMode: false, solidColorMode: self.solidColorMode())
        //profileView.NavBar.title = title
        profileView.backButton?.addTarget(self, action: #selector(toggleProfile), for: UIControlEvents.touchUpInside)
        //profileView.callBack = printHere
        return profileView
    }
    
    func openProfile(tableTitle:String) {
        toggleProfile()
        let profile = profileView as! Profiles
        profile.NavBar.title = tableTitle
    }
    
}


