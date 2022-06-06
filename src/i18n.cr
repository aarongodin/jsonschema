module JSONSchema
  alias Translator = Proc(Array(String), String)
  alias Lang = Hash(Int32, String | Translator)

  # :nodoc:
  EN_US = {
    # Exceptions
    0 => "schema did not provide any constraints",
    1 => "root node must be an object",
    2 => ->(strings : Array(String)) { %{Could not get a valid JSON Schema from "#{strings[0]}"} },

    #--- Validation errors ---
    # GenericValidator
    10 => "Expected value to be equal to the enum",
    11 => "Expected value to be", # "const" value validation

    # ObjectValidator
    20 => "Expected value to be an object",
    21 => ->(strings : Array(String)) { %{Expected required property "#{strings[0]}" to be set} },
    22 => ->(strings : Array(String)) { %{Expected required property "#{strings[0]}" to be set when "#{strings[1]}" is set} },
    23 => ->(strings : Array(String)) { "Expected object to have at least #{strings[0]} properties" },
    24 => ->(strings : Array(String)) { "Expected object to have at most #{strings[0]} properties" },
    25 => "Expected object not to have additional properties",

    # ArrayValidator
    30 => "Expected value to be an array",
    31 => ->(strings : Array(String)) { "Expected array to be tuple of length #{strings[0]}" },
    32 => ->(strings : Array(String)) { "Expected array to contain at least #{strings[0]} matched items" },
    33 => ->(strings : Array(String)) { "Expected array to contain at most #{strings[0]} matched items" },
    34 => "Expected array to contain at least 1 matched item",
    35 => ->(strings : Array(String)) { "Expected array length to be at least #{strings[0]}" },
    36 => ->(strings : Array(String)) { "Expected array length to be at most #{strings[0]}" },
    37 => "Expected array items to be unique",

    # StringValidator
    40 => "Expected value to be a string",
    41 => ->(strings : Array(String)) { "Expected string to have a minimum length of #{strings[0]}" },
    42 => ->(strings : Array(String)) { "Expected string to have a maximum length of #{strings[0]}" },
    43 => ->(strings : Array(String)) { "Expected string to match pattern /#{strings[0]}/" },
    44 => ->(strings : Array(String)) { %{Expected string to match format "#{strings[0]}"} },

    # NumberValidator
    50 => "Expected value to be a number",
    51 => "Expected numeric value to be an integer",
    52 => ->(strings : Array(String)) { "Expected numeric value be greater than or equal to #{strings[0]}" },
    53 => ->(strings : Array(String)) { "Expected numeric value be less than or equal to #{strings[0]}" },
    54 => ->(strings : Array(String)) { "Expected numeric value be greater than #{strings[0]}" },
    55 => ->(strings : Array(String)) { "Expected numeric value be less than #{strings[0]}" },
    56 => ->(strings : Array(String)) { "Expected numeric value to be multiple of #{strings[0]}" },

    # NullValidator
    60 => "Expected value to be null",

    # BooleanValidator
    70 => "Expected value to be a boolean",

    # CompositeValidator
    80 => "Expected value to match all schemas",
    81 => "Expected value to match any of the schemas",
    82 => "Expected value to match only one of the schemas",
    83 => "Expected value not to match any of the schemas",
  }

  @@i18n = I18N.new

  # Provides a reference to the I18N instance global to the module
  def self.i18n : I18N
    @@i18n
  end

  # Allows translation of generated messages (mostly exceptions). Generally you do not need
  # to interact with this class, other than to set the lang to a custom configuration.
  #
  # To create your own translation, copy the value `EN_US` [from the source](https://github.com/aarongodin/jsonschema/blob/main/src/i18n.cr) and define it in your
  # application (with a different constant name). Translate the strings, ensuring that the keys are not changed. Then, call `#set_lang`:
  #
  # ```
  # require "jsonschema"
  #
  # LANG = {
  #   0 => "..",
  #   # ...etc
  # }
  #
  # JSONSchema.i18n.set_lang(LANG)
  # ```
  class I18N
    @lang = EN_US

    # Used internally to display translated messages.
    def get(key)
      translated = if @lang.has_key?(key)
        @lang[key]
      else
        EN_US[key]
      end

      translated.as(String)
    end

    def get(key, *strings)
      translator = if @lang.has_key?(key) @lang[key] else EN_US[key] end
      translator.as(Translator).call(strings.to_a)
    end

    # Set a user-created lang. A `lang` is just a `Hash` where the keys of the Hash
    # are identical to the expected keys for the lang.
    #
    # See the constant value `EN_US` for a reference.
    def set_lang(lang : Lang)
      @lang = lang
    end
  end
end
