require "random_attributes/version"
require "active_support/concern"
require "active_support/callbacks"

# RandomAttributes
#
# Getters, setters and object building for a someone elses data structure.
#
# Example:
#
#   class Runner
#     include RandomAttributes
#     attribute 'runnerName', alias: :name
#   end
#
#   runner = Runner.new "runnerName" => "Phar Lap"
#   runner.name #=> "Phar Lap"
#
module RandomAttributes
  extend ActiveSupport::Concern
  include ActiveSupport::Callbacks

  class Register
    class AliasError < StandardError; end

    attr_reader :originals, :aliased, :type, :parent_node, :try_node

    def initialize(attrs, options = {})

      if attrs.is_a?(Array)
        raise AliasError, "if you want to alias attributes you need to specify the alias in the options" unless
          options[:alias].present?
        @aliased = options[:alias].to_s
      else
        @aliased = options[:alias].to_s.presence || attrs.underscore
        attrs = [attrs]
      end

      @originals   = attrs
      @parent_node = options[:within]
      @try_node    = options[:try]

      @type        = options[:type]
      @model       = options[:model]
      @collection  = options[:collection]
      @cast_proc   = options[:parse] || cast_to_proc
    end

    def key
      @originals.join '__'
    end

    def cast(value)
      @cast_proc.call value
    end

    private

    # TODO refactor this.
    def cast_to_proc
      if @type
        ->(value) { value ? Kernel.send(@type.to_s, value) : value }
      elsif @model
        ->(value) { value ? @model.parse(value) : value }
      elsif @collection
        if @collection.respond_to?(:parse)
          ->(value) {
            if value
              value.map do |member|
                member.is_a?(@collection) ? member : @collection.parse(member)
              end
            else
              []
            end
          }
        else
          ->(value) {
            if value
              value.map do |member|
                member.is_a?(@collection) ? member : @collection.new(member)
              end
            else
              []
            end
          }
        end
      else
        ->(value) { value }
      end
    end
  end

  included do
    define_callbacks :parse
  end

  module ClassMethods
    def attribute(attrs, options = {})
      register = Register.new attrs, options

      attribute_register[register.aliased] = register

      define_method register.aliased do
        get_attribute register
      end

      define_method :"#{register.aliased}=" do |value|
        set_attribute register.aliased, value
      end
    end

    def attribute_register
      @_attribute_register ||= {}
    end

    def parse(attributes)
      new.parse attributes
    end

    def before_parse(*args, &block)
      set_callback(:parse, :before, *args, &block)
    end

    def after_parse(*args, &block)
      set_callback(:parse, :after, *args, &block)
    end
  end

  def initialize(attrs = nil)
    parse attrs
  end

  def cache_key
    @raw_attributes_hash
  end

  def parse(attrs = nil)
    @parsed_attributes = {}
    attrs && attrs.stringify_keys!
    run_callbacks :parse do
      @raw_attributes = attributes.merge(attrs.nil? ? {} : attrs).freeze
      @raw_attributes_hash = Digest::MD5.hexdigest(attributes.to_s)
    end
    self
  end

  alias :merge_attributes :parse

  def attributes
    @raw_attributes ||= {}.freeze
  end

  private

  def parsed_attributes
    @parsed_attributes ||= {}
  end

  def get_attribute(register)
    if parsed_attributes.key?(register.aliased)
      parsed_attributes[register.aliased]
    else
      parsed_attributes[register.aliased] = _get_attribute(register)
    end
  end

  def set_attribute(key, value)
    parsed_attributes[key.to_s] = value
  end

  def _search_originals(register, node, value = nil)
     register.originals.each do |key|
       break if value = node[key]
     end
     value
  end

  def _get_attribute(register)

    value = attributes[register.aliased]

    unless value
      if register.try_node
        if try_node = send(register.try_node)
          value = _search_originals register, try_node
        else
          value = _search_originals register, attributes
        end
      elsif register.parent_node
        if parent_node = send(register.parent_node)
          value = _search_originals register, parent_node
        end
      else
        value = _search_originals register, attributes
      end
    end

    register.cast(value)
  end
end
