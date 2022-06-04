require "json"

require "./validator"

private COMPOSITE_KEYS = ["allOf", "anyOf", "oneOf", "not"]
private GENERIC_KEYS   = COMPOSITE_KEYS + ["enum", "const"]

module JSONSchema
  extend self

  private def define_schema(node : JSON::Any)
    schema = node.as_h

    case schema["type"]?
    when "object"
      return define_object_validator(schema)
    when "array"
      return define_array_validator(schema)
    when "string"
      return define_string_validator(schema)
    when "number"
      return define_number_validator(schema)
    when "integer"
      return define_number_validator(schema, true)
    when "null"
      return NullValidator.new
    when "boolean"
      return BooleanValidator.new
    else
      if is_generic_schema(schema)
        return define_generic_validator(schema)
      end

      raise "Schema did not provide any known constraints"
    end
  end

  private def is_generic_schema(schema : Hash(String, JSON::Any))
    (schema.keys & (GENERIC_KEYS)).size > 0
  end

  private def define_object_validator(schema : Hash(String, JSON::Any)) : ObjectValidator
    if (schema["additionalProperties"]? == false && !schema["properties"])
      raise %{Expected "object" schema to define "properties" when "additionalProperties" is false}
    end

    v = ObjectValidator.new
    v.has_disabled_additional_properties = schema["additionalProperties"]? == false

    if schema.has_key?("minProperties")
      v.min_properties = schema["minProperties"].as_i?
    end

    if schema.has_key?("maxProperties")
      v.max_properties = schema["maxProperties"].as_i?
    end

    if schema.has_key?("required")
      v.required = schema["required"].as_a.map &.as_s
    end

    if schema.has_key?("propertyNames")
      v.property_names = define_string_validator(schema["propertyNames"].as_h)
    end

    if (schema.has_key?("additionalProperties") && !schema["additionalProperties"].as_h?.nil?)
      v.additional_properties = define_schema(schema["additionalProperties"])
    end

    if schema.has_key?("dependentRequired")
      schema["dependentRequired"].as_h.each do |prop_name, required_list|
        v.dependent_required[prop_name] = required_list.as_a.map &.as_s
      end
    end

    if schema.has_key?("properties")
      schema["properties"].as_h.each do |prop_name, prop|
        v.properties[prop_name] = define_schema(prop)
      end
    end

    if schema.has_key?("patternProperties")
      schema["patternProperties"].as_h.each do |prop_regex, prop|
        v.pattern_properties[Regex.new(prop_regex)] = define_schema(prop)
      end
    end

    if schema.has_key?("enum")
      v.enum_list = schema["enum"].as_a
    end

    v.composites = define_composite_validators(schema)
    return v
  end

  private def define_array_validator(schema : Hash(String, JSON::Any))
    v = ArrayValidator.new

    v.min_contains = schema.has_key?("minContains") ? schema["minContains"].as_i : nil
    v.max_contains = schema.has_key?("maxContains") ? schema["maxContains"].as_i : nil
    v.min_items = schema.has_key?("minItems") ? schema["minItems"].as_i : nil
    v.max_items = schema.has_key?("maxItems") ? schema["maxItems"].as_i : nil
    v.unique_items = schema.has_key?("uniqueItems") ? schema["uniqueItems"].as_bool : false

    if schema.has_key?("contains")
      v.contains = define_schema(schema["contains"])
    end

    if schema.has_key?("items")
      if schema.has_key?("prefixItems")
        items_value = schema["items"].as_bool rescue nil
        if items_value == false
          v.has_disabled_additional_items = true
        end
      else
        v.items = define_schema(schema["items"])
      end
    end

    if schema.has_key?("prefixItems")
      schema["prefixItems"].as_a.each do |item|
        v.prefix_items << define_schema(item)
      end
    end

    if schema.has_key?("enum")
      v.enum_list = schema["enum"].as_a
    end

    v.composites = define_composite_validators(schema)
    return v
  end

  private def define_string_validator(schema : Hash(String, JSON::Any))
    v = StringValidator.new

    if schema.has_key?("minLength")
      v.min_length = schema["minLength"].as_i
    end

    if schema.has_key?("maxLength")
      v.max_length = schema["maxLength"].as_i
    end

    if schema.has_key?("pattern")
      value = schema["pattern"].as_s?
      unless value.nil?
        v.pattern = Regex.new(value)
      end
    end

    if schema.has_key?("format")
      v.format = schema["format"].as?(String)
    end

    if schema.has_key?("enum")
      v.enum_list = schema["enum"].as_a
    end

    v.composites = define_composite_validators(schema)
    return v
  end

  private def define_number_validator(schema : Hash(String, JSON::Any), has_integer_constraint = false)
    v = NumberValidator.new
    v.has_integer_constraint = has_integer_constraint
    v.multiple_of = schema.has_key?("multipleOf") ? schema["multipleOf"].as_i : nil
    v.minimum = schema.has_key?("minimum") ? schema["minimum"].as_i : nil
    v.maximum = schema.has_key?("maximum") ? schema["maximum"].as_i : nil
    v.exclusive_minimum = schema.has_key?("exclusiveMinimum") ? schema["exclusiveMinimum"].as_i : nil
    v.exclusive_maximum = schema.has_key?("exclusiveMaximum") ? schema["exclusiveMaximum"].as_i : nil

    if schema.has_key?("enum")
      v.enum_list = schema["enum"].as_a
    end

    v.composites = define_composite_validators(schema)
    return v
  end

  private def define_generic_validator(schema : Hash(String, JSON::Any))
    v = GenericValidator.new

    if schema.has_key?("enum")
      v.enum_list = schema["enum"].as_a
    end

    if schema.has_key?("const")
      v.const = schema["const"]
    end

    v.composites = define_composite_validators(schema)
    return v
  end

  private def define_composite_validators(schema : Hash(String, JSON::Any))
    composites = [] of CompositeValidator

    COMPOSITE_KEYS.each do |keyword|
      if schema.has_key?(keyword)
        children_defs = schema[keyword].as_a.map { |child_schema| define_schema(child_schema).as(Validator) }
        composites.push(CompositeValidator.new(keyword, children_defs))
      end
    end

    return composites
  end
end
