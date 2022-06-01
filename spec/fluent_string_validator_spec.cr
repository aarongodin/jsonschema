require "./spec_helper"

f = JSONSchema.fluent

describe JSONSchema::Fluent do
  describe "#string" do
    context "given no block is passed" do
      it "creates a StringValidator" do
        f.string.should be_a(JSONSchema::StringValidator)
      end
    end

    context "given a block is passed" do
      it "creates a StringValidator with the specified options" do
        validator = f.string do
          min_length 1
          max_length 32
          pattern /^test/
          format "email"
        end

        validator.min_length.should eq(1)
        validator.max_length.should eq(32)
        validator.pattern.should be_a(Regex)
        validator.format.should eq("email")
      end
    end
  end
end
