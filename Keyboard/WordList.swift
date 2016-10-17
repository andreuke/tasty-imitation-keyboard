//
//  WordList.swift
//  TastyImitationKeyboard
//
//  Created by Zack Burns on 10/16/16.
//  Copyright © 2016 Apple. All rights reserved.
//

import UIKit

class WordList: NSObject {
    
    var words = [String]()
    
    var pathToFile = FileManager.default.currentDirectoryPath
    
    func getWords(){
        do {
            let text = try NSString(contentsOf: URL(string: self.pathToFile)!, encoding: String.Encoding.utf8.rawValue)
            self.words = text.components(separatedBy: "\n")
        } catch let error as NSError {
            print("Failed reading from URL: \(self.pathToFile), Error: " + error.localizedDescription)
        }
    }
    
    func recommendWords(input: String)->[String]{
        var resultSet = [String]()
        for word in self.words {
            if word.hasPrefix(input) {
                resultSet.append(word)
            }
        }
        return resultSet
    }

}
