//
//  NettyMacrosPlugin.swift
//
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros
 
@main
struct NettyMacrosPlugin: CompilerPlugin {
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
        RequiresAccessTokenMacro.self,
        TokenLabelMacro.self,
        HeadersMacro.self,
        BodyMacro.self,
        FileUploadMacro.self
    ]
}
