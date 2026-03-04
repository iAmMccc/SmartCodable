//
//  SmartSubclassMacro.swift
//  Mccc
//
//  Created by qixin on 2025/4/24.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros


/// A macro that automatically implements SmartCodable inheritance support
public struct SmartSubclassMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try expansionImpl(of: node, providingMembersOf: declaration, in: context)
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try expansionImpl(of: node, providingMembersOf: declaration, in: context)
    }

    private static func expansionImpl(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            throw MacroError("@SmartSubclassMacro can only be applied to class declarations")
        }

        guard let inheritedNames = classDecl.inheritanceClause?.inheritedTypes,
              !inheritedNames.isEmpty else {
            throw MacroError("@SmartSubclassMacro requires the class to inherit from a parent class")
        }

        // 获取类的属性
        let properties = try extractProperties(from: classDecl)
        
        var members: [DeclSyntax] = []
        
        // 生成CodingKeys枚举
        members.append(generateCodingKeysEnum(for: properties))

        // 生成init(from:)方法
        members.append(generateInitFromDecoder(for: properties))

        // 生成encode(to:)方法
        members.append(generateEncodeToEncoder(for: properties))
        

        if hasRequiredInitializer(classDecl) {
            return members
        } else {
            // 生成required init()方法
            members.append(generateRequiredInit())
            return members
        }
    }
      
    // 辅助方法：提取类的属性
    private static func extractProperties(from classDecl: ClassDeclSyntax) throws -> [ModelMemberProperty] {
        var properties: [ModelMemberProperty] = []
          
        for member in classDecl.memberBlock.members {
            // 只处理变量声明
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  varDecl.bindingSpecifier.text == "var" else {
                continue
            }

            // 跳过 lazy 属性：
            // lazy 属性具有惰性初始化语义，即在首次访问时才会执行初始化表达式。
            // 如果在解码过程中赋值 lazy 属性，会导致其原始初始化逻辑被绕过，违背 lazy 的设计初衷；
            // 而如果保留其 lazy 行为，解码赋值将会失效或被覆盖，从而丧失参与解码的意义。
            // 因此，出于语义一致性与编码正确性的考虑，lazy 属性将被排除在解码逻辑之外。
            let isLazy = varDecl.modifiers.contains { $0.name.text == "lazy" }
            if isLazy {
                continue
            }
              
            // 遍历所有绑定
            for binding in varDecl.bindings {
                // 确保有标识符和类型注解
                let identifier = try binding.getIdentifierPattern()
                let baseType = try binding.getVariableType()
                  
                let name = identifier.identifier.text

                // 检查是否是存储属性（有初始值或没有getter/setter）
                let isStored = binding.accessorBlock == nil ||
                               (binding.accessorBlock?.accessors.as(AccessorDeclListSyntax.self) == nil &&
                                binding.accessorBlock?.accessors.as(CodeBlockItemListSyntax.self) == nil)
                  
                // 只添加存储属性
                if isStored {
                    
                    // 判断是否使用了属性包装器
                    var effectiveType = baseType
                    var isWrapped = false
                    let attrs = varDecl.attributes
                    if !attrs.isEmpty {
                        for attr in attrs {
                            if let attrSyntax = attr.as(AttributeSyntax.self),
                               let wrapperName = attrSyntax.attributeName.as(IdentifierTypeSyntax.self)?.name.text {
                                
                                // 如果属性使用了 @objc 修饰，则跳过它作为“属性包装器”处理
                                if wrapperName == "objc" { continue }
                                
                                effectiveType = "\(wrapperName)<\(baseType)>"
                                isWrapped = true
                                break
                            }
                        }
                    }
                    
                    properties.append(ModelMemberProperty(name: name, type: effectiveType, isWrapped: isWrapped, isStored: true))
                }
            }
        }
          
        return properties
    }

    
    // 辅助方法：生成CodingKeys枚举
    private static func generateCodingKeysEnum(for properties: [ModelMemberProperty]) -> DeclSyntax {
        let caseDeclarations = properties.map { property in
            "case \(property.codingKeyName)"
        }.joined(separator: "\n")
          
        return """
        enum CodingKeys: CodingKey {
            \(raw: caseDeclarations)
        }
        """
    }
      
    // 辅助方法：生成init(from:)方法
    private static func generateInitFromDecoder(for properties: [ModelMemberProperty]) -> DeclSyntax {
        let decodingStatements = properties.map { property in
            let propertyName = property.accessName
            let propertyType = property.type
              
            // 处理可选类型
            if propertyType.hasSuffix("?") {
                let baseType = propertyType.dropLast()
                return "self.\(propertyName) = try container.decodeIfPresent(\(baseType).self, forKey: .\(property.codingKeyName)) ?? self.\(propertyName)"
            } else {
                return "self.\(propertyName) = try container.decodeIfPresent(\(propertyType).self, forKey: .\(property.codingKeyName)) ?? self.\(propertyName)"
            }
        }.joined(separator: "\n")
          
        return """
        required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
              
            let container = try decoder.container(keyedBy: CodingKeys.self)
            \(raw: decodingStatements)
        }
        """
    }
      
    // 辅助方法：生成encode(to:)方法
    private static func generateEncodeToEncoder(for properties: [ModelMemberProperty]) -> DeclSyntax {
        let encodingStatements = properties.map { property in
            if property.type.hasSuffix("?") {
                return "try container.encodeIfPresent(\(property.accessName), forKey: .\(property.codingKeyName))"
            } else {
                return "try container.encode(\(property.accessName), forKey: .\(property.codingKeyName))"
            }
        }.joined(separator: "\n")
          
        return """
        override func encode(to encoder: Encoder) throws {
            try super.encode(to: encoder)
              
            var container = encoder.container(keyedBy: CodingKeys.self)
            \(raw: encodingStatements)
        }
        """
    }
      
    
    // 检查是否已存在required init()
    private static func hasRequiredInitializer(_ classDecl: ClassDeclSyntax) -> Bool {
        for member in classDecl.memberBlock.members {
            if let initializer = member.decl.as(InitializerDeclSyntax.self),
               initializer.signature.parameterClause.parameters.isEmpty,
               initializer.modifiers.contains(where: { $0.name.text == "required" }) == true {
                return true
            }
        }
        return false
    }
    
    // 辅助方法：生成required init()方法
    private static func generateRequiredInit() -> DeclSyntax {
        return """
        required init() {
            super.init()
        }
        """
    }
}
