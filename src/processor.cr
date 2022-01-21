require "json"
require "./error"

private COMPOSITE_KEYS = ["allOf", "anyOf", "oneOf", "not"]

private module NextVar
  @@n = 0

  def self.get
    var = "v#{@@n}"
    @@n = @@n + 1
    var
  end
end

private def create_enum_list_assignment_string(var : String, enum_items : Array(JSON::Any))
  return "" if enum_items.size == 0

  enum_tokens = enum_items.map do |enum_item|
    case enum_item.raw
    when Int64
      "JSON::Any.new(#{enum_item.raw}_i64)"
    when String
      %{JSON::Any.new("#{enum_item.raw}")}
    else
      "JSON::Any.new(#{enum_item.raw})"
    end
  end

  %{#{var}.enum_list = [#{enum_tokens.join(", ")}]}
end

private def define_object_validator(schema : Hash(String, JSON::Any))
  var = NextVar.get

  if (schema["additionalProperties"]? == false && !schema["properties"])
    raise %{Expected "object" schema to define "properties" when "additionalProperties" is false}
  end

  options = {
    "has_disabled_additional_properties" => schema["additionalProperties"]? == false,
    "required"                           => schema["required"]? || "nil",
    "property_names"                     => schema.has_key?("propertyNames") ? define_string_validator(schema["propertyNames"].as_h) : "nil",
    "min_properties"                     => schema["minProperties"]? || "nil",
    "max_properties"                     => schema["maxProperties"]? || "nil",
  }

  if (schema.has_key?("additionalProperties") && !schema["additionalProperties"].as_h?.nil?)
    options["additional_properties"] = define_schema(schema["additionalProperties"])
  end

  dependent_required = String.build do |str|
    if schema.has_key?("dependentRequired")
      schema["dependentRequired"].as_h.each do |prop_name, required_list|
        required_list_strings = required_list.as_a.map { |list_item| %{"#{list_item}"} }
        str << %{#{var}.dependent_required["#{prop_name}"] = [#{required_list_strings.join(", ")}]}
      end
    end
  end

  options_mapped = options.map do |prop, value|
    "#{var}.#{prop} = #{value}"
  end

  properties = String.build do |str|
    if schema.has_key?("properties")
      schema["properties"].as_h.each do |prop_name, prop|
        str << "#{var}.properties[\"#{prop_name}\"] = #{define_schema(prop)}\n"
      end
    end
  end

  pattern_properties = String.build do |str|
    if schema.has_key?("patternProperties")
      schema["patternProperties"].as_h.each do |prop_regex, prop|
        str << "#{var}.pattern_properties[/#{prop_regex}/] = #{define_schema(prop)}\n"
      end
    end
  end

  enum_list = if schema.has_key?("enum")
                create_enum_list_assignment_string(var, schema["enum"].as_a)
              else
                ""
              end

  return (
    <<-SCH
      (-> {
        #{var} = JSONSchema::ObjectValidator.new
        #{properties}
        #{pattern_properties}
        #{dependent_required}
        #{enum_list}
        #{options_mapped.join("\n")}
        return #{var}
      }).call
    SCH
  ).strip
end

private def define_array_validator(schema : Hash(String, JSON::Any))
  var = NextVar.get

  options = {
    "contains"     => schema["contains"]? ? define_schema(schema["contains"]) : "nil",
    "min_contains" => schema["minContains"]? || "nil",
    "max_contains" => schema["maxContains"]? || "nil",
    "min_items"    => schema["minItems"]? || "nil",
    "max_items"    => schema["maxItems"]? || "nil",
    "unique_items" => schema["uniqueItems"]? || false,
  }

  if schema.has_key?("items")
    if schema.has_key?("prefixItems")
      items_value = schema["items"].as_bool rescue nil
      if (items_value == false)
        options["has_disabled_additional_items"] = true
      end
    else
      options["items"] = define_schema(schema["items"])
    end
  end

  options_mapped = options.map do |prop, value|
    "#{var}.#{prop} = #{value}"
  end

  prefix_items = String.build do |str|
    if schema.has_key?("prefixItems")
      schema["prefixItems"].as_a.each do |item|
        str << "#{var}.prefix_items << #{define_schema(item)}\n"
      end
    end
  end

  enum_list = if schema.has_key?("enum")
                create_enum_list_assignment_string(var, schema["enum"].as_a)
              else
                ""
              end

  return (
    <<-SCH
      (-> {
        #{var} = JSONSchema::ArrayValidator.new
        #{options_mapped.join("\n")}
        #{prefix_items}
        #{enum_list}
        return #{var}
      }).call
    SCH
  ).strip
end

private def define_string_validator(schema : Hash(String, JSON::Any))
  var = NextVar.get

  options = ({
    "min_length" => schema["minLength"]? || "nil",
    "max_length" => schema["maxLength"]? || "nil",
    "pattern"    => schema.has_key?("pattern") ? "/#{schema["pattern"]}/" : "nil",
  }).map do |prop, value|
    "#{var}.#{prop} = #{value}"
  end

  if schema.has_key?("format")
    options.push %{#{var}.format = "#{schema["format"]}"}
  end

  enum_list = if schema.has_key?("enum")
                create_enum_list_assignment_string(var, schema["enum"].as_a)
              else
                ""
              end

  return (
    <<-SCH
      (-> {
        #{var} = JSONSchema::StringValidator.new
        #{options.join("\n")}
        #{enum_list}
        return #{var}
      }).call
    SCH
  ).strip
end

private def define_number_validator(schema : Hash(String, JSON::Any), has_integer_constraint = false)
  var = NextVar.get

  options = ({
    "has_integer_constraint" => has_integer_constraint,
    "multiple_of"            => schema["multipleOf"]? || "nil",
    "minimum"                => schema["minimum"]? || "nil",
    "maximum"                => schema["maximum"]? || "nil",
    "exclusive_minimum"      => schema["exclusiveMinimum"]? || "nil",
    "exclusive_maximum"      => schema["exclusiveMaximum"]? || "nil",
  }).map do |prop, value|
    "#{var}.#{prop} = #{value}"
  end

  enum_list = if schema.has_key?("enum")
                create_enum_list_assignment_string(var, schema["enum"].as_a)
              else
                ""
              end

  return (
    <<-SCH
      (-> {
        #{var} = JSONSchema::NumberValidator.new
        #{options.join("\n")}
        #{enum_list}
        return #{var}
      }).call
    SCH
  ).strip
end

private def define_null_validator(schema : Hash(String, JSON::Any))
  "JSONSchema::NullValidator.new"
end

private def define_boolean_validator(schema : Hash(String, JSON::Any))
  "JSONSchema::BooleanValidator.new"
end

private def define_composite_validator(schema : Hash(String, JSON::Any))
  keyword_keys = schema.keys.select { |key| COMPOSITE_KEYS.includes?(key) }
  raise "Composite schema may not have more than one keyword" unless keyword_keys.size === 1
  keyword = keyword_keys[0]
  raise "Composite schema value must be an array" if schema[keyword].nil?

  children_defs = schema[keyword].as_a.map do |child_schema|
    define_schema child_schema
  end

  return "JSONSchema::CompositeValidator.new(\"#{keyword}\", [#{children_defs.join(", ")}] of JSONSchema::Validator)"
end

private def define_generic_validator(schema : Hash(String, JSON::Any))
  var = NextVar.get

  enum_list = if schema.has_key?("enum")
                create_enum_list_assignment_string(var, schema["enum"].as_a)
              else
                ""
              end

  return (
    <<-SCH
      (-> {
        #{var} = JSONSchema::GenericValidator.new
        #{enum_list}
        return #{var}
      }).call
    SCH
  ).strip
end

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
    return define_null_validator(schema)
  when "boolean"
    return define_boolean_validator(schema)
  else
    # if (COMPOSITE_KEYS.any? { |keyword| schema.has_key?(keyword) })
    #   return define_composite_validator(schema)
    # end

    if (schema.has_key?("enum"))
      return define_generic_validator(schema)
    end

    raise "Schema did not provide any known constraints"
  end
end

module JSONSchema
  extend self

  # :nodoc:
  def process_file(filename : String) : String
    begin
      contents = File.read filename
      schema = JSON.parse contents
      define_schema(schema)
    rescue ex
      raise JSONSchema::InvalidSchemaError.new(ex.message, ex, filename)
    end
  end
end
