require "./lexer"
require "./node"

# Simple calculator grammar for now
#
# expr   -> term LEFT_PAREN PLUS term RIGHT_PAREN
#         | term LEFT_PAREN MIN  term RIGHT_PAREN
#         | term
# term   -> factor LEFT_PAREN DIV factor RIGHT_PAREN
#         | factor LEFT_PAREN MUL factor RIGHT_PAREN
#         | factor

# factor -> LEFT_PAREN expr RIGHT_PAREN
#         | number
# number -> INT
#
#
#
#expr    = mul ("+" mul | "-" mul)*
#mul     = primary ("*" primary | "/" primary)*
#primary = num | "(" expr ")"
#
#
# Recursive descent works like so
#
# For each rule, create a procedure that attempts to match a non-terminal
# production.
# a -> b c
#    | d
# b -> ckk
module Holycc
  class Parser
    class Error < Exception
    end

    alias T = Token::Type
    @tokens : Array(Token)

    def initialize(@code : String)
      @lex = Lexer.new(@code)
      @tokens = [] of Token
      @pos = 0
    end

    def parse
      @tokens = @lex.tokens
      # @toens << Token.new(0, 0, T::EOF, "\0") unles
      _root
    end

    ##

    private def _root
      return Ast::Nop.new if eof?
      e = _expr
      error "expected EOF, got `#{curr.value}`" unless eof?
      e
    end

    private def _expr
      # _factor

      n = _mul

      loop do
        if accept T::PLUS
          n = Ast::BinOp.new(:+, n, _mul)
        elsif accept T::MIN
          n = Ast::BinOp.new(:-, n, _mul)
        else
          return n
        end
      end
    end

    private def _mul
      n = _primary

      loop do
        if accept T::MUL
          n = Ast::BinOp.new(:*, n, _primary)
        elsif accept T::DIV
          n = Ast::BinOp.new(:/, n, _primary)
        else
          return n
        end
      end
    end

    private def _primary
      if accept T::LEFT_PAREN
        e = _expr
        consume T::RIGHT_PAREN
        return e
      end

      _number
    end

    private def _number
      if accept T::INT
        return Ast::NumberLiteral.new(prev.value)
      end
      error "expected a number, got `#{curr.value}`"
    end

    ##

    # private def consume(*types : Array(T), msg : String)
    private def consume(type : T, msg : String? = "")
      unless accept type
        error "expected a #{type}, got `#{curr.value}`"
      end
    end

    private def accept(type)
      if match? type
        @pos += 1
        prev
      end
    end

    private def match?(type)
      return false if eof?
      curr.type == type
    end

    private def eof?
      @pos >= @tokens.size
    end

    private def last?
      @pos == @tokens.size - 1
    end

    private def curr
      error "no tokens available for #curr" if @tokens.size.zero?
      error "pos #{@pos} out of range for #curr" if eof? # rm
      @tokens[@pos]
    end

    private def prev
      error "no tokens available for #prev" if @tokens.empty?
      @tokens[@pos - 1]
    end

    private def error(msg : String)
      raise Error.new(msg)
    end
  end
end
