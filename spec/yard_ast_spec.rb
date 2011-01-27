# -*- coding: utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "YardAst" do
  def node(expression)
    YARD::Parser::Ruby::RubyParser.new(expression, nil).parse.root
  end

  describe YARD::Parser::Ruby::AstNode do
    describe Symbol do
      it "normal style" do
        node(":symbol1").inspect.should == 's(s(:symbol_literal, s(:symbol, s(:ident, "symbol1"))))'
      end

      {
        "with double quotation" => ':"symbol1"',
        "with single quotation" => ":'symbol1'",
      }.each do |example_name, expression|
        it(example_name) do
          node(expression).inspect.should == 's(s(:dyna_symbol, s(s(:tstring_content, "symbol1"))))'
        end
      end
    end

    describe String do
      {
        "with double quotation" => '"symbol1"',
        "with single quotation" => "'symbol1'",
        "with %q{}" => "%q{symbol1}",
      }.each do |example_name, expression|
        it(example_name) do
          node(expression).inspect.should == 's(s(:string_literal, s(:string_content, s(:tstring_content, "symbol1"))))'
        end
      end
    end

    describe "method invocation" do
      context "without brace" do
        it "no arguments" do
          node("foo1").inspect.should == 's(s(:var_ref, s(:ident, "foo1")))'
          node("foo1")[0].inspect.should == 's(:var_ref, s(:ident, "foo1"))'
          node("foo1")[0][0].inspect.should == 's(:ident, "foo1")'
        end

        it "Symbol" do
          node("foo1 :bar1").inspect.should == 's(s(:command, s(:ident, "foo1"), s(s(:symbol_literal, s(:symbol, s(:ident, "bar1"))), false)))'
          node("foo1 :bar1")[0].inspect.should == 's(:command, s(:ident, "foo1"), s(s(:symbol_literal, s(:symbol, s(:ident, "bar1"))), false))'
          node("foo1 :bar1")[0][0].inspect.should == 's(:ident, "foo1")'
          node("foo1 :bar1")[0][1].inspect.should == 's(s(:symbol_literal, s(:symbol, s(:ident, "bar1"))), false)'
          node("foo1 :bar1")[0][1][0].inspect.should == 's(:symbol_literal, s(:symbol, s(:ident, "bar1")))'
          node("foo1 :bar1")[0][1][0][0].inspect.should == 's(:symbol, s(:ident, "bar1"))'
        end

        it "Symbol, variable" do
          node("foo1 :bar1, baz").inspect.should == 's(s(:command, s(:ident, "foo1"), s(s(:symbol_literal, s(:symbol, s(:ident, "bar1"))), s(:var_ref, s(:ident, "baz")), false)))'
          node("foo1 :bar1, baz")[0].inspect.should == 's(:command, s(:ident, "foo1"), s(s(:symbol_literal, s(:symbol, s(:ident, "bar1"))), s(:var_ref, s(:ident, "baz")), false))'
          node("foo1 :bar1, baz")[0][0].inspect.should == 's(:ident, "foo1")'
          node("foo1 :bar1, baz")[0][1].inspect.should == 's(s(:symbol_literal, s(:symbol, s(:ident, "bar1"))), s(:var_ref, s(:ident, "baz")), false)'
          node("foo1 :bar1, baz")[0][1][0].inspect.should == 's(:symbol_literal, s(:symbol, s(:ident, "bar1")))'
          node("foo1 :bar1, baz")[0][1][1].inspect.should == 's(:var_ref, s(:ident, "baz"))'
        end

        it "Symbol, option" do
          node("foo1 :bar1, :baz1 => true").inspect.should == 's(s(:command, s(:ident, "foo1"), s(s(:symbol_literal, s(:symbol, s(:ident, "bar1"))), s(s(:assoc, s(:symbol_literal, s(:symbol, s(:ident, "baz1"))), s(:var_ref, s(:kw, "true")))), false)))'
        end

        it "Symbol, options" do
          node("foo1 :bar1, :baz1 => true, :baz2 => 1").inspect.should == 's(s(:command, s(:ident, "foo1"), s(s(:symbol_literal, s(:symbol, s(:ident, "bar1"))), s(s(:assoc, s(:symbol_literal, s(:symbol, s(:ident, "baz1"))), s(:var_ref, s(:kw, "true"))), s(:assoc, s(:symbol_literal, s(:symbol, s(:ident, "baz2"))), s(:int, "1"))), false)))'
        end

        it "brace block" do
          node("foo1{ baz }").inspect.should == 's(s(:fcall, s(:ident, "foo1"), s(), s(:brace_block, nil, s(s(:var_ref, s(:ident, "baz"))))))'
          node("foo1{ baz }")[0].inspect.should == 's(:fcall, s(:ident, "foo1"), s(), s(:brace_block, nil, s(s(:var_ref, s(:ident, "baz")))))'
          node("foo1{ baz }")[0][0].inspect.should == 's(:ident, "foo1")'
          node("foo1{ baz }")[0][1].inspect.should == 's()'
          node("foo1{ baz }")[0][1].empty?.should == true
          node("foo1{ baz }")[0][2].inspect.should == 's(:brace_block, nil, s(s(:var_ref, s(:ident, "baz"))))'
        end

        it "do..end block" do
          node("foo1 do\n  baz\nend").inspect.should == 's(s(:fcall, s(:ident, "foo1"), s(), s(:do_block, nil, s(s(:var_ref, s(:ident, "baz"))))))'
        end

        it "Symbol, option and do...end block" do
          node("foo1 :bar1, :baz1 => true do\n  foo1\nend").inspect.should == 's(s(:command, s(:ident, "foo1"), s(s(:symbol_literal, s(:symbol, s(:ident, "bar1"))), s(s(:assoc, s(:symbol_literal, s(:symbol, s(:ident, "baz1"))), s(:var_ref, s(:kw, "true")))), false), s(:do_block, nil, s(s(:var_ref, s(:ident, "foo1"))))))'
        end
      end

      context "with brace" do
        it "no arguments" do
          node("foo1()").inspect.should == 's(s(:fcall, s(:ident, "foo1"), s(:arg_paren, nil)))'
          node("foo1()")[0].inspect.should == 's(:fcall, s(:ident, "foo1"), s(:arg_paren, nil))'
          node("foo1()")[0][0].inspect.should == 's(:ident, "foo1")'
          node("foo1()")[0][1].inspect.should == 's(:arg_paren, nil)'
        end

        it "Symbol" do
          node("foo1(:bar1)").inspect.should == 's(s(:fcall, s(:ident, "foo1"), s(:arg_paren, s(s(:symbol_literal, s(:symbol, s(:ident, "bar1"))), false))))'
          node("foo1(:bar1)")[0].inspect.should == 's(:fcall, s(:ident, "foo1"), s(:arg_paren, s(s(:symbol_literal, s(:symbol, s(:ident, "bar1"))), false)))'
          node("foo1(:bar1)")[0][0].inspect.should == 's(:ident, "foo1")'
          node("foo1(:bar1)")[0][1].inspect.should == 's(:arg_paren, s(s(:symbol_literal, s(:symbol, s(:ident, "bar1"))), false))'
          node("foo1(:bar1)")[0][1][0].inspect.should == 's(s(:symbol_literal, s(:symbol, s(:ident, "bar1"))), false)'
          node("foo1(:bar1)")[0][1][0][0].inspect.should == 's(:symbol_literal, s(:symbol, s(:ident, "bar1")))'
        end

        it "Symbol, variable" do
          node("foo1(:bar1, baz)").inspect.should == 's(s(:fcall, s(:ident, "foo1"), s(:arg_paren, s(s(:symbol_literal, s(:symbol, s(:ident, "bar1"))), s(:var_ref, s(:ident, "baz")), false))))'
          node("foo1(:bar1, baz)")[0].inspect.should == 's(:fcall, s(:ident, "foo1"), s(:arg_paren, s(s(:symbol_literal, s(:symbol, s(:ident, "bar1"))), s(:var_ref, s(:ident, "baz")), false)))'
          node("foo1(:bar1, baz)")[0][0].inspect.should == 's(:ident, "foo1")'
          node("foo1(:bar1, baz)")[0][1].inspect.should == 's(:arg_paren, s(s(:symbol_literal, s(:symbol, s(:ident, "bar1"))), s(:var_ref, s(:ident, "baz")), false))'
          node("foo1(:bar1, baz)")[0][1][0].inspect.should == 's(s(:symbol_literal, s(:symbol, s(:ident, "bar1"))), s(:var_ref, s(:ident, "baz")), false)'
          node("foo1(:bar1, baz)")[0][1][0][0].inspect.should == 's(:symbol_literal, s(:symbol, s(:ident, "bar1")))'
          node("foo1(:bar1, baz)")[0][1][0][1].inspect.should == 's(:var_ref, s(:ident, "baz"))'
        end

        it "Symbol, option" do
          node("foo1(:bar1, :baz1 => true)").inspect.should == 's(s(:fcall, s(:ident, "foo1"), s(:arg_paren, s(s(:symbol_literal, s(:symbol, s(:ident, "bar1"))), s(s(:assoc, s(:symbol_literal, s(:symbol, s(:ident, "baz1"))), s(:var_ref, s(:kw, "true")))), false))))'
        end

        it "Symbol, options" do
          node("foo1(:bar1, :baz1 => true, :baz2 => 1)").inspect.should == 's(s(:fcall, s(:ident, "foo1"), s(:arg_paren, s(s(:symbol_literal, s(:symbol, s(:ident, "bar1"))), s(s(:assoc, s(:symbol_literal, s(:symbol, s(:ident, "baz1"))), s(:var_ref, s(:kw, "true"))), s(:assoc, s(:symbol_literal, s(:symbol, s(:ident, "baz2"))), s(:int, "1"))), false))))'
        end

        it "brace block" do
          node("foo1(){ baz }").inspect.should == 's(s(:fcall, s(:ident, "foo1"), s(:arg_paren, nil), s(:brace_block, nil, s(s(:var_ref, s(:ident, "baz"))))))'
          node("foo1(){ baz }")[0].inspect.should == 's(:fcall, s(:ident, "foo1"), s(:arg_paren, nil), s(:brace_block, nil, s(s(:var_ref, s(:ident, "baz")))))'
          node("foo1(){ baz }")[0][0].inspect.should == 's(:ident, "foo1")'
          node("foo1(){ baz }")[0][1].inspect.should == 's(:arg_paren, nil)'
          node("foo1(){ baz }")[0][1].empty?.should == false
          node("foo1(){ baz }")[0][1][0].should == nil
          node("foo1(){ baz }")[0][2].inspect.should == 's(:brace_block, nil, s(s(:var_ref, s(:ident, "baz"))))'
        end

        it "do..end block" do
          node("foo1() do\n  baz\nend").inspect.should == 's(s(:fcall, s(:ident, "foo1"), s(:arg_paren, nil), s(:do_block, nil, s(s(:var_ref, s(:ident, "baz"))))))'
        end

        it "Symbol, option and do...end block" do
          node("foo1(:bar1, :baz1 => true) do\n  foo1\nend").inspect.should == 's(s(:fcall, s(:ident, "foo1"), s(:arg_paren, s(s(:symbol_literal, s(:symbol, s(:ident, "bar1"))), s(s(:assoc, s(:symbol_literal, s(:symbol, s(:ident, "baz1"))), s(:var_ref, s(:kw, "true")))), false)), s(:do_block, nil, s(s(:var_ref, s(:ident, "foo1"))))))'
        end
      end

    end
  end


 describe YardAstEditable::Fcall do
    before do
      script = <<-EOS
# comment1
instance("i-12345678") do
  # comment2
  agent("mm_system_agent") do
    # comment3
    service("system")
    # comment4
  end
  # comment5
end
# comment6
EOS
      ast = YARD::Parser::Ruby::RubyParser.new(script, nil).parse.root
      node = ast.fcall_by_ident(:instance){|fcall|
        !fcall.arguments.empty? && (n = fcall.arguments.first; n.first.source == "i-12345678")
      }
      @caller = YardAstEditable::Fcall.new(node)
    end

    describe :block_content_source do
      # reported by totty. ありがとー
      it "[BUG] ネストしているブロックの内部のendの処理がおかしい" do
        # バグ修正前は以下のようになっていました。
        # -  agent("mm_system_agent") do
        # +agent("mm_system_agent") do
        #      service("system")
        # -  end
        # +  
        # +end
        @caller.block.nil?.should be_false
        result = @caller.block_content_source
        result.should == <<-EXPECT
  # comment2
  agent("mm_system_agent") do
    # comment3
    service("system")
    # comment4
  end
  # comment5
EXPECT
      end
    end
  end

end
