require "./define"
require "./validator"
require "./error"

module JSONSchema
  VERSION = "0.1.0"

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
  # r.request_body_validator  # => #<JSONSchema::ObjectValidator:...
  # r.response_body_validator # => #<JSONSchema::ObjectValidator:...
  # ```
  macro create_validator_method(filename, method_name)
    def {{ method_name }} : JSONSchema::Validator
      {{ run("./process", filename) }}
    end
  end

  # Generates a `Validator` object from the `JSON::Any` provided as input.
  # Raises if the schema is not created due to invalid schema.
  # To generate the schema at compile time, see the `JSONSchema#create_validator` macro.
  #
  # ```
  # schema = JSON.parse(%<{"type": "string"}>)
  # validator = JSONSchema::Runtime.create_validator schema
  # ```
  def self.from_json(node : JSON::Any) : Validator
    node.as_h rescue raise InvalidSchemaJSONError.new("root node must be an object")
    define_schema(node)
  end

  # Generates a `Validator` object from the `JSON::Any` provided as input.
  # Returns `nil` if a validator cannot be created from the input JSON.
  #
  # ```
  # schema = JSON.parse(%<{"type": "string"}>)
  # validator = JSONSchema::Runtime.create_validator schema
  # ```
  def self.from_json?(node : JSON::Any) : Validator?
    begin
      define_schema(node)
    rescue
      nil
    end
  end
end
