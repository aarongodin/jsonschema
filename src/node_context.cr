module JSONSchema
  # Tracks the location of a JSON value within a JSON schema.
  class NodeContext
    property parent : NodeContext?
    property path : String

    def initialize(@path = ".", @parent = nil)
    end

    # Get a string representation of the node's full path. The format is dot and square bracket notation,
    # similar to the format expected by `jq`, a popular [JSON querying CLI](https://stedolan.github.io/jq/).
    #
    # Example: `.parent.children[0].example`
    #
    # The top-level `.` will always refer to the root node.
    def to_s
      string_parts = [] of String
      node = self

      until node.nil?
        string_parts.push(node.path)
        node = node.parent
      end

      String.build do |str|
        string_parts.reverse_each { |string_part| str << string_part }
      end
    end

    # Calls `JSON::Any#dig` on a given input to dig to the value represented by this NodeContext.
    def dig_into(input : JSON::Any)
      accessors = [] of String | Int32
      node = self

      until node.nil?
        if node.path == "."
          node = node.parent
          next
        end

        case node.path
        when .starts_with?('.')
          accessors.push(node.path[1..])
        when .starts_with?('[')
          accessors.push(node.path.strip("[]").to_i)
        else
          accessors.push(node.path)
        end

        node = node.parent
      end

      if (accessors.size == 0)
        return input
      end

      accessors.reverse!

      value = input.dig(accessors[0])
      accessor_index = 1

      while (accessor_index < accessors.size)
        value = value.dig(accessors[accessor_index])
        accessor_index = accessor_index + 1
      end

      value
    end

    # Create a child NodeContext based on `self`, taking into account whether `self` is the root node.
    def from_property(prop : String)
      if self.path == "." # We know we are at the root context, so we don't need to prepend `.`
        NodeContext.new(prop, self)
      else
        NodeContext.new(".#{prop}", self)
      end
    end
  end
end
