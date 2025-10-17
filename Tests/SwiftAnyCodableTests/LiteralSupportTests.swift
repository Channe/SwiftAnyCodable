// Copyright (c) 2025 Daniel Farrelly
// Licensed under BSD 2-Clause "Simplified" License
//
// See the LICENSE file for license information

import Foundation
import Testing
@testable import SwiftAnyCodable

@Suite struct LiteralSupportTests {

	@Test("String literal support")
	func stringLiteralSupport() {
		let value: AnyCodableValue = "hello"
		#expect(value.stringValue == "hello")
	}
	
	@Test("Integer literal support")
	func integerLiteralSupport() {
		let value: AnyCodableValue = 42
		#expect(value.integerValue == 42)
	}
	
	@Test("Float literal support")
	func floatLiteralSupport() {
		let value: AnyCodableValue = 3.14
		#expect(value.doubleValue == 3.14)
	}
	
	@Test("Boolean literal support")
	func booleanLiteralSupport() {
		let trueValue: AnyCodableValue = true
		let falseValue: AnyCodableValue = false
		#expect(trueValue.boolValue == true)
		#expect(falseValue.boolValue == false)
	}
	
	@Test("Array literal support")
	func arrayLiteralSupport() {
		let value: AnyCodableValue = [1, "two", 3.0, true]
		
		guard let array = value.arrayValue else {
			Issue.record("Expected array value")
			return
		}
		
		#expect(array.count == 4)
		#expect(array[0].integerValue == 1)
		#expect(array[1].stringValue == "two")
		#expect(array[2].doubleValue == 3.0)
		#expect(array[3].boolValue == true)
	}
	
	@Test("Dictionary literal support")
	func dictionaryLiteralSupport() {
		let value: AnyCodableValue = [
			"name": "John",
			"age": 30,
			"active": true
		]
		
		guard let dict = value.dictionaryValue else {
			Issue.record("Expected dictionary value")
			return
		}
		
		#expect(dict["name" as AnyCodableKey]?.stringValue == "John")
		#expect(dict["age" as AnyCodableKey]?.integerValue == 30)
		#expect(dict["active" as AnyCodableKey]?.boolValue == true)
	}
	
	@Test("Nested literal support")
	func nestedLiteralSupport() {
		let value: AnyCodableValue = [
			"user": [
				"name": "Alice",
				"age": 25,
				"hobbies": ["reading", "coding", "gaming"]
			],
			"active": true
		]
		
		guard let dict = value.dictionaryValue else {
			Issue.record("Expected dictionary value")
			return
		}
		
		guard let userDict = dict["user" as AnyCodableKey]?.dictionaryValue else {
			Issue.record("Expected user dictionary")
			return
		}
		
		#expect(userDict["name" as AnyCodableKey]?.stringValue == "Alice")
		#expect(userDict["age" as AnyCodableKey]?.integerValue == 25)
		
		guard let hobbies = userDict["hobbies" as AnyCodableKey]?.arrayValue else {
			Issue.record("Expected hobbies array")
			return
		}
		
		#expect(hobbies.count == 3)
		#expect(hobbies[0].stringValue == "reading")
		#expect(hobbies[1].stringValue == "coding")
		#expect(hobbies[2].stringValue == "gaming")
	}
	
	@Test("Mixed type array")
	func mixedTypeArray() {
		let value: AnyCodableValue = [
			"text",
			42,
			3.14,
			true,
			["nested": "value"]
		]
		
		guard let array = value.arrayValue else {
			Issue.record("Expected array value")
			return
		}
		
		#expect(array.count == 5)
		#expect(array[0].stringValue == "text")
		#expect(array[1].integerValue == 42)
		#expect(array[2].doubleValue == 3.14)
		#expect(array[3].boolValue == true)
		#expect(array[4].dictionaryValue != nil)
	}

}

