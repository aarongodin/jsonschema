require "./spec_helper"

nested_context_fixture = JSONSchema::NodeContext.new(
  ".nested2",
  JSONSchema::NodeContext.new(
    "[2]",
    JSONSchema::NodeContext.new(
      "nested1",
      JSONSchema::NodeContext.new
    )
  )
)

describe JSONSchema::NodeContext do
  describe "#to_s" do
    context "given a root node" do
      it "creates the root string" do
        JSONSchema::NodeContext.new.to_s.should eq(".")
      end
    end

    context "given a nested object node" do
      it "creates the nested string" do
        JSONSchema::NodeContext.new(
          ".nested2",
          JSONSchema::NodeContext.new(
            "nested1",
            JSONSchema::NodeContext.new
          )
        ).to_s.should eq(".nested1.nested2")
      end
    end

    context "given a root level array" do
      it "creates the root string" do
        JSONSchema::NodeContext.new("[2]").to_s.should eq("[2]")
      end
    end

    context "given a nested object and array structure" do
      it "creates the string" do
        nested_context_fixture.to_s.should eq(".nested1[2].nested2")
      end
    end
  end

  describe "#dig_into" do
    context "given a root node context" do
      it "raises" do
        expect_raises(Exception, "Cannot dig beyond root node context") do
          JSONSchema::NodeContext.new.dig_into(JSON.parse(%{"something"}))
        end
      end
    end

    context "given a nested node context" do
      nested_context_fixture.dig_into(JSON.parse(%{
        {
          "nested1": [
            {"test1": "test"},
            {"test2": "test"},
            {"nested2": "TEST!"}
          ]
        }
      })).should eq(JSON::Any.new("TEST!"))
    end
  end
end