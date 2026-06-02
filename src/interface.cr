raise "You must pass one single filename!" unless ARGV.size == 1
raise "GGUF filenames must end in \".gguf\"!" unless ARGV[0].ends_with? /\.gguf/i

require "./backend.cr"

puts GGUFFilenameInspector.decode_filename(ARGV.first)
