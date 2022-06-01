require "./spec_helper"

f = JSONSchema.fluent

describe JSONSchema::Fluent do
  describe "#array" do
    context "given no block is passed" do
      it "creates an ObjectValidator" do
        f.array.should be_a(JSONSchema::ArrayValidator)
      end
    end

    context "given a block is passed" do
      it "creates an ArrayValidator with the specified options" do
        validator = f.array do
          items f.string
          prefix_items f.number, f.string
          disable_additional_items
          contains f.string { format "email" }
          min_contains 1
          max_contains 10
          min_items 0
          max_items 100
          unique_items
        end

        validator.items.should be_a(JSONSchema::StringValidator)
        validator.prefix_items.size.should eq(2)
        validator.has_disabled_additional_items.should be_true
        validator.contains.should be_a(JSONSchema::StringValidator)
        validator.min_contains.should eq(1)
        validator.max_contains.should eq(10)
        validator.min_items.should eq(0)
        validator.max_items.should eq(100)
        validator.unique_items.should be_true
      end
    end
  end
end
