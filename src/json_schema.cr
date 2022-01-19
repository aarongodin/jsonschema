require "json"
require "./error"

module JSONSchema
  VERSION = "0.1.0"

  # Captures an error message and the corresponding path to the value where the error occurred.
  struct ValidationError
    property message : String
    property path : String

    def initialize(@message, @path)
    end
  end

  # Captures result of validation, including a status and any number of corresponding errors
  struct ValidationResult
    property status : Symbol
    property errors : Array(ValidationError) = [] of ValidationError

    def initialize(@status)
    end
  end

  # Alias type for any type of `Validator`. The top-level `Validator` returned from the macros
  # can be any one of the following.
  alias Validator = ObjectValidator |
    StringValidator |
    NumberValidator |
    NullValidator |
    BooleanValidator |
    ArrayValidator |
    CompositeValidator

  # Validates schema where the `type` is `object`.
  #
  # This is a raw `Validator` class that you most likely do not need to use directly.
  # See the `JSONSchema#create_validator` macro for common usage of this shard.
  class ObjectValidator
    property properties : Hash(String, Validator) = Hash(String, Validator).new
    property pattern_properties : Hash(Regex, Validator) = Hash(Regex, Validator).new
    property has_disabled_additional_properties = false
    property additional_properties : Validator?
    property required : Array(String)?
    property property_names : StringValidator?
    property min_properties : Int32?
    property max_properties : Int32?

    def validate(node : JSON::Any)
      true
    end
  end

  # Validates schema where the `type` is `array`.
  #
  # This is a raw `Validator` class that you most likely do not need to use directly.
  # See the `JSONSchema#create_validator` macro for common usage of this shard.
  class ArrayValidator
    property items : Validator?
    property prefix_items : Array(Validator)? = [] of Validator
    property has_disabled_additional_items = false
    property contains : Validator?
    property min_contains : Int32?
    property max_contains : Int32?
    property min_items : Int32?
    property max_items : Int32?
    property unique_items = false

  end

  # Validates schema where the `type` is `string`.
  #
  # This is a raw `Validator` class that you most likely do not need to use directly.
  # See the `JSONSchema#create_validator` macro for common usage of this shard.
  class StringValidator
    property min_length : Int32?
    property max_length : Int32?
    property pattern : Regex?
    property format : String?
  end

  # Validates schema where the `type` is `number` or `integer`.
  #
  # This is a raw `Validator` class that you most likely do not need to use directly.
  # See the `JSONSchema#create_validator` macro for common usage of this shard.
  class NumberValidator
    property has_integer_constraint = false
    property multiple_of : Int32?
    property minimum : Int32?
    property maximum : Int32?
    property exclusive_minimum : Int32?
    property exclusive_maximum : Int32?
  end

  # Validates schema where the `type` is `null`.
  #
  # This is a raw `Validator` class that you most likely do not need to use directly.
  # See the `JSONSchema#create_validator` macro for common usage of this shard.
  class NullValidator
  end

  # Validates schema where the `type` is `boolean`.
  #
  # This is a raw `Validator` class that you most likely do not need to use directly.
  # See the `JSONSchema#create_validator` macro for common usage of this shard.
  class BooleanValidator
  end

  # Validates schema that has any of the keywords for [composite/compound schema](https://json-schema.org/understanding-json-schema/reference/combining.html)
  # set as a property. The possible keywords are `allOf`, `anyOf`, `oneOf`, and `not`.
  #
  # This is a raw `Validator` class that you most likely do not need to use directly.
  # See the `JSONSchema#create_validator` macro for common usage of this shard.
  class CompositeValidator
    property keyword : String
    property children : Array(Validator)

    def initialize(@keyword, @children)
    end
  end

  # Generates code for a `Validator` object from the JSON schema in `filename`.
  #
  # ```
  # validator = JSONSchema.create_validator "my_schema.json"
  # ```
  macro create_validator(filename)
    {{ run("./process", filename) }}
  end

  # Generates code for defining a method that returns a `Validator` object from the JSON schema in `filename`.
  #
  # ```
  # class Body
  #   JSONSchema.create_validator_method "my_schema.json"
  # end
  #
  # b = Body.new
  # b.validator # => #<JSONSchema::ObjectValidator:...
  # ```
  macro create_validator_method(filename)
    def validator : JSONSchema::Validator
      {{ run("./process", filename) }}
    end
  end

  # Generates code for defining a method that returns a `Validator` object from the JSON schema in `filename`,
  # with a custom method name.
  #
  # ```
  # class Request
  #   JSONSchema.create_validator_method "request_schema.json", "request_body_validator"
  #   JSONSchema.create_validator_method "response_schema.json", "response_body_validator"
  # end
  # 
  # r = Request.new
  # 
  # r.request_body_validator # => #<JSONSchema::ObjectValidator:...
  # r.response_body_validator # => #<JSONSchema::ObjectValidator:...
  # ```
  macro create_validator_method(filename, method_name)
    def {{ method_name }} : JSONSchema::Validator
      {{ run("./process", filename) }}
    end
  end
end
