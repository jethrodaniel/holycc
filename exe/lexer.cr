require "../src/holycc"

puts "[lexer] 'q' to exit"
prompt = "lex> "

print prompt
while line = gets
  exit if line == "q"

  lex = Holycc::Lexer.new(line)

  begin
    res = lex.next_token
    puts "=> #{res}"
  rescue e : Holycc::Lexer::Error
    puts "#{e.class} #{e.message}"
  end

  print prompt
end
