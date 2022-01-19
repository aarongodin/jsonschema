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
    property errors : Array(ValidationError)

    def initialize(@status, @errors = [] of ValidationError)
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

    def validate(node : JSON::Any, errors = [] of ValidationError)
      value = node.as_h rescue return ValidationResult.new(:error, [ValidationError.new("Expected value to be an object", "boop")])

      unless self.required.nil?
        self.required.as(Array(String)).each do |required_prop|
          errors.push(ValidationError.new("Expected required property #{required_prop} to be set", "boop")) unless value.has_key?(required_prop)
        end
      end

      unless self.property_names.nil?
        value.keys.each do |property_name|
          self.property_names.as(StringValidator).validate(JSON::Any.new(property_name), errors)
        end
      end

      unless self.min_properties.nil?
        unless value.keys.size >= self.min_properties.as(Int32)
          errors.push(ValidationError.new("Expected object to have at least #{self.min_properties} properties", "boop"))
        end
      end

      unless self.max_properties.nil?
        if value.keys.size > self.max_properties.as(Int32)
          errors.push(ValidationError.new("Expected object to have at most #{self.max_properties} properties", "boop"))
        end
      end
      
      self.properties.each do |property_name, property_validator|
        property_value = value[property_name]?

        unless property_value.nil?
          property_validator.validate(property_value, errors)
        end
      end

      if errors.size > 0
        return ValidationResult.new(:error, errors)
      end

      ValidationResult.new(:success)
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

    def validate(node : JSON::Any, errors = [] of ValidationError)
      ValidationResult.new(:success)
    end
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

    def validate(node : JSON::Any, errors = [] of ValidationError)
      validate(node.as_s, errors)
    end

    def validate(value : String, errors = [] of ValidationError)
      unless self.min_length.nil?
        if self.min_length.as(Int32) >= value.size
          errors.push(ValidationError.new("Expected string to have minLength #{self.min_length}", "boop"))
        end
      end

      unless self.max_length.nil?
        if value.size > self.max_length.as(Int32)
          errors.push(ValidationError.new("Expected string to have maxLength #{self.max_length}", "boop"))
        end
      end

      if errors.size > 0
        return ValidationResult.new(:error, errors)
      end

      ValidationResult.new(:success)
    end
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

    def validate(node : JSON::Any, errors = [] of ValidationError)
      validate(node.as_i, errors)
    end

    def validate(value : Int32 | Float, errors = [] of ValidationError)
      pp self
      unless self.minimum.nil?
        unless self.minimum.as(Int32) <= value
          errors.push(ValidationError.new("Expected numeric value be greater than or equal to #{self.minimum}", "boop"))
        end
      end

      unless self.maximum.nil?
        unless value <= self.maximum.as(Int32)
          errors.push(ValidationError.new("Expected numeric value be less than or equal to #{self.maximum}", "boop"))
        end
      end

      unless self.exclusive_minimum.nil?
        unless self.exclusive_minimum.as(Int32) < value
          errors.push(ValidationError.new("Expected numeric value be greater than #{self.exclusive_minimum}", "boop"))
        end
      end

      unless self.exclusive_maximum.nil?
        unless value < self.exclusive_maximum.as(Int32)
          errors.push(ValidationError.new("Expected numeric value be less than #{self.exclusive_maximum}", "boop"))
        end
      end

      if errors.size > 0
        return ValidationResult.new(:error, errors)
      end

      ValidationResult.new(:success)
    end
  end

  # Validates schema where the `type` is `null`.
  #
  # This is a raw `Validator` class that you most likely do not need to use directly.
  # See the `JSONSchema#create_validator` macro for common usage of this shard.
  class NullValidator
    def validate(node : JSON::Any, errors = [] of ValidationError)
      ValidationResult.new(:success)
    end
  end

  # Validates schema where the `type` is `boolean`.
  #
  # This is a raw `Validator` class that you most likely do not need to use directly.
  # See the `JSONSchema#create_validator` macro for common usage of this shard.
  class BooleanValidator
    def validate(node : JSON::Any, errors = [] of ValidationError)
      ValidationResult.new(:success)
    end
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

    def validate(node : JSON::Any, errors = [] of ValidationError)
      ValidationResult.new(:success)
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
