require "json"

require "./format"
require "./node_context"

module JSONSchema
  # Captures an error message and the corresponding path to the value where the error occurred.
  struct ValidationError
    # Description of what error occurred.
    getter message : String
    #  Provides a reference to where this error occurred in the input JSON. See `JSONSchema::NodeContext` for more information.
    getter context : NodeContext

    def initialize(@message, @context)
    end
  end

  # Captures result of validation, including a status and any number of corresponding errors
  struct ValidationResult
    # Either `:success` or `:error`
    getter status : Symbol
    getter errors : Array(ValidationError)

    def initialize(@status, @errors = [] of ValidationError)
    end
  end

  # Alias type for any type of `Validator`. The top-level `Validator` returned from the macros
  # can be any one of the following.
  alias Validator = ObjectValidator |
                    ArrayValidator |
                    StringValidator |
                    NumberValidator |
                    NullValidator |
                    BooleanValidator |
                    GenericValidator |
                    CompositeValidator

  def self.validate_enum(value : JSON::Any, enum_list : Array(JSON::Any), context : NodeContext) : ValidationError?
    found_match = false
    item_iterator = enum_list.each.take_while { |item| !found_match }
    current_item = item_iterator.next

    while current_item.is_a?(JSON::Any)
      found_match = value == current_item
      current_item = item_iterator.next
    end

    if found_match
      return nil
    end

    ValidationError.new "Expected value to be equal to the enum", context
  end

  # Validates schema that has no type. Allows for constraints such as `enum`, `const` or
  # composite schemas that do not require a `type` keyword (`enum` is also available on typed schemas).
  #
  # This is a raw `Validator` class that you most likely do not need to use directly.
  # See the `JSONSchema#create_validator` macro for common usage of this shard.
  class GenericValidator
    property enum_list : Array(JSON::Any) = [] of JSON::Any
    property const : JSON::Any?
    property composites : Array(CompositeValidator) = [] of CompositeValidator

    def validate(node : JSON::Any, context = NodeContext.new)
      errors = [] of ValidationError

      unless @enum_list.size == 0
        enum_result = JSONSchema.validate_enum(node, @enum_list, context)

        unless enum_result.nil?
          errors.push(enum_result.as(ValidationError))
        end
      end

      unless @const.nil?
        unless node == @const
          errors.push ValidationError.new("Expected value to be #{@const}", context)
        end
      end

      validate_composites(@composites, node, errors)

      if errors.size > 0
        return ValidationResult.new(:error, errors)
      end

      ValidationResult.new(:success)
    end
  end

  # Validates schema where the `type` is `object`.
  #
  # This is a raw `Validator` class that you most likely do not need to use directly.
  # See the `JSONSchema#create_validator` macro for common usage of this shard.
  class ObjectValidator
    property properties : Hash(String, Validator) = Hash(String, Validator).new
    property pattern_properties : Hash(Regex, Validator) = Hash(Regex, Validator).new
    property has_disabled_additional_properties = false
    property additional_properties : Validator?
    property required : Array(String)?
    property dependent_required : Hash(String, Array(String)) = Hash(String, Array(String)).new
    property property_names : StringValidator?
    property min_properties : Int32?
    property max_properties : Int32?
    property enum_list : Array(JSON::Any) = [] of JSON::Any
    property composites : Array(CompositeValidator) = [] of CompositeValidator

    def validate(node : JSON::Any, context = NodeContext.new("."))
      value = node.as_h rescue return ValidationResult.new(:error, [ValidationError.new("Expected value to be an object", context)])

      errors = [] of ValidationError

      unless @required.nil?
        @required.as(Array(String)).each do |required_prop|
          errors.push(ValidationError.new(%{Expected required property "#{required_prop}" to be set}, context)) unless value.has_key?(required_prop)
        end
      end

      unless @dependent_required.size == 0
        @dependent_required.each do |dependent_prop, required_props|
          required_props.each do |required_prop|
            errors.push(ValidationError.new(%{Expected required property "#{required_prop}" to be set when "#{dependent_prop}" is set}, context)) unless value.has_key?(required_prop)
          end
        end
      end

      unless @property_names.nil?
        value.keys.each do |property_name|
          result = @property_names.as(StringValidator).validate(JSON::Any.new(property_name), context.from_property(property_name))
          if result.status == :error
            errors.concat(result.errors)
          end
        end
      end

      unless @min_properties.nil?
        unless value.keys.size >= @min_properties.as(Int32)
          errors.push(ValidationError.new("Expected object to have at least #{@min_properties} properties", context))
        end
      end

      unless @max_properties.nil?
        if value.keys.size > @max_properties.as(Int32)
          errors.push(ValidationError.new("Expected object to have at most #{@max_properties} properties", context))
        end
      end

      @properties.each do |property_name, property_validator|
        property_value = value[property_name]?

        unless property_value.nil?
          result = property_validator.validate(property_value, context.from_property(property_name))
          if result.status == :error
            errors.concat(result.errors)
          end
        end
      end

      @pattern_properties.each do |pattern, pattern_validator|
        value.each do |k, v|
          if pattern =~ k
            result = pattern_validator.validate(v, context.from_property(k))
            if result.status == :error
              errors.concat(result.errors)
            end
          end
        end
      end

      additional_keys = value.keys.select do |key|
        !@properties.has_key?(key)
      end

      if @has_disabled_additional_properties
        if additional_keys.size > 0
          errors.push(ValidationError.new("Expected object not to have additional properties", context))
        end
      else
        unless @additional_properties.nil?
          additional_keys.each do |additional_key|
            result = @additional_properties.as(Validator).validate(value[additional_key], context.from_property(additional_key))
            if result.status == :error
              errors.concat(result.errors)
            end
          end
        end
      end

      unless @enum_list.size == 0
        enum_result = JSONSchema.validate_enum(node, @enum_list, context)

        unless enum_result.nil?
          errors.push(enum_result.as(ValidationError))
        end
      end

      validate_composites(@composites, node, errors)

      if errors.size > 0
        return ValidationResult.new(:error, errors)
      end

      ValidationResult.new(:success)
    end
  end

  # Validates schema where the `type` is `array`.
  #
  # This is a raw `Validator` class that you most likely do not need to use directly.
  # See the `JSONSchema#create_validator` macro for common usage of this shard.
  class ArrayValidator
    property items : Validator?
    property prefix_items : Array(Validator) = [] of Validator
    property has_disabled_additional_items = false
    property contains : Validator?
    property min_contains : Int32?
    property max_contains : Int32?
    property min_items : Int32?
    property max_items : Int32?
    property unique_items = false
    property enum_list : Array(JSON::Any) = [] of JSON::Any
    property composites : Array(CompositeValidator) = [] of CompositeValidator

    def validate(node : JSON::Any, context = NodeContext.new)
      value = node.as_a rescue return ValidationResult.new(:error, [ValidationError.new("Expected value to be an array", context)])
      errors = [] of ValidationError

      unless @items.nil?
        value.each_with_index do |item, i|
          result = @items.as(Validator).validate(item)
          if (result.status == :error)
            errors.concat(result.errors)
          end
        end
      end

      unless @prefix_items.size == 0
        @prefix_items.as(Array).each_with_index do |prefix_item, i|
          result = prefix_item.validate(value[i])
          if (result.status == :error)
            errors.concat(result.errors)
          end
        end

        if @has_disabled_additional_items && value.size > @prefix_items.size
          errors.push(ValidationError.new("Expected array to be tuple of length #{@prefix_items.size}", context))
        end
      end

      unless @contains.nil?
        if !@max_contains.nil? || !@min_contains.nil?
          value_contains_results = value.select { |item| @contains.as(Validator).validate(item).status == :success }

          unless @min_contains.nil?
            if value_contains_results.size < @min_contains.as(Int32)
              errors.push(ValidationError.new("Expected array to contain at least #{@min_contains} matched items", context))
            end
          end

          unless @max_contains.nil?
            if value_contains_results.size > @max_contains.as(Int32)
              errors.push(ValidationError.new("Expected array to contain at most #{@max_contains} matched items", context))
            end
          end
        else
          found_contains = false
          item_iterator = value.each.take_while { |item| !found_contains }
          current_item = item_iterator.next

          while current_item.is_a?(JSON::Any)
            result = @contains.as(Validator).validate(current_item)
            if (result.status == :success)
              found_contains = true
            end
            current_item = item_iterator.next
          end

          if !found_contains
            errors.push(ValidationError.new("Expected array to contain at least 1 matched item", context))
          end
        end
      end

      unless @min_items.nil?
        if value.size < @min_items.as(Int32)
          errors.push(ValidationError.new("Expected array length to be at least #{@min_items}", context))
        end
      end

      unless @min_items.nil?
        if value.size > @max_items.as(Int32)
          errors.push(ValidationError.new("Expected array length to be at most #{@max_items}", context))
        end
      end

      if @unique_items
        if value.uniq.size != value.size
          errors.push(ValidationError.new("Expected array items to be unique", context))
        end
      end

      unless @enum_list.size == 0
        enum_result = JSONSchema.validate_enum(node, @enum_list, context)

        unless enum_result.nil?
          errors.push(enum_result.as(ValidationError))
        end
      end

      validate_composites(@composites, node, errors)

      if errors.size > 0
        return ValidationResult.new(:error, errors)
      end

      ValidationResult.new(:success)
    end
  end

  # Validates schema where the `type` is `string`.
  #
  # This is a raw `Validator` class that you most likely do not need to use directly.
  # See the `JSONSchema#create_validator` macro for common usage of this shard.
  class StringValidator
    property min_length : Int32?
    property max_length : Int32?
    property pattern : Regex?
    property format : String?
    property enum_list : Array(JSON::Any) = [] of JSON::Any
    property composites : Array(CompositeValidator) = [] of CompositeValidator

    def validate(node : JSON::Any, context = NodeContext.new)
      value = node.as_s rescue return ValidationResult.new(:error, [ValidationError.new("Expected value to be a string", context)])
      errors = [] of ValidationError

      unless @min_length.nil?
        if @min_length.as(Int32) > value.size
          errors.push(ValidationError.new("Expected string to have a minimum length of #{@min_length}", context))
        end
      end

      unless @max_length.nil?
        if value.size > @max_length.as(Int32)
          errors.push(ValidationError.new("Expected string to have a maximum length of #{@max_length}", context))
        end
      end

      unless @pattern.nil?
        if (@pattern =~ value).nil?
          errors.push(ValidationError.new("Expected string to match pattern /#{@pattern.as(Regex).source}/", context))
        end
      end

      unless @format.nil?
        case @format.as(String)
        when "uuid" then self.check_format(@format.as(String), Format.is_uuid(value), errors, context)
        end
      end

      unless @enum_list.size == 0
        enum_result = JSONSchema.validate_enum(node, @enum_list, context)

        unless enum_result.nil?
          errors.push(enum_result.as(ValidationError))
        end
      end

      validate_composites(@composites, node, errors)

      if errors.size > 0
        return ValidationResult.new(:error, errors)
      end

      ValidationResult.new(:success)
    end

    private def check_format(format : String, matched_format : Bool, errors : Array(ValidationError), context : NodeContext)
      if !matched_format
        errors.push(ValidationError.new(%{Expected string to match format "#{format}"}, context))
      end
    end
  end

  # Validates schema where the `type` is `number` or `integer`.
  #
  # This is a raw `Validator` class that you most likely do not need to use directly.
  # See the `JSONSchema#create_validator` macro for common usage of this shard.
  class NumberValidator
    property has_integer_constraint = false
    property multiple_of : Int32?
    property minimum : Int32?
    property maximum : Int32?
    property exclusive_minimum : Int32?
    property exclusive_maximum : Int32?
    property enum_list : Array(JSON::Any) = [] of JSON::Any
    property composites : Array(CompositeValidator) = [] of CompositeValidator

    def validate(node : JSON::Any, context = NodeContext.new)
      value = node.as_f rescue node.as_i rescue return ValidationResult.new(:error, [ValidationError.new("Expected value to be a number", context)])
      errors = [] of ValidationError

      if @has_integer_constraint && (value % 1 != 0)
        errors.push(ValidationError.new("Expected numeric value to be an integer", context))
      end

      unless @minimum.nil?
        unless @minimum.as(Int32) <= value
          errors.push(ValidationError.new("Expected numeric value be greater than or equal to #{@minimum}", context))
        end
      end

      unless @maximum.nil?
        unless value <= @maximum.as(Int32)
          errors.push(ValidationError.new("Expected numeric value be less than or equal to #{@maximum}", context))
        end
      end

      unless @exclusive_minimum.nil?
        unless @exclusive_minimum.as(Int32) < value
          errors.push(ValidationError.new("Expected numeric value be greater than #{@exclusive_minimum}", context))
        end
      end

      unless @exclusive_maximum.nil?
        unless value < @exclusive_maximum.as(Int32)
          errors.push(ValidationError.new("Expected numeric value be less than #{@exclusive_maximum}", context))
        end
      end

      unless @multiple_of.nil?
        unless value % multiple_of.as(Int32) == 0
          errors.push(ValidationError.new("Expected numeric value to be multiple of #{@multiple_of}", context))
        end
      end

      unless @enum_list.size == 0
        enum_result = JSONSchema.validate_enum(node, @enum_list, context)

        unless enum_result.nil?
          errors.push(enum_result.as(ValidationError))
        end
      end

      validate_composites(@composites, node, errors)

      if errors.size > 0
        return ValidationResult.new(:error, errors)
      end

      ValidationResult.new(:success)
    end
  end

  # Validates schema where the `type` is `null`.
  #
  # This is a raw `Validator` class that you most likely do not need to use directly.
  # See the `JSONSchema#create_validator` macro for common usage of this shard.
  class NullValidator
    def validate(node : JSON::Any, context = NodeContext.new)
      node.as_nil rescue return ValidationResult.new(:error, [ValidationError.new("Expected value to be null", context)])
      ValidationResult.new(:success)
    end
  end

  # Validates schema where the `type` is `boolean`.
  #
  # This is a raw `Validator` class that you most likely do not need to use directly.
  # See the `JSONSchema#create_validator` macro for common usage of this shard.
  class BooleanValidator
    def validate(node : JSON::Any, context = NodeContext.new)
      node.as_bool rescue return ValidationResult.new(:error, [ValidationError.new("Expected value to be a boolean", context)])
      ValidationResult.new(:success)
    end
  end

  # Validates schema that has any of the keywords for [composite/compound schema](https://json-schema.org/understanding-json-schema/reference/combining.html)
  # set as a property. The possible keywords are `allOf`, `anyOf`, `oneOf`, and `not`.
  #
  # This is a raw `Validator` class that you most likely do not need to use directly.
  # See the `JSONSchema#create_validator` macro for common usage of this shard.
  class CompositeValidator
    property keyword : String
    property children : Array(Validator)

    def initialize(@keyword, @children)
    end

    def validate(node : JSON::Any, context = NodeContext.new)
      results = @children.map do |child|
        child.validate(node)
      end

      results_with_errors = results.select { |result| result.status == :error }

      case @keyword
      when "allOf"
        if results_with_errors.size > 0
          return ValidationResult.new(:error, [ValidationError.new("Expected value to match all schemas", context)])
        end
      when "anyOf"
        unless results.size - results_with_errors.size > 0
          return ValidationResult.new(:error, [ValidationError.new("Expected value to match any of the schemas", context)])
        end
      when "oneOf"
        unless results.size - results_with_errors.size == 1
          return ValidationResult.new(:error, [ValidationError.new("Expected value to match only one of the schemas", context)])
        end
      when "not"
        unless results.size == results_with_errors.size
          return ValidationResult.new(:error, [ValidationError.new("Expected value not to match any of the schemas", context)])
        end
      end

      ValidationResult.new(:success)
    end
  end
end

# This modifies an error array with any errors that are the result of the composite validators in the array
# when validated against the given node.
private def validate_composites(composites : Array(JSONSchema::CompositeValidator), node : JSON::Any, errors : Array(JSONSchema::ValidationError))
  unless composites.size == 0
    composite_results = composites.map { |composite| composite.validate(node) }.each do |composite_result|
      if composite_result.status == :error
        errors.concat(composite_result.errors)
      end
    end
  end
end
