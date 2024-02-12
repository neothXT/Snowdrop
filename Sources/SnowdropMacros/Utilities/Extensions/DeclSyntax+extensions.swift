//
//  DeclSyntax+extensions.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import Foundation
import SwiftSyntax

struct URLParam {
    let key: String
    let value: String
}

protocol ArgumentListBearable {
    var methodType: MethodType? { get }
    func getNodes() -> [AttributeSyntax]
    func getPassedArguments() -> AttributeSyntax.PassedArgumentList?
}

extension ArgumentListBearable {
    var methodType: MethodType? {
        let methodTypes: [MethodType] = getNodes().compactMap { MethodType(rawValue: $0.attributeName.description.lowercased()) }
        guard methodTypes.count == 1 else { return nil }
        return methodTypes.first
    }
    
    func getPassedArguments() -> AttributeSyntax.PassedArgumentList? {
        let argumentLists = getNodes().map { $0.passedArguments }
        guard var finalList = argumentLists.first else { return nil }
        
        argumentLists.dropFirst().forEach {
            finalList = finalList.merged(with: $0)
        }
        
        return finalList
    }
}

extension FunctionDeclSyntax: ArgumentListBearable {
    func getNodes() -> [AttributeSyntax] {
        attributes.compactMap { $0.as(AttributeSyntax.self) }
    }
}

extension ProtocolDeclSyntax: ArgumentListBearable {
    func getNodes() -> [AttributeSyntax] {
        attributes.compactMap { $0.as(AttributeSyntax.self) }
    }
}
