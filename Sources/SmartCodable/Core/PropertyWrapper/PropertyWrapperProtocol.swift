//
//  PropertyWrapperProtocol.swift
//  SmartCodable
//
//  Created by qixin on 2025/4/9.
//

import Foundation

/**
 Protocol defining requirements for types that can publish wrapped Codable values.
 
 Provides a unified interface for any type conforming to this protocol.
 - WrappedValue: The generic type that must conform to Codable
 - createInstance: Attempts to create an instance from any value
 */
public protocol PropertyWrapperable {
    associatedtype WrappedValue
    
    var wrappedValue: WrappedValue { get }
    
    init(wrappedValue: WrappedValue)
    
    static func createInstance(with value: Any) -> Self?
    
    /**
     Callback invoked when the wrapped value finishes decoding/mapping.
     
     - Returns: An optional new instance of the wrapper with processed value
     - Note: Primarily used by property wrappers containing types conforming to SmartDecodable
     */
    func wrappedValueDidFinishMapping() -> Self?
}
