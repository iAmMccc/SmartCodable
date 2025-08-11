//
//  SmartPublished.swift
//  SmartCodable
//
//  Created by qixin on 2024/9/26.
//

import Foundation
import SwiftUI
import Combine


/**
 A property wrapper that combines Combine's publishing functionality with Codable serialization.
 
 Key Features:
 - Simplifies property declaration with property wrapper syntax
 - Supports reactive programming through Combine publishers
 - Maintains Codable compatibility for serialization
 */
@propertyWrapper
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
public struct SmartPublished<Value: Codable>: PropertyWrapperable {
    
    
    public var wrappedValue: Value {
        // Notify subscribers before value changes
        willSet {
            publisher.subject.send(newValue)
        }
    }
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
        publisher = Publisher(wrappedValue)
    }
    
    public static func createInstance(with value: Any) -> SmartPublished? {
        if let value = value as? Value {
            return SmartPublished(wrappedValue: value)
        }
        return nil
    }
    
    public func wrappedValueDidFinishMapping() -> SmartPublished<Value>? {
        if var temp = wrappedValue as? SmartDecodable {
            temp.didFinishMapping()
            return SmartPublished(wrappedValue: temp as! Value)
        }
        return nil
    }
    
    
    /// The publisher that exposes the wrapped value's changes
    public var projectedValue: Publisher {
        publisher
    }
    
    private var publisher: Publisher
    
    // MARK: - Publisher Implementation
    
    /**
     The publisher that broadcasts changes to the wrapped value.
     
     Uses CurrentValueSubject which:
     - Maintains the current value
     - Sends current value to new subscribers
     - More suitable than PassthroughSubject for property wrapper scenarios
     */
    public struct Publisher: Combine.Publisher {
        public typealias Output = Value
        public typealias Failure = Never
        
        // CurrentValueSubject 是 Combine 中的一种 Subject，它会保存当前值并向新订阅者发送当前值。相比于 PassthroughSubject，它在初始化时就要求有一个初始值，因此更适合这种包装属性的场景。
        var subject: CurrentValueSubject<Value, Never>
        
        // 这个方法实现了 Publisher 协议，将 subscriber 传递给 subject，从而将订阅者连接到这个发布者上。
        public func receive<S>(subscriber: S) where S: Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
            subject.subscribe(subscriber)
        }
        
        // Publisher 的构造函数接受一个初始值，并将其传递给 CurrentValueSubject 的初始化方法。
        init(_ output: Output) {
            subject = .init(output)
        }
    }
    

    /**
     Custom subscript for property wrapper integration with ObservableObject.
     
     - Parameters:
       - observed: The ObservableObject instance containing this property
       - wrappedKeyPath: Reference to the wrapped value
       - storageKeyPath: Reference to this property wrapper instance
     */
    public static subscript<OuterSelf: ObservableObject>(
        _enclosingInstance observed: OuterSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<OuterSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<OuterSelf, Self>
    ) -> Value {
        get {
            observed[keyPath: storageKeyPath].wrappedValue
        }
        set {
            // Notify observers before changing value
            if let subject = observed.objectWillChange as? ObservableObjectPublisher {
                subject.send()
                observed[keyPath: storageKeyPath].wrappedValue = newValue
            }
        }
    }
}

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
extension SmartPublished: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(Value.self)
        self.wrappedValue = value
        publisher = Publisher(wrappedValue)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.wrappedValue)
    }
}




