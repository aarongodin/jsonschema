require "./processor"

filename = ARGV[0]

puts JSONSchema.process_file(filename)