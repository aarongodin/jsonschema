require "json"

require "./validator"

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

private def stringify_enum_list(enum_list : Array(JSON::Any))
  String.build do |str|
    str << "["
    i = 0
    enum_list.each do |enum_item|
      str << stringify_json_any(enum_item)
      unless i >= enum_list.size
        str << ", "
      end
      i = i + 1
    end
    str << "]"
  end
end

private module NextVar
  @@n = 0

  def self.get
    var = "v#{@@n}"
    @@n = @@n + 1
    var
  end
end

module JSONSchema
  # Shared module to provide render capability to Validator classes.
  # This module is private and intended to only be used by the macros in this library.
  module ValidatorRender
    private def create_instance(options : Hash(String, String))
      var = NextVar.get
      mapped = options.map do |prop, value|
        "#{var}.#{prop} = #{value}"
      end

      (
        <<-SCH
          (-> {
            #{var} = #{self.class}.new
            #{mapped.join("\n")}
            return #{var}
          }).call
        SCH
      ).strip
    end
  end

  class GenericValidator
    include ValidatorRender

    def to_cr
      options = {} of String => String

      unless @enum_list.size == 0
        options["enum_list"] = stringify_enum_list(@enum_list)
      end

      unless @const.nil?
        options["const"] = stringify_json_any(@const.as(JSON::Any))
      end

      unless @composites.size == 0
        options["composites"] = "[#{@composites.join(", ", &.to_cr)}]"
      end

      create_instance options
    end
  end

  class ObjectValidator
    include ValidatorRender

    def to_cr
      options = {} of String => String

      if @has_disabled_additional_properties
        options["has_disabled_additional_properties"] = "true"
      end

      unless @required.nil?
        options["required"] = @required.to_s + " of String"
      end

      unless @property_names.nil?
        options["property_names"] = @property_names.as(StringValidator).to_cr
      end

      unless @min_properties.nil?
        options["min_properties"] = @min_properties.to_s
      end

      unless @max_properties.nil?
        options["max_properties"] = @max_properties.to_s
      end

      unless @additional_properties.nil?
        options["additional_properties"] = @additional_properties.as(Validator).to_cr
      end

      unless @dependent_required.size == 0
        options["dependent_required"] = @dependent_required.to_s
      end

      unless @dependent_schemas.size == 0
        options["dependent_schemas"] = String.build do |str|
          str << "{\n"
          i = 0
          @dependent_schemas.each do |prop, subschema|
            str << "\"#{prop}\" => #{subschema.to_cr}"
            unless i >= @dependent_schemas.size
              str << ",\n"
            end
            i = i + 1
          end
          str << "} of String => JSONSchema::ObjectValidator"
        end
      end

      unless @properties.size == 0
        options["properties"] = String.build do |str|
          str << "{\n"
          i = 0
          @properties.each do |prop, validator|
            str << "\"#{prop}\" => #{validator.to_cr}"
            unless i >= @properties.size
              str << ",\n"
            end
            i = i + 1
          end
          str << "} of String => JSONSchema::Validator"
        end
      end

      unless @pattern_properties.size == 0
        options["pattern_properties"] = String.build do |str|
          str << "{\n"
          i = 0
          @pattern_properties.each do |pattern, validator|
            str << "/#{pattern.source}/ => #{validator.to_cr}"
            unless i >= @pattern_properties.size
              str << ",\n"
            end
            i = i + 1
          end
          str << "} of Regex => JSONSchema::Validator"
        end
      end

      unless @composites.size == 0
        options["composites"] = "[#{@composites.join(", ", &.to_cr)}]"
      end

      unless @enum_list.size == 0
        options["enum_list"] = stringify_enum_list(@enum_list)
      end

      create_instance options
    end
  end

  class ArrayValidator
    include ValidatorRender

    def to_cr
      options = {} of String => String

      unless @items.nil?
        options["items"] = @items.as(Validator).to_cr
      end

      unless @prefix_items.size == 0
        options["prefix_items"] = "[#{@prefix_items.join(", ", &.to_cr)}] of JSONSchema::Validator"
      end

      if @has_disabled_additional_items
        options["has_disabled_additional_items"] = "true"
      end

      unless @contains.nil?
        options["contains"] = @contains.as(Validator).to_cr
      end

      unless @min_contains.nil?
        options["min_contains"] = @min_contains.to_s
      end

      unless @max_contains.nil?
        options["max_contains"] = @max_contains.to_s
      end

      unless @min_items.nil?
        options["min_items"] = @min_items.to_s
      end

      unless @max_items.nil?
        options["max_items"] = @max_items.to_s
      end

      if @unique_items
        options["unique_items"] = "true"
      end

      unless @enum_list.size == 0
        options["enum_list"] = stringify_enum_list(@enum_list)
      end

      unless @composites.size == 0
        options["composites"] = "[#{@composites.join(", ", &.to_cr)}]"
      end

      create_instance options
    end
  end

  class StringValidator
    include ValidatorRender

    def to_cr
      options = {} of String => String

      unless @min_length.nil?
        options["min_length"] = @min_length.to_s
      end

      unless @max_length.nil?
        options["max_length"] = @max_length.to_s
      end

      unless @pattern.nil?
        options["pattern"] = "/#{@pattern.as(Regex).source}/"
      end

      unless @format.nil?
        options["format"] = @format.to_s
      end

      unless @enum_list.size == 0
        options["enum_list"] = stringify_enum_list(@enum_list)
      end

      unless @composites.size == 0
        options["composites"] = "[#{@composites.join(", ", &.to_cr)}]"
      end

      create_instance options
    end
  end

  class NumberValidator
    include ValidatorRender

    def to_cr
      options = {} of String => String

      if @has_integer_constraint
        options["has_integer_constraint"] = "true"
      end

      unless @multiple_of.nil?
        options["multiple_of"] = @multiple_of.to_s
      end

      unless @minimum.nil?
        options["minimum"] = @minimum.to_s
      end

      unless @maximum.nil?
        options["maximum"] = @maximum.to_s
      end

      unless @exclusive_minimum.nil?
        options["exclusive_minimum"] = @exclusive_minimum.to_s
      end

      unless @exclusive_maximum.nil?
        options["exclusive_maximum"] = @exclusive_maximum.to_s
      end

      unless @enum_list.size == 0
        options["enum_list"] = stringify_enum_list(@enum_list)
      end

      unless @composites.size == 0
        options["composites"] = "[#{@composites.join(", ", &.to_cr)}]"
      end

      create_instance options
    end
  end

  class NullValidator
    def to_cr
      "JSONSchema::NullValidator.new"
    end
  end

  class BooleanValidator
    def to_cr
      "JSONSchema::BooleanValidator.new"
    end
  end

  class CompositeValidator
    include ValidatorRender

    def to_cr
      create_instance({
        "keyword"  => @keyword,
        "children" => "[#{@children.join(", ", &.to_cr)}]",
      })
    end
  end
end
