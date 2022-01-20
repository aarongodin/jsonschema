require "./processor"

path = Path.new ARGV[0]

if path.extension == ""
  puts JSONSchema.process_file("#{path}.json")
else
  puts JSONSchema.process_file(path.to_s)
end
