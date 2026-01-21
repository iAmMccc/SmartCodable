//
//  SmartKeyEncodingStrategy.swift
//  SmartCodable
//
//  Created by Mccc on 2024/9/26.
//

import Foundation

extension JSONEncoder {
    /// Data的解析策略
    /// 由于是JSONEncoder解析器只能解析JSON数据，所以Data类型只能用base64.
    public enum SmartDataEncodingStrategy: Sendable {
        case base64
    }
}


extension JSONEncoder {
    
    public enum SmartKeyEncodingStrategy : Sendable {
        
        /// Use the keys specified by each type. This is the default strategy.
        case useDefaultKeys

        /// Convert from "camelCaseKeys" to "snake_case_keys" before writing a key to JSON payload.
        ///
        /// Capital characters are determined by testing membership in Unicode General Categories Lu and Lt.
        /// The conversion to lower case uses `Locale.system`, also known as the ICU "root" locale. This means the result is consistent regardless of the current user's locale and language preferences.
        ///
        /// Converting from camel case to snake case:
        /// 1. Splits words at the boundary of lower-case to upper-case
        /// 2. Inserts `_` between words
        /// 3. Lowercases the entire string
        /// 4. Preserves starting and ending `_`.
        ///
        /// For example, `oneTwoThree` becomes `one_two_three`. `_oneTwoThree_` becomes `_one_two_three_`.
        ///
        /// - Note: Using a key encoding strategy has a nominal performance cost, as each string key has to be converted.
        case toSnakeCase
        
        /// Convert the first letter of the key to lower case before attempting to match a key with the one specified by each type.
        /// For example, `OneTwoThree` becomes `oneTwoThree`.
        ///
        /// - Note: This strategy should be used with caution, especially if the key's first letter is intended to be uppercase for distinguishing purposes. It also incurs a nominal performance cost, as the first character of each key needs to be inspected and possibly modified.
        case firstLetterLower
        
        /// Convert the first letter of the key to upper case before attempting to match a key with the one specified by each type.
        /// For example, `oneTwoThree` becomes `OneTwoThree`.
        ///
        /// - Note: This strategy should be used when the keys are expected to start with a lowercase letter and need to be converted to start with an uppercase letter. It incurs a nominal performance cost, as the first character of each key needs to be inspected and possibly modified.
        case firstLetterUpper
    }
}


extension JSONEncoder.SmartKeyEncodingStrategy {
    
    static func _convertFirstLetterToLowercase(_ stringKey: String) -> String {
        guard !stringKey.isEmpty else { return stringKey }

        return stringKey.prefix(1).lowercased() + stringKey.dropFirst()
    }
    
    static func _convertFirstLetterToUppercase(_ stringKey: String) -> String {
        guard !stringKey.isEmpty else { return stringKey }

        return stringKey.prefix(1).uppercased() + stringKey.dropFirst()
    }
    
    static func _convertToSnakeCase(_ stringKey: String) -> String {
        guard !stringKey.isEmpty else { return stringKey }

        var words: [Range<String.Index>] = []
        // The general idea of this algorithm is to split words on transition from lower to upper case, then on transition of >1 upper case characters to lowercase
        //
        // myProperty -> my_property
        // myURLProperty -> my_url_property
        //
        // We assume, per Swift naming conventions, that the first character of the key is lowercase.
        var wordStart = stringKey.startIndex
        var searchRange = stringKey.index(after: wordStart)..<stringKey.endIndex

        // Find next uppercase character
        while let upperCaseRange = stringKey.rangeOfCharacter(from: CharacterSet.uppercaseLetters, options: [], range: searchRange) {
            let untilUpperCase = wordStart..<upperCaseRange.lowerBound
            words.append(untilUpperCase)

            // Find next lowercase character
            searchRange = upperCaseRange.lowerBound..<searchRange.upperBound
            guard let lowerCaseRange = stringKey.rangeOfCharacter(from: CharacterSet.lowercaseLetters, options: [], range: searchRange) else {
                // There are no more lower case letters. Just end here.
                wordStart = searchRange.lowerBound
                break
            }

            // Is the next lowercase letter more than 1 after the uppercase? If so, we encountered a group of uppercase letters that we should treat as its own word
            let nextCharacterAfterCapital = stringKey.index(after: upperCaseRange.lowerBound)
            if lowerCaseRange.lowerBound == nextCharacterAfterCapital {
                // The next character after capital is a lower case character and therefore not a word boundary.
                // Continue searching for the next upper case for the boundary.
                wordStart = upperCaseRange.lowerBound
            } else {
                // There was a range of >1 capital letters. Turn those into a word, stopping at the capital before the lower case character.
                let beforeLowerIndex = stringKey.index(before: lowerCaseRange.lowerBound)
                words.append(upperCaseRange.lowerBound..<beforeLowerIndex)

                // Next word starts at the capital before the lowercase we just found
                wordStart = beforeLowerIndex
            }
            searchRange = lowerCaseRange.upperBound..<searchRange.upperBound
        }
        words.append(wordStart..<searchRange.upperBound)
        let result = words.map({ (range) in
            return stringKey[range].lowercased()
        }).joined(separator: "_")
        return result
    }
}
