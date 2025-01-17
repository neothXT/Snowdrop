//
//  SnowdropMacrosPlugin.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros
 
@main
struct SnowdropMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        GetMacro.self,
        PostMacro.self,
        PutMacro.self,
        DeleteMacro.self,
        PatchMacro.self,
        ConnectMacro.self,
        HeadMacro.self,
        OptionsMacro.self,
        QueryMacro.self,
        TraceMacro.self,
        ServiceMacro.self,
        HeadersMacro.self,
        BodyMacro.self,
        FileUploadMacro.self,
        QueryParamsMacro.self,
        MockableMacro.self
    ]
}
