# -*- coding: utf-8 -*-
require 'yard'

module YardAstEditable

  class Fcall
    attr_reader :node
    def initialize(node)
      @node = node
    end

    def name
      @node[0].source
    end

    def block
      @node[2]
    end

    def arguments
      return @arguments if @arguments
      n = @node[1]
      @arguments = (n.type == :arg_paren ? n[0] : n) || []
      @arguments.pop if @arguments.last == false
      @arguments
    end

    def block_content_source
      return nil unless block
      result = block.source
      case block.type
      when :do_block then
        result.sub!(/\Ado[ \t\f]*(\|.*?\|)?\n?/, '')
        result.sub!(/end[\s\n]*\Z/, '')
      when :brace_block then
        result.sub!(/^\{\s*(\|.*?\|)?\n?/, '')
        result.sub!(/\}[\s\n]*\Z/, '')
      end
      result
    end
  end


  FCALL_TYPES = [:fcall, :command].freeze

  # メソッドを見つける
  # fcall_ident: メソッド名
  def fcall_by_ident(fcall_ident)
    fcall_ident = fcall_ident.to_s
    traverse do |child|
      if FCALL_TYPES.include?(child.type)
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

#   def children_source
#     ranges = children.map{|c| [c.comments_range, c.source_range] }.flatten.compact
#     min_range = ranges.min_by(&:first)
#     max_range = ranges.max_by(&:last)
#     puts "min_range: #{min_range.inspect}"
#     puts "max_range: #{max_range.inspect}"
#     full_source[min_range.first..max_range.last]
#   end


  def replace_source(node, new_source)
    result = full_source.dup
    result[node.source_range] = new_source
    result
  end

end

YARD::Parser::Ruby::AstNode.module_eval do
  include YardAstEditable
end
