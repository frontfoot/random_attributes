require 'spec_helper'
require 'active_support/core_ext/hash'
require 'ffaker'

class TestAttributeThing
  include RandomAttributes

  attribute 'name'
end

class TestAttributeCasting
  include RandomAttributes

  attribute 'name'
  attribute 'venue', type: String
  attribute 'fooName', alias: :bar_name
  attribute 'raceIdentifier', alias: :identifier, type: String
  attribute 'number', type: Integer
  attribute 'stake', type: Float
  attribute ['fooMeeting', 'barMeeting'], alias: :meeting
  attribute 'manyThings', collection: TestAttributeThing
  attribute 'singleThing', model: TestAttributeThing
  attribute 'someDetails', alias: :details
  attribute 'nestedDetail', within: :details
  attribute ['status', 'raceStatus'], alias: :status, try: :details
  attribute 'afterParseValue'
  attribute 'afterOptions', parse: ->(value) { "#{value} after parse!" }

  after_parse :change_value

  def change_value
    # We have to use this method here because I can't figure out why the
    # dynamic method is not working.
    set_attribute :after_parse_value, 'after parse!'
  end
end

describe RandomAttributes do
  let(:string) {
    Faker::Name.name
  }

  it "should default to given type" do
    subject = TestAttributeCasting.parse 'name' => string
    subject.name.should eq string
  end

  it "should cast strings and rename attribute" do
    subject = TestAttributeCasting.parse 'venue' => string
    subject.venue.should be_a(String)
  end

  it "should cast floats" do
    subject = TestAttributeCasting.parse 'stake' => '1.5'
    subject.stake.should be_a(Float)
  end

  it "should cast integers" do
    subject = TestAttributeCasting.parse 'number' => '10'
    subject.number.should be_a(Integer)
  end

  it "should rename attributes" do
    subject = TestAttributeCasting.parse 'raceIdentifier' => string
    subject.identifier.should eq string
  end

  it "should create setter method" do
    subject = TestAttributeCasting.parse 'raceIdentifier' => string
    subject.identifier = 'Matamata'
    subject.identifier.should eq 'Matamata'
  end

  it "should try many attributes" do
    subject = TestAttributeCasting.parse 'fooMeeting' => nil, 'barMeeting' => string
    subject.meeting.should eq string
  end

  it "should try a collection" do
    subject = TestAttributeCasting.parse 'manyThings' => [{ "name" => string}]
    subject.many_things.first.name.should eq string
  end

  it "should just return element if already a collection member" do
    subject = TestAttributeCasting.parse 'manyThings' => [TestAttributeThing.new(name: string)]
    subject.many_things.first.name.should eq string
  end

  it "should memoize instance variables" do
    subject = TestAttributeCasting.parse 'manyThings' => [{ "name" => string}]
    subject.many_things.first.object_id.should eq subject.many_things.first.object_id
  end

  it "should return an array if collection nil" do
    subject = TestAttributeCasting.parse 'manyThings' => nil
    subject.many_things.should be_a(Array)
  end

  it "should try a member" do
    subject = TestAttributeCasting.parse 'singleThing' => { "name" => string}
    subject.single_thing.name.should eq string
  end

  it "should assign something one deep" do
    subject = TestAttributeCasting.parse 'someDetails' => { 'nestedDetail' => string }
    subject.nested_detail.should eq string
  end

  it "should try other places for the data" do
    subject = TestAttributeCasting.parse 'someDetails' => { 'raceStatus' => string }
    subject.status.should eq string

    subject = TestAttributeCasting.parse 'raceStatus' => string
    subject.status.should eq string

    subject = TestAttributeCasting.parse 'status' => string
    subject.status.should eq string
  end

  it "should return the aliased value if present" do
    subject = TestAttributeCasting.parse "bar_name" => string
    subject.bar_name.should eq string
  end

  it "should call the after parse method" do
    subject = TestAttributeCasting.parse "afterParseValue" => string
    subject.after_parse_value.should eq "after parse!"
  end

  it "should add a callback from the options hash" do
    subject = TestAttributeCasting.parse "afterOptions" => string
    subject.after_options.should eq "#{string} after parse!"
  end

  it "should clear memoized data when parsed is called" do
    subject = TestAttributeCasting.new

    subject.name.should be_nil

    subject = TestAttributeCasting.parse 'name' => string
    subject.name.should eq string
  end

  it "should have instance method parse methods" do
    subject = TestAttributeCasting.new

    subject.parse 'name' => 'foo'
    subject.name.should eq 'foo'

    subject.merge_attributes 'name' => 'bar'
    subject.name.should eq 'bar'
  end

  it "should return a reliable cache key" do
    subject = TestAttributeThing.parse 'name' => 'foo'
    subject.cache_key.should eq "c9e2bd1b9e2ee9b862a8f035e4ec9d57"
  end

  it "should return the original raw attributes hash as a cache key" do
    subject_one = TestAttributeThing.parse 'name' => 'foo'
    subject_two = TestAttributeThing.parse 'name' => 'foo'
    subject_one.cache_key.should eq subject_two.cache_key
  end
end
