require "./spec_helper"
require "../src/codegen/compiler"

def it_runs(name, file, expected)
  describe "running" do
    it name do
      output = IO::Memory.new
      err = IO::Memory.new
      Process.run "z",
        ["run", file],
        env: {"PATH" => File.join(Dir.current, "bin") + ":/usr/bin:/bin"},
        output: output,
        error: err
      got = output.to_s.chomp
      puts err.to_s
      begin
        expected.should eq(got)
      rescue error
        fail diff(expected, got)
      end
    end
  end
end

def it_compiles(name, code, expected)
  describe "compiling" do
    it name do
      output = IO::Memory.new
      compiled = Z::Compiler.new(code).compile

      begin
        expected.should eq(compiled)
      rescue error
        fail diff(expected, compiled)
      end
    end
  end
end

for_each_spec do |name, files|
  src = files.find { |f| f.ends_with? ".c" }.not_nil!
  ast = files.find { |f| f.ends_with? ".s" }.not_nil!
  it_compiles name, File.read(src).chomp, File.read(ast).chomp

  if output = files.find { |f| f.ends_with? ".out" }
    it_runs name, src, File.read(output).chomp
  end
end
