require "./spec_helper"

number_fixture = JSON.parse(%{100})
boolean_true_fixture = JSON.parse("true")
boolean_false_fixture = JSON.parse("false")
null_fixture = JSON.parse("null")
array_fixture = JSON.parse("[1,2,3]")
object_fixture = JSON.parse("{}")
string_fixture = JSON.parse(%{"test"})

describe JSONSchema::NumberValidator do
  describe "#validate" do
    context "given the null schema" do
      validator = JSONSchema.create_validator "spec/fixtures/basic_boolean"

      it "is successful for boolean values" do
        assert_validation_success validator.validate(boolean_true_fixture)
        assert_validation_success validator.validate(boolean_false_fixture)
      end

      it "has an error for any other value" do
        assert_validation_error validator.validate(number_fixture), "Expected value to be a boolean"
        assert_validation_error validator.validate(null_fixture), "Expected value to be a boolean"
        assert_validation_error validator.validate(array_fixture), "Expected value to be a boolean"
        assert_validation_error validator.validate(object_fixture), "Expected value to be a boolean"
        assert_validation_error validator.validate(string_fixture), "Expected value to be a boolean"
      end
    end
  end
end
