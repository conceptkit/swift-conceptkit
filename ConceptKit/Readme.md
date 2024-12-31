## Introduction

Concept Kit is a multi-modal conceptual language designed for programmability and comprehensibility on limited screen real estate and with non-keyboard input modalities. It aims to broaden access to and manipulation of computer automation. Built on syntax minimalism, Concept Kit reduces cognitive load with a remarkably small syntax set of just 5-10 elements. This approach replaces traditional codebases, which can be cumbersome to comprehend and modify, with a structured knowledge graph that is more intuitive and easier to work with.

The Concept Kit vision centers around thinking of software systems as information flows from inputs to outputs. Developers define Concepts, which represent abstract ideas or entities, which form a `ConceptGraph` super structure. Then, they resolve the necessary concepts.

Concept Kit is still in the working preview phase, with some ontological flaws to be addressed. It's being actively worked on to address these flaws and release a stable version 1.0. Examples and recipes will be added soon to help users get started with integrating Concept Kit into their projects. You're invited to join our community to stay up-to-date on our progress.

## Whats Included

### Concept Code to ConceptGraph

```
var error: String? = nil
var code = """
Bull Candle
------------
Candle.Close Price > Candle.Open Price
"""
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
guard let builtValues = graph["Face"]?.resolve(values: &inputs, graph: graph, isHardStop: &isFatal) else {
    if isFatal {
        print("Encountered hard stop e.g. end of data source.")
    } else {
        print("Failed to build: Face")
    }
}
```

## Current Line Counts

- 17  Concept.swift            (core syntax and data structures) 
- 503 Concept+Resolve.swift    (resolver logic)
- 76  Concept+Extensions.swift (additional functionality and extensions)
  
Total: 596

A simple syntax model is bound to result in a low specification code count (Concept.swift), it requires a lot more mental striving to keep the resolver code low. It was always a good feeling to see the code count drop in the resolver as a reflection of a *better* (smaller) Concept Kit syntax. 

## Quick Syntax Guide

Sample Code:

Here are 2 inter-related concepts. 
```
Exponent Does Work
--------------
2 -> Exponent.Base
5 -> Exponent.Power
32 = Exponent.Result

Exponent
----------
0 -> Current Factor
1 -> Result

Current Factor + 1 -> Current Factor
Result * Base -> Result

Power = Current Factor
```
Resolving `Exponent Does Work`, helps determine whether `Exponent` really works. 

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

<img width="147" alt="image" src="https://github.com/user-attachments/assets/3b6c685f-dffa-4647-aa74-7cce534e1163" />


```Current Factor + 1 -> Current Factor```

Typically, all vectors are resolved once, respecting dependancy, but self-referential vectors introduce a potential infinite loop, or are at least ambiguous to how many times it should loop. Therefore, as the condition `Power = Current Factor` fails, it will trace *upstream* the inclusion graph until the first looping vector is found, in which case it can `Current Factor + 1` again and retry the condition upstream. This helps to fulfill the vector's looping destiny as well as creating a mechanism for `Concept`s to describe a concept that can't finish resolving on a single vector pulse. 

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

## Testing

There are 8 Concept Kit examples that test the concept resolver progressively, along with some assorted tests for other required components.
