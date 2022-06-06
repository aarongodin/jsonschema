require "./define"
require "./error"
require "./validator"
require "./render"

path = Path.new ARGV[0]

module JSONSchema
  # :nodoc:
  def self.process_file(filename : String) : String
    define_schema(JSON.parse(File.read(filename))).to_cr rescue raise InvalidSchemaError.new(ex.message, ex, filename)
  end
end

if path.extension == ""
  puts JSONSchema.process_file("#{path}.json")
else
  puts JSONSchema.process_file(path.to_s)
end
