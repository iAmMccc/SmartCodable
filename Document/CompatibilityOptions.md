# Compatibility and recovery options

SmartCodable keeps the existing default array and dynamic-value behavior. The
following options select more precise recovery without changing existing callers.

`SmartDecodingOption` and `SmartEncodingOption` keep their 7.0.1 case sets; this
line adds no new option case, so existing exhaustive switches over them keep
compiling. The opt-in mechanisms below are selected on a decoder or an encoder
instance instead of through a new option case.

## One consumption per optional array element

The historical generic `UnkeyedDecodingContainer.decodeIfPresent(T.self)` fallback
consumes two positions after a failed element. Existing callers retain this legacy
behavior by default. For custom unkeyed decoding, select:

```swift
let decoder = SmartJSONDecoder()
decoder.smartUnkeyedDecodingStrategy = .consumeOnce
// try decoder.smartDecode(CustomSequence.self, from: "[0,2,3]")
```

The mode is selected on the decoder instance: set
`SmartJSONDecoder.smartUnkeyedDecodingStrategy` and decode through
`SmartJSONDecoder.smartDecode(_:from:)`. Under the single-consumption
(`.consumeOnce`) mode, end-of-container returns `nil` without advancing the
cursor and without consuming an element, a `null` element returns `nil` and
consumes that one element, and a normal decode or a tolerant fallback consumes
exactly one element. A `null` element is not passed to the element type's
`init(from:)`, so a tolerant decoder cannot fabricate a non-nil value and the
element type's custom `init(from:)` is not invoked for null elements.
Scalar overloads retain their existing single-element
conversion behavior. The mode does not turn ordinary model arrays into lossy
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

The mode is selected on the encoder instance: set
`SmartJSONEncoder.smartDynamicValueEncodingStrategy` and encode through
`SmartJSONEncoder.encode(_:)`, combined with that encoder's existing date or key
strategies when needed. Runtime dictionary data keys remain data keys; model fields
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

## Model completion callbacks

Completion depends on the decoding entry point and container:

- `Model.deserialize(...)` and `SmartUpdater.update(...)` complete the root model
  once after decoding succeeds. `SmartJSONDecoder.smartDecode(...)` does not add
  a root completion callback; nested properties still use their container rules.
- Keyed model properties, including models inside property wrappers, complete
  after their decoded or fallback value is selected. A nil optional has no model
  to complete.
- Ordinary model arrays complete each successfully decoded model element once.
  Their callback guard checks the static element type: `Optional<Model>` does not
  conform to `SmartDecodable`, so `[Model?]` elements receive no callback.
  Dictionary values (`[String: Model]`) also receive no callback. A failed array
  or dictionary property uses its declared fallback; callbacks already executed
  before the failure remain externally visible.
- `@SmartCompact.Array` completes each successfully decoded non-optional model
  element once and skips malformed elements. Optional model elements retain the
  7.0.1 JSON-value decoding path: model objects and null do not become model
  elements, so `@SmartCompact.Array var values: [Model?] = []` decodes to an empty
  array without model callbacks. This boundary also applies with `consumeOnce`.

## Shared decoder configuration

With fixed configuration, SmartJSONDecoder keeps parsing identifiers, options and
model contexts local to each call. Decoding no longer inserts session metadata
into the caller's `userInfo`. Do not mutate instance strategies or `userInfo`
concurrently with decoding. User-supplied reference values, strategy closures and
custom decoding implementations must provide their own synchronization. Global
option access is synchronized individually, not as a transaction covering an
entire model; keep global options fixed when a stable per-call policy is required.
