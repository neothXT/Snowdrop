//
//  AttributeSyntax+extensions.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import Foundation
import SwiftSyntax

extension AttributeSyntax {
    enum ArgumentType: String {
        case url, body, tokenlabel, headers, requiresaccesstoken, fileupload, unknown
    }
    
    struct PassedArgumentList {
        var url: String?
        var body: String?
        var tokenLabel: String?
        var headers: String?
        var requiresAccessToken: Bool = false
        var urlParams: [URLParam] = []
        var isUploadingFile: Bool = false
        
        func merged(with argumentsList: PassedArgumentList) -> PassedArgumentList {
            .init(
                url: self.url ?? argumentsList.url,
                body: self.body ?? argumentsList.body,
                tokenLabel: self.tokenLabel ?? argumentsList.tokenLabel,
                headers: self.headers ?? argumentsList.headers,
                requiresAccessToken: self.requiresAccessToken || argumentsList.requiresAccessToken,
                urlParams: self.urlParams + argumentsList.urlParams,
                isUploadingFile: self.isUploadingFile || argumentsList.isUploadingFile
            )
        }
    }
}

extension AttributeSyntax {
    var passedArguments: PassedArgumentList {
        var argumentsList = PassedArgumentList()
        argumentsList.requiresAccessToken = attributeName.description.lowercased() == ArgumentType.requiresaccesstoken.rawValue
        argumentsList.isUploadingFile = attributeName.description.lowercased() == ArgumentType.fileupload.rawValue
        arguments?.as(LabeledExprListSyntax.self)?.forEach { argument in
            let key = ArgumentType(rawValue: (argument.name ?? attributeName.description).lowercased()) ?? .unknown
            
            switch key {
            case .url:
                argumentsList.url = argument.asString()
                argumentsList.urlParams = urlParams(for: argument.asString())
            case .body:
                argumentsList.body = argument.asString()
            case .tokenlabel:
                argumentsList.tokenLabel = argument.asString()
            case .headers:
                argumentsList.headers = argument.asString()
            default:
                return
            }
        }
        
        return argumentsList
    }
    
    func urlParams(for url: String?) -> [URLParam] {
        guard let url else { return [] }
        
        guard let regex = try? NSRegularExpression(pattern: #"\{[a-zA-Z_]*=[\\a-zA-Z\-0-9\" ]*\}"#) else { return [] }
        let matches = regex.matches(in: url, range: NSRange(url.startIndex..., in: url))
        
        guard matches.count > 0 else { return [] }
        
        return matches.reduce([]) {
            let results = String(url[Range($1.range, in: url)!]).split(separator: "=").map { String($0) }
            guard results.count == 2 else { return $0 }
            
            let key = String(results[0].dropFirst())
            let value = String(results[1].dropLast())
            
            return $0 + [.init(key: key, value: value)]
        }
    }
}

extension LabeledExprSyntax {
    var name: String? {
        label?.text.lowercased()
    }
    
    private var stringLiteral: StringLiteralExprSyntax? {
        expression.as(StringLiteralExprSyntax.self)
    }
    
    private var dictionary: DictionaryExprSyntax? {
        expression.as(DictionaryExprSyntax.self)
    }
    
    func asString() -> String? {
        stringLiteral?.segments.description ?? dictionary?.description
    }
}
