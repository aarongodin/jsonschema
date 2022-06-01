require "./spec_helper"

f = JSONSchema.fluent

describe JSONSchema::Fluent do
  describe "#object" do
    context "given no block is passed" do
      it "creates an ObjectValidator" do
        f.object.should be_a(JSONSchema::ObjectValidator)
      end
    end

    context "given a block is passed" do
      it "creates an ObjectValidator with the specified options" do
        validator = f.object do
          prop "name", f.string
          pattern_prop /^test/, f.number
          disable_additional_properties
          additional_properties f.string
          required "one", "two", "three"
          dependent_required({
            "creditCard" => ["billingAddress"],
          })
          dependent_required "couponCode", ["source"]
          property_names f.string { min_length 10 }
          min_properties 1
          max_properties 5
        end

        validator.should be_a(JSONSchema::ObjectValidator)
        validator.properties["name"].should be_a(JSONSchema::StringValidator)
        validator.pattern_properties.size.should eq(1)
        validator.has_disabled_additional_properties.should be_true
        validator.additional_properties.should be_a(JSONSchema::StringValidator)
        validator.required.should eq(["one", "two", "three"])
        validator.dependent_required["creditCard"].should eq(["billingAddress"])
        validator.dependent_required["couponCode"].should eq(["source"])
        validator.property_names.should be_a(JSONSchema::StringValidator)
        validator.min_properties.should eq(1)
        validator.max_properties.should eq(5)
      end
    end
  end
end
