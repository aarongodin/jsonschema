require "./spec_helper"

js = JSONSchema.fluent

STATES = {"AL", "AK", "AZ", "AR"}

describe JSONSchema::Validator do
  describe "#to_json" do
    it "serizlies the validators" do
      validator = js.object do
        prop "name", (js.string do
          min_length 2
          max_length 64
        end)

        prop "age", js.integer
        prop "likes", (js.array {
          min_items 3
          max_items 50
          items js.string { min_length 3 }
          unique_items
        })

        prop "is_registered", js.boolean
        prop "address", (js.generic {
          any_of(
            js.object {
              prop "street", js.string
              prop "city", js.string
              prop "state", js.generic { enum_list *STATES }
              prop "zipcode", js.string
            },
            js.null
          )
        })
      end

      validator.to_json.should eq(File.read("spec/fixtures/serialize_result.json"))
    end
  end
end
