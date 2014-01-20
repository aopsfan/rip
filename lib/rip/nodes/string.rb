module Rip::Nodes
  class String < Base
    attr_reader :characters

    def initialize(location, characters = [])
      super(location)
      @characters = characters
    end

    def ==(other)
      super &&
        (characters == other.characters)
    end

    def interpret(context)
    end

    def to_debug(level = 0)
      characters_debug = characters.map(&:data).join('')

      [
        [ level, "#{self.class.short_name}@#{location.to_debug} (#{characters_debug})" ]
      ]
    end
  end
end
