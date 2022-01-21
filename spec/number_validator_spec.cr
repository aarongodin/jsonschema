require "./spec_helper"

boolean_fixture = JSON.parse("true")
null_fixture = JSON.parse("null")
array_fixture = JSON.parse("[1,2,3]")
object_fixture = JSON.parse("{}")
string_fixture = JSON.parse(%{"test"})

describe JSONSchema::NumberValidator do
  describe "#validate" do
    context "given the basic number schema" do
      validator = JSONSchema.create_validator "spec/fixtures/basic_number"

      it "is successful for all number values" do
        assert_validation_success validator.validate(JSON.parse(%{100}))
        assert_validation_success validator.validate(JSON.parse(%{100.123}))
        assert_validation_success validator.validate(JSON.parse(%{0}))
        assert_validation_success validator.validate(JSON.parse(%{-100}))
      end

      it "has an error for any other value" do
        assert_validation_error validator.validate(boolean_fixture), "Expected value to be a number"
        assert_validation_error validator.validate(null_fixture), "Expected value to be a number"
        assert_validation_error validator.validate(array_fixture), "Expected value to be a number"
        assert_validation_error validator.validate(object_fixture), "Expected value to be a number"
        assert_validation_error validator.validate(string_fixture), "Expected value to be a number"
      end
    end

    context "given the basic integer schema" do
      validator = JSONSchema.create_validator "spec/fixtures/basic_integer"

      it "is successful for integers" do
        assert_validation_success validator.validate(JSON.parse(%{100}))
        assert_validation_success validator.validate(JSON.parse(%{0}))
        assert_validation_success validator.validate(JSON.parse(%{-100}))
      end

      it "has an error for non-integer values" do
        assert_validation_error validator.validate(JSON.parse(%{10.123})), "Expected numeric value to be an integer"
        assert_validation_error validator.validate(JSON.parse(%{-100.123})), "Expected numeric value to be an integer"
        assert_validation_error validator.validate(boolean_fixture), "Expected value to be a number"
        assert_validation_error validator.validate(null_fixture), "Expected value to be a number"
        assert_validation_error validator.validate(array_fixture), "Expected value to be a number"
        assert_validation_error validator.validate(object_fixture), "Expected value to be a number"
        assert_validation_error validator.validate(string_fixture), "Expected value to be a number"
      end
    end

    context "given the multipleOf constraint is set" do
      validator = JSONSchema.create_validator "spec/fixtures/integer_multiple_of"

      it "is successful for multiples of 10" do
        assert_validation_success validator.validate(JSON.parse(%{10}))
        assert_validation_success validator.validate(JSON.parse(%{100}))
        assert_validation_success validator.validate(JSON.parse(%{0}))
      end

      it "has an error for not multiples of 10" do
        assert_validation_error validator.validate(JSON.parse(%{5})), "Expected numeric value to be multiple of 10"
        assert_validation_error validator.validate(JSON.parse(%{55})), "Expected numeric value to be multiple of 10"
      end
    end

    context "given the range constraints are set (inclusive)" do
      validator = JSONSchema.create_validator "spec/fixtures/number_range"

      it "is successful for numbers in the range (inclusive)" do
        assert_validation_success validator.validate(JSON.parse(%{0}))
        assert_validation_success validator.validate(JSON.parse(%{100}))
        assert_validation_success validator.validate(JSON.parse(%{50}))
      end

      it "has an error for numbers not in the range" do
        assert_validation_error validator.validate(JSON.parse(%{-1})), "Expected numeric value be greater than or equal to 0"
        assert_validation_error validator.validate(JSON.parse(%{101})), "Expected numeric value be less than or equal to 100"
      end
    end

    context "given the exclusive range constraints are set" do
      validator = JSONSchema.create_validator "spec/fixtures/number_range_exclusive"

      it "is successful for numbers in the range (exclusive)" do
        assert_validation_success validator.validate(JSON.parse(%{1}))
        assert_validation_success validator.validate(JSON.parse(%{99}))
        assert_validation_success validator.validate(JSON.parse(%{50}))
      end

      it "has an error for numbers not in the range" do
        assert_validation_error validator.validate(JSON.parse(%{0})), "Expected numeric value be greater than 0"
        assert_validation_error validator.validate(JSON.parse(%{100})), "Expected numeric value be less than 100"
      end
    end
  end
end