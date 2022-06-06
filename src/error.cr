require "./i18n"

module JSONSchema
  # Exception thrown at compile-time for any invalid schema. A schema may be invalid if the file cannot be read,
  # the JSON string in the file is not valid JSON (cannot be parsed), or if the resulting JSON has invalid
  # definitions for JSON Schema. Compile-time checks will throw this error if your schema cannot be turned into valid Crystal code,
  # or to protect your application from runtime errors related to a schema that would not make logical sense.
  class InvalidSchemaError < Exception
    def initialize(message : String?, cause : Exception?, filename : String?)
      full_msg = "jsonschema: #{JSONSchema.i18n.get(2, filename)}:\n\t#{message}"
      super(full_msg, cause)
    end
  end

  # Exception thrown at runtime for any invalid schema. A runtime schema can be invalid
  # given the JSON does not describe a valid JSON Schema.
  class InvalidSchemaJSONError < Exception
  end
end
