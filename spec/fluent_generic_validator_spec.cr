require "./spec_helper"

f = JSONSchema.fluent

describe JSONSchema::Fluent do
  describe "#generic" do
    it "creates a GenericValidator with the specified options" do
      validator = f.generic do
        const "something"
        enum_list "one", "two", "three"
      end

      validator.should be_a(JSONSchema::GenericValidator)
      validator.const.should eq("something")
      validator.enum_list.should eq(["one", "two", "three"])
    end
  end
end

describe JSONSchema::FluentValidatorGenericProperties do
  describe "#all_of" do
    it "sets the composite validator" do
      validator = f.object do
        any_of(
          f.string,
          f.number
        )
      end

      validator.should be_a(JSONSchema::ObjectValidator)
      validator.composites.size.should eq(1)
      validator.composites[0].keyword.should eq("anyOf")
      validator.composites[0].children[0].should be_a(JSONSchema::StringValidator)
      validator.composites[0].children[1].should be_a(JSONSchema::NumberValidator)
    end
  end
end
