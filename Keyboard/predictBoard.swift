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
    var recommendationEngine: Database? = nil //= Database()
    var reccommendationEngineLoaded = false
    var editProfilesView: ExtraView?
    var profileView: Profiles?
    var phrasesView: Phrases?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {

        UserDefaults.standard.register(defaults: ["profile": "Default"])
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func keyPressed(_ key: Key, secondaryMode: Bool) {
        
        
        var keyOutput = ""
        if key.type != .backspace {
                keyOutput = key.outputForCase(self.shiftState.uppercase(), secondary: secondaryMode)
        }
        //type in main app
        if UserDefaults.standard.bool(forKey: "keyboardInputToApp") == true
        {
            let textDocumentProxy = self.textDocumentProxy
            if key.type != .backspace {
                textDocumentProxy.insertText(keyOutput)
                if key.type == .space {
                    do {
                        let context = textDocumentProxy.documentContextBeforeInput
                        let components = context?.components(separatedBy: " ")
                        let count = (components?.count)! as Int
                        var word1 = ""
                        var word2 = ""
                        var word3 = ""
                        if count >= 4 {
                            word1 = (components?[count-4])! as String
                        }
                        if count >= 3 {
                            word2 = (components?[count-3])! as String
                        }
                        word3 = (components?[count-2])! as String
                        
                        // Create possible ngrams
                        let one_gram = (gram: word3, n: 1)
                        let two_gram = (gram: word2+" "+word3, n: 2)
                        let three_gram = (gram: word1+" "+word2+" "+word3, n: 3)
                        
                        let db_path = dbObjects().db_path
                        let db = try Connection("\(db_path)/db.sqlite3")
                        let containers = dbObjects.Containers()
                        let currentProfile = UserDefaults.standard.value(forKey: "profile") as! String
                        
                        // Insert ngrams into database and increment their frequencies
                        for ngram in [one_gram, two_gram, three_gram] {
                            // if word notExists in database
                            let exists_in_profile = try db.scalar(containers.table
                                                    .filter(containers.ngram == ngram.gram)
                                                    .filter(containers.profile == currentProfile)
                                                    .count) > 0
                            let exists_in_default = try db.scalar(containers.table
                                                    .filter(containers.ngram == ngram.gram)
                                                    .filter(containers.profile == "Default")
                                                    .count) > 0
                            if (!exists_in_profile) {
                                // insert ngram into profile
                                let insert = containers.table.insert(containers.ngram <- ngram.gram,
                                                                containers.profile <- currentProfile,
                                                                containers.n <- ngram.n)
                                _ = try? db.run(insert)
                            }
                            if (!exists_in_default) {
                                // insert ngram into Default
                                let insert = containers.table.insert(containers.ngram <- ngram.gram,
                                                                containers.profile <- "Default",
                                                                containers.n <- ngram.n)
                                _ = try? db.run(insert)
                            }
                            // increment ngram in current_profile and default cases
                            _ = try db.run(containers.table.filter(containers.ngram == ngram.gram)
                                .filter(containers.profile == currentProfile)
                                .update(containers.frequency++, containers.lastused <- Date()))
                            _ = try db.run(containers.table.filter(containers.ngram == ngram.gram)
                                .filter(containers.profile == "Default")
                                .update(containers.frequency++, containers.lastused <- Date()))
                        }
                    } catch {}
                }
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
        self.banner?.phraseSelector.addTarget(self, action: #selector(switchToPhraseMode), for: .touchUpInside)
        
        //setup autocomplete buttons
        for button in (self.banner?.buttons)! {
            button.addTarget(self, action: #selector(autocompleteClicked), for: .touchUpInside)
            
        }
        
        let globalQueue = DispatchQueue.global(qos: .userInitiated)
        
        globalQueue.async {
            // Background thread
            self.recommendationEngine = Database(progressView: (self.banner?.progressBar)!)
            self.reccommendationEngineLoaded = true
            DispatchQueue.main.async {
                // UI Updates
                self.banner?.showLoadingScreen(toShow: false)
                self.updateButtons()
            }
        }

        
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
                let db_path = dbObjects().db_path
                let db = try Connection("\(db_path)/db.sqlite3")

                let containers = dbObjects.Containers()
                let currentProfile = UserDefaults.standard.value(forKey: "profile") as! String
                try db.run(containers.table.filter(containers.ngram == wordToAdd)
                    .filter(containers.profile == currentProfile)
                    .update(containers.frequency++, containers.lastused <- Date()))
            }
            catch {
                print("Incrementing word frequency failed")
            }
            updateButtons()
        }
    }
    

    func updateButtons() {
        // Get previous words to give to recommendWords()
        // ------------------------
        if self.reccommendationEngineLoaded {
            let context = textDocumentProxy.documentContextBeforeInput
            let components = context?.components(separatedBy: " ")
            var count = 0
            if (components != nil) {
                count = (components?.count)! as Int
            }
            var word1 = ""
            var word2 = ""
            var current_input = ""
            if count >= 3 {
                word1 = (components?[count-3])! as String
            }
            if count >= 2 {
                word2 = (components?[count-2])! as String
            }
            if count >= 1 {
                current_input = (components?[count-1])! as String
            }
            // ------------------------
            let recEngine = recommendationEngine!
            let recommendations = Array(recEngine.recommendWords(word1: word1, word2: word2,
                                                             current_input: current_input)).sorted()
            
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
    }
    
    /*func otherUpdate() {
     let prevWord = self.getLastWord(delete: false)
     var recommendations = recommendationEngine.recommendWords(input: prevWord)
     //filter away any blank values, because it causes problems
     recommendations = recommendations.filter() { $0 != "" }
     let buttonsPerRow = (banner?.allButtons)! / (banner?.numRows)!
     let numRows: Int = banner?.numRows
     for row in stride(from: numRows, to: 0, by: -1) {
     let constant = row * buttonsPerRow
     for buttonIndex in 0..<buttonsPerRow {
     
     }
     }
     }*/
    
    
    
    //Pop ups
    @IBAction func showPopover(sender: UIButton) {
        
        let maxHeight = self.forwardingView.frame.maxY - sender.frame.maxY
        let popUpViewController = PopUpViewController(selector: sender as UIButton!, maxHeight: maxHeight, callBack: updateButtons)
        popUpViewController.modalPresentationStyle = UIModalPresentationStyle.popover
        popUpViewController.addButton.addTarget(self, action: #selector(switchToAddProfileMode), for: .touchUpInside)
        popUpViewController.editButton.addTarget(self, action: #selector(toggleEditProfiles), for: .touchUpInside)
        
        present(popUpViewController, animated: true, completion: nil)
        
        let popoverPresentationController = popUpViewController.popoverPresentationController
        popoverPresentationController?.sourceView = sender
        let height = Int(sender.frame.height)
        let width = Int(sender.frame.height) / 2
        
        
        popoverPresentationController?.sourceRect = CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: width, height: height))
    }
    
    func switchToAddProfileMode(){
        self.banner?.selectTextView()
        self.banner?.textFieldLabel.text = "Profile Name:"
        self.banner?.saveButton.addTarget(self, action: #selector(saveProfile), for: .touchUpInside)
        self.banner?.backButton.addTarget(self, action: #selector(completedAddProfileMode), for: .touchUpInside)
    }
    
    //go from internal text input mode to forwarding view
    func completedAddProfileMode(){
        
        self.banner?.saveButton.removeTarget(self, action: #selector(saveProfile), for: .touchUpInside)
        self.banner?.backButton.removeTarget(self, action: #selector(completedAddProfileMode), for: .touchUpInside)
        self.banner?.selectDefaultView()
        //self.banner?.textField.resignFirstResponder()
        //dismissKeyboard()
    }
    
    
    //go from internal text input mode to profile view
    func saveProfile() {
        let globalQueue = DispatchQueue.global(qos: .userInitiated)
        globalQueue.async {
            // Background thread
            self.recommendationEngine?.addProfile(profile_name: (self.banner?.textField.text)!)
            DispatchQueue.main.async {
                // UI Updates
                self.banner?.showLoadingScreen(toShow: false)
                self.showForwardingView(toShow: false)
                self.showBanner(toShow: false)
                self.profileView = self.createProfile(profileName:(self.banner?.textField.text)!)
                self.showView(viewToShow: self.profileView!, toShow: true)
                self.reccommendationEngineLoaded = true
            }
        }
        self.reccommendationEngineLoaded = false
        completedAddProfileMode()
        self.banner?.loadingLabel.text = "Creating new Profile (this may take several minutes)"
        self.banner?.showLoadingScreen(toShow: true)
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
    
    func editProfilesNameView() {
        profileTextEntryView(toShow: true)
        self.banner?.textFieldLabel.text = "Edit Name:"
        self.banner?.textField.text = profileView?.profileName!//(profileView as! Profiles).profileName!
        self.banner?.saveButton.addTarget(self, action: #selector(updateProfileName), for: .touchUpInside)
        self.banner?.backButton.addTarget(self, action: #selector(exiteditProfilesNameView), for: .touchUpInside)
    }
    

    func updateProfileName(){
        //var profile = (profileView as! Profiles)
        let newName = (self.banner?.textField.text)!
        profileView?.NavBar.title = newName
        recommendationEngine?.editProfileName(current_name: (profileView?.profileName!)!, new_name: newName)
        profileView?.profileName = newName
        exiteditProfilesNameView()
    }
    
    func exiteditProfilesNameView() {
        profileTextEntryView(toShow: false)
        self.banner?.saveButton.removeTarget(self, action: #selector(updateProfileName), for: .touchUpInside)
        self.banner?.backButton.removeTarget(self, action: #selector(exiteditProfilesNameView), for: .touchUpInside)
    }
    
    func addDataSourceView() {
        profileTextEntryView(toShow: true)
        self.banner?.textFieldLabel.text = "Data Source URL:"
        self.banner?.textField.text = "www."
        self.banner?.saveButton.addTarget(self, action: #selector(addDataSource), for: .touchUpInside)
        self.banner?.backButton.addTarget(self, action: #selector(exitDataSourceView), for: .touchUpInside)
    }
    
    func exitDataSourceView() {
        profileTextEntryView(toShow: false)
        self.banner?.saveButton.removeTarget(self, action: #selector(addDataSource), for: .touchUpInside)
        self.banner?.backButton.removeTarget(self, action: #selector(exitDataSourceView), for: .touchUpInside)
    }
    
    func addDataSource() {
        
        //For now data source title and data source name are the same
        let globalQueue = DispatchQueue.global(qos: .userInitiated)
        
        globalQueue.async {
            // Background thread
            self.recommendationEngine?.addDataSource(target_profile: (self.profileView?.profileName)!, new_data_source: (self.banner?.textField.text)!, new_title: (self.banner?.textField.text)!)
            DispatchQueue.main.async {
                // UI Updates
                self.profileView?.reloadData()
            }
        }

        exitDataSourceView()
        
    }
    
    func deleteProfile() {
        let profileName = profileView?.profileName!
        recommendationEngine?.deleteProfile(profile_name: profileName!)
        profileToEditProfiles()
    }
    
    func profileTextEntryView(toShow: Bool) {
        if toShow {
            showView(viewToShow: profileView!, toShow: false)
            self.banner?.selectTextView()
        }
        else {
            self.banner?.selectDefaultView()
            //if you cancel just reopen view.  showView will recreate it, we dont need to do that
            profileView?.isHidden = false
            profileView?.isUserInteractionEnabled = true
        }
        showForwardingView(toShow: toShow)
        showBanner(toShow: toShow)
        
    }
    
    @IBAction func toggleEditProfiles() {
        let toShow = self.forwardingView.isHidden
        showForwardingView(toShow: toShow)
        showBanner(toShow: toShow)
        if (!toShow) {
            editProfilesView = createEditProfiles()
        }
        showView(viewToShow: editProfilesView!, toShow: !toShow)
        
    }
    
    func openProfile(profileName: String) {
        profileView = createProfile(profileName: profileName)
        if (editProfilesView != nil) {
            showView(viewToShow: editProfilesView!, toShow: false)
        }
        showView(viewToShow: profileView!, toShow: true)
        
    }
    
    func profileToEditProfiles() {
        editProfilesView = createEditProfiles()
        showView(viewToShow: editProfilesView!, toShow: true)
        showView(viewToShow: profileView!, toShow: false)
    }
    
    
    func goToKeyboard() {
        if (editProfilesView != nil) {
            showView(viewToShow: editProfilesView!, toShow: false)
        }
        if (profileView != nil) {
            showView(viewToShow: profileView!, toShow: false)
        }
        if phrasesView != nil {
            showView(viewToShow: phrasesView!, toShow: false)
        }
        showForwardingView(toShow: true)
        showBanner(toShow: true)
    }
    
    func switchToPhraseMode() {
        phrasesView = createPhrases()
        showView(viewToShow: phrasesView!, toShow: true)
        showForwardingView(toShow: false)
        showBanner(toShow: false)
    }
    
    func createEditProfiles() -> ExtraView? {
        let editProfiles = EditProfiles(globalColors: type(of: self).globalColors, darkMode: false, solidColorMode: self.solidColorMode())
        
        editProfiles.backButton?.addTarget(self, action: #selector(toggleEditProfiles), for: UIControlEvents.touchUpInside)
        editProfiles.callBack = openProfileCallback
        return editProfiles
    }
    
    func createProfile(profileName:String) -> Profiles? {
        // note that dark mode is not yet valid here, so we just put false for clarity
        let profileView = Profiles(profileName: profileName, globalColors: type(of: self).globalColors, darkMode: false, solidColorMode: self.solidColorMode())
        //profileView.NavBar.title = title
        profileView.backButton?.addTarget(self, action: #selector(goToKeyboard), for: UIControlEvents.touchUpInside)
        profileView.profileViewButton?.addTarget(self, action: #selector(profileToEditProfiles), for: UIControlEvents.touchUpInside)
        profileView.editName?.action = #selector(editProfilesNameView)
        profileView.editName?.target = self
        profileView.addButton?.action = #selector(addDataSourceView)
        profileView.addButton?.target = self
        profileView.deleteButton.action = #selector(deleteProfile)

        profileView.deleteButton.target = self
        return profileView
    }
    
    func openProfileCallback(tableTitle:String) {
        let title = tableTitle.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        openProfile(profileName: title)
        //let profile = profileView as! Profiles
        profileView?.NavBar.title = title
        //we dont want you editing the default profile name
        if title == "Default" {
            profileView?.editName.isEnabled = false
            profileView?.deleteButton.isEnabled = false
        }
        else {
            profileView?.editName.isEnabled = true
            profileView?.deleteButton.isEnabled = true
        }
    }
    
    func createPhrases() -> Phrases? {
        // note that dark mode is not yet valid here, so we just put false for clarity
        let phrasesView = Phrases(globalColors: type(of: self).globalColors, darkMode: false, solidColorMode: self.solidColorMode())
        //profileView.NavBar.title = title
        phrasesView.backButton?.addTarget(self, action: #selector(goToKeyboard), for: UIControlEvents.touchUpInside)

        phrasesView.addButton?.action = #selector(addDataSourceView)
        phrasesView.addButton?.target = self

        return phrasesView
    }
    
}


