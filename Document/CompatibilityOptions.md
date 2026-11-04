# Compatibility and recovery options

SmartCodable keeps the existing default array and dynamic-value behavior. The
following options select more precise recovery without changing existing callers.

## One consumption per optional array element

The historical generic `UnkeyedDecodingContainer.decodeIfPresent(T.self)` fallback
consumes two positions after a failed element. Existing callers retain this legacy
behavior by default. For custom unkeyed decoding, select:

```swift
let decoder = SmartJSONDecoder()
decoder.smartUnkeyedDecodingStrategy = .consumeOnce
// try decoder.smartDecode(CustomSequence.self, from: "[0,2,3]")
```

The convenience entry points accept `options: [.unkeyed(.consumeOnce)]`.
An unsuccessful element consumes one position and returns nil; decoding beyond the
end throws without advancing. Scalar overloads retain their existing single-element
conversion behavior. The option does not turn ordinary model arrays into lossy
arrays; use `@SmartCompact.Array` to skip invalid elements.

## Recursive runtime encoding

By default, `@SmartAny` and `@SmartCompact.Dictionary` retain their existing nested
runtime-value fallback behavior. To encode nested Date/Data/URL and Encodable models
using the current encoder and its strategies:

```swift
let encoder = SmartJSONEncoder()
encoder.smartDynamicValueEncodingStrategy = .recursive
encoder.dateEncodingStrategy = .millisecondsSince1970
// try encoder.encode(model)
```

The dictionary/string convenience methods accept
`options: [.dynamicValues(.recursive)]`, combined with their existing date or key
options when needed. Runtime dictionary data keys remain data keys; model fields
still use the model's mappings and value transformers. Optional values and arrays
are traversed recursively. Unsupported leaves throw `EncodingError.invalidValue`
with their coding path, rather than silently losing data. Compact dictionaries
still skip unsupported direct entries according to their existing compact contract.

## Integer conversion boundaries

The original decimal value must be within the target integer's range before
`.truncate` or `.rounded` applies. UInt8 rejects `"255.4"` and `"-0.4"` under all
policies, while `.rounded` accepts `"254.6"` as 255. Out-of-range input falls back
through the existing property/container recovery path. Range and rounding use
exact decimal digits, so a tiny fractional overflow at Int64/UInt64 boundaries is
also rejected; no intermediate Double may make it appear in range.

## Partial updates and failure recovery

SmartUpdater resolves source aliases once, merges root CodingKey identities, then
decodes the root without applying its aliases again. A first alias named `name`
for `firstName` cannot overwrite an independent `name` when only `first_name` is
supplied. Nested models retain their existing wire mappings and merge semantics;
this is not a recursive change to all nested update policies. The existing primary
alias null fallback and the `preserving` closure remain available. Runtime state
excluded from Codable still requires explicit preservation by the caller.

Value transformers are looked up by the original CodingKey before the output
key is mapped. An output alias cannot select another field's transformer.

Encoding snapshots are scoped to an individual model encoding attempt. If custom
encoding catches a nested model's error, a subsequent fallback does not inherit
that failed model's value transformers.

## Shared decoder configuration

With fixed configuration, SmartJSONDecoder keeps parsing identifiers, options and
model contexts local to each call. Decoding no longer inserts session metadata
into the caller's `userInfo`. Do not mutate instance strategies or `userInfo`
concurrently with decoding. User-supplied reference values, strategy closures and
custom decoding implementations must provide their own synchronization. Global
option access is synchronized individually, not as a transaction covering an
entire model; keep global options fixed when a stable per-call policy is required.
