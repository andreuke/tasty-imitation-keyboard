//
//  ExNumKeyboard.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/10/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

func exNumKeyboard() -> Keyboard {
    let exNumKeyboard = Keyboard()
    
    let shift = Key(.shift)
    let backspace = Key(.backspace)
    let offset = 0
    
    /*
    for key in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"] {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(key)
        exNumKeyboard.addKey(keyModel, row: 0, page: 0)
    }
    for key in ["-", "+", "="] {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(key)
        exNumKeyboard.addKey(keyModel, row: 0, page: 0)
    }*/

    for key in ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "{", "}"] {
        let keyModel = Key(.character)
        keyModel.setLetter(key)
        exNumKeyboard.addKey(keyModel, row: 0 + offset, page: 0)
    }

    let tabKey = Key(.tab)
    tabKey.uppercaseKeyCap = "tab"
    tabKey.uppercaseOutput = "\t"
    tabKey.lowercaseOutput = "\t"
    exNumKeyboard.addKey(tabKey, row: 1 + offset, page: 0)
    for key in ["A", "S", "D", "F", "G", "H", "J", "K", "L", ":", "\"", "!"] {
        let keyModel = Key(.character)
        keyModel.setLetter(key)
        exNumKeyboard.addKey(keyModel, row: 1 + offset, page: 0)
    }
    //exNumKeyboard.addKey(newBackspace, row: 1 + offset, page: 0)
    //let keyModel = Key(.shift)
    exNumKeyboard.addKey(shift, row: 2 + offset, page: 0)
    
    for key in ["Z", "X", "C", "V", "B", "N", "M", ",", ".", "?"] {
        let keyModel = Key(.character)
        keyModel.setLetter(key)
        exNumKeyboard.addKey(keyModel, row: 2 + offset, page: 0)
    }
    
    //let backspace = Key(.backspace)
    exNumKeyboard.addKey(backspace, row: 2 + offset, page: 0)
    let keyModeChangeNumbers = Key(.modeChange)
    keyModeChangeNumbers.uppercaseKeyCap = "123"
    keyModeChangeNumbers.toMode = 1
    exNumKeyboard.addKey(keyModeChangeNumbers, row: 3 + offset, page: 0)
    
    
    
    let keyboardChange = Key(.keyboardChange)
    exNumKeyboard.addKey(keyboardChange, row: 3 + offset, page: 0)
    
    let settings = Key(.settings)
    exNumKeyboard.addKey(settings, row: 3 + offset, page: 0)
    
    let space = Key(.space)
    space.uppercaseKeyCap = "space"
    space.uppercaseOutput = " "
    space.lowercaseOutput = " "
    exNumKeyboard.addKey(space, row: 3 + offset, page: 0)
    
    let returnKey = Key(.return)
    returnKey.uppercaseKeyCap = "return"
    returnKey.uppercaseOutput = "\n"
    returnKey.lowercaseOutput = "\n"
    exNumKeyboard.addKey(returnKey, row: 3 + offset, page: 0)
    
    
    for key in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"] {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(key)
        exNumKeyboard.addKey(keyModel, row: 0, page: 1)
    }
    
    for key in ["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""] {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(key)
        exNumKeyboard.addKey(keyModel, row: 1, page: 1)
    }
    
    let keyModeChangeSpecialCharacters = Key(.modeChange)
    keyModeChangeSpecialCharacters.uppercaseKeyCap = "#+="
    keyModeChangeSpecialCharacters.toMode = 2
    exNumKeyboard.addKey(keyModeChangeSpecialCharacters, row: 2, page: 1)
    
    for key in [".", ",", "?", "!", "'", "\""] {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(key)
        exNumKeyboard.addKey(keyModel, row: 2, page: 1)
    }
    
    exNumKeyboard.addKey(Key(backspace), row: 2, page: 1)
    
    let keyModeChangeLetters = Key(.modeChange)
    keyModeChangeLetters.uppercaseKeyCap = "ABC"
    keyModeChangeLetters.toMode = 0
    exNumKeyboard.addKey(keyModeChangeLetters, row: 3, page: 1)
    
    exNumKeyboard.addKey(Key(keyboardChange), row: 3, page: 1)
    
    exNumKeyboard.addKey(Key(settings), row: 3, page: 1)
    
    exNumKeyboard.addKey(Key(space), row: 3, page: 1)
    
    exNumKeyboard.addKey(Key(returnKey), row: 3, page: 1)
    
    for key in ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="] {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(key)
        exNumKeyboard.addKey(keyModel, row: 0, page: 2)
    }
    
    for key in ["_", "\\", "|", "~", "<", ">", "€", "£", "¥", "•"] {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(key)
        exNumKeyboard.addKey(keyModel, row: 1, page: 2)
    }
    
    exNumKeyboard.addKey(Key(keyModeChangeNumbers), row: 2, page: 2)
    
    for key in [".", ",", "?", "!", "'", "\""] {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(key)
        exNumKeyboard.addKey(keyModel, row: 2, page: 2)
    }
    
    exNumKeyboard.addKey(Key(backspace), row: 2, page: 2)
    
    exNumKeyboard.addKey(Key(keyModeChangeLetters), row: 3, page: 2)
    
    exNumKeyboard.addKey(Key(keyboardChange), row: 3, page: 2)
    
    exNumKeyboard.addKey(Key(settings), row: 3, page: 2)
    
    exNumKeyboard.addKey(Key(space), row: 3, page: 2)
    
    exNumKeyboard.addKey(Key(returnKey), row: 3, page: 2)
    
    return exNumKeyboard
}
