module Rip::Core
  class Base
    attr_reader :properties

    def initialize
      @properties = {}
    end

    def ==(other)
      properties == other.properties
    end

    def [](key)
      _key = key.to_s

      reply = properties['class'].ancestors.inject(properties[_key]) do |memo, ancestor|
        memo || ancestor['@'][_key]
      end

      finalize_property(_key, reply)
    end

    def []=(key, value)
      properties[key.to_s] = value
    end

    def to_s
      to_s_prep.join(' ')
    end

    def to_s_prep
      to_s_prep_prefix +
        to_s_prep_body +
        to_s_prep_postfix
    end

    def to_s_prep_prefix
      [ '#<' ]
    end

    def to_s_prep_body
      [
        self['class'].to_s,
        [
          '[',
          property_names.sort.join(', '),
          ']'
        ].join(' ')
      ]
    end

    def to_s_prep_postfix
      [ '>' ]
    end

    def property_names
      self['class']['@'].properties.merge(properties).keys.uniq
    end

    def symbols
      properties.keys
    end

    def self.define_class_instance(core_module_name = nil, &block)
      define_singleton_method :class_instance do
        return @class_instance if instance_variable_defined? :@class_instance

        @class_instance = if core_module_name
          load_path = Rip.root + 'core'
          Rip::Loaders::FileSystem.new(core_module_name, [ load_path ]).load
        else
          Rip::Core::Class.new.tap do |reply|
            reply['class'] = Rip::Core::Class.class_instance
          end
        end

        block.call(@class_instance)

        @class_instance
      end
    end

    protected

    def finalize_property(key, property)
      case property
      when NilClass
        location = key.location if key.respond_to?(:location)
        raise Rip::Exceptions::RuntimeException.new("Unknown property `#{key}`", location)
      when Rip::Core::DynamicProperty
        property.resolve(key, self)
      when Rip::Core::DelayedProperty
        reply = property.resolve(key, self)
        reply.is_a?(Rip::Core::Lambda) ? finalize_property(key, reply) : reply
      when Rip::Core::Lambda
        property.bind(self)
      else
        property
      end
    end
  end
end
