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
        case url, body, tokenlabel, headers, requiresaccesstoken, fileupload, queryparams, unknown
    }
    
    struct PassedArgumentList {
        var url: String?
        var body: String?
        var headers: String?
        var urlParams: [URLParam] = []
        var queryParams: String?
        var isUploadingFile: Bool = false
        
        func merged(with argumentsList: PassedArgumentList) -> PassedArgumentList {
            .init(
                url: self.url ?? argumentsList.url,
                body: self.body ?? argumentsList.body,
                headers: self.headers ?? argumentsList.headers,
                urlParams: self.urlParams + argumentsList.urlParams,
                queryParams: self.queryParams ?? argumentsList.queryParams,
                isUploadingFile: self.isUploadingFile || argumentsList.isUploadingFile
            )
        }
    }
}

extension AttributeSyntax {
    var passedArguments: PassedArgumentList {
        var argumentsList = PassedArgumentList()
        argumentsList.isUploadingFile = attributeName.description.lowercased() == ArgumentType.fileupload.rawValue
        arguments?.as(LabeledExprListSyntax.self)?.forEach { argument in
            let key = ArgumentType(rawValue: (argument.name ?? attributeName.description).lowercased()) ?? .unknown
            
            switch key {
            case .url:
                argumentsList.url = argument.asString()
                argumentsList.urlParams = PathVariableFinder(url: argument.asString()).findParams()
            case .body:
                argumentsList.body = argument.asString()
            case .headers:
                argumentsList.headers = argument.asString()
            case .queryparams:
                argumentsList.queryParams = argument.asString()
            default:
                return
            }
        }
        
        return argumentsList
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
    
    private var array: ArrayExprSyntax? {
        expression.as(ArrayExprSyntax.self)
    }
    
    func asString() -> String? {
        stringLiteral?.segments.description ?? array?.description ?? dictionary?.description
    }
}
