import CoreFoundation
import Foundation

/// Compares JSON values while ignoring object-key order and preserving array order,
/// element counts, JSON types, and missing-versus-present structure.
enum DemoJSONOracle {
    static func matchesJSON(_ actual: String, _ expected: String) -> Bool {
        guard
            let actualData = actual.data(using: .utf8),
            let expectedData = expected.data(using: .utf8),
            let actualValue = try? JSONSerialization.jsonObject(with: actualData, options: [.fragmentsAllowed]),
            let expectedValue = try? JSONSerialization.jsonObject(with: expectedData, options: [.fragmentsAllowed])
        else {
            return false
        }

        return equalJSONValues(actualValue, expectedValue)
    }

    private static func equalJSONValues(_ lhs: Any, _ rhs: Any) -> Bool {
        if lhs is NSNull || rhs is NSNull {
            return lhs is NSNull && rhs is NSNull
        }

        if let left = lhs as? [String: Any], let right = rhs as? [String: Any] {
            guard Set(left.keys) == Set(right.keys) else { return false }
            return left.allSatisfy { key, value in
                guard let otherValue = right[key] else { return false }
                return equalJSONValues(value, otherValue)
            }
        }

        if let left = lhs as? [Any], let right = rhs as? [Any] {
            guard left.count == right.count else { return false }
            return zip(left, right).allSatisfy { equalJSONValues($0.0, $0.1) }
        }

        if let left = lhs as? String, let right = rhs as? String {
            return left == right
        }

        if let left = lhs as? NSNumber, let right = rhs as? NSNumber {
            let leftIsBoolean = CFGetTypeID(left) == CFBooleanGetTypeID()
            let rightIsBoolean = CFGetTypeID(right) == CFBooleanGetTypeID()
            guard leftIsBoolean == rightIsBoolean else { return false }
            return left == right
        }

        return false
    }
}
