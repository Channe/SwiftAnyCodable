
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
	
	/// 支持字面量初始化：let dict: AnyCodableDictionary = [:]
	public init(dictionaryLiteral elements: (String, AnyCodableValue)...) {
		self.storage = Dictionary(uniqueKeysWithValues: elements)
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
}

// MARK: - ExpressibleByDictionaryLiteral

extension AnyCodableDictionary: ExpressibleByDictionaryLiteral {
	public typealias Key = String
	public typealias Value = AnyCodableValue
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

