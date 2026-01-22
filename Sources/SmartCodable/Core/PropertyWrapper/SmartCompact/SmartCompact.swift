//
//  SmartCompact.swift
//  SmartCodable
//
//  Created by qixin on 2026/1/22.
//

import Foundation


/// SmartCompact 是一个命名空间，用于组织“宽容解析”的 Property Wrapper。
///
/// 目标：解决 JSON 中数组/字典字段可能包含异常值导致解析失败的问题。
///
/// 使用方式：
/// - @SmartCompact.Array：对数组进行宽容解析（遇到无法解析的元素则跳过）
/// - @SmartCompact.Dictionary：对字典进行宽容解析（遇到无法解析的键值对则跳过）
///
/// 例如：
///
/// struct Model: Decodable {
///     // 数组中可能包含非 Int 类型，解析时会自动忽略异常元素
///     @SmartCompact.Array
///     var ages: [Int]
///
///     // 字典中可能包含非目标类型或结构异常，解析时会自动忽略异常项
///     @SmartCompact.Dictionary
///     var info: [String: String]
/// }
///
/// 注意：
/// - SmartCompact 只是一个命名空间（namespace），本身不包含解析逻辑。
/// - 解析逻辑由 SmartCompact.Array / SmartCompact.Dictionary 实现。
/// - 本次设计支持更多的类型的“宽容解析”， 如有需要，提交 issue。
///
/// public enum SmartCompact { }
public enum SmartCompact { }
