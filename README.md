# SwiftAnyCodable

`SwiftAnyCodable` is a Swift package that provides tools to work with heterogeneous or loosely-structured data while maintaining strong type safety and leveraging Swift's powerful `Codable` protocol. It includes support for dynamic coding keys, decoding nested data, and handling any codable value seamlessly.

## Swift 6 & Sendable Support

✨ **SwiftAnyCodable is fully compatible with Swift 6's strict concurrency checking and provides complete `Sendable` support.**

All core types in this library conform to `Sendable`, making them safe to use across concurrency domains:

- **`AnyCodableKey`**: Fully `Sendable` - safe to pass across actor boundaries
- **`AnyCodableValue`**: Fully `Sendable` - including recursive array and dictionary cases
- **`InstancesOf<Element>`**: Conditionally `Sendable` when `Element` conforms to `Sendable`

This means you can safely use these types in:
- Async/await contexts
- Actor-isolated code
- Task and TaskGroup operations
- Any concurrent Swift code

The library compiles without warnings under `-strict-concurrency=complete`.

## Features

- **`AnyCodableKey`**: A flexible coding key type that supports both string and integer keys.
- **`AnyCodableValue`**: A versatile type that can decode and encode a wide variety of primitive and composite values, such as numbers, strings, arrays, and dictionaries.
- **`InstancesOf`**: A utility structure to extract collections of a specific type from complex data sources.
- **Decoding Extensions**: Extensions for `KeyedDecodingContainer` and `UnkeyedDecodingContainer` to simplify decoding collections of specific types, including nested structures.
- **Literal Support**: `AnyCodableValue` supports Swift literal syntax for strings, integers, floats, booleans, arrays, and dictionaries, making it easy to create values inline.

### Why would anyone want this?

I have found that, in practice, third-party APIs can be volatile. This particularly applies when you're using _private_ APIs, which change based on the whims of those using them.

Using the tools this library provides helps to avoid needing to provide rigid stuctures for the code you don't necessarily want to actually parse or use, and get right to the good stuff, while reducing the possibility that the API could break on you.

## Installation

In your `Package.swift` Swift Package Manager manifest, add the following dependency to your `dependencies` argument:

```swift
.package(url: "https://github.com/jellybeansoup/swift-any-codable.git", from: "1.0.0"),
```

Add the dependency to any targets you've declared in your manifest:

```swift
.target(
    name: "MyTarget",
    dependencies: [
        .product(name: "SwiftAnyCodable", package: "SwiftAnyCodable"),
    ]
),
```

## Usage

### Working with `AnyCodableValue`

`AnyCodableValue` can encode and decode a variety of primitive types seamlessly. This allows it to be used as a placeholder when you're not sure exactly what kind of data you're going to get.

```swift
import SwiftAnyCodable

enum DecodingKeys: String, Hashable {
    case key, nested
}

let jsonData = Data(#"{ "key": 123, "nested": [1, 2, 3] }"#.utf8)
let decoded = try JSONDecoder().decode([DecodingKeys: AnyCodableValue].self, from: jsonData)

if let intValue = decoded[.key]?.integerValue {
    print("Decoded integer value: \(intValue)")
}

if let array = decoded[.nested]?.arrayValue {
    print("Decoded array: \(array)")
}
```

### Flexible Coding Keys with `AnyCodableKey`

The combination of `AnyCodableValue` with `AnyCodableKey` provides a flexible solution when working with dynamic or unknown structures, while supporting both string– and integer-based keys. You can decode unfamiliar data in a way that remains accessible via code, while ensuring that it can also be encoded again easily.

```swift
import SwiftAnyCodable

struct Post: Codable {
    var title: String
    var author: String
    var unsupportedValues: [String: AnyCodableValue]

    enum CodingKeys: String, CodingKey, CaseIterable {
        case title
        case author
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        self.author = try container.decode(String.self, forKey: .author)

        let unsupportedContainer = try decoder.container(keyedBy: AnyCodableKey.self)
        var unsupportedValues: [String: AnyCodableValue] = [:]
        for key in unsupportedContainer.allKeys where CodingKeys.allCases.map(AnyCodableKey.init).contains(key) == false {
            unsupportedValues[key.stringValue] = try unsupportedContainer.decode(AnyCodableValue.self, forKey: key)
        }
        self.unsupportedValues = unsupportedValues
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: AnyCodableKey.self)
        try container.encode(self.title, forKey: AnyCodableKey(CodingKeys.title.rawValue))
        try container.encode(self.author, forKey: AnyCodableKey(CodingKeys.author.rawValue))

        for (key, value) in self.unsupportedValues {
            try container.encode(value, forKey: AnyCodableKey(key))
        }
    }

}

let jsonData = Data(#"{"title": "Example", "author": "Jelly", "date": "2025-01-01T12:34:56Z", "draft": true}"#.utf8)
let post = try JSONDecoder().decode(Post.self, from: jsonData)
print(post) // Post(title: "Example", author: "Jelly", unsupportedValues: ["draft": .bool(true), "date": .string("2025-01-01T12:34:56Z")])

let encoded = try JSONEncoder().encode(post)
print(String(data: encoded, encoding: .utf8)!) // {"author":"Jelly","draft":true,"title":"Example","date":"2025-01-01T12:34:56Z"}
```

### Decoding Collections with `InstancesOf`

`InstancesOf` simplifies extracting a specific type from complex data, even when that data is nested deep within the structure. This greatly simplifies working with APIs where you only care about specific objects within the structure, or where the structure itself may change.

Take, for instance, this very realistic JSON response from a very real API:

```json
{
    "data": {
        "repository": {
            "milestone": {
                "title": "v2025.1",
                "issues": {
                    "nodes": [
                         {
                             "number": 100,
                             "title": "A very real problem!"
                         },
                         {
                             "number": 101,
                             "title": "Less of a problem, more of a request."
                         },
                    ]
                }
            }
        }
    }
}
```

Instead of needing to write out a complete structured set of models to capture the entire response (six!), you can write _two_, and then use `InstancesOf` to skip past the nonsense, and right to the models you actually care about:

```swift
import SwiftAnyCodable

struct Milestone: Decodable, Equatable {
    var title: String
    var issues: [Issue]

    enum CodingKeys: String, CodingKey {
        case title
        case issues
    }

    init(title: String, issues: [Issue]) {
        self.title = title
        self.issues = issues
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        issues = try container.decode(instancesOf: Issue.self, forKey: .issues)
    }

}

struct Issue: Decodable, Equatable {
    var number: Int
    var title: String
}

let milestones = try JSONDecoder().decode(InstancesOf<Milestone>.self, from: jsonData)
print(Array(milestones)) // [Milestone(title: "v2025.1", issues: [Issue(number: 100, title: "A very real problem!"), Issue(number: 101, title: "Less of a problem, more of a request.")])]
```

### Literal Support

`AnyCodableValue` supports Swift's literal syntax, making it incredibly convenient to create values inline:

```swift
import SwiftAnyCodable

// String literal
let name: AnyCodableValue = "John Doe"

// Integer literal
let age: AnyCodableValue = 30

// Float literal
let price: AnyCodableValue = 19.99

// Boolean literal
let isActive: AnyCodableValue = true

// Array literal with mixed types
let items: AnyCodableValue = [
    "string",
    42,
    3.14,
    true
]

// Dictionary literal
let user: AnyCodableValue = [
    "name": "Alice",
    "age": 25,
    "isActive": true,
    "tags": ["swift", "ios", "developer"]
]

// Nested structures
let response: AnyCodableValue = [
    "status": "success",
    "data": [
        "user": [
            "id": 123,
            "name": "Bob",
            "email": "bob@example.com"
        ],
        "metadata": [
            "timestamp": 1234567890,
            "version": "2.0"
        ]
    ]
]
```

This makes working with dynamic data structures much more ergonomic, especially when constructing test data or working with loosely-typed APIs.

## License

This project is licensed under the BSD 2-Clause "Simplified" License. See the [LICENSE](LICENSE) file for details.
