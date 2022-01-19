module JSONSchema
  # Exception thrown at compile-time for any invalid schema. A schema may be invalid if the file cannot be read,
  # the JSON string in the file is not valid JSON (cannot be parsed), or if the resulting JSON has invalid 
  # definitions for JSON Schema. Compile-time checks will throw this error if your schema cannot be turned into valid Crystal code,
  # or to protect your application from runtime errors related to a schema that would not make logical sense.
  class InvalidSchemaError < Exception
    def initialize(message : String?, cause : Exception?, filename : String?)
      full_msg = String.build do |str|
        str << "json-schema: Could not get a valid JSON Schema from \"#{filename}\":\n"
        str << "\t#{message}"
      end

      super(full_msg, cause)
    end
  end
end