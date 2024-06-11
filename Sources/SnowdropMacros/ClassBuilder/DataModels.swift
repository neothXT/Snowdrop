//
//  DataModels.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 26/04/2024.
//

import Foundation

struct FuncDetails {
    let funcName: String
    let enrichedParamsString: String
    let extendedEnrichedParamsString: String
    let executableEnrichedParamsString: String
    let effectSpecifiers: String
    let returnClause: String
}

struct FuncBodyDetails {
    let url: String
    let method: String
    let headers: String
    let body: EnrichedParameter?
    let returnType: String?
    let isUploadingFile: Bool
    let serviceName: String
    let doesThrow: Bool
}
