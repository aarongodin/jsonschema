require "./spec_helper"

describe JSONSchema::GenericValidator do
  describe "#validate" do
    context "given enum array has numbers" do
      validator = JSONSchema.create_validator "spec/fixtures/generic_enum_numbers"

      it "is successful when passed a matching number" do
        assert_validation_success validator.validate(JSON.parse(%{1}))
        assert_validation_success validator.validate(JSON.parse(%{0.123}))
      end

      it "has an error when passed a non-matching number or other value" do
        assert_validation_error validator.validate(JSON.parse(%{5})), "Expected value to be equal to the enum"
        assert_validation_error validator.validate(JSON.parse(%{"Test"})), "Expected value to be equal to the enum"
        assert_validation_error validator.validate(JSON.parse(%{{"test": "testing"}})), "Expected value to be equal to the enum"
        assert_validation_error validator.validate(JSON.parse(%{[1,2,3]})), "Expected value to be equal to the enum"
      end
    end

    context "given enum array has strings" do
      validator = JSONSchema.create_validator "spec/fixtures/generic_enum_strings"

      it "is successful when passed a matching string" do
        assert_validation_success validator.validate(JSON.parse(%{"red"}))
      end

      it "has an error when passed a non-matching string or other value" do
        assert_validation_error validator.validate(JSON.parse(%{5})), "Expected value to be equal to the enum"
        assert_validation_error validator.validate(JSON.parse(%{"purple"})), "Expected value to be equal to the enum"
        assert_validation_error validator.validate(JSON.parse(%{{"test": "testing"}})), "Expected value to be equal to the enum"
        assert_validation_error validator.validate(JSON.parse(%{[1,2,3]})), "Expected value to be equal to the enum"
      end

      it "has an error with the correct root context" do
        assert_validation_error_context validator.validate(JSON.parse(%{5})), "."
      end
    end

    context "given a const value is set" do
      validator = JSONSchema.create_validator "spec/fixtures/generic_const"

      it "is successful when passed an equal value" do
        assert_validation_success validator.validate(JSON.parse(%{"testing"}))
      end

      it "has an error when passed an inequal value" do
        assert_validation_error validator.validate(JSON.parse(%{5})), "Expected value to be testing"
        assert_validation_error validator.validate(JSON.parse(%{"purple"})), "Expected value to be testing"
      end

      it "has an error with the correct root context" do
        assert_validation_error_context validator.validate(JSON.parse(%{5})), "."
      end
    end
  end
end
