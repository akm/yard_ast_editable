# -*- coding: utf-8 -*-
require 'yard'

module YardAstEditable

  class Fcall
    def initialize(base_node)
      @base_node = base_node
    end

    def name
      @base_node[0].source
    end

    def arguments
      unless @arguments
        arg_paren = @base_node[1]
        @arguments = arg_paren.empty? ? [] :
          (args_node = arg_paren[0]; args_node.nil? ? [] : args_node.map{|node| node})
        @arguments.pop if arg_paren.type == :arg_paren
      end
      @arguments
    end

    def block
      @base_node[2]
    end
  end


  # メソッドを見つける
  # fcall_ident: メソッド名
  def fcall_by_ident(fcall_ident)
    fcall_ident = fcall_ident.to_s
    traverse do |child|
      if child.type == :fcall
        if child[0].source == fcall_ident
          if block_given?
            return(child) if yield(Fcall.new(child))
          else
            return(child)
          end
        end
      end
    end
    nil
  end
end

YARD::Parser::Ruby::AstNode.module_eval do
  include YardAstEditable
end
