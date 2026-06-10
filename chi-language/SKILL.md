---
name: chi-language
description: Guide for writing Chi language code. Covers syntax differences from mainstream languages, type system, effects, modules, stdlib, and known quirks to avoid.
---

# Chi Language Reference for Code Generation

Chi is a statically-typed language with Hindley-Milner type inference and structural typing that compiles to Lua (LuaJIT). Think of it as: ML-family type system + Kotlin-like syntax + algebraic effects + Lua runtime.

## How Chi differs from what you know

### Variables: `val` (immutable) and `var` (mutable)

```chi
val x = 42          // immutable, type inferred as int
var counter = 0     // mutable
counter += 1
val name: string = "Chi"  // explicit type annotation
```

### Primitives: `int`, `float`, `bool`, `string`, `unit`

`unit` is Chi's null/void. There is also `any` (top type).

### Arrays are 1-indexed

```chi
val arr = [10, 20, 30]
arr[1]   // 10, NOT arr[0]
arr[3]   // 30
```

### Records (not classes/objects)

Chi has no classes. Records are structural, anonymous, and mutable:

```chi
val person = { name: "Alice", age: 30 }
person.name      // "Alice"
person.age = 31  // field mutation allowed
```

Functions accept records by structure (extra fields are fine) and by name:

```chi
fn greet(p: { name: string }): string { "Hello ${p.name}" }
greet({ name: "Bob", age: 25 })  // OK -- extra fields are fine
```

### Functions: implicit return, no `fun`/`func`/`def`

The last expression is the return value. Use `return` only for early exit.

```chi
fn add(a: int, b: int): int { a + b }

pub fn greet(name: string): string {
    "Hello $name!"
}
```

### Lambdas: `{ params -> body }`

```chi
val double = { x: int -> x * 2 }
val add = { a, b -> a + b }       // types inferred
val thunk = { "hello" }           // no-arg lambda
```

### Trailing lambda syntax

When the last parameter is a function, the lambda can go outside the parentheses:

```chi
arr.forEach { x -> println(x) }
arr.fold(0) { acc, x -> acc + x }
```

This is preffered notation.

### UFCS (Uniform Function Call Syntax)

Any function can be called as a method on its first argument:

```chi
fn double(x: int): int { x * 2 }
5.double()     // same as double(5)
"hello".len()  // len from std/lang.string -- no import needed (see resolution below)
```

This is how all "methods" work in Chi -- there are no method declarations.

**How `x.foo()` resolves -- this decides when you actually need an import:**

- **Receiver of a concrete type** (`array[int]`, `string`, a record/sum/variant):
  resolves WITHOUT an import. The compiler finds `foo` in the package that
  *defines* the receiver's type. So `myArray.size()` needs no
  `import std/lang.array { size }` -- the import would be dead.
- **Receiver of type `any`** (or a not-yet-resolved type variable): the type
  can't narrow the candidates, so resolution falls back to either (a) a function
  of that name imported in this file, or (b) a globally *unique* public name
  across all loaded packages.
  - If the name is exported by several packages and none is imported, it is a
    COMPILE ERROR (`AMBIGUOUS_METHOD`) -- e.g. `size` exists in array/map/set.
    Fix: annotate or cast the receiver to a concrete type, or import the one you want.
  - Uniquely-named functions (e.g. `len`, `toInt` -- only in std/lang.string)
    resolve even on an `any` receiver.

Practical consequences:
- Prefer concrete types over `any` so UFCS resolves import-free.
- A function declared to return `any` forces every `.method()` on its result
  down the ambiguous `any` path. Declare the narrowest real return type
  (e.g. `array[any]`, `Type`, `Expr`) instead of `any` whenever the body
  actually produces one -- it both improves type checking and keeps UFCS working.

### `if` is an expression

```chi
val label = if x > 0 { "positive" } else { "negative" }
```

### `when` expression (like `cond`/`switch`)

```chi
val result = when {
    x < 0  -> "negative"
    x == 0 -> "zero"
    else   -> "positive"
}
```

### `for` iterates over arrays, records, and generators

```chi
for item in [1, 2, 3] { println(item) }
for idx, val in ["a", "b"] { println("$idx: $val") }  // 1-based index
for key, val in { x: 1, y: 2 } { println("$key=$val") }
```

### String interpolation: `$var` and `${expr}`

```chi
val name = "World"
println("Hello $name! Sum: ${1 + 2}")
```

Escape `$` with `\$`.

### Weave operator `~>` (piping with placeholder)

```chi
"hello" ~> toUpper(_) ~> "${_}!"
```

`_` is replaced with the left-hand value at each step.

### Sum types (union types)

```chi
type Result = int | string
val x: Result = 42

if x is int {
    val n = x as int
    println(n)
}
```

`Option[T]` is just `T | unit` (from `std/lang.option`).

### Type aliases are transparent

```chi
type Name = string
type Point = { x: int, y: int }
type Callback = (int) -> string
```

They do not create new distinct types.

### Generics with `[T]`

```chi
fn identity[T](x: T): T { x }
fn map[T, R](arr: array[T], f: (T) -> R): array[R] { ... }
type Pair[A, B] = { first: A, second: B }
```

### Algebraic effects

Effects are Chi's unique approach to side effects. Define, invoke inside `handle`, handle with `resume`:

```chi
effect ask(prompt: string): string
effect log(msg: string): unit

val result = handle {
    log("starting")
    val name = ask("who?")
    "Hello $name"
} with {
    ask(prompt) -> resume("World")
    log(msg) -> {
        println("LOG: $msg")
        resume(unit)
    }
}
```

Effects can be `pub` for cross-package use. They support type parameters: `effect read[T](): T`.

### Variant types (algebraic data types)

```chi
data Shape =
    Circle(radius: float)
    | Rectangle(width: float, height: float)

data Option[T] = Some(value: T) | None
data pub Node(value: int, next: Node)  // recursive
```

### Modules and imports

```chi
package myapp/utils              // module: myapp, package: utils
package std/lang.option          // module: std, package: lang.option

import std/lang.array { map, fold, size }
import std/lang.string { len, toLower }
import std/math { abs, pow }
import mod/pkg as p              // alias: p.foo()
import mod/pkg { foo as bar }    // name alias
```

Only `pub` declarations are visible across modules. `println`, `print`, `eval` are auto-imported.

### Visibility

```chi
pub fn publicFn() { ... }
pub val publicVal = 42
fn privateFn() { ... }        // only visible within module
```

## Quirks and pitfalls

These are real compiler limitations. Follow the workarounds exactly.

### No automatic `main` -- top-level code runs

A program runs its top-level statements top to bottom. There is NO implicit
entry point: defining `pub fn main() { ... }` does nothing on its own -- the
program produces no output unless something is at the top level (or calls your
entry function there). To run code, put it at the top level:

```chi
package demo/app
val arr = [1, 2, 3]
println(arr.size())   // runs; prints 3
```

### `package` declarations need a module/package path

Every file starts with `package <module>/<package>`. A bare `package foo`
(no slash) is a parse error. Dots are allowed in the package part:

```chi
package myapp/utils       // OK
package std/lang.array    // OK -- dotted package
package foo               // PARSE ERROR -- needs a slash
```

### Mutual recursion requires `var` pattern

Self-recursion via `fn` works fine. However, mutual recursion (two functions calling each other) requires the `var` workaround since Chi lacks forward declarations:

```chi
// Self-recursion works directly:
fn factorial(n: int): int {
    if n <= 1 { 1 } else { n * factorial(n - 1) }
}

// Mutual recursion needs var pattern:
var isEven: (int) -> bool = { n -> false }
var isOdd: (int) -> bool = { n -> false }
isEven = { n: int -> if n == 0 { true } else { isOdd(n - 1) } }
isOdd = { n: int -> if n == 0 { false } else { isEven(n - 1) } }
```

### Reserved Lua names cause runtime errors

Avoid naming functions or variables: `repeat`, `type`, `error`, `load`, `require`, `select`, `pairs`, `ipairs`, `next`, `pcall`, `xpcall`, `tostring`, `tonumber`, `unpack`, `rawget`, `rawset`.

### Negative float literals

`-3.14` as an argument can fail. Assign to a variable first:

```chi
// WRONG: fabs(-3.14)
val neg: float = 0.0 - 3.14
fabs(neg)
```

### Record iteration order is non-deterministic

`for k, v in { a: 1, b: 2 }` may iterate in any order (Lua's `pairs()` behavior).

### Default parameters have type-checking issues

Functions with default parameters may produce unexpected type errors in some cases. Test carefully.

## Standard library quick reference

All stdlib modules use the `std/` prefix. Import specific functions.

| Module            | Key exports                                                                                                                                                                                               |
| ----------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `std/lang.array`  | `size`, `push`, `pop`, `map`, `fold`, `reduce`, `sort`, `sortWith`, `reverse`, `any`, `all`, `count`, `indexOf`, `forEach`, `first`, `last`, `isEmpty`, `sum`, `joinToStringWithSeparator`, `intersperse` |
| `std/lang.string` | `len`, `find`, `substring`, `toLower`, `toUpper`, `trim`, `replace`, `replaceAll`, `split`, `contains`, `startsWith`, `endsWith`, `isEmpty`, `reverse`, `toInt`, `codePoints`                             |
| `std/lang.option` | `Option[T]` (= `T \| unit`), `valueOr`, `ifPresent`, `orElse`, `map`                                                                                                                                      |
| `std/lang.map`    | `emptyMap[K,V]()`, `put`, `get`, `getOrDefault`, `size`, `forEach`, `keys`, `values`, `mapValues`                                                                                                         |
| `std/lang.set`    | `emptySet[T]()`, `add`, `remove`, `contains`, `size`, `toArray`, `fromArray`                                                                                                                              |
| `std/math`        | `abs`, `min`, `max`, `pow`, `sqrt`, `floor`, `ceil`, `sin`, `cos`, `tan`, `pi`                                                                                                                            |
| `std/math.random` | `seed`, `randomInt`, `randomFloat`                                                                                                                                                                        |
| `std/io`          | `readLine`                                                                                                                                                                                                |
| `std/io.file`     | `readString`, `writeString`, `readAllLines`, `lineIterator`, `open`, `close`, `write`                                                                                                                     |
| `std/utils`       | `range(from, to)` returns an iterator                                                                                                                                                                     |

### Stdlib usage pattern

```chi
import std/lang.array { map, fold, size }
import std/lang.string { len, split }

val words = "hello world chi".split(" ")
val lengths = words.map { w -> w.len() }
val total = lengths.fold(0) { acc, n -> acc + n }
```

## Lua FFI

Chi can call Lua directly for low-level operations:

```chi
import std/lang { luaExpr, embedLua }

val time = luaExpr("os.time()")         // eval Lua expression, return result
embedLua("print('from lua')")           // execute Lua statements (side effects)
```

**RULE: `luaExpr`/`embedLua` are a last resort — use them ONLY when no
native Chi alternative exists.** This applies everywhere: application
code, compiler code, and tests alike. Existing code (including the chicc
compiler) still contains legacy FFI that predates native alternatives —
do NOT copy that idiom into new code, even when editing a file full of it.

Before reaching for FFI, check this list of native replacements:

| Tempting FFI | Native Chi instead |
| --- | --- |
| `luaExpr("{}")` as empty array | `[]` (e.g. `val xs: array[any] = []`) |
| `embedLua("table.insert(xs, v)")` | `xs.push(v)` |
| `luaExpr("#xs")` | `xs.size()` (on a concretely-typed array) |
| `luaExpr("xs[i]")` / `embedLua("xs[i] = v")` | `xs[i]` / `xs[i] = v` |
| `luaExpr("t.field")` on a record or `any` | `t.field` (dynamic field access works on `any`) |
| `embedLua("t.field = v")` | `t.field = v` |
| raw table as string-keyed map | `std/lang.map` (`emptyMap`/`put`/`get`/`keys`) |
| counting entries via `pairs` loop | keep a counter, or `m.size()` on a concrete Map |
| string ops via `string.*` | `std/lang.string` (`len`, `find`, `substring`, ...) |

On `any`-typed receivers prefer globally-unique stdlib names (`put`, `get`,
`keys`) — shared names (`size`, `forEach`) raise `AMBIGUOUS_METHOD` there
(see UFCS resolution above).

Legitimate FFI (no native alternative today):

- `pcall`/`error` interop — Chi has no try/catch
- OS/IO facilities not wrapped by the stdlib (`os.time()`, `os.getenv`...)
- reaching into Lua runtime internals (`package.loaded`, metatables)
- genuinely performance-critical raw-table code (measure first)

When you do use FFI, keep the snippet minimal and put the surrounding
logic in Chi.
