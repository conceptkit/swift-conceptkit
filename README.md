## Introduction

Concept Kit is a multi-modal concept language with a minimal array of available syntax operations (about 5). There are no types, classes, functions, data types or strings. There is only the `Concept` with it's `Vector`s between inclusions. Instead of procedural code, Concept Kit asks the analyst to specify a series of `Concept`s that form a `ConceptGraph` superstructure (`[ConceptID: Concept]`). Instead of executing a program, one "resolves" a `Concept` in the graph.

Traditional procedural languages require analysts to define the order of statements, encapsulate logic, abstract hardware details, and use various syntactic constructs to express automation goals. However, the underlying conceptual goals of the automation remain in the analyst's mind, with procedural language tokens arranged to approximate those goals.

In contrast, Concept Kit focuses on providing an intuitive conceptual framework from which a new computational method is derived. It aims to demonstrate that it is a more concise and accessible language for implementing automation goals. A Concept Kit codebase hopes to be a fundamentally different resource compared to a procedural codebase.

Note: It is still in the working preview phase whilst it under-goes further testing. Examples and recipes will be added soon. You are invited to join our community to stay up-to-date on our progress.

## Quick Syntax Guide

Concept Kit is a case-insensitive and space-insensitive language. 

Here is a concept graph containing inter-related concepts. The capitalization of Square is a convention to help differentiate the Concept from the inclusion of the Concept.

**Textual Representation:**

```
Square
----------
number * number -> result

Test Square
------
7 -> Square.number
Square.result = 49

```

**Visual Representation:**

<img width="944" height="420" alt="Screenshot 2025-09-07 at 14 30 57" src="https://github.com/user-attachments/assets/9204deba-32c1-4ecf-8480-9cc9746a8e4e" />

Resolving `Test Square`, will trigger the resolving of `Square` with the injected value `7 -> Square.number`.

A concept's inclusions are the referenced elements within it. Numbers flow between inclusions via the arrows. Vectors (conceptual arrows) indicate directional dependency between inclusions.

Examples:

`Pixel.index + 1 -> final index`

`total / count -> average`

Additionally, vectors can impose conditional constraints on the concept's resolution.

Examples:

`Square.result = 49`

`next.Object.index = 1`

All possible inclusion arithmetic combinations:
- Add: +
- Subtract: -
- Subtract with absolute value: --
- Multiply: *
- Multiply with integer result: **
- Divide: /
- Divide with integer result: //

All possible conditional constraints:
- Equal to: =
- Greater than: >
- Less than: < 
- Less than or equal to: <=
- Greater than or equal to: >=

Other:
- Or: | e.g. `Apples | Oranges`
- Exclusion: ! e.g. `!Threshold Is Breached`

Vectors can refer to other concepts in the graph by name, which triggers a resolution of those sub-concepts to access their referenced inclusions. This resolution process is not tied to the order of the Concept Kit code, but rather occurs based on a topological order derived from the dependencies between vectors. 

### Self-Referential Vectors

```
Exponent
----------
0 -> current factor
1 -> result

current factor + 1 -> current factor
result * base -> result

power = current factor


Test Exponent
--------------
2 -> Exponent.base
5 -> Exponent.power
32 = Exponent.result
```

<img width="147" alt="image" src="https://github.com/user-attachments/assets/3b6c685f-dffa-4647-aa74-7cce534e1163" />

```current factor + 1 -> current Factor```

A concept's vectors are resolved once, following their dependency chain. However, self-referential vectors introduce ambiguity, potentially leading to infinite loops or uncertainty about the number of iterations required. When the condition `power = current factor` fails, the system traces upstream through the causal vector graph to identify the first self-referential vector, increments `current factor` by 1, re-resolves from there, and retries the condition downstream. This mechanism manages the iterative nature of self-referential vectors, enabling Concept Kit to model systems that require multiple passes in multiple concepts to resolve. By leveraging the ambiguity of graph cycles, it represents plurality (multiple valid states) and conditionality (context-dependent outcomes) as core concepts.

### Data Sources

The world outside a `ConceptGraph` is constrained to various "frames" of a key/value store. The keys are `ConceptIDPath`s and the values are `Double`s. 

```
// backing data types
typealias ConceptID = String
typealias ConceptIDPath = [ConceptID]
typealias ConceptValues = [ConceptIDPath: Double]

// backing data example 
var data: [ConceptValues] = [
    [ 
        ["Color", "Red"]: 244, 
        ["Color", "Green"]: 132, 
        ["Color", "Blue"]: 132 ]
    ],
    [ 
        ["Color", "Red"]: 213, 
        ["Color", "Green"]: 12, 
        ["Color", "Blue"]: 43 ]
    ],
]

protocol ConceptValueFrames {
    subscript(_ index: Int) -> ConceptValues { get set }
    var count: Int { get }
    // ...
}
```
Here is a simple Array based ConceptValueFrames impl:

```
public struct ArrayConceptValueFrames: ConceptValueFrames {
    private var frames: [ConceptValues]
    
    public init(frames: [ConceptValues] = []) {
        self.frames = frames
    }
    
    public subscript(_ index: Int) -> ConceptValues {
        get {
            return frames[index]
        }
        set {
            if index >= frames.count {
                frames.append(contentsOf: Array(repeating: [:], count: index - frames.count + 1))
            }
            frames[index] = newValue
        }
    }
    
    public var count: Int {
        frames.count
    }
    
    public func commitEdits() -> Bool {
        true
    }
}
```

Key-value data frames (`[[String: Double]]`, i.e., arrays of dictionaries) are integrated for reading and writing through micro-adapters. These adapters can connect to various sources, such as an image file on disk, a JSON url endpoint, or a camera feed. Represented as virtual concepts, these data frames are accessible via consistent `ConceptIDPath`s.

## What's Included

### Concept Code to ConceptGraph

```
var code = """
Bull Candle
------------
Candle.close price > Candle.open price
"""

var error: String? = nil
guard let graph = ConceptGraph.fromCode(code, error: &error) else {
    print("A problem occured: \(error)")
}
```
### ConceptGraph to Concept Code

```
let code: String = graph.toCode()
```
### Concept Resolver

```
var inputs = [ConceptIDPath: Double]()
var isFatal: Bool = false

guard let outputs: [ConceptIDPath: Double] = graph["Face"]?.resolve(values: &inputs, graph: graph, isHardStop: &isFatal) else {
    if isFatal {
        print("Encountered hard stop e.g. end of data source.")
    } else {
        print("Failed to build: Face")
    }
}
```

## Source Code Information

A key objective throughout the development has been to minimize complexity (line counts) in concept-resolving code, and this will most likely remain a priority moving forward. The simplicity (or otherwise) of the resolution logic is seen as a reflection of the simplicity of the Concept Kit algorithm. Small implementation footprints should enable rapid implementation of Concept Kit resolvers across a wide range of software environments - even edge devices.

| Line Count | File |  |
| ----- | ----- | ----- |
| 17 | Concept.swift | core syntax and data structures |
| 433 | Concept+Resolve.swift | resolver logic |
| 122 | Vector+Traverse.swift | dependancy order and graph traversal |
| 43 | Concept+ConceptValues.swift | key/values and data frames |
| 615 | TOTAL |
| 774 | /Parser/*.swift |less important to track line counts |

Future language environments on the roadmap include:

- Python
- C
- JavaScript
- Java
- Go
- C#
- Kotlin

What are we missing?


## Testing

There are 8 Concept Kit examples under `\Tests\ResolverTests` that test the concept resolver progressively, along with some assorted tests for other required components.
