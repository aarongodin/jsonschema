# json-schema-cr

A compile-time generator of [JSON Schema](https://json-schema.org/) validation for Crystal.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     json-schema-cr:
       github: aarongodin/json-schema-cr
   ```

2. Run `shards install`

## Overview

This library reads JSON files from your project **at compile time** and generates Crystal code to map a JSON Schema definition to a `Validator` object. The only runtime processing is to perform the runtime validation against any input JSON.

## Usage

There are a few macros you can use to interact with generating Validators:

### `create_validator(filename)`

This macro generates code and outputs a reference to a `JSONSchema::Validator` object. You can assign the value to a variable or use it any place an expression can be used.

```crystal
validator = JSONSchema.create_validator "my_schema.json"
```

### `create_validator_method(filename)`

Convenience macro for generating the schema and creating a method to access the validator.

```crystal
class Body
  JSONSchema.create_validator_method "my_schema.json"
end
```

This is syntactically equivalent to:

```crystal
class Body
  def validator : JSONSchema::Validator
    JSONSchema.create_validator "my_schema.json"
  end
end
```

### `create_validator_method(filename, method_name)`

Convenience macro similar to `create_validator_method(filename)` but for setting the method name.

```crystal
class Request
  JSONSchema.create_validator_method "request_schema.json", "request_body_validator"
  JSONSchema.create_validator_method "response_schema.json", "response_body_validator"
end

r = Request.new

r.request_body_validator # => #<JSONSchema::ObjectValidator:...
r.response_body_validator # => #<JSONSchema::ObjectValidator:...
```

## Features

### Core Types

All core types _are_ supported:

* `string`
* `number` and `integer`
* `array`
* `object`
* `null`
* `boolean`

### Composite Schema

Composite schemas using `anyOf`, `allOf`, `oneOf`, and `not` _are_ supported.

## Unsupported

These features of JSON Schema are not yet supported, but will be supported in a future release (at least before `1.0.0`).

* [References](https://json-schema.org/understanding-json-schema/structuring.html#ref)
* [Media Types](https://json-schema.org/understanding-json-schema/reference/non_json_data.html)

### Dialects

The latest revision of this module only supports the latest revision of JSON Schema (2020-12). There is not yet support for using a different dialect.

## Acknowledgements

The source for this module is heavily based on the `ECR` and `JSON` implementations from the std lib. Thanks to the Crystal team for creating an amazing standard library!