// Copyright (c) 2025 Daniel Farrelly
// Licensed under BSD 2-Clause "Simplified" License
//
// See the LICENSE file for license information

import Foundation
import Testing
@testable import SwiftAnyCodable

@Suite struct SendableTests {

	@Test("AnyCodableKey is Sendable")
	func anyCodableKeyIsSendable() async {
		let key: AnyCodableKey = "test"
		
		await Task {
			let _ = key
		}.value
		
		// If this compiles, AnyCodableKey conforms to Sendable
	}
	
	@Test("AnyCodableValue is Sendable")
	func anyCodableValueIsSendable() async {
		let value: AnyCodableValue = .string("test")
		
		await Task {
			let _ = value
		}.value
		
		// If this compiles, AnyCodableValue conforms to Sendable
	}
	
	@Test("InstancesOf is Sendable when Element is Sendable")
	func instancesOfIsSendable() async {
		struct TestItem: Codable, Sendable {
			let id: Int
		}
		
		let instances = InstancesOf([TestItem(id: 1)])
		
		await Task {
			let _ = instances
		}.value
		
		// If this compiles, InstancesOf<Sendable> conforms to Sendable
	}
	
	@Test("Complex nested structures with Sendable")
	func complexNestedStructuresAreSendable() async {
		let dictionary: [AnyCodableKey: AnyCodableValue] = [
			"key1": .string("value1"),
			"key2": .integer(42),
			"nested": .dictionary([
				"inner": .bool(true)
			])
		]
		
		await Task {
			let _ = dictionary
		}.value
		
		// If this compiles, nested structures are Sendable
	}

}

