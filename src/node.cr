
module Holycc
  module Ast
    abstract class Node
      class Error < Exception; end

      def name
        {{ @type }}.to_s.split("::").last.underscore
      end

      def to_s(io)
        io.print "s(:#{name})"
      end
    end

    class NumberLiteral < Node
      property :value
      def initialize(@value : String)
      end
      def to_s(io)
        io.print "s(:#{name}, #{@value})"
      end
      def ==(o)
        value == o.value
      end
    end
    class Nop < Node
    end
    class BinOp < Node
      property :type, :left, :right
      def initialize(@type : Symbol, @left : Node, @right : Node)
      end
      def to_s(io)
        io.print "s(:#{name}, :#{@type}, #{left}, #{right})"
      end
    end

  end
end
