require "./validator"

module JSONSchema
  @@fluent = Fluent.new

  # Accessor for the Fluent API. See the `JSONSchema::Fluent` class for details on creating validators through
  # methods on the Fluent API.
  def self.fluent : Fluent
    @@fluent
  end

  # Contains methods for creating `JSONSchema::Validator` instances without interacting with the low-level domain objects. This class implements a
  # DSL through block receivers rather than the standard method-chaining fluent API seen in json-schema libraries in other languages.
  #
  # An instance of this class is available through `JSONSchema.fluent`.
  #
  # ```
  # require "jsonschema"
  #
  # js = JSONSchema.fluent
  #
  # validator = js.object do
  #   prop "first_name", (js.string do
  #     min_length 2
  #     max_length 64
  #   end)
  #
  #   prop "last_name", (js.string do
  #     min_length 2
  #     max_length 64
  #   end)
  #
  #   prop "email", js.string { format "email" }
  #
  #   prop "address", (js.object do
  #     prop "street", js.string
  #     prop "city", js.string
  #     prop "state", js.string
  #     prop "zipcode", js.string
  #   end)
  #
  #   prop "nicknames", (js.array do
  #     min_items 1
  #     items js.string
  #   end)
  # end
  # ```
  #
  # As in the example above, it's recommended to create a shorter variable that references `JSONSchema.fluent`.
  # This will improve readability and can be customized to the needs of your code (rather than `jsonschema` exposing a global method
  # with a short name).
  class Fluent
    # Create a `JSONSchema::GenericValidator` using the fluent API. See `JSONSchema::FluentGenericValidator` for receiver methods.
    # Accepts a block to receive options for the validator.
    #
    # This method does not have a corresponding non-block-accepting method because a generic validator must
    # have options to be a valid schema.
    #
    # ```
    # js = JSONSchema.fluent
    #
    # validator = js.generic do
    #   enum_list "one", "two", "three"
    # end
    # ```
    def generic(&block) : GenericValidator
      fluent = FluentGenericValidator.new
      with fluent yield
      fluent.validator
    end

    # Create a `JSONSchema::ObjectValidator` using the fluent API. See `JSONSchema::FluentObjectValidator` for receiver methods.
    #
    # ```
    # js = JSONSchema.fluent
    #
    # validator = js.object do
    #   prop "name", js.string
    #   prop "age", (js.integer do
    #     minimum 0
    #   end)
    #   required "name", "age"
    # end
    # ```
    def object(&block) : ObjectValidator
      fluent = FluentObjectValidator.new
      with fluent yield
      fluent.validator
    end

    # Convenience method for creating a new `JSONSchema::ObjectValidator` without options.
    def object : ObjectValidator
      ObjectValidator.new
    end

    # Create a `JSONSchema::ArrayValidator` using the fluent API. See `JSONSchema::FluentArrayValidator` for receiver methods.
    #
    # ```
    # js = JSONSchema.fluent
    #
    # validator = js.array do
    #   unique_items
    #   validator js.string
    # end
    # ```
    def array(&block) : ArrayValidator
      fluent = FluentArrayValidator.new
      with fluent yield
      fluent.validator
    end

    # Convenience method for creating a new `JSONSchema::ArrayValidator` without options.
    def array : ArrayValidator
      ArrayValidator.new
    end

    # Create a `JSONSchema::StringValidator` using the fluent API. See `JSONSchema::FluentStringValidator` for receiver methods.
    #
    # ```
    # js = JSONSchema.fluent
    #
    # validator = js.string do
    #   min_length 10
    #   pattern /^[a-z0-9-_]$/
    # end
    # ```
    def string(&block) : StringValidator
      fluent = FluentStringValidator.new
      with fluent yield
      fluent.validator
    end

    # Convenience method for creating a new `JSONSchema::StringValidator` without options.
    def string : StringValidator
      StringValidator.new
    end

    # Create a `JSONSchema::NumberValidator` using the fluent API. See `JSONSchema::FluentNumberValidator` for receiver methods.
    #
    # ```
    # js = JSONSchema.fluent
    #
    # validator = js.number do
    #   minimum 0
    #   maximum 100
    # end
    # ```
    def number(&block) : NumberValidator
      fluent = FluentNumberValidator.new
      with fluent yield
      fluent.validator
    end

    # Convenience method for creating a new `JSONScheam::NumberValidator` without options.
    def number : NumberValidator
      NumberValidator.new
    end

    # Create a `JSONSchema::NumberValidator` with the integer constraint set using the fluent API. See `JSONSchema::FluentNumberValidator` for receiver methods.
    #
    # ```
    # js = JSONSchema.fluent
    #
    # validator = js.integer do
    #   minimum 0
    #   multiple_of 5
    # end
    # ```
    def integer(&block) : NumberValidator
      fluent = FluentNumberValidator.new
      fluent.has_integer_constraint
      with fluent yield
      fluent.validator
    end

    # Convenience method for creating a new `JSONSchema::NumberValidator` with the integer constraint set (and not other options).
    def integer : NumberValidator
      validator = NumberValidator.new
      validator.has_integer_constraint = true
      validator
    end

    # Convenience method for creating a new `JSONSchema::NullValidator`.
    def null
      NullValidator.new
    end

    # Convenience method for creating a new `JSONSchema::BooleanValidator`.
    def boolean
      BooleanValidator.new
    end
  end

  # Contains fluent methods for interfacing with generic json-schema properties such as [enum](https://json-schema.org/understanding-json-schema/reference/generic.html#enumerated-values)
  # and [composite schemas](https://json-schema.org/understanding-json-schema/reference/combining.html).
  module FluentValidatorGenericProperties
    # Set a list of values that are allowed for this schema. This method is not called `enum` to avoid conflicting with the `enum` keyword.
    #
    # ```
    # validator = JSONSchema.generic do
    #   enum_list "one", "two", "three"
    # end
    # ```
    def enum_list(*values)
      validator.enum_list = values.to_a.map { |value| JSON::Any.new(value) }
    end

    # Constraint that _all_ of the passed schemas must be valid given the input JSON. Accepts any number of children as `JSONSchema::Validator` objects.
    def all_of(*children)
      validator.composites << CompositeValidator.new("allOf", children.to_a.map &.as(Validator))
    end

    # Constraint that _at least one_ of the passed schemas must be valid given the input JSON. Accepts any number of children as `JSONSchema::Validator` objects.
    def any_of(*children)
      validator.composites << CompositeValidator.new("anyOf", children.to_a.map &.as(Validator))
    end

    # Constraint that _only one_ of the passed schemas is valid given the input JSON. Accepts any number of children as `JSONSchema::Validator` objects.
    def oneOf(*children)
      validator.composites << CompositeValidator.new("oneOf", children.to_a.map &.as(Validator))
    end

    # Constraint that the passed schema is not valid given the input JSON. Accepts any number of children as `JSONSchema::Validator` objects.
    def not(*children)
      validator.composites << CompositeValidator.new("not", children.to_a.map &.as(Validator))
    end
  end

  # A fluent API for creating instances of `JSONSchema::GenericValidator`.
  class FluentGenericValidator
    include FluentValidatorGenericProperties
    getter validator = GenericValidator.new

    # Sets `JSONSchema::GenericValidator#const`. Learn about [const](https://json-schema.org/understanding-json-schema/reference/generic.html#constant-values).
    #
    # ```
    # validator = JSONSchema.generic do
    #   const "United States"
    # end
    # ```
    def const(value : JSON::Any::Type)
      validator.const = JSON::Any.new(value)
    end
  end

  # A fluent API for creating instances of `JSONSchema::ObjectValidator`.
  class FluentObjectValidator
    include FluentValidatorGenericProperties
    getter validator = ObjectValidator.new

    # Set the validator for a property by name. This method is named `prop` to not conflict with the global `property` macro.
    def prop(name : String, v : Validator)
      validator.properties[name] = v
    end

    # Set the validator for a given `Regex`. See [Pattern Properties](https://json-schema.org/understanding-json-schema/reference/object.html#pattern-properties).
    def pattern_property(pattern : Regex, v : Validator)
      validator.pattern_properties[pattern] = v
    end

    # Set the constraint for disabling additional properties. See [Addiitonal Properties](https://json-schema.org/understanding-json-schema/reference/object.html#additional-properties).
    def has_disabled_additional_properties
      validator.has_disabled_additional_properties = true
    end

    # Set the validator for any additional properties not in the properties definition. See [Additional Properties](https://json-schema.org/understanding-json-schema/reference/object.html#additional-properties).
    def additional_properties(v : Validator)
      validator.additional_properties = v
    end

    # Set the list of required properties as any number of strings.
    #
    # ```
    # validator = JSONSchema.fluent.object do
    #   required "name", "age"
    # end
    # ```
    def required(*properties)
      validator.required = properties.to_a
    end

    # Set the list of dependent required properties. See [Dependent Required](https://json-schema.org/understanding-json-schema/reference/conditionals.html#dependentrequired).
    #
    # ```
    # validator = JSONSchema.fluent.object do
    #   dependent_required({
    #     "creditCard" => ["billingAddress"],
    #   })
    # end
    # ```
    def dependent_required(value : Hash(String, Array(String)))
      validator.dependent_required = value
    end

    # Set a single dependent required property by name. See [Dependent Required](https://json-schema.org/understanding-json-schema/reference/conditionals.html#dependentrequired).
    #
    # ```
    # validator = JSONSchema.fluent.object do
    #   dependent_required "creditCard", ["billingAddress"]
    #   dependent_required "couponCode", ["source"]
    # end
    # ```
    def dependent_required(name : String, values : Array(String))
      validator.dependent_required[name] = values
    end

    # Set a validator for all property names. See [Property names](https://json-schema.org/understanding-json-schema/reference/object.html#property-names).
    def property_names(v : Validator)
      validator.property_names = v
    end

    # Set a validator for the minimum number of properties that must be on the object.
    def min_properties(value : Int32)
      validator.min_properties = value
    end

    # Set a validator for the minimum number of properties that must be on the object.
    def max_properties(value : Int32)
      validator.max_properties = value
    end
  end

  # A fluent API for creating instances of `JSONSchema::ArrayValidator`.
  class FluentArrayValidator
    include FluentValidatorGenericProperties
    getter validator = ArrayValidator.new

    # Set a validator for items in the array. See [Items](https://json-schema.org/understanding-json-schema/reference/array.html#items).
    #
    # ```
    # js = JSONSchema.fluent
    #
    # validator = js.array do
    #   items js.string { min_length 10 }
    # end
    # ```
    def items(v : Validator)
      validator.items = v
    end

    # Set validators for Tuple validation of the array. See [Tuple validation](https://json-schema.org/understanding-json-schema/reference/array.html#tuple-validation).
    #
    # ```
    # js = JSONSchema.fluent
    #
    # validator = js.array do
    #   prefix_items(
    #     js.number,
    #     js.string,
    #     js.string
    #   )
    # end
    # ```
    def prefix_items(*validators)
      validator.prefix_items = validators.to_a.map &.as(Validator)
    end

    # Set the constraint that the array does not allow additional items beyond those specified in `prefix_items`. See [Additional Items](https://json-schema.org/understanding-json-schema/reference/array.html#additional-items).
    def has_disabled_additional_items
      validator.has_disabled_additional_items = true
    end

    # Set the validator to check that at least one item matches the schema. See [Contains](https://json-schema.org/understanding-json-schema/reference/array.html#contains).
    def contains(v : Validator)
      validator.contains = v
    end

    # Set the `min_contains`. See [Contains](https://json-schema.org/understanding-json-schema/reference/array.html#contains).
    def min_contains(value : Int32)
      validator.min_contains = value
    end

    # Set the `max_contains`. See [Contains](https://json-schema.org/understanding-json-schema/reference/array.html#contains).
    def max_contains(value : Int32)
      validator.max_contains = value
    end

    # Set the `min_items`. See [Length](https://json-schema.org/understanding-json-schema/reference/array.html#length)
    def min_items(value : Int32)
      validator.min_items = value
    end

    # Set the `max_items`. See [Length](https://json-schema.org/understanding-json-schema/reference/array.html#length)
    def max_items(value : Int32)
      validator.max_items = value
    end

    # Sets the uniqueness constraint on items in the array.
    def unique_items
      validator.unique_items = true
    end
  end

  # A fluent API for creating instances of `JSONSchema::StringValidator`.
  class FluentStringValidator
    include FluentValidatorGenericProperties
    getter validator = StringValidator.new

    # Sets `min_length`. See [Length](https://json-schema.org/understanding-json-schema/reference/string.html#length)
    def min_length(value : Int32)
      validator.min_length = value
    end

    # Sets `max_length`. See [Length](https://json-schema.org/understanding-json-schema/reference/string.html#length)
    def max_length(value : Int32)
      validator.max_length = value
    end

    # Sets `pattern`. See [Regular Expressions](https://json-schema.org/understanding-json-schema/reference/string.html#regular-expressions)
    def pattern(value : Regex)
      validator.pattern = value
    end

    # Sets a format for the string. See [Format](https://json-schema.org/understanding-json-schema/reference/string.html#format).
    def format(value : String)
      validator.format = value
    end
  end

  # A fluent API for creating instances of `JSONSchema::NumberValidator`.
  class FluentNumberValidator
    include FluentValidatorGenericProperties
    getter validator = NumberValidator.new

    # Sets the constraint for requiring the number to be an integer.
    def has_integer_constraint
      validator.has_integer_constraint = true
    end

    # Sets `multiple_of`. See [Multiples](https://json-schema.org/understanding-json-schema/reference/numeric.html#multiples)
    def multiple_of(value : Int32)
      validator.multiple_of = value
    end

    # Sets `minimum`. See [Range](https://json-schema.org/understanding-json-schema/reference/numeric.html#range)
    def minimum(value : Int32)
      validator.minimum = value
    end

    # Sets `maximum`. See [Range](https://json-schema.org/understanding-json-schema/reference/numeric.html#range)
    def maximum(value : Int32)
      validator.maximum = value
    end

    # Sets `exclusive_minimum`. See [Range](https://json-schema.org/understanding-json-schema/reference/numeric.html#range)
    def exclusive_minimum(value : Int32)
      validator.exclusive_minimum = value
    end

    # Sets `exclusive_maximum`. See [Range](https://json-schema.org/understanding-json-schema/reference/numeric.html#range)
    def exclusive_maximum(value : Int32)
      validator.exclusive_maximum = value
    end
  end
end
