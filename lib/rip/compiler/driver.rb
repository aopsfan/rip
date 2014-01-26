module Rip::Compiler
  class Driver
    attr_reader :syntax_tree

    def initialize(syntax_tree)
      @syntax_tree = syntax_tree
    end

    def interpret(context = global_context)
      syntax_tree.interpret(context)
    end

    def global_context
      Rip::Utilities::Scope.new({
        'System' => Rip::Core::System.class_instance,
        'true' => Rip::Core::Boolean.true,
        'false' => Rip::Core::Boolean.false
      })
    end
  end
end
