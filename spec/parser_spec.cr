require "./spec_helper"
require "../src/syntax/ast/shorthand"

def it_parses(str, node : Z::Ast::Node)
  it str do
    parser = Z::Parser.new(str)
    parser.parse.should eq node
  end
end

include Z::Ast::Shorthand

describe Z::Parser do
  it_parses "1;", prog(num("1"))
  it_parses "(1);", prog(num("1"))
  it_parses "((1));", prog(num("1"))
  it_parses "1 + 2;", prog(bi(:+, num("1"), num("2")))
  it_parses "1 - 2;", prog(bi(:-, num("1"), num("2")))
  it_parses "1 + 2 * 3;",
    prog(
      bi(:+,
        num("1"),
        bi(:*, num("2"), num("3"))))
  it_parses "1 - 2 / 3;",
    prog(
      bi(:-,
        num("1"),
        bi(:/, num("2"), num("3"))))
  it_parses "+1;", prog(num("1"))
  it_parses "+ 1;", prog(num("1"))
  it_parses "- 1;", prog(bi(:-, num("0"), num("1")))
  it_parses "-1;", prog(bi(:-, num("0"), num("1")))
  it_parses "1 <= 2;", prog(bi(:<=, num("1"), num("2")))
  it_parses "1 <= 2;", prog(bi(:<=, num("1"), num("2")))
  it_parses "1 < 2;", prog(bi(:<, num("1"), num("2")))
  it_parses "1 >= 2;", prog(bi(:>=, num("1"), num("2")))
  it_parses "1 > 2;", prog(bi(:>, num("1"), num("2")))
  it_parses "1 == 2;", prog(bi(:==, num("1"), num("2")))
  it_parses "1 == 2;", prog(bi(:==, num("1"), num("2")))
  it_parses "a = 5;", prog(assign(lvar("a", 8), num("5")), 8)
  it_parses "42;", prog(num("42"))
  it_parses "a=b=2;", prog(assign(lvar("a", 8), assign(lvar("b", 16), num("2"))), 16)
  it_parses "a = 5;", prog(assign(lvar("a", 8), num("5")), 8)
end
