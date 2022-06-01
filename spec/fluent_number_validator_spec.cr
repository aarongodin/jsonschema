require "./spec_helper"

f = JSONSchema.fluent

describe JSONSchema::Fluent do
  describe "#number" do
    context "given no block is passed" do
      it "creates a NumberValidator" do
        f.number.should be_a(JSONSchema::NumberValidator)
      end
    end

    context "given a block is passed" do
      it "creates a NumberValidator with the specified options" do
        validator = f.number do
          multiple_of 5
          minimum 10
          maximum 100
          exclusive_minimum 9
          exclusive_maximum 101
        end

        validator.multiple_of.should eq(5)
        validator.minimum.should eq(10)
        validator.maximum.should eq(100)
        validator.exclusive_minimum.should eq(9)
        validator.exclusive_maximum.should eq(101)
      end
    end
  end

  describe "#integer" do
    it "creates a NumberValidator with the integer constraint" do
      validator = f.integer
      validator.should be_a(JSONSchema::NumberValidator)
      validator.has_integer_constraint.should be_true
    end
  end
end
