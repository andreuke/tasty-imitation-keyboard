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


// temp parse thing :: START

extension String {
    var html2AttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return nil }
        do {
            return try NSAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch let error as NSError {
            print(error.localizedDescription)
            return  nil
        }
    }
    var html2String: String {
        return html2AttributedString?.string ?? ""
    }
}

extension Dictionary where Value: Comparable {
    var valueKeySorted: [(Key, Value)] {
        return sorted{ if $0.value != $1.value { return $0.value > $1.value } else { return String(describing: $0.key) < String(describing: $1.key) } }
    }
}

// temp parse thing :: END



class PredictBoard: KeyboardViewController, UIPopoverPresentationControllerDelegate {
    
    var banner: PredictboardBanner? = nil
    var recommendationEngine: Database? = nil
    var reccommendationEngineLoaded = false
    var editProfilesView: ExtraView?
    var profileView: Profiles?
    var phrasesView: Phrases?
    var total = 100
    let globalQueue = DispatchQueue.global(qos: .userInitiated)
    var keyPressTimer: Timer?
    var canPress: Bool = true
    let canPressDelay: TimeInterval = 0.15
    var deleteScreen:DeleteViewController?
    let defaultProf = "Default"
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {

        UserDefaults.standard.register(defaults: ["profile": self.defaultProf])
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        keyPressTimer?.invalidate()
    }
    
    override func keyPressed(_ key: Key, secondaryMode: Bool) {
        var keyOutput = ""
        if key.type != .backspace {
                keyOutput = key.outputForCase(self.shiftState.uppercase(), secondary: secondaryMode)
        }

        if key.type == .shift {
            //updateButtons()
            return
        }
        
        //make sure Brad does not accidently double click
//        if !self.canPress && !fastDeleteMode(key: key, secondaryMode: secondaryMode) {
//            return
//        }
        self.canPress = false
        self.keyPressTimer = Timer.scheduledTimer(timeInterval: canPressDelay, target: self, selector: #selector(resetCanPress), userInfo: nil, repeats: false)
        
        if key.type == .backspace {
            if fastDeleteMode(key: key, secondaryMode: secondaryMode) {
                fastDelete()
                return //in fast delete mode do not update buttons
            }
            else {
                backspace()
            }
        }
        
        if key.type == .return && !UserDefaults.standard.bool(forKey: "keyboardInputToApp") {
            self.banner?.saveButton.sendActions(for: .touchUpInside)
            return
        }
        
        let punctuation = [".", ",", ";", "!", "?", "\'", ":", "\"", "-"]
        if punctuation.contains(keyOutput){
            let preContext = self.contextBeforeInput()
            //ensure at least 2 characters have been typed
            if preContext.characters.count > 1 {
                let endIndex = preContext.endIndex
                let preIndex = preContext.index(before: endIndex)
                let twoBeforeIndex = preContext.index(before: preIndex)
                if (preContext[preIndex] == " ") && (preContext[twoBeforeIndex] != " ") {
                    backspace()
                    keyOutput += " "
                }
            }
        }
        if key.type == .space {
            let components = self.contextBeforeInput().components(separatedBy: " ")
            let lastWord = components[components.count-1]
            
            if let correction = self.corrections(lastWord)?.first {
                self.autoComplete(correction)
            } else {
                self.addText(text: keyOutput)
            }
            if(self.reccommendationEngineLoaded) {
                self.incrementNgrams()
            }
        }
        else {
            self.addText(text: keyOutput)
        }
        //self.updateButtons()
    }
    
    func backspace() {
        if UserDefaults.standard.bool(forKey: "keyboardInputToApp") {
            self.textDocumentProxy.deleteBackward()
        }
        else {
            self.bannerTextBackspace()
        }
    }
    
    func addText(text:String) {
        if UserDefaults.standard.bool(forKey: "keyboardInputToApp") {
            self.textDocumentProxy.insertText(text)
        }
        else {
            self.banner?.textField.text? += text
        }
    }
    
    func contextBeforeInput() -> String {
        var context = ""
        if UserDefaults.standard.bool(forKey: "keyboardInputToApp") {
            if let textContext = self.textDocumentProxy.documentContextBeforeInput {
                context = textContext
            }
        }
        else {
            context = (self.banner?.textField.text)!
        }
        return context
    }
    
    func contextAfterInput() ->String {
        var context = ""
        if UserDefaults.standard.bool(forKey: "keyboardInputToApp") {
            if let textContext = self.textDocumentProxy.documentContextAfterInput {
                context = textContext
            }
        }
        else {
            context = ""
        }
        return context
    }
    
    func bannerTextBackspace() {
        let oldText = (self.banner?.textField.text)!
        if oldText.characters.count > 0 {
            var endIndex = oldText.endIndex
            
            self.banner?.textField.text? = oldText.substring(to: oldText.index(before: endIndex))
            if self.banner?.textField.text?.characters.count == 0 {
            }
        }

    }
    
    override func setupKeys() {
        super.setupKeys()
    }
    
    override func createBanner() -> ExtraView? {
        self.banner = PredictboardBanner(setCaps: self.setCapsIfNeeded, globalColors: type(of: self).globalColors, darkMode: self.darkMode(), solidColorMode: self.solidColorMode())
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
        
        //setup autocomplete buttons in in app text input mode
        for button in (self.banner?.tiButtons)! {
            button.addTarget(self, action: #selector(autocompleteClicked), for: .touchUpInside)
        }
        
        
        
        self.globalQueue.async {
            // Background thread
            self.recommendationEngine = Database(progressView: (self.banner?.progressBar)!, numElements: 30000)
            self.reccommendationEngineLoaded = true
            DispatchQueue.main.async {
                // UI Updates
                self.banner?.showLoadingScreen(toShow: false)
                self.updateButtons()
            }
        }

        
        return self.banner
    }
    
    func resetCanPress() {
        self.canPress = true
    }
    
    ///autocomplete code
    func autoComplete(_ word:String) -> () {
        
        _ = getLastWord(delete: true)
        var insertionWord = word
        let postContext = self.contextAfterInput()
        
        if postContext.characters.count > 0
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
        addText(text: insertionWord)
    }
    
    
    func fastDelete() {
        let deletedWord = getLastWord(delete: true)
        if (deletedWord.characters.count == 0) {
            let context = self.contextBeforeInput()

            if context.characters.count > 0 {
                backspace()
                _ = getLastWord(delete: true)
            }

        }
    }
    
    func getLastWord(delete: Bool) ->String {
        var prevWord = ""
        let context = contextBeforeInput()
        if context.characters.count > 0
        {
            var index = context.endIndex
            index = context.index(before: index)
            
            while index > context.startIndex && context[index] != " "
            {
                prevWord.insert(context[index], at: prevWord.startIndex)
                index = context.index(before: index)
                if delete{
                    backspace()
                }
            }
            if index == context.startIndex && context[index] != " "
            {
                prevWord.insert(context[index], at: prevWord.startIndex)
                if delete {
                    backspace()
                }
            }
        }
        return prevWord
    }
    
    func autocompleteClicked(_ sender:UIButton) {
        //make sure Brad does not accidently double click
        if !self.canPress {
            return
        }
        self.canPress = false
        self.keyPressTimer = Timer.scheduledTimer(timeInterval: canPressDelay, target: self, selector: #selector(resetCanPress), userInfo: nil, repeats: false)
        
        let wordToAdd = sender.titleLabel!.text!.replacingOccurrences(of: "\"", with: "")
        if wordToAdd != " "
        {
            self.autoComplete(wordToAdd)
            self.incrementNgrams()
            //updateButtons()
            setCapsIfNeeded()
        }
    }

    
    func incrementNgrams() {
        
        self.globalQueue.sync {
            let context = self.contextBeforeInput()
            let components = context.components(separatedBy: " ")
            let count = (components.count) as Int
            var word1 = ""
            var word2 = ""
            var word3 = ""
            if count >= 4 {
                word1 = (components[count-4]) as String
            }
            if count >= 3 {
                word2 = (components[count-3]) as String
            }
            word3 = (components[count-2]) as String
            
            // Create possible ngrams
            let one_gram = (gram: word3, n: 1)
            let two_gram = (gram: word2+" "+word3, n: 2)
            let three_gram = (gram: word1+" "+word2+" "+word3, n: 3)
            
            // Insert ngrams into database and increment their frequencies
            for ngram in [one_gram, two_gram, three_gram] {
                self.recommendationEngine?.insertAndIncrement(ngram: ngram.gram, n: ngram.n)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        print("ASDFLHASDFLKHASDLFKHASDLFKH MEMORY WARNING")
    }

    override func updateButtons() {
        // Get previous words to give to recommendWords()
        // ------------------------
        
        self.globalQueue.async {
            if self.reccommendationEngineLoaded {
                var context = self.contextBeforeInput()
                context = context.replacingOccurrences(of: "\n", with: " ")
                let normalInputMode = UserDefaults.standard.bool(forKey: "keyboardInputToApp")
                let components = context.components(separatedBy: " ")
                var count = (components.count) as Int
                var word1 = ""
                var word2 = ""
                var current_input = ""
                if count >= 3 {
                    word1 = (components[count-3]) as String
                }
                if count >= 2 {
                    word2 = (components[count-2]) as String
                }
                if count >= 1 {
                    current_input = (components[count-1]) as String
                }
                // ------------------------
                let recEngine = self.recommendationEngine!
                var numResults = (normalInputMode ? (self.banner?.numButtons)!: 5)

                // UITextChecker
                var recommendations = [String]()
                
                let corrections = self.corrections(current_input)
                if (corrections != nil) {
                    recommendations = corrections!
                }
                
                let textChecker = UITextChecker()
                var misspelledRange = textChecker.rangeOfMisspelledWord(
                    in: current_input, range: NSRange(0..<current_input.utf16.count),
                    startingAt: 0, wrap: false, language: "en_US")
                
                if misspelledRange.location != NSNotFound {
                    if let completions = textChecker.completions(forPartialWordRange: misspelledRange, in: current_input, language: "en_US") {
                        recommendations.append(contentsOf: completions)
                    }
                }
                
                recommendations.append(contentsOf: Array(recEngine.recommendWords(word1: word1, word2: word2,
                                                                     current_input: current_input,
                                                                     shift_state: self.shiftState,
                                                                     numResults:numResults)).sorted())
                
                let words = self.contextBeforeInput().components(separatedBy: " ")
                if(words.last != nil && words.last!.characters.count > 0) {
                    recommendations = recommendations.filter{$0.lowercased() != words.last!.lowercased()}
                    recommendations.insert("\"" + words.last! + "\"", at: 0)
                }

                var index = 0
                DispatchQueue.main.async {
                    var buttons = [BannerButton]()
                    if normalInputMode {
                        buttons = (self.banner?.buttons)!
                    }
                    else {
                        buttons = (self.banner?.tiButtons)!
                    }
                    for button in buttons {
                        if index < recommendations.count {
                            if(corrections != nil && (corrections?.count)! > 0 && recommendations[index] == corrections?[0]) {
                                button.backgroundColor = GlobalColors.buttonColor(self.darkMode())
                            }
                            else {
                                button.backgroundColor = GlobalColors.lightModeSpecialKey
                            }
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
        }
    }
    
    
    
    //Pop ups
    @IBAction func showPopover(sender: UIButton) {
        
        let maxHeight = self.forwardingView.frame.maxY - sender.frame.maxY
        let popUpViewController = PopUpViewController(selector: sender as UIButton!, maxHeight: maxHeight, callBack: updateButtons)
        popUpViewController.modalPresentationStyle = UIModalPresentationStyle.popover
        popUpViewController.editButton.addTarget(self, action: #selector(toggleEditProfiles), for: .touchUpInside)
        
        present(popUpViewController, animated: true, completion: nil)
        
        let popoverPresentationController = popUpViewController.popoverPresentationController
        popoverPresentationController?.sourceView = sender
        let height = Int(sender.frame.height)
        let width = Int(sender.frame.height) / 2
        
        
        popoverPresentationController?.sourceRect = CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: width, height: height))
    }
    
    func switchToAddProfileMode(){
        self.showBanner(toShow: true)
        self.showForwardingView(toShow: true)
        self.showView(viewToShow: self.editProfilesView!, toShow: false)
        self.banner?.selectTextView()
        //self.updateButtons()
        self.banner?.textFieldLabel.text = "Profile Name:"
        self.banner?.saveButton.addTarget(self, action: #selector(saveProfile), for: .touchUpInside)
        self.banner?.backButton.addTarget(self, action: #selector(completedAddProfileMode), for: .touchUpInside)
    }
    
    //go from internal text input mode to forwarding view
    func completedAddProfileMode(){
        
        self.banner?.saveButton.removeTarget(self, action: #selector(saveProfile), for: .touchUpInside)
        self.banner?.backButton.removeTarget(self, action: #selector(completedAddProfileMode), for: .touchUpInside)
        self.showView(viewToShow: self.editProfilesView!, toShow: true)
        self.showBanner(toShow: false)
        self.showForwardingView(toShow: false)
        self.banner?.selectDefaultView()

    }
    
    
    //go from internal text input mode to profile view
    func saveProfile() {
        let profileName = (self.banner?.textField.text)!
        if !(self.recommendationEngine?.checkProfile(profile_name: profileName))! {
            self.banner?.showWarningView(title: "Duplicate Profile", message: "Please change your profile name")
            return
        }
        if (self.banner?.emptyTextbox())! {
            return
        }
        self.reccommendationEngineLoaded = false
        
        self.banner?.saveButton.removeTarget(self, action: #selector(saveProfile), for: .touchUpInside)
        self.banner?.backButton.removeTarget(self, action: #selector(completedAddProfileMode), for: .touchUpInside)
        self.banner?.selectDefaultView()
        
        self.banner?.loadingLabel.text = "Creating new Profile (this may take several minutes)"
        self.banner?.showLoadingScreen(toShow: true)
        
        self.globalQueue.sync {
            // Background thread
            self.recommendationEngine?.numElements = 30000
            self.recommendationEngine?.addProfile(profile_name: profileName)
            DispatchQueue.main.async {
                // UI Updates
                self.banner?.showLoadingScreen(toShow: false)
                self.showForwardingView(toShow: false)
                self.showBanner(toShow: false)
                self.profileView = self.createProfile(profileName:profileName)
                self.showView(viewToShow: self.profileView!, toShow: true)
                self.reccommendationEngineLoaded = true
            }
        }
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
        textEntryView(toShow: true, view:profileView!)
        self.banner?.textFieldLabel.text = "Edit Name:"
        self.banner?.textField.text = profileView?.profileName!
        self.banner?.saveButton.addTarget(self, action: #selector(updateProfileName), for: .touchUpInside)
        self.banner?.backButton.addTarget(self, action: #selector(exiteditProfilesNameView), for: .touchUpInside)
    }
    

    func updateProfileName(){
        let newName = (self.banner?.textField.text)!
        
        if !(self.recommendationEngine?.checkProfile(profile_name: newName))! {
            self.banner?.showWarningView(title: "Duplicate Profile", message: "Please change your profile name")
            return
        }
        if (self.banner?.emptyTextbox())! {
            return
        }
        
        profileView?.NavBar.title = newName
        recommendationEngine?.editProfileName(current_name: (profileView?.profileName!)!, new_name: newName)
        profileView?.profileName = newName
        exiteditProfilesNameView()
    }
    
    func exiteditProfilesNameView() {
        textEntryView(toShow: false, view: profileView!)
        self.banner?.saveButton.removeTarget(self, action: #selector(updateProfileName), for: .touchUpInside)
        self.banner?.backButton.removeTarget(self, action: #selector(exiteditProfilesNameView), for: .touchUpInside)
    }
    
    func addDataSourceView() {
        textEntryView(toShow: true, view: profileView!)
        self.banner?.textFieldLabel.text = "Data Source URL:"
        self.banner?.textField.text = ""
        self.banner?.saveButton.addTarget(self, action: #selector(addDataSource), for: .touchUpInside)
        self.banner?.backButton.addTarget(self, action: #selector(exitDataSourceView), for: .touchUpInside)
    }
    
    func exitDataSourceView() {
        textEntryView(toShow: false, view: profileView!)
        self.banner?.saveButton.removeTarget(self, action: #selector(addDataSource), for: .touchUpInside)
        self.banner?.backButton.removeTarget(self, action: #selector(exitDataSourceView), for: .touchUpInside)
    }
    
    func addDataSource() {
         //grab url before it is cleared
        let myURLString = self.banner?.textField.text
        
        if (self.banner?.emptyTextbox())! {
            return
        }
        // REPLACE THIS WITH THE NAME OF THE PROFILE YOU'RE TARGETING, NOT THE ONE YOU'RE USING
        let target_profile:String = (self.profileView?.profileName!)!
        
        if !(self.recommendationEngine?.checkDataSource(targetProfile: target_profile, dataSource: myURLString!))! {
            self.banner?.showWarningView(title: "Duplicate Data Source", message: "This data source has already been added")
            return
        }
        var HTMLArray = [" "]
        
        //For now data source title and data source name are the same
        
        
        //show loading screen, and open keyboard while loading
        exitDataSourceView()
        self.goToKeyboard()
        self.banner?.showLoadingScreen(toShow: true)
        self.banner?.progressBar.isHidden = true
        self.banner?.loadingLabelMessage.text = "YooHooo"
        //start loading data in another thread
        self.globalQueue.async {
            // temp HTML parse code :: START
            DispatchQueue.main.async {
                self.banner?.loadingLabelMessage.text = "Accessing URL"
                return
            }
            guard let myURL = URL(string: myURLString!) else { // include ! after myURLString for first opt, exclude for second opt
                print("Error: \(myURLString) doesn't seem to be a valid URL")
                
                self.banner?.showWarningView(title: "Warning", message: "Invalid URL. Please try again.")
                //self.banner?.showLoadingScreen(toShow: false)
                self.addDataSourceView()
                self.banner?.textField.text = myURLString
                return
            }
            
            DispatchQueue.main.async {
                self.banner?.loadingLabelMessage.text = "Processing text"
                return
            }
            
            do {
                //let myHTMLString = try String(contentsOf: myURL, encoding: .utf8) // select only p
                let myHTMLString = try String(contentsOf: myURL, encoding: .utf8).html2String
                print(myHTMLString)
                var modString = (myHTMLString as NSString).replacingOccurrences(of: "\n", with: "   ")
                modString = modString.lowercased()
                let characterset = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789-' ")
                modString = modString.components(separatedBy: characterset.inverted).joined(separator: " ")
                HTMLArray = modString.components(separatedBy: " ")
            } catch let error {
                print("Error: \(error)")
                
                self.banner?.showWarningView(title: "Warning", message: "Unable to reach URL. Please try again.")
                self.banner?.showLoadingScreen(toShow: false)
                self.banner?.progressBar.isHidden = false
                self.addDataSourceView()
                self.banner?.textField.text = myURLString
                
                return
            }
            
         
            // gen n-grams
            
            var unigrams = [String: Int]()
            var bigrams = [String: Int]()
            var trigrams = [String: Int]()
            
            var i = 0
            
            
            let len = HTMLArray.count
            print(HTMLArray)
            while(i < len){
                // update unigrams
                let curUnigram = HTMLArray[i]
                if curUnigram == ""{
                    i += 1
                    continue
                }
                if (unigrams[curUnigram] != nil){
                    unigrams[curUnigram] = unigrams[curUnigram]! + 1
                }
                else{
                    unigrams[curUnigram] = 1
                }
                
                // update bigrams
                if i < len - 1{
                    if HTMLArray[i+1]==""{
                      i += 1
                      continue
                    }
                    let curBigram = String(describing: HTMLArray[i]) + " " + String(describing: HTMLArray[i+1])
                    if bigrams[curBigram] != nil{
                        bigrams[curBigram] = bigrams[curBigram]! + 1
                    }
                    else{
                        bigrams[curBigram] = 1
                    }
                }
                
                // update trigrams
                if i < len - 2{
                    if HTMLArray[i+1]=="" || HTMLArray[i+2]==""{
                        i += 1
                        continue
                    }
                    let curTrigram = String(describing: HTMLArray[i]) + " " + String(describing: HTMLArray[i+1]) + " " + String(describing: HTMLArray[i+2])
                    if trigrams[curTrigram] != nil{
                        trigrams[curTrigram] = trigrams[curTrigram]! + 1
                    }
                    else{
                        trigrams[curTrigram] = 1
                    }
                }
                
                // increment
                i += 1
            }
            
            /*
            print("\n---Unigrams---\n")
            print(unigrams.valueKeySorted)
            print("\n---Bigrams---\n")
            print(bigrams.valueKeySorted)
            print("\n---Trigrams---\n")
            print(trigrams.valueKeySorted)
            */
            // temp HTML parse code :: END
            // Background thread
            // NEW IDEA:
            //   -get all current ngrams from profile (1 db call)
            //   -put those into a set
            //   -if new ngram is not in the set, append to bulk_insert string
            //   -update frequency
            let source = (self.banner?.textField.text)!
            self.recommendationEngine?.addDataSource(target_profile: target_profile, new_data_source: source, new_title: source)

            var bulk_insert = "INSERT INTO Containers (profile, ngram, n, dataSource, frequency) VALUES "
            var bulk_update = ""
            var all_updates = [String: Int]()
            
            // -----------------------------------
            // is it possible to do a bulk update?
            // idk but I'm gonna try anyway
            // -----------------------------------
            
            // ---------------------------------------
            var ngramsSet = self.recommendationEngine?.getNgramsFromProfile(profile: target_profile)
            
            self.recommendationEngine?.numElements = Int(unigrams.count + bigrams.count + trigrams.count)
            /*
            DispatchQueue.main.async {
                self.recommendationEngine?.counter = 0
                return
            }*/
            
            for unigram in unigrams {
                //self.recommendationEngine?.insertAndIncrement(ngram: unigram.key, n: 1,
                //                                              new_freq: Float64(unigram.value))
                if !(ngramsSet?.contains(unigram.key))! {
                    // append to bulk insert
                    bulk_insert.append("(\"\(target_profile)\",\"\(unigram.key)\",1,"
                                        + "\"\(source)\",\(unigram.value)), ")
                    ngramsSet?.insert(unigram.key)
                }
                else {
                    // update frequency
                    // use bulk_update if that's possible
                    let new_update = "UPDATE Containers SET frequency = frequency + \(unigram.value) WHERE profile = \"\(target_profile)\" AND ngram = \"\(unigram.key)\"; "
                    bulk_update.append(new_update)
                    all_updates[unigram.key] = unigram.value
                }
                
                /*DispatchQueue.main.async {
                    self.recommendationEngine?.counter += 1
                    return
                }*/
            }
            for bigram in bigrams {
                //self.recommendationEngine?.insertAndIncrement(ngram: bigram.key, n: 2,
                //                                              new_freq: Float64(bigram.value))
                if !(ngramsSet?.contains(bigram.key))! {
                    // append to bulk insert
                    bulk_insert.append("(\"\(target_profile)\",\"\(bigram.key)\",2,"
                                        + "\"\(source)\",\(bigram.value)), ")
                    ngramsSet?.insert(bigram.key)
                }
                else {
                    // update frequency
                    // use bulk_update if that's possible
                    let new_update = "UPDATE Containers SET frequency = frequency + \(bigram.value) WHERE ngram = \"\(bigram.key)\" AND profile = \"\(target_profile)\"; "
                    bulk_update.append(new_update)
                    all_updates[bigram.key] = bigram.value
                }
                
               /* DispatchQueue.main.async {
                    self.recommendationEngine?.counter += 1
                    return
                }*/
            }
            for trigram in trigrams {
                //self.recommendationEngine?.insertAndIncrement(ngram: trigram.key, n: 3,
                //                                              new_freq: Float64(trigram.value))
                if !(ngramsSet?.contains(trigram.key))! {
                    // append to bulk insert
                    bulk_insert.append("(\"\(target_profile)\",\"\(trigram.key)\",3,"
                                        + "\"\(source)\",\(trigram.value)), ")
                    ngramsSet?.insert(trigram.key)
                }
                else {
                    // update frequency
                    // use bulk_update if that's possible
                    let new_update = "UPDATE Containers SET frequency = frequency + \(trigram.value) WHERE ngram = \"\(trigram.key)\" AND profile = \"\(target_profile)\"; "
                    bulk_update.append(new_update)
                    all_updates[trigram.key] = trigram.value
                }
                
               /* DispatchQueue.main.async {
                    self.recommendationEngine?.counter += 1
                    return
                }*/
            }
            
            // Run insert and update
            do {
                let db_path = dbObjects().db_path
                let db = try Connection("\(db_path)/db.sqlite3")
                
                
                DispatchQueue.main.async {
                    self.banner?.loadingLabelMessage.text = "Updating words"
                    return
                }
                _ = try db.run(bulk_update)
                
                DispatchQueue.main.async {
                    self.banner?.loadingLabelMessage.text = "Adding words"
                    return
                }
                _ = try db.run(String(bulk_insert.characters.dropLast(2))+";")
                
                DispatchQueue.main.async {
                    self.banner?.loadingLabelMessage.text = "Load Completed"
                    return
                }

            } catch {
                print("Error: \(error)")
            }
                
            DispatchQueue.main.async {
                // UI Updates
                self.banner?.showLoadingScreen(toShow: false)
                self.showForwardingView(toShow: false)
                self.showBanner(toShow: false)
                self.profileView?.reloadData()
                self.showView(viewToShow: self.profileView!, toShow: true)
            }
        }
    }
    
    func deleteProfilePressed() {
        self.deleteScreen = DeleteViewController(view: self.profileView! as UIView, type: "profile", name: (profileView?.profileName!)!)
        self.deleteScreen?.cancelButton.addTarget(self, action: #selector(self.removeDeleteScreen), for: .touchUpInside)
        //self.deleteScreen?.deleteButton.tag = (indexPath as NSIndexPath).row
        self.deleteScreen?.deleteButton.addTarget(self, action: #selector(self.deleteProfile), for: .touchUpInside)
    }
    
    func deleteProfileHelper(profile:String) {
        recommendationEngine?.deleteProfile(profile_name: profile)
        if profile == UserDefaults.standard.string(forKey: "profile") {
            UserDefaults.standard.string(forKey: "profile")
            UserDefaults.standard.register(defaults: ["profile": self.defaultProf])
            self.banner?.profileSelector.setTitle(UserDefaults.standard.string(forKey: "profile")!, for: UIControlState())
        }
    }
    
    func deleteProfile() {
        let profileName = profileView?.profileName!
        deleteProfileHelper(profile: profileName!)
        profileToEditProfiles()
    }
    
    func removeDeleteScreen() {
        if self.deleteScreen != nil {
            self.deleteScreen?.warningView.removeFromSuperview()
        }
        self.deleteScreen = nil
    }
    
    func textEntryView(toShow: Bool, view:ExtraView) {
        if toShow {
            showView(viewToShow: view, toShow: false)
            self.banner?.selectTextView()
            //self.updateButtons()
        }
        else {
            self.banner?.selectDefaultView()
            //if you cancel just reopen view.  showView will recreate it, we dont need to do that
            profileView?.isHidden = false
            profileView?.isUserInteractionEnabled = true
        }
        //updateButtons()
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
    
    func addPhraseView() {
        textEntryView(toShow: true, view: phrasesView!)
        self.banner?.textFieldLabel.text = "Add Phrase:"
        self.banner?.saveButton.addTarget(self, action: #selector(addPhrase), for: .touchUpInside)
        self.banner?.backButton.addTarget(self, action: #selector(exitAddPhraseView), for: .touchUpInside)
    }
    
    func exitAddPhraseView() {
        textEntryView(toShow: false, view: phrasesView!)
        showView(viewToShow: phrasesView!, toShow: true)
        self.banner?.saveButton.removeTarget(self, action: #selector(addPhrase), for: .touchUpInside)
        self.banner?.backButton.removeTarget(self, action: #selector(exitAddPhraseView), for: .touchUpInside)
    }
    
    func addPhrase() {
        if !(self.recommendationEngine?.checkPhrase(phrase: (self.banner?.textField.text!)!))! {
            self.banner?.showWarningView(title: "Duplicate Phrase", message: "This phrase already exists")
            return
        }
        if (self.banner?.emptyTextbox())! {
            return
        }
        self.recommendationEngine?.addPhrase(phrase: (self.banner?.textField.text!)!)
        self.phrasesView?.reloadData()
        exitAddPhraseView()
    }
    
    func editPhraseView(phrase:String) {
        textEntryView(toShow: true, view: phrasesView!)
        phrasesView?.oldEditPhrase = phrase
        self.banner?.textFieldLabel.text = "Edit Phrase:"
        self.banner?.textField.text = phrase
        self.banner?.saveButton.addTarget(self, action: #selector(editPhrase), for: .touchUpInside)
        self.banner?.backButton.addTarget(self, action: #selector(exitEditPhraseView), for: .touchUpInside)
    }
    
    func editPhrase() {
        let newPhrase = self.banner?.textField.text
        if (self.banner?.emptyTextbox())! {
            return
        }
        
        if !(self.recommendationEngine?.checkPhrase(phrase: (self.banner?.textField.text!)!))! {
            self.banner?.showWarningView(title: "Duplicate Phrase", message: "This phrase already exists")
            return
        }
        
        recommendationEngine?.editPhrase(old_phrase: (phrasesView?.oldEditPhrase)!, new_phrase: newPhrase!)
        phrasesView?.reloadData()
        exitAddPhraseView()
    }
    
    func exitEditPhraseView() {
        textEntryView(toShow: false, view: phrasesView!)
        showView(viewToShow: phrasesView!, toShow: true)
        phrasesView?.tableView?.setEditing(false, animated: false)
        self.banner?.saveButton.removeTarget(self, action: #selector(editPhrase), for: .touchUpInside)
        self.banner?.backButton.removeTarget(self, action: #selector(exitEditPhraseView), for: .touchUpInside)
    }
    
    func createEditProfiles() -> ExtraView? {
        let editProfiles = EditProfiles(globalColors: type(of: self).globalColors, darkMode: false, solidColorMode: self.solidColorMode())
        
        editProfiles.keyboardButton?.action = #selector(toggleEditProfiles)
        editProfiles.keyboardButton?.target = self
        editProfiles.addButton?.action = #selector(switchToAddProfileMode)
        editProfiles.addButton?.target = self
        editProfiles.callBack = openProfileCallback
        editProfiles.deleteCallback = deleteProfileHelper
        return editProfiles
    }
    
    func createProfile(profileName:String) -> Profiles? {
        // note that dark mode is not yet valid here, so we just put false for clarity
        let profileView = Profiles(profileName: profileName, globalColors: type(of: self).globalColors, darkMode: false, solidColorMode: self.solidColorMode())

        profileView.keyboardButton?.action = #selector(goToKeyboard)
        profileView.keyboardButton?.target = self
        
        profileView.profileViewButton?.action = #selector(profileToEditProfiles)
        profileView.keyboardButton?.target = self
        profileView.editName?.action = #selector(editProfilesNameView)
        profileView.editName?.target = self
        profileView.addButton?.action = #selector(addDataSourceView)
        profileView.addButton?.target = self
        profileView.deleteButton.action = #selector(deleteProfilePressed)

        profileView.deleteButton.target = self
        return profileView
    }
    
    func openProfileCallback(tableTitle:String) {
        //let title = tableTitle.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        openProfile(profileName: tableTitle)
        profileView?.NavBar.title = tableTitle
        //we dont want you editing the default profile name
        if title == self.defaultProf {
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
        let phrasesView = Phrases(onClickCallBack: typePhrase, editCallback: editPhraseView, globalColors: type(of: self).globalColors, darkMode: false, solidColorMode: self.solidColorMode())

        phrasesView.backButton?.action = #selector(goToKeyboard)
        phrasesView.backButton?.target = self
        
        phrasesView.addButton?.action = #selector(addPhraseView)
        phrasesView.addButton?.target = self

        return phrasesView
    }
    
    override func shiftPressed() {
        //updateButtons()
    }
    
    override func setCapsIfNeeded() -> Bool {
        if self.shouldAutoCapitalize() {
            switch self.shiftState {
            case .disabled:
                self.shiftState = .enabled
            case .enabled:
                self.shiftState = .enabled
            case .locked:
                self.shiftState = .locked
            }
            self.updateButtons()
            return true
        }
        else {
            switch self.shiftState {
            case .disabled:
                self.shiftState = .disabled
            case .enabled:
                self.shiftState = .disabled
            case .locked:
                self.shiftState = .locked
            }
            self.updateButtons()
            return false
        }
    }
    
    override func shouldAutoCapitalize() -> Bool {
        if !UserDefaults.standard.bool(forKey: kAutoCapitalization) {
            return false
        }
        
        let traits = self.textDocumentProxy
        let normalInputMode = UserDefaults.standard.bool(forKey: "keyboardInputToApp")
        if let autocapitalization = (normalInputMode ? traits.autocapitalizationType : UITextAutocapitalizationType.sentences) {
            switch autocapitalization {
            case .none:
                return false
            case .words:
                let beforeContext = self.contextBeforeInput()
                if beforeContext.characters.count > 0 {
                    let previousCharacter = beforeContext[beforeContext.characters.index(before: beforeContext.endIndex)]
                    return self.characterIsWhitespace(previousCharacter)
                }
                else {
                    return true
                }
                
            case .sentences:
                let beforeContext = self.contextBeforeInput()
                if beforeContext.characters.count > 0 {
                    let offset = min(3, beforeContext.characters.count)
                    var index = beforeContext.endIndex
                    
                    for i in 0 ..< offset {
                        index = beforeContext.index(before: index)
                        let char = beforeContext[index]
                        
                        if characterIsPunctuation(char) {
                            if i == 0 {
                                return false //not enough spaces after punctuation
                            }
                            else {
                                return true //punctuation with at least one space after it
                            }
                        }
                        else {
                            if !characterIsWhitespace(char) {
                                return false //hit a foreign character before getting to 3 spaces
                            }
                            else if characterIsNewline(char) {
                                return true //hit start of line
                            }
                        }
                    }
                    
                    return true //either got 3 spaces or hit start of line
                }
                else {
                    return true
                }
            case .allCharacters:
                return true
            }
        }
        else {
            return false
        }
    }

    func typePhrase(_ sentence: String) {
        print(sentence)
        
        let insertionSentence = sentence + " "
        // update database with insertion word
        addText(text: insertionSentence)
        //updateButtons()
        setCapsIfNeeded()
        self.goToKeyboard()
    }
    
    func fastDeleteMode(key:Key, secondaryMode:Bool) ->Bool {
        return (key.type == .backspace && secondaryMode)
    }
    
    func corrections(_ word: String) -> [String]? {
        let textChecker = UITextChecker()
        let misspelledRange = textChecker.rangeOfMisspelledWord(
            in: word, range: NSRange(0..<word.utf16.count),
            startingAt: 0, wrap: false, language: "en_US")
        
        if misspelledRange.location != NSNotFound {
            return textChecker.guesses(forWordRange: misspelledRange, in: word, language: "en_US")! as [String]
        } else {
            return nil
        }
    }
}


