## Introduction

Concept Kit is a multi-modal conceptual language with a very small number of available syntax operations (about 5). There are no types, classes, functions, data types or strings. There is only the `Concept` with it's inclusions and `Vector`s. Locating an Occam's razor syntax set that can specify and resolve a growing list of automation goals can be very difficult. It must be reflexively intuitive yet still capable and deterministic. Concept Kit asks the analyst to specify a series of `Concept`s that form a `[ConceptID: Concept]` or `ConceptGraph` superstructure.

Traditional procedural languages allow analysts to declare statement order, encapsulate logic, offer hardware abstractions, and utilize many other syntactic functions, all in the hope of intuitively and efficiently expressing the required automation. The actual conceptual automation goals behind the codebase are held in the analyst's mind, and tokens of (usually) procedural languages are arranged to achieve those goals. 

Conversely, Concept Kit concerns itself with finding an intuitive concept framework, from which a method of computation can also be derived. Instead of executing a program, one "resolves" a concept in the graph. Concept Kit aims to demonstrate that it's conceptual specification is a superior substrate to store automation goals & analytic information in general. 

It is still in the working preview phase, with some ontological flaws to be addressed. Examples and recipes will be added soon to help users get started with integrating Concept Kit into their projects. You are invited to join our community to stay up-to-date on our progress.

## Quick Syntax Guide

Here is a concept graph containing inter-related concepts. 

```
Square
----------
Number * Number -> Result

Test Square
------
7 -> Square.Number
Square.Result = 49

```

<img width="255" alt="image" src="https://github.com/user-attachments/assets/69a097df-f845-4110-bb3d-208f77aafa18" /><img width="300" alt="image" src="https://github.com/user-attachments/assets/08bf7017-d879-4710-b0fb-804a698fc963" />


Resolving `Test Square`, will trigger the resolving of `Square` by it's mention.

### Inclusions

A concept's inclusions are the elements within a concept. Numbers move between inclusions via the arrows. Vectors (conceptual arrows) can indicate directional dependency between inclusions. They can also represent arithmetic synthesis, where the output of one inclusion is used as input to another. Additionally, vectors can impose conditional constraints, controlling the flow of data between inclusions.

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

Typically, all vectors are resolved once, respecting dependancy, but self-referential vectors introduce a potential infinite loop, or are at least ambiguous to how many times it should loop. Therefore, as the condition `Power = Current Factor` fails, it will trace *upstream* the inclusion graph until the first looping vector is found, in which case it can `Current Factor + 1` again and retry the condition *downstream*. This mechanism helps to fulfill the vector's looping realities and enables `Concept`s to model that which cannot be fully resolved after a single vector pulse. Most importantly, this provides a handle on plurality as a concept.

### Data Sources

The world outside a `ConceptGraph` is constrained to various "frames" of a key/value store. The keys are `ConceptIDPath`s and the values are `Double`s. 

```
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

This Swift implementation is intended to be the first of many. A key objective throughout the development has been to minimize line counts in concept-resolving code, and this will remain a priority moving forward. By keeping the resolution logic concise, it remains straightforward and easy to use. Small implementation footprints should enable rapid implementation of Concept Kit resolvers across a wide range of software environments.

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
