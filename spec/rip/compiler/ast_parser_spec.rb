require 'spec_helper'

describe Rip::Compiler::AST do
  let(:location) { location_for }
  let(:expressions) { syntax_tree(rip).expressions }

  context 'some basics' do
    describe 'tree for empty module' do
      let(:rip) { '' }
      let(:rip_module) { Rip::Nodes::Module.new(location, []) }

      specify do
        expect(syntax_tree(rip)).to eq(rip_module)
        expect(expressions.count).to eq(0)
      end
    end

    describe 'tree for comments' do
      let(:rip) { '# this is a comment' }
      let(:comment) { Rip::Nodes::Comment.new(location.add_character, ' this is a comment') }
      let(:rip_module) { Rip::Nodes::Module.new(location, [ comment ]) }

      specify do
        expect(expressions.count).to eq(1)
        expect(expressions.first).to eq(comment)
      end
    end
  end

  context 'single token module' do
    let(:rip) { 'rip' }
    let(:reference_node) { Rip::Nodes::Reference.new(location, rip) }

    it 'finds a single node' do
      expect(expressions.count).to eq(1)
    end

    it 'finds a single reference as the first node' do
      expect(expressions.first).to eq(reference_node)
    end
  end

  context 'key-value pair' do
    subject { expressions.first }
    let(:rip) { ':key: :value' }
    let(:key_characters) do
      [
        Rip::Nodes::Character.new(location.add_character(1), 'k'),
        Rip::Nodes::Character.new(location.add_character(2), 'e'),
        Rip::Nodes::Character.new(location.add_character(3), 'y')
      ]
    end
    let(:key_node) { Rip::Nodes::String.new(location.add_character, key_characters) }
    let(:value_characters) do
      [
        Rip::Nodes::Character.new(location.add_character(7), 'v'),
        Rip::Nodes::Character.new(location.add_character(8), 'a'),
        Rip::Nodes::Character.new(location.add_character(9), 'l'),
        Rip::Nodes::Character.new(location.add_character(10), 'u'),
        Rip::Nodes::Character.new(location.add_character(11), 'e')
      ]
    end
    let(:value_node) { Rip::Nodes::String.new(location.add_character(7), value_characters) }
    let(:key_value_node) { Rip::Nodes::KeyValue.new(location.add_character, key_node, value_node) }

    it 'has one top-level node' do
      expect(expressions.count).to eq(1)
    end

    it 'finds the key-value node' do
      expect(expressions.first).to eq(key_value_node)
    end

    its(:key) { should eq(key_node) }
    its(:value) { should eq(value_node) }
  end

  context 'range' do
    subject { expressions.first }
    let(:rip) { '`a..`z' }
    let(:a_node) { Rip::Nodes::Character.new(location.add_character, 'a') }
    let(:z_node) { Rip::Nodes::Character.new(location.add_character(5), 'z') }
    let(:range_node) { Rip::Nodes::Range.new(location.add_character, a_node, z_node) }

    it 'has one top-level node' do
      expect(expressions.count).to eq(1)
    end

    it 'finds the range node' do
      expect(expressions.first).to eq(range_node)
    end

    its(:start) { should eq(a_node) }
    its(:end) { should eq(z_node) }
    its(:exclusivity) { should be_false }
  end

  context 'property' do
    subject { expressions.first }
    let(:rip) { 'one.two' }
    let(:object_node) { Rip::Nodes::Reference.new(location, 'one') }
    let(:property_node) { Rip::Nodes::Property.new(location.add_character(4), object_node, 'two') }

    it 'has one top-level node' do
      expect(expressions.count).to eq(1)
    end

    it 'finds the property node' do
      expect(expressions.first).to eq(property_node)
    end

    its(:object) { should eq(object_node) }
    its(:name) { should eq('two') }
  end

  context 'assignment' do
    let(:line_two) { new_location(:rspec, 10, 2, 1) }
    let(:rip) { "# find me\nlanguage = :rip" }
    let(:comment_node) { Rip::Nodes::Comment.new(location.add_character, ' find me') }
    let(:reference_node) { Rip::Nodes::Reference.new(line_two, 'language') }
    let(:characters) do
      [
        Rip::Nodes::Character.new(line_two.add_character(12), 'r'),
        Rip::Nodes::Character.new(line_two.add_character(13), 'i'),
        Rip::Nodes::Character.new(line_two.add_character(14), 'p')
      ]
    end
    let(:string_node) { Rip::Nodes::String.new(line_two.add_character(12), characters) }
    let(:assignment_node) { Rip::Nodes::Assignment.new(line_two.add_character(9), reference_node, string_node) }

    let(:comment) { expressions.first }
    let(:assignment) { expressions.last }

    it 'has two top-level nodes' do
      expect(expressions.count).to eq(2)
    end

    it 'knows the first node is a comment' do
      expect(comment).to eq(comment_node)
    end

    it 'finds an assignment as the last node' do
      expect(assignment).to eq(assignment_node)
      expect(assignment.reference).to eq(reference_node)
      expect(assignment.value).to eq(string_node)
    end
  end

  context 'blocks' do
    let(:rip) { '-> (other) {}' }

    let(:dash_rocket_node) { Rip::Utilities::Keywords[:dash_rocket] }
    let(:parameter_nodes) { [ Rip::Nodes::Reference.new(location.add_character(4), 'other') ] }
    let(:body_node) { Rip::Nodes::BlockBody.new(location.add_character(11), []) }
    let(:lambda_node) { Rip::Nodes::Lambda.new(location, dash_rocket_node, parameter_nodes, body_node) }

    it 'has one top-level node' do
      expect(expressions.count).to eq(1)
    end

    it 'finds the lambda' do
      expect(expressions.first).to eq(lambda_node)
    end
  end

  context 'property assignment' do
    let(:rip) { '@.== = -> (other) {}' }

    let(:prototype_node) { Rip::Nodes::Reference.new(location, '@') }
    let(:property_node) { Rip::Nodes::Property.new(location.add_character(2), prototype_node, '==') }

    let(:assignment_node) { Rip::Nodes::Assignment.new(location.add_character(5), property_node, lambda_node) }

    let(:dash_rocket_node) { Rip::Utilities::Keywords[:dash_rocket] }
    let(:parameter_node) { Rip::Nodes::Reference.new(location.add_character(11), 'other') }
    let(:body_node) { Rip::Nodes::BlockBody.new(location.add_character(18), []) }
    let(:lambda_node) { Rip::Nodes::Lambda.new(location.add_character(7), dash_rocket_node, [parameter_node], body_node) }

    let(:assignment) { expressions.first }
    let(:assignee) { assignment.reference }
    let(:value) { assignment.value }

    it 'has one top-level node' do
      expect(expressions.count).to eq(1)
    end

    it 'finds the assignment' do
      expect(assignment).to eq(assignment_node)
    end

    it 'assigns to the == property' do
      expect(assignee).to eq(property_node)
    end

    it 'assigns a lambda' do
      expect(value).to eq(lambda_node)
    end
  end

  shared_examples_for 'invocation' do
    it 'has one top-level node' do
      expect(expressions.count).to eq(1)
    end

    it 'finds the plus invocation' do
      expect(invocation_plus).to eq(invocation_node_plus)
      expect(invocation_plus.arguments).to eq([two_node])
      expect(invocation_plus.callable).to eq(property_node_plus)
      expect(invocation_plus.callable.object).to eq(one_node)
      expect(invocation_plus.callable.name).to eq('+')
    end

    it 'finds the times invocation' do
      expect(invocation_times).to eq(invocation_node_times)
      expect(invocation_times.arguments).to eq([three_node])
      expect(invocation_times.callable).to eq(property_node_times)
      expect(invocation_times.callable.object).to eq(invocation_plus)
      expect(invocation_times.callable.name).to eq('*')
    end
  end

  context 'standard invocation' do
    let(:rip) { '1.+(2).*(3)' }

    let(:one_node) { Rip::Nodes::Integer.new(location, '1') }
    let(:two_node) { Rip::Nodes::Integer.new(location.add_character(4), '2') }
    let(:three_node) { Rip::Nodes::Integer.new(location.add_character(9), '3') }

    let(:property_node_plus) { Rip::Nodes::Property.new(location.add_character(2), one_node, '+') }
    let(:invocation_node_plus) { Rip::Nodes::Invocation.new(location.add_character(3), property_node_plus, [two_node]) }

    let(:property_node_times) { Rip::Nodes::Property.new(location.add_character(7), invocation_node_plus, '*') }
    let(:invocation_node_times) { Rip::Nodes::Invocation.new(location.add_character(8), property_node_times, [three_node]) }

    let(:invocation_times) { expressions.first }
    let(:invocation_plus) { invocation_times.callable.object }

    it_behaves_like 'invocation'
  end

  context 'operator invocation' do
    let(:rip) { '1 + 2 * 3' }

    let(:one_node) { Rip::Nodes::Integer.new(location, '1') }
    let(:two_node) { Rip::Nodes::Integer.new(location.add_character(4), '2') }
    let(:three_node) { Rip::Nodes::Integer.new(location.add_character(8), '3') }

    let(:property_node_plus) { Rip::Nodes::Property.new(location.add_character(2), one_node, '+') }
    let(:invocation_node_plus) { Rip::Nodes::Invocation.new(location.add_character(2), property_node_plus, [two_node]) }

    let(:property_node_times) { Rip::Nodes::Property.new(location.add_character(6), invocation_node_plus, '*') }
    let(:invocation_node_times) { Rip::Nodes::Invocation.new(location.add_character(6), property_node_times, [three_node]) }

    let(:invocation_times) { expressions.first }
    let(:invocation_plus) { invocation_times.callable.object }

    it_behaves_like 'invocation'
  end

  context 'switch blocks' do
    let(:rip) do
      strip_heredoc(<<-RIP)
        switch (x) {
          case (1) {}
          case (2) {}
          case (3) {}
          else     {}
        }
      RIP
    end

    let(:line_2) { location.add_character(12).add_line }
    let(:case_1_argument_node) { Rip::Nodes::Integer.new(line_2.add_character(8), '1') }
    let(:case_1_body_node) { Rip::Nodes::BlockBody.new(line_2.add_character(11), []) }
    let(:case_1_node) { Rip::Nodes::Case.new(line_2.add_character(2), [ case_1_argument_node ], case_1_body_node) }

    let(:line_3) { line_2.add_character(13).add_line }
    let(:case_2_argument_node) { Rip::Nodes::Integer.new(line_3.add_character(8), '2') }
    let(:case_2_body_node) { Rip::Nodes::BlockBody.new(line_3.add_character(11), []) }
    let(:case_2_node) { Rip::Nodes::Case.new(line_3.add_character(2), [ case_2_argument_node ], case_2_body_node) }

    let(:line_4) { line_3.add_character(13).add_line }
    let(:case_3_argument_node) { Rip::Nodes::Integer.new(line_4.add_character(8), '3') }
    let(:case_3_body_node) { Rip::Nodes::BlockBody.new(line_4.add_character(11), []) }
    let(:case_3_node) { Rip::Nodes::Case.new(line_4.add_character(2), [ case_3_argument_node ], case_3_body_node) }

    let(:line_5) { line_4.add_character(13).add_line }
    let(:else_body_node) { Rip::Nodes::BlockBody.new(line_5.add_character(11), []) }
    let(:else_node) { Rip::Nodes::Else.new(line_5.add_character(2), else_body_node) }

    let(:switch_argument_node) { Rip::Nodes::Reference.new(location.add_character(8), 'x') }
    let(:switch_node) { Rip::Nodes::Switch.new(location, switch_argument_node, [ case_1_node, case_2_node, case_3_node ], else_node) }

    let(:switch_block) { expressions.first }

    it 'has one top-level node' do
      expect(expressions.count).to eq(1)
    end

    it 'finds the switch' do
      expect(switch_block.case_blocks[0]).to eq(switch_node.case_blocks[0])
      expect(switch_block.case_blocks[1]).to eq(switch_node.case_blocks[1])
      expect(switch_block.case_blocks[2]).to eq(switch_node.case_blocks[2])

      expect(switch_block.else_block).to eq(switch_node.else_block)

      expect(switch_block).to eq(switch_node)
    end
  end

  context 'interpolation for regular expression' do
    let(:rip) { '/#{a}b/' }

    let(:reference) { Rip::Nodes::Reference.new(location.add_character(3), 'a') }
    let(:interpolation) { Rip::Nodes::Interpolation.new(location.add_character(1), [ reference ]) }
    let(:plus) { Rip::Nodes::Property.new(location.add_character(4), interpolation, '+') }

    let(:character) { Rip::Nodes::Character.new(location.add_character(5), 'b') }
    let(:regular_expression) { Rip::Nodes::RegularExpression.new(location.add_character(5), [ character ]) }

    let(:concatenation_node) { Rip::Nodes::Invocation.new(location.add_character(4), plus, [ regular_expression ]) }

    let(:concatenation) { expressions.first }

    it 'has one top-level node' do
      expect(expressions.count).to eq(1)
    end

    it 'transforms interpolation into regular expression concatenation' do
      expect(concatenation.callable.object).to eq(interpolation)
      expect(concatenation.callable).to eq(plus)
      expect(concatenation.arguments.first).to eq(regular_expression)

      expect(concatenation).to eq(concatenation_node)
    end
  end

  context 'interpolation for string' do
    let(:rip) { '"#{a}b"' }

    let(:reference) { Rip::Nodes::Reference.new(location.add_character(3), 'a') }
    let(:interpolation) { Rip::Nodes::Interpolation.new(location.add_character(1), [ reference ]) }
    let(:plus) { Rip::Nodes::Property.new(location.add_character(4), interpolation, '+') }

    let(:character) { Rip::Nodes::Character.new(location.add_character(5), 'b') }
    let(:string) { Rip::Nodes::String.new(location.add_character(5), [ character ]) }

    let(:concatenation_node) { Rip::Nodes::Invocation.new(location.add_character(4), plus, [ string ]) }

    let(:concatenation) { expressions.first }

    it 'has one top-level node' do
      expect(expressions.count).to eq(1)
    end

    it 'transforms interpolation into string concatenation' do
      expect(concatenation.callable.object).to eq(interpolation)
      expect(concatenation.callable).to eq(plus)
      expect(concatenation.arguments.first).to eq(string)

      expect(concatenation).to eq(concatenation_node)
    end
  end

  context 'binary conditional block' do
    let(:rip) do
      strip_heredoc(<<-RIP)
        if (true) { :hello }
        else      { :goodbye }
      RIP
    end

    let(:reference_node) { Rip::Nodes::Reference.new(location.add_character(4), 'true') }

    let(:hello_node) { Rip::Nodes::String.new(location.add_character(13), rip_string_nodes(location.add_character(12), 'hello')) }
    let(:true_body) { Rip::Nodes::BlockBody.new(location.add_character(10), [ hello_node ]) }

    let(:line_2) { location.add_character(20).add_line }
    let(:goodbye_node) { Rip::Nodes::String.new(line_2.add_character(13), rip_string_nodes(line_2.add_character(12), 'goodbye')) }
    let(:false_body) { Rip::Nodes::BlockBody.new(line_2.add_character(10), [ goodbye_node ]) }

    let(:if_else_node) { Rip::Nodes::If.new(location, reference_node, true_body, false_body) }

    let(:if_else) { expressions.first }

    it 'has one top-level node' do
      expect(expressions.count).to eq(1)
    end

    it 'transforms into if' do
      expect(if_else.argument).to eq(reference_node)

      expect(if_else.true_body).to eq(true_body)
      expect(if_else.false_body).to eq(false_body)

      expect(if_else).to eq(if_else_node)
    end
  end

  context 'binary conditional block with synthesized else' do
    let(:rip) { 'unless (false) { :implied_else }' }

    let(:reference_node) { Rip::Nodes::Reference.new(location.add_character(8), 'false') }

    let(:implied_node) { Rip::Nodes::String.new(location.add_character(18), rip_string_nodes(location.add_character(17), 'implied_else')) }
    let(:false_body) { Rip::Nodes::BlockBody.new(location.add_character(15), [ implied_node ]) }

    let(:true_body) { Rip::Nodes::BlockBody.new(location.add_character(15), []) }

    let(:unless_else_node) { Rip::Nodes::Unless.new(location, reference_node, false_body, true_body) }

    let(:unless_else) { expressions.first }

    it 'has one top-level node' do
      expect(expressions.count).to eq(1)
    end

    it 'transforms into unless' do
      expect(unless_else.argument).to eq(reference_node)

      expect(unless_else.false_body).to eq(false_body)
      expect(unless_else.true_body).to eq(true_body)

      expect(unless_else).to eq(unless_else_node)
    end
  end
end
