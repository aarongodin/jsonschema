require "benchmark"

require "../src/jsonschema"

basic_object = JSONSchema.create_validator("spec/fixtures/basic_object")
basic_string = JSONSchema.create_validator("spec/fixtures/basic_string")
object_properties = JSONSchema.create_validator("spec/fixtures/object_properties")
object_additional_properties_schema = JSONSchema.create_validator("spec/fixtures/object_additional_properties_schema")

object_fixture = JSON.parse(
  <<-JSON
    {
      "name": "Test"
    }
  JSON
)

string_fixture = JSON.parse(%{"test"})
number_fixture = JSON.parse("10")

object_properties_fixture = JSON.parse(
  <<-JSON
    {
      "schemaString": "Test",
      "schemaNumber": 22.5,
      "schemaInteger": 10,
      "schemaBoolean": true,
      "schemaNull": null
    }
  JSON
)
object_additional_properties_schema_fixture = JSON.parse(
  <<-JSON
    {
      "schemaString": "Test",
      "schemaAdditional": 100,
      "schemaAdditional2": "invalid"
    }
  JSON
)

Benchmark.ips do |x|
  x.report("basic_object") { basic_object.validate(object_fixture) }
  x.report("basic_string") { basic_string.validate(string_fixture) }
  x.report("basic_string_with_number") { basic_string.validate(number_fixture) }
  x.report("object_properties") { object_properties.validate(object_properties_fixture) }
  x.report("object_additional_properties_schema") { object_additional_properties_schema.validate(object_additional_properties_schema_fixture) }
end
