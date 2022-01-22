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

private def stringify_json_any(node : JSON::Any)
  case node.raw
  when Int64
    "JSON::Any.new(#{node.raw}_i64)"
  when String
    %{JSON::Any.new("#{node.raw}")}
  else
    "JSON::Any.new(#{node.raw})"
  end
end

private def create_enum_list_assignment_string(var : String, enum_items : Array(JSON::Any))
  return "" if enum_items.size == 0
  enum_tokens = enum_items.map { |enum_item| stringify_json_any(enum_item) }
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

  enum_list = schema.has_key?("enum") ? create_enum_list_assignment_string(var, schema["enum"].as_a) : ""

  return (
    <<-SCH
      (-> {
        #{var} = JSONSchema::ObjectValidator.new
        #{properties}
        #{pattern_properties}
        #{dependent_required}
        #{enum_list}
        #{options_mapped.join("\n")}
        #{define_composite_validators(var, schema)}
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

  enum_list = schema.has_key?("enum") ? create_enum_list_assignment_string(var, schema["enum"].as_a) : ""

  return (
    <<-SCH
      (-> {
        #{var} = JSONSchema::ArrayValidator.new
        #{options_mapped.join("\n")}
        #{prefix_items}
        #{enum_list}
        #{define_composite_validators(var, schema)}
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

  enum_list = schema.has_key?("enum") ? create_enum_list_assignment_string(var, schema["enum"].as_a) : ""

  return (
    <<-SCH
      (-> {
        #{var} = JSONSchema::StringValidator.new
        #{options.join("\n")}
        #{enum_list}
        #{define_composite_validators(var, schema)}
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

  enum_list = schema.has_key?("enum") ? create_enum_list_assignment_string(var, schema["enum"].as_a) : ""

  return (
    <<-SCH
      (-> {
        #{var} = JSONSchema::NumberValidator.new
        #{options.join("\n")}
        #{enum_list}
        #{define_composite_validators(var, schema)}
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

private def is_generic_schema(schema : Hash(String, JSON::Any))
  (schema.keys & (COMPOSITE_KEYS + ["enum", "const"])).size > 0
end

private def define_composite_validator(keyword : String, children : Array(JSON::Any))
  children_defs = children.map { |child_schema| define_schema(child_schema).as(String) }
  return %{JSONSchema::CompositeValidator.new("#{keyword}", [#{children_defs.join(", ")}] of JSONSchema::Validator)}
end

private def define_composite_validators(var : String, schema : Hash(String, JSON::Any))
  composites = [] of String

  COMPOSITE_KEYS.each do |keyword|
    if schema.has_key?(keyword)
      composites.push(define_composite_validator(keyword, schema[keyword].as_a))
    end
  end

  if composites.size == 0
    return ""
  end

  composites_mapped = composites.map { |composite| %{#{var}.composites.push(#{composite})} }
  composites_mapped.join("\n")
end

private def define_generic_validator(schema : Hash(String, JSON::Any))
  var = NextVar.get

  enum_list = schema.has_key?("enum") ? create_enum_list_assignment_string(var, schema["enum"].as_a) : ""
  const = schema.has_key?("const") ? "#{var}.const = #{stringify_json_any(schema["const"])}" : ""

  return (
    <<-SCH
      (-> {
        #{var} = JSONSchema::GenericValidator.new
        #{enum_list}
        #{const}
        #{define_composite_validators(var, schema)}
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
    if is_generic_schema(schema)
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
