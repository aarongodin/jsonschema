require "./spec_helper"

number_fixture = JSON.parse("10")
boolean_fixture = JSON.parse("true")
null_fixture = JSON.parse("null")
array_fixture = JSON.parse("[1,2,3]")
object_fixture = JSON.parse("{}")
string_fixture = JSON.parse(%{"test"})

describe JSONSchema::StringValidator do
  describe "#validate" do
    context "given the basic schema" do
      validator = JSONSchema.create_validator "spec/fixtures/basic_string"

      it "is successful for any string" do
        assert_validation_success validator.validate(string_fixture)
      end

      it "has an error for any other type" do
        assert_validation_error validator.validate(number_fixture), "Expected value to be a string"
        assert_validation_error validator.validate(boolean_fixture), "Expected value to be a string"
        assert_validation_error validator.validate(null_fixture), "Expected value to be a string"
        assert_validation_error validator.validate(array_fixture), "Expected value to be a string"
        assert_validation_error validator.validate(object_fixture), "Expected value to be a string"
      end
    end

    context "given length constraints are set" do
      validator = JSONSchema.create_validator "spec/fixtures/string_length"

      it "is successful for strings of correct length" do
        assert_validation_success validator.validate(JSON.parse(%{"tests"}))
        assert_validation_success validator.validate(JSON.parse(%{"testing"}))
        assert_validation_success validator.validate(JSON.parse(%{"_testtest_"}))
      end

      it "has errors for strings of invalid length" do
        assert_validation_error validator.validate(JSON.parse(%{"test"})), "Expected string to have a minimum length of 5"
        assert_validation_error validator.validate(JSON.parse(%{"really long string"})), "Expected string to have a maximum length of 10"
      end
    end

    context "given a pattern is set" do
      validator = JSONSchema.create_validator "spec/fixtures/string_pattern"

      it "is successful for strings that match the Regex" do
        assert_validation_success validator.validate(JSON.parse(%{"testing"}))
      end

      it "has an error for strings that do not match the Regex" do
        assert_validation_error validator.validate(JSON.parse(%{"test"})), "Expected string to match pattern /ing$/"
      end
    end

    # This test only covers "date-time" format, but the unlderlying formats are all regular expressions
    context "given a format is set" do
      validator = JSONSchema.create_validator "spec/fixtures/string_format"

      it "is successful for strings that match the format" do
        assert_validation_success validator.validate(JSON.parse(%{"2018-11-13T20:20:39+00:00"}))
      end

      it "has an error when the string does not match the format" do
        assert_validation_error validator.validate(JSON.parse(%{"test"})), %{Expected string to match format "date-time"}
      end
    end
  end
end
