require "json"

require "./validator"

module JSONSchema
  class GenericValidator
    # Serialize the validator into its string representation.
    #
    # ```
    # js = JSONSchema.fluent
    #
    # validator = js.generic do
    #   const "test"
    # end
    #
    # validator.to_json # => {"const":"test"}
    # ```
    def to_json(json : JSON::Builder)
      json.object do
        json.field "const", @const unless @const.nil?
        serialize_generic_fields(self, json)
      end
    end
  end

  class ObjectValidator
    # Serialize the validator into its string representation.
    #
    # ```
    # js = JSONSchema.fluent
    #
    # validator = js.object do
    #   prop "name", js.string
    # end
    #
    # validator.to_json # => {"type":"object","properties":{"name":{"type":"string"}}}
    # ```
    def to_json(json : JSON::Builder)
      json.object do
        json.field "type", "object"

        unless @properties.size == 0
          json.field "properties" do
            json.object do
              @properties.each { |prop, validator| json.field prop, validator }
            end
          end
        end

        unless @pattern_properties.size == 0
          json.field "patternProperties" do
            json.object do
              @pattern_properties.each { |prop, validator| json.field prop.source, validator }
            end
          end
        end

        if @has_disabled_additional_properties
          json.field "additionalProperties", false
        else
          unless @additional_properties.nil?
            json.field "additionalProperties", @additional_properties
          end
        end

        required = @required
        json.field "required", @required unless required.nil? || required.size == 0

        if @dependent_required.size > 0
          json.field "dependentRequired" do
            json.object do
              @dependent_required.each do |prop, props|
                json.field prop, props
              end
            end
          end
        end

        json.field "propertyNames", @property_names unless @property_names.nil?
        json.field "minProperties", @min_properties unless @min_properties.nil?
        json.field "maxProperties", @max_properties unless @max_properties.nil?

        serialize_generic_fields(self, json)
      end
    end
  end

  class ArrayValidator
    # Serialize the validator into its string representation.
    #
    # ```
    # js = JSONSchema.fluent
    #
    # validator = js.array do
    #   items js.string
    # end
    #
    # validator.to_json # => {"type":"array","items":{"type":"string"}}
    # ```
    def to_json(json : JSON::Builder)
      json.object do
        json.field "type", "array"
        if @has_disabled_additional_items
          json.field "items", false
        else
          json.field "items", @items unless @items.nil?
        end
        json.field "prefixItems", @prefix_items unless @prefix_items.size == 0
        json.field "contains", @contains unless @contains.nil?
        json.field "minContains", @min_contains unless @min_contains.nil?
        json.field "maxContains", @max_contains unless @max_contains.nil?
        json.field "minItems", @min_items unless @min_items.nil?
        json.field "maxItems", @max_items unless @max_items.nil?
        json.field "uniqueItems", true if @unique_items
        serialize_generic_fields(self, json)
      end
    end
  end

  class StringValidator
    # Serialize the validator into its string representation.
    #
    # ```
    # js = JSONSchema.fluent
    #
    # validator = js.string do
    #   min_length 10
    # end
    #
    # validator.to_json # => {"type":"string","minLength":10}
    # ```
    def to_json(json : JSON::Builder)
      json.object do
        json.field "type", "string"
        json.field "minLength", @min_length unless @min_length.nil?
        json.field "maxLength", @max_length unless @max_length.nil?
        pattern = @pattern
        json.field "pattern", pattern.source unless pattern.nil?
        json.field "format", @format unless @format.nil?
        serialize_generic_fields(self, json)
      end
    end
  end

  class NumberValidator
    # Serialize the validator into its string representation.
    #
    # ```
    # js = JSONSchema.fluent
    #
    # validator = js.integer do
    #   minimum 0
    # end
    #
    # validator.to_json # => {"type":"number","minimum":0}
    # ```
    def to_json(json : JSON::Builder)
      json.object do
        json.field "type", @has_integer_constraint ? "integer" : "number"
        json.field "multipleOf", @multiple_of unless @multiple_of.nil?
        json.field "minimum", @minimum unless @minimum.nil?
        json.field "maximum", @maximum unless @maximum.nil?
        json.field "exclusiveMinimum", @exclusive_minimum unless @exclusive_minimum.nil?
        json.field "exclusiveMaximum", @exclusive_maximum unless @exclusive_maximum.nil?
        serialize_generic_fields(self, json)
      end
    end
  end

  class NullValidator
    # Serialize the validator into its string representation.
    #
    # ```
    # js = JSONSchema.fluent
    # validator = js.null
    # validator.to_json # => {"type":"null"}
    # ```
    def to_json(json : JSON::Builder)
      json.object do
        json.field "type", "null"
      end
    end
  end

  class BooleanValidator
    # Serialize the validator into its string representation.
    #
    # ```
    # js = JSONSchema.fluent
    # validator = js.boolean
    # validator.to_json # => {"type":"boolean"}
    # ```
    def to_json(json : JSON::Builder)
      json.object do
        json.field "type", "boolean"
      end
    end
  end
end

private def serialize_generic_fields(validator, json)
  json.field "enum", validator.enum_list unless validator.enum_list.size == 0
  validator.composites.each do |c|
    json.field c.keyword, c.children
  end
end
