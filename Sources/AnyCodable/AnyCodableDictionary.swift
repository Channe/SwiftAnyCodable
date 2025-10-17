
// Copyright (c) 2025 Daniel Farrelly
// Licensed under BSD 2-Clause "Simplified" License
//
// See the LICENSE file for license information

import Foundation

// MARK: - String-keyed Dictionary Support for Cross-Module Literal Syntax

public typealias AnyCodableArray = [AnyCodableValue]

/// 自定义字典类型，支持自动类型转换
@dynamicMemberLookup
public struct AnyCodableDictionary: Codable, Sendable {
	private var storage: [String: AnyCodableValue] = [:]
	
	public init() {}
	
	public init(_ dictionary: [String: AnyCodableValue]) {
		self.storage = dictionary
	}
	
	/// 支持字面量初始化，自动转换常见类型
	public init(dictionaryLiteral elements: (String, Any)...) {
		self.storage = [:]
		for (key, value) in elements {
			self.storage[key] = Self.convertToAnyCodableValue(value)
		}
	}
	
	/// 将常见类型转换为 AnyCodableValue
	private static func convertToAnyCodableValue(_ value: Any) -> AnyCodableValue {
		switch value {
		case let v as AnyCodableValue:
			return v
		case let v as String:
			return .string(v)
		case let v as Int:
			return .integer(v)
		case let v as Double:
			return .double(v)
		case let v as Float:
			return .double(Double(v))
		case let v as Bool:
			return .bool(v)
		case let v as [AnyCodableValue]:
			return .array(v)
		case let v as AnyCodableDictionary:
			// 转换为 [AnyCodableKey: AnyCodableValue]
			let dict = v.storage.reduce(into: [AnyCodableKey: AnyCodableValue]()) { result, pair in
				result[.string(pair.key)] = pair.value
			}
			return .dictionary(dict)
		default:
			// 不支持的类型，使用字符串表示
			return .string(String(describing: value))
		}
	}
	
	/// 下标：直接访问 AnyCodableValue（用于读取）
	public subscript(key: String) -> AnyCodableValue? {
		get { storage[key] }
		set { storage[key] = newValue }
	}
	
	/// 下标重载：String 类型自动转换
	public subscript(key: String) -> String? {
		get { storage[key]?.stringValue }
		set { storage[key] = newValue.map { .string($0) } }
	}
	
	/// 下标重载：Int 类型自动转换
	public subscript(key: String) -> Int? {
		get { storage[key]?.integerValue }
		set { storage[key] = newValue.map { .integer($0) } }
	}
	
	/// 下标重载：Double 类型自动转换
	public subscript(key: String) -> Double? {
		get { storage[key]?.doubleValue }
		set { storage[key] = newValue.map { .double($0) } }
	}
	
	/// 下标重载：Bool 类型自动转换
	public subscript(key: String) -> Bool? {
		get { storage[key]?.boolValue }
		set { storage[key] = newValue.map { .bool($0) } }
	}
	
	/// @dynamicMemberLookup 必需的 subscript
	public subscript(dynamicMember member: String) -> AnyCodableValue? {
		get { storage[member] }
		set { storage[member] = newValue }
	}
	
	// MARK: - Codable
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		storage = try container.decode([String: AnyCodableValue].self)
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(storage)
	}
	
	// MARK: - Convenience
	
	public var isEmpty: Bool { storage.isEmpty }
	public var count: Int { storage.count }
	public var keys: Dictionary<String, AnyCodableValue>.Keys { storage.keys }
	public var values: Dictionary<String, AnyCodableValue>.Values { storage.values }
	
	public mutating func removeValue(forKey key: String) -> AnyCodableValue? {
		storage.removeValue(forKey: key)
	}
	
	public mutating func removeAll() {
		storage.removeAll()
	}
	
	/// 支持 forEach 迭代
	public func forEach(_ body: ((key: String, value: AnyCodableValue)) throws -> Void) rethrows {
		try storage.forEach(body)
	}
	
	/// 合并字典，返回新字典（类似标准 Dictionary.merging）
	public func merging(
		_ other: AnyCodableDictionary,
		uniquingKeysWith combine: (AnyCodableValue, AnyCodableValue) throws -> AnyCodableValue
	) rethrows -> AnyCodableDictionary {
		var result = self
		for (key, value) in other.storage {
			if let existing = result.storage[key] {
				result.storage[key] = try combine(existing, value)
			} else {
				result.storage[key] = value
			}
		}
		return result
	}
	
	/// 原地合并字典（类似标准 Dictionary.merge）
	public mutating func merge(
		_ other: AnyCodableDictionary,
		uniquingKeysWith combine: (AnyCodableValue, AnyCodableValue) throws -> AnyCodableValue
	) rethrows {
		for (key, value) in other.storage {
			if let existing = storage[key] {
				storage[key] = try combine(existing, value)
			} else {
				storage[key] = value
			}
		}
	}
}

// MARK: - ExpressibleByDictionaryLiteral

extension AnyCodableDictionary: ExpressibleByDictionaryLiteral {
	public typealias Key = String
	public typealias Value = Any
}

// MARK: - Sequence

extension AnyCodableDictionary: Sequence {
	public typealias Element = (key: String, value: AnyCodableValue)
	
	public func makeIterator() -> Dictionary<String, AnyCodableValue>.Iterator {
		storage.makeIterator()
	}
}

// MARK: - CustomStringConvertible

extension AnyCodableDictionary: CustomStringConvertible {
	public var description: String {
		storage.description
	}
}

