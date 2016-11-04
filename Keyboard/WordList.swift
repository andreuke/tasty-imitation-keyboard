//
//  WordList.swift
//  TastyImitationKeyboard
//
//  Created by Zack Burns on 10/16/16.
//  Copyright © 2016 Apple. All rights reserved.
//

import UIKit
import SQLite


class WordList: NSObject {
    
    override init() {
        
        do {
            let db_path = NSSearchPathForDirectoriesInDomains(
                        .documentDirectory, .userDomainMask, true).first!
            let pathToWords = Bundle.main.path(forResource: "google-10000", ofType: "txt")
            let content = try String(contentsOfFile:pathToWords!, encoding: String.Encoding.utf8)
            let allWords = content.components(separatedBy: "\n")
            
            let db = try Connection("\(db_path)/db.sqlite3")

            let ngrams = Table("Ngrams")
            let gram = Expression<String>("gram")
            let n = Expression<Int>("n")
            
            try? db.run(ngrams.create { t in
                t.column(gram, primaryKey: true)
                t.column(n)
            })
            
            for word in allWords {
                // check if word is in db
                let result = try? db.scalar(ngrams.filter(gram == word).count)
                // if not in db, insert into db
                if result! == 0 {
                    let insert = ngrams.insert(gram <- word, n <- 1)
                    _ = try? db.run(insert)
                }
                else if result! > 1{
                    print("There's a duplicate word in the db!")
                }
            }
        }
        catch {
            print("uh oh")
        }
        
    }
    
    func recommendWords(input: String)->[String]{
        var resultSet = [String]()
        do {
            let db_path = NSSearchPathForDirectoriesInDomains(
                .documentDirectory, .userDomainMask, true).first!
            let db = try Connection("\(db_path)/db.sqlite3")
            
            for row in try db.prepare("SELECT gram, n FROM Ngrams WHERE gram LIKE '\(input.lowercased())%'") {
                if (row[1] as! Int64) == 1 {
                    resultSet.append((row[0] as! String))
                }
            }
        }
        catch {
            print("There was an error while fetching recommendations")
        }
        return resultSet
    }
    
}
