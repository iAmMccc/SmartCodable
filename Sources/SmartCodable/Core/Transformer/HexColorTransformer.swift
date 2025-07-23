//
//  HexColorTransformer.swift
//  SmartCodable
//
//  Created by qixin on 2025/7/23.
//

import Foundation
import Foundation


public struct SmartHexColorTransformer: ValueTransformable {
    
    public typealias Object = UIColor
    public typealias JSON = String
    
    let colorFormat : SmartHexColor.HexFormat
    public init(colorFormat: SmartHexColor.HexFormat) {
        self.colorFormat = colorFormat
    }
    public func transformFromJSON(_ value: Any) -> UIColor? {
        return UIColor.red
//        if let colorStr = value as? String {
//            return SmartHexColor.toColor(from: colorStr, format: colorFormat)
//        }
//        return nil
    }
    
    public func transformToJSON(_ value: UIColor) -> String? {
        SmartHexColor.toHexString(from: value, format: colorFormat)
    }
}
