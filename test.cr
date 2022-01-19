require "json"
require "./src/json_schema"

class Body
  JSONSchema.create_validator_method "test.json"
end

b = Body.new

pp b.validator

object_val = JSON.parse({ "age" => 1000 }.to_json)

puts "Object:"
puts b.validator.validate(object_val)


# require "json"
# a = JSON.parse <<-JSON
# {
#   "firstName": "Aaron"
# }
# JSON

# pp typeof(a)
