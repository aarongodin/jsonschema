require "./spec_helper"

number_fixture = JSON.parse(%{100})
boolean_fixture = JSON.parse("true")
null_fixture = JSON.parse("null")
array_fixture = JSON.parse("[1,2,3]")
object_fixture = JSON.parse("{}")
string_fixture = JSON.parse(%{"test"})

describe JSONSchema::NumberValidator do
  describe "#validate" do
    context "given the null schema" do
      validator = JSONSchema.create_validator "spec/fixtures/basic_null"

      it "is successful for null" do
        assert_validation_success validator.validate(null_fixture)
      end

      it "has an error for any other value" do
        assert_validation_error validator.validate(number_fixture), "Expected value to be null"
        assert_validation_error validator.validate(boolean_fixture), "Expected value to be null"
        assert_validation_error validator.validate(array_fixture), "Expected value to be null"
        assert_validation_error validator.validate(object_fixture), "Expected value to be null"
        assert_validation_error validator.validate(string_fixture), "Expected value to be null"
      end
    end
  end
end