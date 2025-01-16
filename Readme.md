## Introduction

Concept Kit is a multi-modal conceptual language with a minimal array of available syntax operations (about 5). There are no types, classes, functions, data types or strings. There is only the `Concept` with it's inclusions and `Vector`s. Instead of procedural code, Concept Kit asks the analyst to specify a series of `Concept`s that form a `[ConceptID: Concept]` or `ConceptGraph` superstructure. Instead of executing a program, one "resolves" a `Concept` in the graph.

Traditional procedural languages require analysts to define the order of statements, encapsulate logic, abstract hardware details, and use various syntactic constructs to intuitively and efficiently express automation goals. However, the underlying conceptual goals of the automation remain in the analyst's mind, with procedural language tokens arranged to approximate those goals.

In contrast, Concept Kit focuses on providing an intuitive conceptual framework from which a new computational method is derived. It aims to demonstrate that it is a cleaner, more concise, and accessible language for implementing automation goals. A Concept Kit codebase is designed to serve as a fundamentally different resource compared to a procedural codebase.

Note: It is still in the working preview phase, with some ontological flaws to be addressed. Examples and recipes will be added soon. You are invited to join our community to stay up-to-date on our progress.

## Quick Syntax Guide

Here is a concept graph containing inter-related concepts. 

**Visual Representation:**

<img width="647" alt="image" src="https://github.com/user-attachments/assets/2068c55f-871f-4089-92ba-526e34d830b1" />


**Textual Representation:**

```
Test Square
------
7 -> Square.Number
Square.Result = 49

Square
----------
Number * Number -> Result

```


Resolving `Test Square`, will trigger the resolving of `Square` by it's mention.

A concept's inclusions are the elements within a concept. Numbers move between inclusions via the arrows. Vectors (conceptual arrows) can indicate directional dependency between inclusions.

Examples:

`Pixel.Index + 1 -> Final Index`

`Total / Count -> Average`

Additionally, vectors can impose conditional constraints on the concept's resolution.

Examples:

`First.Object.Index >= Last.Object.Index`

`Next.Object.Index = 1`

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

Vectors can refer to other concepts in the graph by name, which triggers a resolution of those sub-concepts to access their referenced inclusions. This resolution process is not tied to the order of the Concept Kit code, but rather occurs based on the interdependencies between vectors. In other words, vectors resolve in the order that makes sense based on their relationships, rather than the order in which they are written.

### Self-Referential Vectors

```
Exponent
----------
0 -> Current Factor
1 -> Result

Current Factor + 1 -> Current Factor
Result * Base -> Result

Power = Current Factor


Test Exponent
--------------
2 -> Exponent.Base
5 -> Exponent.Power
32 = Exponent.Result
```

<img width="147" alt="image" src="https://github.com/user-attachments/assets/3b6c685f-dffa-4647-aa74-7cce534e1163" />

```Current Factor + 1 -> Current Factor```

Typically, all vectors are resolved once, respecting dependancy, but self-referential vectors introduce a potential infinite loop, or are at least ambiguous to how many times it should loop. Therefore, as the condition `Power = Current Factor` fails, it will trace *upstream* the inclusion graph until the first looping vector is found, in which case it can execute `Current Factor + 1` again, and eventually retrying the condition *downstream*. This mechanism helps to fulfill the vector's looping realities and enables `Concept`s to model that which cannot be fully resolved after a single vector pulse. Most importantly, this provides a handle on modeling plurality as a concept.

### Data Sources

The world outside a `ConceptGraph` is constrained to various "frames" of a key/value store. The keys are `ConceptIDPath`s and the values are `Double`s. 

```
var data = [
    [["Index"]: 0, ["Color", "Red"]: 244, ["Color", "Green"]: 132, ["Color", "Blue"]: 132]],
    [["Index"]: 1, ["Color", "Red"]: 213, ["Color", "Green"]: 12, ["Color", "Blue"]: 43]],
]


// backing data types
typealias ConceptID = String
typealias ConceptIDPath = [ConceptID]
typealias ConceptValues = [ConceptIDPath: Double]

protocol ConceptValueFrames {
    subscript(_ index: Int) -> ConceptValues { get set }
    var count: Int { get }
    // ...
}
```

These 'conceptified' data frames are integrated for read & write via micro adapters. One adapter might be a JSON file from a disk, a REST endpoint or a camera feed. They exist as almost virtual concepts and can be accessed via the same `ConceptIDPath`(s). 

## What's Included

### Concept Code to ConceptGraph

```
var code = """
Bull Candle
------------
Candle.Close Price > Candle.Open Price
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

This Swift implementation is intended to be the first of several. A key objective throughout the development has been to minimize line counts in concept-resolving code, and this will remain a priority moving forward. By keeping the resolution logic concise, it remains straightforward and easy to use. Small implementation footprints should enable rapid implementation of Concept Kit resolvers across a wide range of software environments.

| Line Count | File |  |
| ----- | ----- | ----- |
| 17 | Concept.swift | core syntax and data structures |
| 503 | Concept+Resolve.swift | resolver logic |
| 76 | Concept+Extensions.swift |  |
| 784 | /Parser/*.swift |less important to track line counts |

Future language environments on the roadmap include:

- JavaScript
- Python
- Go
- C
- Java
- C#
- Kotlin

What are we missing?


## Testing

There are 8 Concept Kit examples that test the concept resolver progressively, along with some assorted tests for other required components.
