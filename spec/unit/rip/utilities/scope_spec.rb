require 'spec_helper'

describe Rip::Utilities::Scope do
  subject { scope_foo }
  let(:scope_foo) { Rip::Utilities::Scope.new }

  before(:each) { scope_foo[:foo] = 111 }

  specify { expect(scope_foo[:foo]).to be(111) }
  specify { expect(scope_foo[:zebra]).to be_nil }

  specify do
    expect { scope_foo[:foo] = 000 }.to raise_error(Rip::Exceptions::CompilerException)
  end

  context 'extending' do
    before(:each) { scope_foo[:bar] = 222 }

    specify { expect(scope_foo[:foo]).to be(111) }
    specify { expect(scope_foo[:bar]).to be(222) }

    context 'shadowing' do
      subject { scope_bar }
      let(:scope_bar) { scope_foo.nested_context }

      before(:each) { scope_bar[:bar] = 333 }

      specify { expect(scope_foo[:foo]).to be(111) }
      specify { expect(scope_foo[:bar]).to be(222) }

      specify { expect(scope_bar[:foo]).to be(111) }
      specify { expect(scope_bar[:bar]).to be(333) }

      describe '#==' do
        let(:expected) { scope_foo.nested_context }

        before(:each) { expected[:bar] = 333 }

        specify { expect(scope_bar).to eq(expected) }
      end

      describe '#symbols' do
        specify { expect(scope_foo.symbols).to match_array([ 'foo', 'bar' ]) }
        specify { expect(scope_bar.symbols).to match_array([ 'foo', 'bar' ]) }
      end
    end

    describe '#==' do
      specify { expect(scope_foo.nested_context).to eq(scope_foo.nested_context) }
    end
  end

  describe '#==' do
    let(:new_scope) { Rip::Utilities::Scope.new }

    before(:each) { new_scope[:foo] = 111 }

    specify { expect(scope_foo).to eq(new_scope) }
  end

  describe '#origin' do
    let(:origin_context) { Rip::Utilities::Scope.new(scope_foo, :ORIGIN) }

    specify { expect(scope_foo.origin).to be_nil }
    specify { expect(scope_foo.nested_context.origin).to be_nil }
    specify { expect(scope_foo.nested_context.nested_context.origin).to be_nil }

    specify { expect(origin_context.outer_context.origin).to be_nil }
    specify { expect(origin_context.origin).to eq(:ORIGIN) }
    specify { expect(origin_context.nested_context.origin).to eq(:ORIGIN) }
    specify { expect(origin_context.nested_context.nested_context.origin).to eq(:ORIGIN) }
  end

  describe '#symbols' do
    specify { expect(scope_foo.symbols).to match_array(['foo']) }
  end
end
