require "./spec_helper"

private class BasicString
  JSONSchema.create_validator_method("spec/fixtures/basic_string.json")
end

describe JSONSchema do
  describe "#create_validator" do
    it "outputs a JSONSchema::Validator" do
      JSONSchema.create_validator("spec/fixtures/basic_string.json").should be_a(JSONSchema::StringValidator)
      JSONSchema.create_validator("spec/fixtures/basic_number.json").should be_a(JSONSchema::NumberValidator)
      JSONSchema.create_validator("spec/fixtures/basic_object.json").should be_a(JSONSchema::ObjectValidator)
      JSONSchema.create_validator("spec/fixtures/basic_array.json").should be_a(JSONSchema::ArrayValidator)
      JSONSchema.create_validator("spec/fixtures/basic_boolean.json").should be_a(JSONSchema::BooleanValidator)
      JSONSchema.create_validator("spec/fixtures/basic_null.json").should be_a(JSONSchema::NullValidator)
    end
  end

  describe "#create_validator_method" do
    it "creates a method named validator" do
      t = BasicString.new
      t.responds_to?(:validator).should be_true
    end
  end
end
