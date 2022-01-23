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

describe JSONSchema::ArrayValidator do
  describe "#validate" do
    context "given the basic schema" do
      validator = JSONSchema.create_validator "spec/fixtures/basic_array"

      it "is successful for any objects" do
        assert_validation_success validator.validate(array_fixture)
      end

      it "has an error for any non-object" do
        assert_validation_error validator.validate(number_fixture), "Expected value to be an array"
        assert_validation_error validator.validate(boolean_fixture), "Expected value to be an array"
        assert_validation_error validator.validate(null_fixture), "Expected value to be an array"
        assert_validation_error validator.validate(object_fixture), "Expected value to be an array"
        assert_validation_error validator.validate(string_fixture), "Expected value to be an array"
      end
    end

    context "given an items validator is set" do
      validator = JSONSchema.create_validator "spec/fixtures/array_items"

      it "is successful for an array of items matching the schema" do
        assert_validation_success validator.validate(JSON.parse(%{["red", "yellow", "blue"]}))
      end

      it "has an error for items that do not match the schema" do
        assert_validation_error validator.validate(JSON.parse(%{[1]})), "Expected value to be a string"
        assert_validation_error validator.validate(JSON.parse(%{[true]})), "Expected value to be a string"
        assert_validation_error validator.validate(JSON.parse(%{[null]})), "Expected value to be a string"
        assert_validation_error validator.validate(JSON.parse(%{[{}]})), "Expected value to be a string"
      end
    end

    context "given prefix_items is set" do
      validator = JSONSchema.create_validator "spec/fixtures/array_prefix_items"

      it "is successful for any array of items matching the schema" do
        assert_validation_success validator.validate(JSON.parse(%{["red", 1, true]}))
        assert_validation_success validator.validate(JSON.parse(%{["red", 1, true, 2, 3]}))
      end

      it "has an error for items that do not match the schema" do
        assert_validation_errors validator.validate(JSON.parse(%{[1, "green", null]})), [
          "Expected value to be a string",
          "Expected value to be a number",
          "Expected value to be a boolean",
        ]
      end
    end

    context "given prefix_items is set and items is set to false" do
      validator = JSONSchema.create_validator "spec/fixtures/array_prefix_items_tuple"

      it "is successful with a matching tuple" do
        assert_validation_success validator.validate(JSON.parse(%{["red", 1, true]}))
      end

      it "has an error for extra items" do
        assert_validation_error validator.validate(JSON.parse(%{["red", 1, true, 2, 3]})), "Expected array to be tuple of length 3"
      end
    end

    context "given contains is set with no range limits" do
      validator = JSONSchema.create_validator "spec/fixtures/array_contains"

      it "is successful with an item that matches the contains schema" do
        assert_validation_success validator.validate(JSON.parse(%{[0, 50, 100]}))
      end

      it "has an error with an array that does not contain a matching item" do
        assert_validation_error validator.validate(JSON.parse(%{[1,2,3,4]})), "Expected array to contain at least 1 matched item"
      end
    end

    context "given contains is set with a range limit on minimum and maximum" do
      validator = JSONSchema.create_validator "spec/fixtures/array_contains_with_range_limits"

      it "is successful with an inclusive number of matched items based on the range" do
        assert_validation_success validator.validate(JSON.parse(%{[5,10,15]}))
        assert_validation_success validator.validate(JSON.parse(%{[5,10,15,20]}))
        assert_validation_success validator.validate(JSON.parse(%{[5,10,15,20,25]}))
      end

      it "has an error when the matched items is outside the range" do
        assert_validation_error validator.validate(JSON.parse(%{[5,10]})), "Expected array to contain at least 3 matched items"
        assert_validation_error validator.validate(JSON.parse(%{[5,10,15,20,25,30]})), "Expected array to contain at most 5 matched items"
      end
    end

    context "given item limits are set" do
      validator = JSONSchema.create_validator "spec/fixtures/array_item_range_limits"

      it "is successful with an inclusive number of items based on the range" do
        assert_validation_success validator.validate(JSON.parse(%{[1,2,3]}))
        assert_validation_success validator.validate(JSON.parse(%{[1,2,3,4]}))
        assert_validation_success validator.validate(JSON.parse(%{[1,2,3,4,5]}))
      end

      it "has an error when the items count is outside the range" do
        assert_validation_error validator.validate(JSON.parse(%{[1,2]})), "Expected array length to be at least 3"
        assert_validation_error validator.validate(JSON.parse(%{[1,2,3,4,5,6]})), "Expected array length to be at most 5"
      end
    end

    context "given the unique constraint is set" do
      validator = JSONSchema.create_validator "spec/fixtures/array_unique_items"

      it "is successful with an array of unique items" do
        assert_validation_success validator.validate(JSON.parse(%{[1, 2, 3]}))
        assert_validation_success validator.validate(JSON.parse(%{["test", "with", "strings"]}))
        assert_validation_success validator.validate(JSON.parse(%{[["first-array"], ["second-array"]]}))
        assert_validation_success validator.validate(JSON.parse(%{[
          { "object1": "test1" },
          { "object2": "test2"}
        ]}))
      end

      it "has an error with an array with duplicate items" do
        assert_validation_error validator.validate(JSON.parse(%{[1,1,2,3]})), "Expected array items to be unique"
        assert_validation_error validator.validate(JSON.parse(%{["test", "with", "test"]})), "Expected array items to be unique"
        assert_validation_error validator.validate(JSON.parse(%{[["first-array"], ["first-array"]]})), "Expected array items to be unique"
        assert_validation_error validator.validate(JSON.parse(%{[
          { "object1": "test1" },
          { "object1": "test1"}
        ]})), "Expected array items to be unique"
      end
    end
  end
end
