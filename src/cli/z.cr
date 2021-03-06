# We're just scripting here instead of using a more modular approach,
# since we don't care about anyone else calling this code, and it's terse.

require "option_parser"
require "../version"
require "../lex/lexer"
require "../parse/parser"
require "../ast/dot"
require "../codegen/compiler"
require "../codegen/obj/elf"

PROG = "z"
lex = false
parse = false
dot = false
compile = false
run = false
stdin = false
string = false
obj = false

parser = OptionParser.new do |parser|
  parser.banner = "Usage: #{PROG} [command] [arguments]"
  parser.on("lex", "Lex input, output tokens") do
    parser.banner = "Usage: #{PROG} lex [arguments]"
    lex = true
  end
  parser.on("parse", "Parse input, output AST") do
    parser.banner = "Usage: #{PROG} parse [arguments]"
    parse = true
  end
  parser.on("dot", "Parse input, output graphviz dot") do
    parser.banner = "Usage: #{PROG} dot [arguments]"
    # ./bin/z -d '1+5;' |tee ast.gv && dot -Tpng ast.gv -o ast.png && firefox ast.png
    dot = true
  end
  parser.on("compile", "Compile input, output assembly") do
    parser.banner = "Usage: #{PROG} compile [arguments]"
    compile = true
  end
  parser.on("run", "Compile and run input") do
    parser.banner = "Usage: #{PROG} run [arguments]"
    run = true
  end
  parser.on("obj", "Analyze object files") do
    parser.banner = "Usage: #{PROG} obj [arguments]"
    obj = true
  end
  parser.on("-i", "Get input from stdin") do
    stdin = true
  end
  parser.on("-c", "Get input from string") do
    string = true
  end
  parser.on("-v", "--version", "Show the version") do
    puts "version #{Z::VERSION}"
    exit
  end
  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end
  parser.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} is not a valid option."
    STDERR.puts parser
    exit(1)
  end
end

parser.parse

if ARGV.empty? && !stdin
  puts parser
  exit
end

if stdin
  input = STDIN.gets_to_end
  puts if STDIN.tty?
elsif string
  input = ARGV[0]
else
  input = File.read(ARGV[0])
end

if lex
  lexer = Z::Lex::Lexer.new(input)
  lexer.each { |token| puts token }
elsif parse
  parser = Z::Parser.new(input)
  puts parser.parse
elsif dot
  parser = Z::Parser.new(input)
  node = parser.parse
  puts node.accept(Z::Ast::Dot.new, STDOUT)
elsif compile
  cc = Z::Compiler.new(input)
  puts cc.compile
elsif obj
  io = IO::Memory.new(input)
  elf = ELF.new(io)
  puts elf
elsif run
  cc = Z::Compiler.new(input.to_s)
  asm_file = File.tempfile("z.S") { |f| f.puts cc.compile }
  bin_file = File.tempfile("a.out") { }
  cc_opts = [] of String
  cc_opts << "-no-pie" if ENV["CI"]?

  # `-no-pie` is needed on Debian to prevent
  #
  # ```
  # a.out: Symbol `putchar' causes overflow in R_X86_64_PC32 relocation
  # ```
  #
  Process.run("gcc", cc_opts + [asm_file.path, "-o", bin_file.path],
    env: {"PATH" => ENV.fetch("PATH")},
    error: STDERR
  )
  Process.exec(bin_file.path)
else
  puts parser
  exit(1)
end
