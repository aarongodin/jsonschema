require "./src/json_schema"

class Body
  JSONSchema.create_validator_method "test.json"
end

b = Body.new

pp b.validator


# require "json"
# a = JSON.parse <<-JSON
# {
#   "firstName": "Aaron"
# }
# JSON

# pp typeof(a)
