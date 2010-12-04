require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

block_tree1 = <<EOS
# comment foo1
foo1(:name1) do |f1|
  # bar1 #1
  bar1 do |b1|
    # bar1 #2
    bar1("name2"){|b2|
      # comment b2 S
      puts b2.inspect
      # comment b2 E
    }
    # comment bar2 E
  end
end
foo1(:name2, :opt1 => :true) do |f1|
    # bar1 #3
  bar1{ puts "name2 bar1" }
end
EOS

describe "YardAstEditable" do
  def node(expression)
    YARD::Parser::Ruby::RubyParser.new(expression, nil).parse.root
  end

  describe :fcall_by_ident do
    before do
      @ast = YARD::Parser::Ruby::RubyParser.new(block_tree1, nil).parse.root
    end

    it "foo1 by name only" do
      node = @ast.fcall_by_ident(:foo1)
      node.should be_a(YARD::Parser::Ruby::AstNode)
      node.source.should =~ /^foo1\(:name1\)/
      node.source.should =~ /bar1 do |b1|/
      node[0].should be_a(YARD::Parser::Ruby::AstNode)
      node[0].source.should == "foo1"
    end

    it "first foo1 by name and block" do
      node = @ast.fcall_by_ident(:foo1){|fcall|
        (fcall.arguments.length == 1) && (n = fcall.arguments.first; n.source == ":name1")
      }
      node.should be_a(YARD::Parser::Ruby::AstNode)
      node[0].source.should == "foo1"
      node[1].source.should == "(:name1)"
    end

    it "second foo1 by name and block" do
      node = @ast.fcall_by_ident(:foo1){|fcall|
        fcall.arguments.length == 2 && (n = fcall.arguments.first; n.source == ":name2")
      }
      node.should be_a(YARD::Parser::Ruby::AstNode)
      node[0].source.should == "foo1"
      node[1].source.should == "(:name2, :opt1 => :true)"
    end

    it "find bar1 #1" do
      node = @ast.fcall_by_ident(:bar1){|fcall| fcall.arguments.empty? }
    end

  end

end
