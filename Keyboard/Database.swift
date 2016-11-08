//
//  WordList.swift
//  TastyImitationKeyboard
//
//  Created by Zack Burns on 10/16/16.
//  Copyright © 2016 Apple. All rights reserved.
//

import UIKit
import SQLite


class dbObjects {
    
    let db_path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    
    struct Ngrams {
        let table = Table("Ngrams")
        let gram = Expression<String>("gram")
        let n = Expression<Int>("n")
    }
    
    struct Profiles {
        let table = Table("Profiles")
        let profileId = Expression<Int64>("profileId")
        let name = Expression<String>("name")
        let linksTo = Expression<Int64>("linksTo")
    }
    
    struct Containers {
        let table = Table("Containers")
        let containerId = Expression<Int64>("containerId")
        let profile = Expression<String>("profile")
        let ngram = Expression<String>("ngram")
        let frequency = Expression<Int64>("frequency")
        let lastused = Expression<Date>("lastused")
    }
    
    struct Phrases {
        let table = Table("Phrases")
        let phraseId = Expression<Int64>("id")
        let phrase = Expression<String>("phrase")
    }
    
}

class Database: NSObject {
    
    override init() {
        
        do {
            
            let pathToWords = Bundle.main.path(forResource: "google-10000", ofType: "txt")
            let content = try String(contentsOfFile:pathToWords!, encoding: String.Encoding.utf8)
            let allWords = content.components(separatedBy: "\n")

            let db_path = dbObjects().db_path
            let db = try Connection("\(db_path)/db.sqlite3")
            
            // Database object references
            let ngrams = dbObjects.Ngrams()
            let profiles = dbObjects.Profiles()
            let containers = dbObjects.Containers()
            let phrases = dbObjects.Phrases()

            // Create Ngrams table
            try? db.run(ngrams.table.create(ifNotExists: true) { t in
                t.column(ngrams.gram, primaryKey: true)
                t.column(ngrams.n)
            })
            
            // Create Profiles table
            try? db.run(profiles.table.create(ifNotExists: true) { t in
                t.column(profiles.profileId, primaryKey: .autoincrement)
                t.column(profiles.name)
                t.column(profiles.linksTo, defaultValue: 0)
            })
            
            // Insert the Default profile into the Profiles table if it doesn't exist
            if (try db.scalar(profiles.table.filter(profiles.profileId == 0).count)) == 0 {
                let insert = profiles.table.insert(profiles.name <- "Default")
                _ = try? db.run(insert)
            }
            
            // Create Containers table (pairing of profile and ngram)
            try? db.run(containers.table.create(ifNotExists: true) { t in
                t.column(containers.containerId, primaryKey: .autoincrement)
                t.column(containers.profile)
                t.column(containers.ngram)
                t.column(containers.frequency, defaultValue: 0)
                t.column(containers.lastused, defaultValue: Date())
            })
            
            // Create Phrases table so user can store pre-defined phrases
            try? db.run(phrases.table.create(ifNotExists: true) { t in
                t.column(phrases.phraseId, primaryKey: .autoincrement)
                t.column(phrases.phrase)
            })
            
            // Check to make sure the number of words in Default matches the number
            //   of words in google-10000.txt --- there were duplicates that I deleted,
            //   so there are only 9989 unique words, not 10000
            // If not, then insert the missing words
            if (try db.scalar(containers.table.filter(containers.profile == "Default").count) < 9989) {
                // Populate the Ngrams table and Container table with words
                for word in allWords {
                    // check if word is in Ngrams, and insert it if it's not
                    let result = try? db.scalar(ngrams.table.filter(ngrams.gram == word).count)
                    if result! == 0 {
                        let insert = ngrams.table.insert(ngrams.gram <- word, ngrams.n <- 1)
                        _ = try? db.run(insert)
                    }
                    else if result! > 1{
                        print("There's a duplicate word in the db!")
                    }
                    
                    // check if word is paired with Default profile in Containers table, insert if not
                    let containerResult = try? db.scalar(containers.table
                                                        .filter(containers.profile == "Default")
                                                        .filter(containers.ngram == word).count)
                    if containerResult == 0 {
                        let insert = containers.table.insert(containers.profile <- "Default",
                                                            containers.ngram <- word)
                        _ = try? db.run(insert)
                    }
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
            let db_path = dbObjects().db_path
            let db = try Connection("\(db_path)/db.sqlite3")
            
            let containers = dbObjects.Containers()
            
            let userProfile = UserDefaults.standard.value(forKey: "profile")
            for row in try db.prepare(containers.table
                                                .filter(containers.profile == userProfile as! String)
                                                .filter(containers.ngram.like("\(input)%"))
                                                .order(containers.frequency.desc, containers.ngram)) {
                resultSet.append(row[containers.ngram])
            }
        }
        catch {
            print("There was an error while fetching recommendations")
        }
        return resultSet
    }
    
}
