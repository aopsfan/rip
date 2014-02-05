require 'spec_helper'

describe Rip::Core::System do
  let(:class_instance) { Rip::Core::System.class_instance }

  describe 'debug methods' do
    specify { expect(class_instance.to_s).to eq('#< System >') }
  end

  describe '.class_instance' do
    specify { expect(class_instance).to_not be_nil }
    specify { expect(class_instance['class']).to eq(Rip::Core::Class.class_instance) }
  end

  describe '.require' do
    specify { expect(class_instance.symbols).to match_array(['@', 'List', 'String', 'class', 'self', 'require']) }
    specify { expect(class_instance['require']).to be_a(Rip::Core::Lambda) }

    let(:project_dir) { Pathname(Dir.pwd) }
    let(:syntax_tree) { syntax_tree = Rip::Compiler::Parser.new(main_file, main_file.read).syntax_tree }
    let(:final_result) { Rip::Compiler::Driver.new(syntax_tree).interpret }

    before(:each) do
      write_file('library.rip', <<-RIP)
        'hello, world'
      RIP

      in_current_dir do
        absolute_path = project_dir + 'library.rip'
        write_file('absolute.rip', <<-RIP)
          System.require('#{absolute_path}')
        RIP
      end

      write_file('relative.rip', <<-RIP)
        System.require('./library')
      RIP

      write_file('broken.rip', <<-RIP)
        System.require('./not_exist')
      RIP
    end

    describe 'requiring an absolute file' do
      let(:main_file) { project_dir + current_dir + 'absolute.rip' }

      specify do
        in_current_dir do
          characters = 'hello, world'.split('').map { |c| Rip::Core::Character.new(c) }
          expect(final_result).to eq(Rip::Core::String.new(characters))
        end
      end
    end

    describe 'requiring a relative file' do
      let(:main_file) { project_dir + 'relative.rip' }

      specify do
        in_current_dir do
          characters = 'hello, world'.split('').map { |c| Rip::Core::Character.new(c) }
          expect(final_result).to eq(Rip::Core::String.new(characters))
        end
      end
    end

    describe 'requiring a non-existent file' do
      let(:main_file) { project_dir + 'broken.rip' }

      specify do
        in_current_dir do
          expect { final_result }.to raise_error(Rip::Exceptions::LoadException)
        end
      end
    end
  end
end