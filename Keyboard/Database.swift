
//
//  Database.swift
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
        let n = Expression<Int>("n")
        let frequency = Expression<Int64>("frequency")
        let lastused = Expression<Date>("lastused")
    }
    
    struct Phrases {
        let table = Table("Phrases")
        let phraseId = Expression<Int64>("id")
        let phrase = Expression<String>("phrase")
    }
    
    struct DataSources {
        let table = Table("DataSources")
        let profile = Expression<String>("profile")
        let title = Expression<String>("title")
        let source = Expression<String>("source")
    }
    
}

class Database: NSObject {
    
    override init() {
        
        do {
            
            let db_path = dbObjects().db_path
            let db = try Connection("\(db_path)/db.sqlite3")
            

            // Database object references
            let ngrams = dbObjects.Ngrams()
            let profiles = dbObjects.Profiles()
            let containers = dbObjects.Containers()
            let phrases = dbObjects.Phrases()
            let data_sources = dbObjects.DataSources()
            
            
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
            
            //try? db.run(profiles.delete())
            
            // Insert the Default profile into the Profiles table if it doesn't exist
            
            if (try db.scalar(profiles.table.filter(profiles.name == "Default").count)) == 0 {
                let insert = profiles.table.insert(profiles.name <- "Default")
                _ = try? db.run(insert)
            }
            
            // Create Containers table (pairing of profile and ngram)
            try? db.run(containers.table.create(ifNotExists: true) { t in
                t.column(containers.containerId, primaryKey: .autoincrement)
                t.column(containers.profile)
                t.column(containers.ngram)
                t.column(containers.n)
                t.column(containers.frequency, defaultValue: 0)
                t.column(containers.lastused, defaultValue: Date())
            })
            
            // Create Phrases table so user can store pre-defined phrases
            try? db.run(phrases.table.create(ifNotExists: true) { t in
                t.column(phrases.phraseId, primaryKey: .autoincrement)
                t.column(phrases.phrase)
            })
            
            // Create DataSource table
            try? db.run(data_sources.table.create(ifNotExists: true) { t in
                t.column(data_sources.profile)
                t.column(data_sources.title)
                t.column(data_sources.source)
            })
            
            
            let pathToWords = Bundle.main.path(forResource: "google-10000", ofType: "txt")
            let pathToTwoGrams = Bundle.main.path(forResource: "2grams-10000", ofType: "txt")
            let pathToThreeGrams = Bundle.main.path(forResource: "3grams-10000", ofType: "txt")
            
            let wordsContent = try String(contentsOfFile:pathToWords!, encoding: String.Encoding.utf8)
            let allWords = wordsContent.components(separatedBy: "\n")
            
            let twoGramsContent = try String(contentsOfFile:pathToTwoGrams!,
                                             encoding: String.Encoding.utf8)
            // The format of the items in allTwoGrams is: <freq>\t<word1>\t<word2>
            let allTwoGrams = twoGramsContent.components(separatedBy: "\r\n")
            
            let threeGramsContent = try String(contentsOfFile:pathToThreeGrams!, encoding: String.Encoding.utf8)
            // The format of the items in allThreeGrams is: <freq>\t<word1>\t<word2>\t<word3>
            let allThreeGrams = threeGramsContent.components(separatedBy: "\r\n")
            
            // Check to make sure Database has been created
            // If not, then insert the missing words
            if (try db.scalar(containers.table.filter(containers.profile == "Default").count) < 20000) {
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
                                                             containers.ngram <- word,
                                                             containers.n <- 1)
                        _ = try? db.run(insert)
                    }
                }
                
                for twoGram in allTwoGrams {
                    if twoGram == "" {
                        break
                    }
                    let twoGramComponents = twoGram.components(separatedBy: "\t")
                    var insertNgram = ""
                    var insert_n = Int()
                    // if the word2 is "n't" then combine word1 and word2 and insert with n=1
                    if twoGramComponents[2] == "n't" {
                        insertNgram = twoGramComponents[1]+twoGramComponents[2]
                        insert_n = 1
                    }
                        // else insert with n=2
                    else {
                        insertNgram = twoGramComponents[1]+" "+twoGramComponents[2]
                        insert_n = 2
                    }
                    let result = try? db.scalar(ngrams.table.filter(ngrams.gram == insertNgram).count)
                    if result! == 0 {
                        let insert = ngrams.table.insert(ngrams.gram <- insertNgram,
                                                         ngrams.n <- insert_n)
                        _ = try? db.run(insert)
                    }
                    
                    
                    // check if insertNgram is paired with Default profile in Containers table, insert if not
                    let containerResult = try? db.scalar(containers.table
                        .filter(containers.profile == "Default")
                        .filter(containers.ngram == insertNgram).count)
                    if (containerResult == 0) && (insertNgram != "") {
                        let insert = containers.table.insert(containers.profile <- "Default",
                                                             containers.ngram <- insertNgram,
                                                             containers.n <- insert_n)
                        _ = try? db.run(insert)
                    }
                }
                
                for threeGram in allThreeGrams {
                    if threeGram == "" {
                        break
                    }
                    let threeGramComponents = threeGram.components(separatedBy: "\t")
                    var word1 = threeGramComponents[1]
                    let word2 = threeGramComponents[2]
                    let word3 = threeGramComponents[3]
                    var insertNgram = ""
                    var insert_n = Int()
                    // handle different cases of 3grams like we did with 2grams
                    if word1 == "n't" {
                        word1 = "not"
                    }
                    if word2 == "n't" {
                        insertNgram = word1+word2+" "+word3
                        insert_n = 2
                    }
                    else if word3 == "n't" {
                        insertNgram = word1+" "+word2+word3
                        insert_n = 2
                    }
                    else {
                        insertNgram = word1+" "+word2+" "+word3
                        insert_n = 3
                    }
                    let result = try? db.scalar(ngrams.table.filter(ngrams.gram == insertNgram).count)
                    if result! == 0 {
                        let insert = ngrams.table.insert(ngrams.gram <- insertNgram,
                                                         ngrams.n <- insert_n)
                        _ = try? db.run(insert)
                    }
                    
                    // check if insertNgram is paired with Default profile in Containers table, insert if not
                    let containerResult = try? db.scalar(containers.table
                        .filter(containers.profile == "Default")
                        .filter(containers.ngram == insertNgram).count)
                    if (containerResult == 0) && (insertNgram != "") {
                        let insert = containers.table.insert(containers.profile <- "Default",
                                                             containers.ngram <- insertNgram,
                                                             containers.n <- insert_n)
                        _ = try? db.run(insert)
                    }
                }
            }
        }
        catch {
            print("uh oh")
        }
    }
    
    func insertIntoNgrams(input_ngram: String, n: Int) {
        do {
            let db_path = dbObjects().db_path
            let db = try Connection("\(db_path)/db.sqlite3")
            
            let ngrams = dbObjects.Ngrams()
            let insert = ngrams.table.insert(ngrams.gram <- input_ngram, ngrams.n <- n)
            _ = try? db.run(insert)
        } catch {}
    }
    
    /*func recommendationQuery(user_profile: String, n: Int, pattern: String,
                             current_input: String, result_set: Set<String>) -> Set<String> {
        var resultSet = result_set
        do {
            let db_path = dbObjects().db_path
            let db = try Connection("\(db_path)/db.sqlite3")
            let containers = dbObjects.Containers()
            
            for row in try db.prepare(containers.table
                .filter(containers.profile == user_profile)
                .filter(containers.ngram.like(pattern))
                .filter(containers.ngram != current_input)
                .filter(containers.ngram != "")
                .filter(containers.n == n)
                .order(containers.frequency.desc, containers.ngram)
                .limit(14, offset: 0)) {
                    // Insert the last word of the 3gram
                    let row_components = row[containers.ngram].components(separatedBy: " ")
                    if row_components[2].hasPrefix(current_input) {
                        resultSet.insert(row_components[2])
                    }
            }
        } catch {}
        return resultSet
    }*/
    
    func recommendWords(word1: String = "", word2: String = "", current_input: String)->Set<String>{
        var resultSet = Set<String>()
        do {
            let db_path = dbObjects().db_path
            let db = try Connection("\(db_path)/db.sqlite3")
            
            let containers = dbObjects.Containers()
            
            let userProfile = UserDefaults.standard.value(forKey: "profile")
            
            // If any previous words are available, use those
            
            // If 2 previous words are available...
            if word1 != "" && word2 != "" {
                // Get recommendations from 3grams where word1 and 
                // word2 are the first two words of the 3gram
                for row in try db.prepare(containers.table
                    .filter(containers.profile == userProfile as! String)
                    .filter(containers.ngram.like("\(word1) \(word2) \(current_input)%"))
                    .filter(containers.ngram != current_input)
                    .filter(containers.ngram != "")
                    .filter(containers.n == 3)
                    .order(containers.frequency.desc, containers.ngram)
                    .limit(14, offset: 0)) {
                        // Insert the last word of the 3gram
                        let row_components = row[containers.ngram].components(separatedBy: " ")
                        if row_components[2].hasPrefix(current_input) {
                            resultSet.insert(row_components[2])
                        }
                }
                
                // Get recommendations from 2grams where 
                // word2 is the first word in the 2gram
                for row in try db.prepare(containers.table
                    .filter(containers.profile == userProfile as! String)
                    .filter(containers.ngram.like("\(word2) \(current_input)%"))
                    .filter(containers.ngram != current_input)
                    .filter(containers.ngram != "")
                    .filter(containers.n == 2)
                    .order(containers.frequency.desc, containers.ngram)
                    .limit(14, offset: 0)) {
                        // Insert the last word of the 2gram
                        let row_components = row[containers.ngram].components(separatedBy: " ")
                        if row_components[1].hasPrefix(current_input) && resultSet.count < 14 {
                            resultSet.insert(row_components[1])
                        }
                }
                
                // Get recommendations from 1grams
                for row in try db.prepare(containers.table
                    .filter(containers.profile == userProfile as! String)
                    .filter(containers.ngram.like("\(current_input)%"))
                    .filter(containers.ngram != current_input)
                    .filter(containers.ngram != "")
                    .filter(containers.n == 1)
                    .order(containers.frequency.desc, containers.ngram)
                    .limit(14, offset: 0)) {
                        // Insert word
                        if resultSet.count < 14 {
                            resultSet.insert(row[containers.ngram])
                        }
                }
            }
            
            
            else if word1 == "" && word2 != "" {
                for row in try db.prepare(containers.table
                    .filter(containers.profile == userProfile as! String)
                    .filter(containers.ngram.like("% \(word2) \(current_input)%"))
                    .filter(containers.ngram != current_input)
                    .filter(containers.ngram != "")
                    .filter(containers.n == 3)
                    .order(containers.frequency.desc, containers.ngram)
                    .limit(14, offset: 0)) {
                        // Find which word to insert
                        let row_components = row[containers.ngram].components(separatedBy: " ")
                        if row_components[2].hasPrefix(current_input) {
                            if resultSet.count < 14 {
                                resultSet.insert(row_components[2])
                            }
                        }
                        else {
                            if resultSet.count < 14 {
                                resultSet.insert(row_components[1]+" "+row_components[2])
                            }
                        }
                }
            }
            
            // If not, just use the current input...
            // Get recommendations where input is the beginning of the ngram
            // Prioritize 2grams for better specificity
            for row in try db.prepare(containers.table
                .filter(containers.profile == userProfile as! String)
                .filter(containers.ngram.like("\(current_input)%"))
                .filter(containers.ngram != current_input)
                .filter(containers.ngram != "")
                .order(containers.n, containers.frequency.desc, containers.ngram)
                .limit(14, offset: 0)) {
                    if resultSet.count < 14 {
                        resultSet.insert(row[containers.ngram])
                    }
            }
    
        }
        catch {
            print("There was an error while fetching recommendations")
        }
        return resultSet
    }
    
    func addProfile(profileName:String){
        do {
            let db_path = dbObjects().db_path
            let db = try Connection("\(db_path)/db.sqlite3")
            
            // Insert the new profile into the database
            let profiles = dbObjects.Profiles()
            
            if (try db.scalar(profiles.table.filter(profiles.name == profileName).count)) == 0 {
                let insert = profiles.table.insert(profiles.name <- profileName)
                _ = try? db.run(insert)
            }
            
            // Insert all of the original words into the new profile
            let ngrams = dbObjects.Ngrams()
            let containers = dbObjects.Containers()
            
            for row in try db.prepare(ngrams.table) {
                let insert = containers.table.insert(containers.profile <- profileName,
                                                     containers.ngram <- row[ngrams.gram],
                                                     containers.n <- row[ngrams.n])
                _ = try? db.run(insert)
            }
            
        } catch {}
    }
    
    // Delete profile function
    func deleteProfile(profile_name: String) {
        do {
            let db_path = dbObjects().db_path
            let db = try Connection("\(db_path)/db.sqlite3")
            
            // Delete profile from Profiles
            let profiles = dbObjects.Profiles()
            _ = try db.run(profiles.table.filter(profiles.name == profile_name).delete())
            
            // Delete all ngrams associated with profile from Containers
            let containers = dbObjects.Containers()
            _ = try db.run(containers.table.filter(containers.profile == profile_name).delete())
            
            // Delete all data sources associated with profile
            let data_sources = dbObjects.DataSources()
            _ = try db.run(data_sources.table.filter(data_sources.profile == profile_name).delete())
            
        } catch {}
    }
    
    func editProfileName(current_name: String, new_name: String) {
        do {
            let db_path = dbObjects().db_path
            let db = try Connection("\(db_path)/db.sqlite3")
            
            let profiles = dbObjects.Profiles()
            let containers = dbObjects.Containers()
            let data_sources = dbObjects.DataSources()
            
            _ = try db.run(profiles.table
                            .filter(profiles.name == current_name)
                            .update(profiles.name <- new_name))
            _ = try db.run(containers.table
                            .filter(containers.profile == current_name)
                            .update(containers.profile <- new_name))
            _ = try db.run(data_sources.table
                            .filter(data_sources.profile == current_name)
                            .update(data_sources.profile <- new_name))
        } catch {}
    }
    
    // Get list of profiles
    // FIX ME
    func getProfiles() /*-> [String]*/ {
        
    }
    
    // Add data source
    // FIX ME
    func addDataSource() {
        
    }
    
    // Remove data source
    // FIX ME
    func removeDataSource() {
        
    }
    
    // Get list of data sources, given a profile name
    // FIX ME
    func getDataSources() /*-> [String]*/ {
        
    }
    
}
