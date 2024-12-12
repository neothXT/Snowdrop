//
//  PathVariableFinder.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 12/10/2024.
//

import Foundation

struct PathVariableFinder {
    private let shortNumericVarPattern = #"[ ]{0,1}=[ ]{0,1}[0-9a-zA-Z\\.]+"#
    private let shortStringPattern = #"[ ]{0,1}=[ ]{0,1}\"[a-zA-Z0-9\\.\\@]*\""#
    private let shortInstancePattern = #"[ ]{0,1}=[ ]{0,1}[a-zA-Z0-9\\.]+\([a-zA-Z0-9\\.\\@\" \\/\[\]\:\(\)\!]+\)[\!]{0,1}"#
    private let shortCollectionPattern = #"[ ]{0,1}=[ ]{0,1}\[[a-zA-Z0-9\\.\\@\" \\/\[\]\:\(\)\!]*\]"#
    private let shortTupleLikePattern = #"[ ]{0,1}=[ ]{0,1}\([a-zA-Z0-9\\.\\@\" \,\\/\[\]\:\(\)\!]*\)"#
    
    private let simpleRegex = try? NSRegularExpression(pattern: #"\{[a-z]+[a-zA-Z0-9]+\}"#)
    private let numericVarRegex = try? NSRegularExpression(pattern: #"\{[a-z]+[a-zA-Z0-9]+[ ]{0,1}=[ ]{0,1}[0-9a-zA-Z\\.]*\}"#)
    private let stringRegex = try? NSRegularExpression(pattern: #"\{[a-z]+[a-zA-Z0-9]+[ ]{0,1}=[ ]{0,1}\"[a-zA-Z0-9\\.\\@]*\"\}"#)
    private let instanceRegex = try? NSRegularExpression(pattern: #"\{[a-z]+[a-zA-Z0-9]+[ ]{0,1}=[ ]{0,1}[a-zA-Z0-9\\.]+\([a-zA-Z0-9\\.\\@\" \\/\[\]\:\(\)\!]+\)[\!]{0,1}\}"#)
    private let collectionRegex = try? NSRegularExpression(pattern: #"\{[a-z]+[a-zA-Z0-9]+[ ]{0,1}=[ ]{0,1}\[[a-zA-Z0-9\\.\\@\" \\/\[\]\:\(\)\!]*\]\}"#)
    private let tupleLikeRegex = try? NSRegularExpression(pattern: #"\{[a-z]+[a-zA-Z0-9]+[ ]{0,1}=[ ]{0,1}\([a-zA-Z0-9\\.\\@\" \,\\/\[\]\:\(\)\!]*\)\}"#)
    
    let url: String?
    
    func findParams() -> [URLParam] {
        guard let url else { return [] }
        var matches = [NSTextCheckingResult]()
        
        for regex in [numericVarRegex, stringRegex, instanceRegex, collectionRegex, tupleLikeRegex] {
            matches += regex?.matches(in: url, range: NSRange(url.startIndex..., in: url)) ?? []
        }
        
        guard matches.count > 0 else { return [] }
        
        return matches.reduce([]) {
            let results = String(url[Range($1.range, in: url)!]).split(separator: "=").map { String($0) }
            guard results.count == 2 else { return $0 }
            
            let key = String(results[0].dropFirst())
            let value = String(results[1].dropLast())
            
            return $0 + [.init(key: key, value: value)]
        }
    }
    
    func escape() throws -> String {
        guard let url else { return "" }
        var outcome = url
        
        let regexes: [(String?, NSRegularExpression?)] = [
            (shortNumericVarPattern, numericVarRegex),
            (shortStringPattern, stringRegex),
            (shortInstancePattern, instanceRegex),
            (shortCollectionPattern, collectionRegex),
            (shortTupleLikePattern, tupleLikeRegex),
            (nil, simpleRegex)
        ]
        
        regexes.forEach { shortRegex, regex in
            guard let regex else { return }
            let matchesCount = regex.matches(in: url, range: .init(location: 0, length: url.count)).count
            (0 ..< matchesCount).forEach { _ in
                guard let match = regex.firstMatch(in: outcome, range: .init(location: 0, length: outcome.count)),
                      let matchRange = Range(match.range) else {
                    return
                }
                
                let startIndex = outcome.index(outcome.startIndex, offsetBy: matchRange.lowerBound)
                let endIndex = outcome.index(outcome.startIndex, offsetBy: matchRange.upperBound)
                let range = startIndex ..< endIndex
                outcome = outcome
                    .replacingOccurrences(of: "}", with: ")", range: range)
                    .replacingOccurrences(of: "{", with: "\\(", range: range)
                
                if let shortRegex {
                    outcome = outcome
                        .replacingOccurrences(of: shortRegex, with: "", options: .regularExpression, range: range)
                }
            }
        }
        
        return outcome
    }
    
    func strippedFromVariables() throws -> String {
        guard let url else { return "" }
        var outcome = url
        
        let regexes = [
            numericVarRegex,
            stringRegex,
            instanceRegex,
            collectionRegex,
            tupleLikeRegex,
            simpleRegex,
        ]
        
        regexes.forEach { regex in
            guard let regex else { return }
            let matchesCount = regex.matches(in: url, range: .init(location: 0, length: url.count)).count
            (0 ..< matchesCount).forEach { _ in
                guard let match = regex.firstMatch(in: outcome, range: .init(location: 0, length: outcome.count)),
                      let _ = Range(match.range) else {
                    return
                }
                
                guard let startIndex = outcome.firstIndex(of: "{"), let endIndex = outcome.firstIndex(of: "}") else { return }
                
                let endIndexWithOffset = endIndex == outcome.endIndex ? endIndex : outcome.index(endIndex, offsetBy: 1)
                let range = startIndex ..< endIndexWithOffset
                
                outcome = outcome.replacingCharacters(in: range, with: "")
            }
        }
        
        return outcome.replacingOccurrences(of: "//", with: "/")
    }
}
