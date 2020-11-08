require "./lexer"
require "./node"

# Simple calculator grammar for now
#
# ```
# expr       = equality
# equality   = relational ("==" relational | "!=" relational)*
# relational = add ("<" add | "<=" add | ">" add | ">=" add)*
# add        = mul ("+" mul | "-" mul)*
# mul        = unary ("*" unary | "/" unary)*
# unary      = ("+" | "-")? primary
# primary    = num | "(" expr ")"1j
# ```
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
      _root
    end

    ##

    private def _root
      return Ast::Nop.new if eof?
      e = _expr
      error "expected EOF, got `#{curr.value}`" unless eof?
      e
    end

    # private def _expr
    # end

    # private def _relational
    #   n = _add

    #   loop do
    #     if accept T::LT
    #       n = Ast::BinOp.new(:+, n, _mul)
    #     elsif accept T::MIN
    #       n = Ast::BinOp.new(:-, n, _mul)
    #     else
    #       return n
    #     end
    #   end

    # end

    # private def _add
    private def _expr
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
      n = _unary

      loop do
        if accept T::MUL
          n = Ast::BinOp.new(:*, n, _unary)
        elsif accept T::DIV
          n = Ast::BinOp.new(:/, n, _unary)
        else
          return n
        end
      end
    end

    private def _unary
      if accept T::PLUS
        return _primary
      elsif accept T::MIN
        return Ast::BinOp.new(:-, Ast::NumberLiteral.new("0"), _primary)
      end

      _primary
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
      # return Token.new(0, 0, T::EOF, "\0") if eof?
      return prev if eof?
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
