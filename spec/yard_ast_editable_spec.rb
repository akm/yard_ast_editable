# -*- coding: utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

block_tree1 = <<EOS
# foo1 #1
foo1(:name1) do |f1|
  # bar1 #1
  bar1 do |b1|
    # bar1 #2
    bar1("name2"){|b2|
      # b2 S
      puts b2.inspect
      # b2 E
    }
    # bar2 E
  end
end
# foo1 #2 S
foo1 :name2, :opt1 => true do |f1|
  # bar1 #3 S
  bar1{ puts "name2 bar1" }
  # bar1 #3 E
end
# foo1 #2 E
EOS

describe "YardAstEditable" do
  before do
    @ast = YARD::Parser::Ruby::RubyParser.new(block_tree1, nil).parse.root
  end

  describe :fcall_by_ident do

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
      node[1].source.should == ":name2, :opt1 => true"
    end

    it "find bar1 #1" do
      node = @ast.fcall_by_ident(:bar1){|fcall| fcall.arguments.empty? }
    end
  end

  describe :children_source do
    
    it "do...endブロックの中身を取得" do
      node = @ast.fcall_by_ident(:foo1){|fcall|
        fcall.arguments.length == 2 && (n = fcall.arguments.first; n.source == ":name2")
      }
      fcall = YardAstEditable::Fcall.new(node)      
      fcall.block_content_source.should == %q{  # bar1 #3 S
  bar1{ puts "name2 bar1" }
  # bar1 #3 E
}
    end
    
    it "{}ブロックの中身を取得" do
      node = @ast.fcall_by_ident(:bar1){|fcall|
        fcall.arguments.length == 1 && (n = fcall.arguments.first; n.source == '"name2"')
      }
      fcall = YardAstEditable::Fcall.new(node)
      fcall.block_content_source.should == %q{      # b2 S
      puts b2.inspect
      # b2 E
    }
    end
    
  end



  describe :replace_source do
    it "全体に対して一部を置換" do
      node = @ast.fcall_by_ident(:foo1){|fcall|
        fcall.arguments.length == 2 && (n = fcall.arguments.first; n.source == ":name2")
      }
      fcall = YardAstEditable::Fcall.new(node)
      fcall.block.should_not == nil
      @ast.replace_source(fcall.block, "do\n  replaced_block\nend").should == <<EOS
# foo1 #1
foo1(:name1) do |f1|
  # bar1 #1
  bar1 do |b1|
    # bar1 #2
    bar1("name2"){|b2|
      # b2 S
      puts b2.inspect
      # b2 E
    }
    # bar2 E
  end
end
# foo1 #2 S
foo1 :name2, :opt1 => true do
  replaced_block
end
# foo1 #2 E
EOS
    end

    it "一部に対して一部を置換" do
      node1 = @ast.fcall_by_ident(:foo1){|fcall|
        fcall.arguments.length == 1 && (n = fcall.arguments.first; n.source == ":name1")
      }
      new_node1 = YARD::Parser::Ruby::RubyParser.new(node1.source, nil).parse.root
      node2 = new_node1.fcall_by_ident(:bar1){|fcall|
        fcall.arguments.length == 1 && (n = fcall.arguments.first; n.source == '"name2"')
      }
      fcall2 = YardAstEditable::Fcall.new(node2)
      fcall2.block.should_not == nil
      expected = <<EOS
foo1(:name1) do |f1|
  # bar1 #1
  bar1 do |b1|
    # bar1 #2
    bar1("name2"){|b2| 'B2'}
    # bar2 E
  end
end
EOS
      expected.chomp!
      new_node1.replace_source(fcall2.block, "{|b2| 'B2'}").should == expected
    end


  end

end
