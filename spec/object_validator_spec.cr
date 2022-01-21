require "./spec_helper"

number_fixture = JSON.parse("10")
boolean_fixture = JSON.parse("true")
null_fixture = JSON.parse("null")
array_fixture = JSON.parse("[1,2,3]")
string_fixture = JSON.parse(%{"test"})

object_fixture = JSON.parse(
  <<-JSON
    {
      "name": "Test"
    }
  JSON
)

object_empty = JSON.parse("{}")

object_properties = JSON.parse(
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

object_properties_invalid = JSON.parse(
  <<-JSON
    {
      "schemaString": 100,
      "schemaNumber": "100",
      "schemaInteger": 100.1,
      "schemaBoolean": "true",
      "schemaNull": "null"
    }
  JSON
)

object_pattern_properties = JSON.parse(
  <<-JSON
    {
      "test1value": "Test",
      "test2value": 100.1,
      "test3value": 100,
      "test4value": true,
      "test5value": null
    }
  JSON
)

object_pattern_properties_invalid = JSON.parse(
  <<-JSON
    {
      "test1value": 100,
      "test2value": "100",
      "test3value": 100.1,
      "test4value": "true",
      "test5value": "null"
    }
  JSON
)

object_additional_properties_disabled = JSON.parse(
  <<-JSON
    {
      "schemaString": "Test"
    }
  JSON
)

object_additional_properties_schema = JSON.parse(
  <<-JSON
    {
      "schemaString": "Test",
      "schemaAdditional": 100
    }
  JSON
)

object_additional_properties_schema_invalid = JSON.parse(
  <<-JSON
    {
      "schemaString": "Test",
      "schemaAdditional": "100"
    }
  JSON
)

object_required = JSON.parse(
  <<-JSON
    {
      "schema1": "Test",
      "schema2": "Test"
    }
  JSON
)

object_required_invalid = JSON.parse(
  <<-JSON
    {
      "schema1": "Test"
    }
  JSON
)

object_property_names = JSON.parse(
  <<-JSON
    {
      "test1": "Test",
      "test2": "Test"
    }
  JSON
)

object_property_names_invalid = JSON.parse(
  <<-JSON
    {
      "test1": "Test",
      "invalid": "Test"
    }
  JSON
)

object_property_limits_invalid_maximum = JSON.parse(
  <<-JSON
    {
      "test1": "test",
      "test2": "test",
      "test3": "test",
      "test4": "test"
    }
  JSON
)

describe JSONSchema::ObjectValidator do
  describe "#validate" do
    context "given the basic schema" do
      validator = JSONSchema.create_validator "spec/fixtures/basic_object"

      it "is successful for any objects" do
        assert_validation_success validator.validate(object_fixture)
      end

      it "has an error for any non-object" do
        assert_validation_error validator.validate(number_fixture), "Expected value to be an object"
        assert_validation_error validator.validate(boolean_fixture), "Expected value to be an object"
        assert_validation_error validator.validate(null_fixture), "Expected value to be an object"
        assert_validation_error validator.validate(array_fixture), "Expected value to be an object"
        assert_validation_error validator.validate(string_fixture), "Expected value to be an object"
      end
    end

    context "given a schema with properties" do
      validator = JSONSchema.create_validator "spec/fixtures/object_properties"

      it "is successful for valid input against all properties" do
        assert_validation_success validator.validate(object_properties)
      end

      it "has an error for any property schemas that receive invalid input" do
        assert_validation_errors validator.validate(object_properties_invalid), [
          "Expected value to be a string",
          "Expected value to be a number",
          "Expected numeric value to be an integer",
          "Expected value to be a boolean",
          "Expected value to be null",
        ]
      end
    end

    context "given a schema with patternProperties" do
      validator = JSONSchema.create_validator "spec/fixtures/object_pattern_properties"

      it "is successful for valid input against all pattern properties" do
        assert_validation_success validator.validate(object_pattern_properties)
      end

      it "has an error for any property schemas that receive invalid input" do
        assert_validation_errors validator.validate(object_pattern_properties_invalid), [
          "Expected value to be a string",
          "Expected value to be a number",
          "Expected numeric value to be an integer",
          "Expected value to be a boolean",
          "Expected value to be null",
        ]
      end
    end

    context "given additionalProperties are disabled" do
      validator = JSONSchema.create_validator "spec/fixtures/object_additional_properties_disabled"

      it "is successful for valid input with no additional properties" do
        assert_validation_success validator.validate(object_additional_properties_disabled)
      end

      it "has an error if there are additional properties" do
        assert_validation_error validator.validate(object_fixture), "Expected object not to have additional properties"
      end
    end

    context "given additionalProperties is a schema" do
      validator = JSONSchema.create_validator "spec/fixtures/object_additional_properties_schema"

      it "is successful for valid input" do
        assert_validation_success validator.validate(object_additional_properties_schema)
      end

      it "has an error if the additional properties do not match the schema" do
        assert_validation_error validator.validate(object_additional_properties_schema_invalid), "Expected value to be a number"
      end
    end

    context "given requird properties array is set" do
      validator = JSONSchema.create_validator "spec/fixtures/object_required"

      it "is successful for valid input" do
        assert_validation_success validator.validate(object_required)
      end

      it "has an error if the required properties are not present" do
        assert_validation_error validator.validate(object_required_invalid), "Expected required property schema2 to be set"
      end
    end

    context "given a propertyNames schema is set" do
      validator = JSONSchema.create_validator "spec/fixtures/object_property_names"

      it "is successful for valid input" do
        assert_validation_success validator.validate(object_property_names)
      end

      it "has an error if the property names do not match the string schema" do
        assert_validation_error validator.validate(object_property_names_invalid), "Expected string to match pattern /^test/"
      end
    end

    context "given property limits are set" do
      validator = JSONSchema.create_validator "spec/fixtures/object_property_limits"

      it "is successful for valid input" do
        assert_validation_success validator.validate(object_fixture)
      end

      it "has an error if the object does not have the minimum number of properties" do
        assert_validation_error validator.validate(object_empty), "Expected object to have at least 1 properties"
      end

      it "has an error if the object does not have the maximum number of properties" do
        assert_validation_error validator.validate(object_property_limits_invalid_maximum), "Expected object to have at most 3 properties"
      end
    end
  end
end
