# Compatibility and recovery options

SmartCodable keeps the existing default array and dynamic-value behavior. The
following options select more precise recovery without changing existing callers.

`SmartDecodingOption` and `SmartEncodingOption` keep their 7.0.1 case sets; this
line adds no new option case, so existing exhaustive switches over them keep
compiling. Decoder and encoder recovery modes are selected on their respective instances.
Compact array conversion uses the separate global `compactElementStrategy` bridge;
none adds a case to either existing option enum.

Existing API calls keep the legacy bridge by default. Select an extension only
when its conversion and error semantics are desired; updating the package alone
does not opt a caller into recursive dynamic encoding or Compact conversion.

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

Under the default `.legacy` strategy, `@SmartAny` retains its existing JSON-value
bridge, including supported JSON scalar and container values, and its
`SmartCodableX` model path. Values outside those supported paths, including
otherwise unknown plain `Encodable` values, fall back to `null` without invoking
their own `encode(to:)`. The Compact wrappers retain their separately documented
legacy contracts.
Choose `.recursive` when those otherwise unsupported values must be encoded;
their custom `encode(to:)` then runs and its errors reach the caller instead of
becoming `null`.

`@SmartCompact.Dictionary` has a different legacy boundary: direct runtime
`Encodable` values are encoded, including Date/Data/URL, typed collections and
plain Encodable models. Their errors propagate. Values that only the JSON-value
bridge can represent, such as heterogeneous `[String: Any]`, `[Any]` and NSNull,
are omitted under `.legacy`. In particular, a nested heterogeneous dictionary
containing a Date is omitted as a whole, rather than being replaced by an empty
object. Choose `.recursive` to retain those containers and encode their leaves
with the selected date/data strategies.

## JSON input boundaries

Dictionary properties keep their object-only input boundary. A JSON object
stored inside a string does not opt the property into another parse: it falls
back to its declaration just as in 7.0.1. Parse that string into an object before
deserializing, or declare an explicit `mappingForValue()` transformer for the
property when the wire format intentionally contains embedded JSON text.

The String entry of `SmartJSONDecoder.smartDecode` accepts JSON objects and
arrays. To decode a top-level JSON fragment, use the existing Data entry:

```swift
let decoder = SmartJSONDecoder()
let value = try decoder.smartDecode(Int.self, from: Data("42".utf8))
// value == 42; smartDecode(Int.self, from: "42") keeps the legacy rejection.
```

`designatedPath` retains the historical treatment of empty or whitespace-only
components: they are skipped. For example, `""`, `" "` and `"."` select the root,
and `"a..b"` selects the same object as `"a.b"`. A real missing component still
fails extraction. Callers that require strict path syntax can validate the
components before calling `deserialize`; the Example designated-path page shows
that explicit validation alongside the legacy default.

## Integer conversion boundaries

The original numeric value must be within the target integer's range before
`.truncate` or `.rounded` applies. UInt8 rejects `"255.4"` and `"-0.4"` under all
policies, while `.rounded` accepts `"254.6"` as 255. Out-of-range input falls back
through the existing property/container recovery path. Range and rounding use
exact decimal digits, so a tiny fractional overflow at Int64/UInt64 boundaries is
also rejected; no intermediate Double may make it appear in range.

Numeric strings retain the historical hexadecimal forms accepted by the former
`Double(string)` bridge: `"0x10"` and `"0x1p4"` both decode as 16. The prefix is
case-insensitive, a sign and hexadecimal fraction are allowed, and `p`/`P` introduces
a signed decimal power of two. This bridge applies only to quoted strings, not
JSON number literals. Binary and octal prefixes (`"0b101"`, `"0o17"`) remain invalid.

Decimal conversion keeps its exact decimal algorithm. The hexadecimal bridge
also uses exact digits and checks the original value before truncation or rounding:
`"0xffffffffffffffff"` is UInt64.max, but `"0xffffffffffffffff.0001"` is out of range
under every policy. Historical floating-point precision loss is not restored.

## Compact array element acceptance

`@SmartCompact.Array` runs in `.legacy` mode by default. An element is appended
only when the bridged JSON value already matches the declared element type, so
`[1, "2", "x", null, 3.5, 4]` decodes as `[1, 4]` for `[Int]`, and `["YES", true]`
decodes as `[true]` for `[Bool]`. Invalid elements are skipped instead of being
replaced by a type default, which is the part of 7.0.1 behavior this option keeps.

Setting `SmartCodableOptions.compactElementStrategy = .convert` enables the
conversion domain: numeric and boolean strings are converted, `3.5` follows
`SmartCodableOptions.numberStrategy`, and plain `Codable` element types decode.
`SmartCodableX` model elements decode and run `didFinishMapping()` in both
modes; other `SmartDecodable` types decode only after opting into `.convert`.
`Optional` elements keep their own legacy path regardless of this option.

Encoding follows the same mode. Under `.legacy` every element is encoded through
the JSON-value bridge, so an element outside that bridge encodes as `null`
without invoking an unknown plain `Encodable`. Supported `SmartCodableX` models
still pass through their historical `toDictionary()` bridge, whose failure becomes
`null`; this differs from `@SmartAny`, where supported model errors propagate.
`.convert` encodes elements through their `Encodable` conformance and propagates
those errors. Keep this global option fixed while encoding or decoding; it is not
a per-call transaction.

## URL string decoding

`SmartURLTransformer` builds the URL from the decoded string first and only
applies percent-encoding when `URL(string:)` rejects the input. An
already-escaped string therefore keeps its escape (`a%20b` stays `a%20b`
instead of becoming `a%2520b`), and a `#` in the input starts a URL fragment
instead of remaining part of the path. Unicode, spaces and plain ASCII inputs
produce the same URL as before.

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
