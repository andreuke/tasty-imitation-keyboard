//
//  ExpandedKeyboard.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/10/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

func expandedKeyboard() -> Keyboard {
    let expandedKeyboard = Keyboard()
    
    let shift = Key(.shift)
    let backspace = Key(.backspace)
    let offset = 0
    
    /*
    for key in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"] {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(key)
        expandedKeyboard.addKey(keyModel, row: 0, page: 0)
    }
    for key in ["-", "+", "="] {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(key)
        expandedKeyboard.addKey(keyModel, row: 0, page: 0)
    }*/

    for key in ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "{", "}"] {
        let keyModel = Key(.character)
        keyModel.setLetter(key)
        expandedKeyboard.addKey(keyModel, row: 0 + offset, page: 0)
    }

    let tabKey = Key(.tab)
    tabKey.uppercaseKeyCap = "tab"
    tabKey.uppercaseOutput = "\t"
    tabKey.lowercaseOutput = "\t"
    expandedKeyboard.addKey(tabKey, row: 1 + offset, page: 0)
    tabKey.size = 1.5
    for key in ["A", "S", "D", "F", "G", "H", "J", "K", "L", ":", "\"", "!"] {
        let keyModel = Key(.character)
        keyModel.setLetter(key)
        expandedKeyboard.addKey(keyModel, row: 1 + offset, page: 0)
    }
    //expandedKeyboard.addKey(newBackspace, row: 1 + offset, page: 0)
    //let keyModel = Key(.shift)
    expandedKeyboard.addKey(shift, row: 2 + offset, page: 0)
    
    for key in ["Z", "X", "C", "V", "B", "N", "M", ",", ".", "?"] {
        let keyModel = Key(.character)
        keyModel.setLetter(key)
        expandedKeyboard.addKey(keyModel, row: 2 + offset, page: 0)
    }
    
    //let backspace = Key(.backspace)
    expandedKeyboard.addKey(backspace, row: 2 + offset, page: 0)
    let keyModeChangeNumbers = Key(.modeChange)
    keyModeChangeNumbers.uppercaseKeyCap = "123"
    keyModeChangeNumbers.toMode = 1
    expandedKeyboard.addKey(keyModeChangeNumbers, row: 3 + offset, page: 0)
    
    
    
    let keyboardChange = Key(.keyboardChange)
    expandedKeyboard.addKey(keyboardChange, row: 3 + offset, page: 0)
    
    let settings = Key(.settings)
    expandedKeyboard.addKey(settings, row: 3 + offset, page: 0)
    
    let space = Key(.space)
    space.uppercaseKeyCap = "space"
    space.uppercaseOutput = " "
    space.lowercaseOutput = " "
    expandedKeyboard.addKey(space, row: 3 + offset, page: 0)
    
    let returnKey = Key(.return)
    returnKey.uppercaseKeyCap = "return"
    returnKey.uppercaseOutput = "\n"
    returnKey.lowercaseOutput = "\n"
    expandedKeyboard.addKey(returnKey, row: 3 + offset, page: 0)
    expandedKeyboard.pages[0].setRelativeSizes(percentArray: [0.1, 0.1, 0.1, 0.5, 0.2], rowNum: 3 + offset)
    
    for key in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"] {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(key)
        expandedKeyboard.addKey(keyModel, row: 0, page: 1)
    }
    
    for key in ["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""] {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(key)
        expandedKeyboard.addKey(keyModel, row: 1, page: 1)
    }
    
    let keyModeChangeSpecialCharacters = Key(.modeChange)
    keyModeChangeSpecialCharacters.uppercaseKeyCap = "#+="
    keyModeChangeSpecialCharacters.toMode = 2
    expandedKeyboard.addKey(keyModeChangeSpecialCharacters, row: 2, page: 1)
    
    for key in [".", ",", "?", "!", "'", "\""] {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(key)
        expandedKeyboard.addKey(keyModel, row: 2, page: 1)
    }
    
    expandedKeyboard.addKey(Key(backspace), row: 2, page: 1)
    
    let keyModeChangeLetters = Key(.modeChange)
    keyModeChangeLetters.uppercaseKeyCap = "ABC"
    keyModeChangeLetters.toMode = 0
    expandedKeyboard.addKey(keyModeChangeLetters, row: 3, page: 1)
    
    expandedKeyboard.addKey(Key(keyboardChange), row: 3, page: 1)
    
    expandedKeyboard.addKey(Key(settings), row: 3, page: 1)
    
    expandedKeyboard.addKey(Key(space), row: 3, page: 1)
    
    expandedKeyboard.addKey(Key(returnKey), row: 3, page: 1)
    expandedKeyboard.pages[1].setRelativeSizes(percentArray: [0.1, 0.1, 0.1, 0.5, 0.2], rowNum: 3 + offset)
    
    for key in ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="] {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(key)
        expandedKeyboard.addKey(keyModel, row: 0, page: 2)
    }
    
    for key in ["_", "\\", "|", "~", "<", ">", "€", "£", "¥", "•"] {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(key)
        expandedKeyboard.addKey(keyModel, row: 1, page: 2)
    }
    
    expandedKeyboard.addKey(Key(keyModeChangeNumbers), row: 2, page: 2)
    
    for key in [".", ",", "?", "!", "'", "\""] {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(key)
        expandedKeyboard.addKey(keyModel, row: 2, page: 2)
    }
    
    expandedKeyboard.addKey(Key(backspace), row: 2, page: 2)
    
    expandedKeyboard.addKey(Key(keyModeChangeLetters), row: 3, page: 2)
    
    expandedKeyboard.addKey(Key(keyboardChange), row: 3, page: 2)
    
    expandedKeyboard.addKey(Key(settings), row: 3, page: 2)
    
    expandedKeyboard.addKey(Key(space), row: 3, page: 2)
    
    expandedKeyboard.addKey(Key(returnKey), row: 3, page: 2)
    expandedKeyboard.pages[2].setRelativeSizes(percentArray: [0.1, 0.1, 0.1, 0.5, 0.2], rowNum: 3 + offset)
    return expandedKeyboard
}
