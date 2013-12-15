# RandomAttributes

Sometimes people give you rubbish data, when they do rather than wiring
everything up with hundreds of methods you could use RandomAttributes.

If mangling crappy data is not your issue you are probably better served by
something like [virtus](https://github.com/solnic/virtus).

## Installation

Add this line to your application's Gemfile:

    gem 'random_attributes'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install random_attributes

## Usage

Vanilla:

```ruby
class Foo
  include RandomAttributes
  attribute "fooBar"
end

foo = Foo.parse { "fooBar" => "hello" }
foo.foo_bar #=> "hello"
```

Alias:

```ruby
class Foo
  include RandomAttributes
  attribute "fooBar", alias: :moo_bar
end

foo = Foo.parse { "fooBar" => "hello" }
foo.moo_bar #=> "hello"
```

Type casting:

```ruby
class Foo
  include RandomAttributes
  attribute "fooBar", type: String
end

foo = Foo.parse { "fooBar" => 34 }
foo.foo_bar #=> "34"
```

Many possible values:

```ruby
class Foo
  include RandomAttributes
  attribute ["fooBar", "mooBar"], alias: :foo_bar
end

foo = Foo.parse { "fooBar" => "hello" }
foo.foo_bar #=> "hello"

foo = Foo.parse { "mooBar" => "hello" }
foo.foo_bar #=> "hello"
```

Trying another node:

```ruby
class Foo
  include RandomAttributes
  attribute "parentNode"
  attribute "fooBar", try: :parent_node
end

foo = Foo.parse { "fooBar" => "hello" }
foo.foo_bar #=> "hello"

foo = Foo.parse { "parentNode" => { "fooBar" => "hello" } }
foo.foo_bar #=> "hello"
```

Nested within a node:

```ruby
class Foo
  include RandomAttributes
  attribute "parentNode"
  attribute "fooBar", within: :parent_node
end

foo = Foo.parse { "parentNode" => { "fooBar" => "hello" } }
foo.foo_bar #=> "hello"
```

Models:

```ruby
class Bar
  attr_reader :message
  def initialize message
    @message = message
  end
end

class Foo
  include RandomAttributes
  attribute "fooBar", model: Bar
end

foo = Foo.parse { "fooBar" => "hello" }
foo.foo_bar.message #=> "hello"
```

Collections:

```ruby
class Bar
  attr_reader :message
  def initialize message
    @message = message
  end
end

class Foo
  include RandomAttributes
  attribute "fooBar", collection: Bar
end

foo = Foo.parse { "fooBar" => ["hello", "goodbye"] }
foo.foo_bar.first.message #=> "hello"
foo.foo_bar.last.message #=> "goodbye"
```

Parse data with proc:

```ruby
class Foo
  include RandomAttributes
  attribute "fooBar", parse: ->(value) { "#{value} from a proc!" }
end

foo = Foo.parse { "fooBar" => "hello" }
foo.foo_bar #=> "hello from a proc!"
```

Callbacks:

```ruby
class Foo
  include RandomAttributes
  attribute "fooBar"
  attribute "multipleFooBar"

  after_parse :multiply_foo_bar

  def multiply_foo_bar
    set_attribute :multiple_foo_bar, foo_bar * 2
  end
end

foo = Foo.parse { "fooBar" => 2 }
foo.multiple_foo_bar #=> 4
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
