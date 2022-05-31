require "./define"
require "./error"
require "./validator"
require "./render"

path = Path.new ARGV[0]

module JSONSchema
  # :nodoc:
  def self.process_file(filename : String) : String
    begin
      contents = File.read filename
      define_schema(JSON.parse(contents)).to_cr
    rescue ex
      raise InvalidSchemaError.new(ex.message, ex, filename)
    end
  end
end

if path.extension == ""
  puts JSONSchema.process_file("#{path}.json")
else
  puts JSONSchema.process_file(path.to_s)
end
