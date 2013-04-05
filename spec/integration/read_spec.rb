require 'spec_helper'
require 'yaml'

describe "Read APIs" do
  FACTUAL_ID = "110ace9f-80a7-47d3-9170-e9317624ebd9"

  before(:all) do
    credentials = YAML.load(File.read(CREDENTIALS_FILE))
    key = credentials["key"]
    secret = credentials["secret"]
    @factual = Factual.new(key, secret)
  end

  it "should be able to get a row" do
    row = @factual.table("places-us").row(FACTUAL_ID)
    row.class.should == Hash
    row.keys.should_not be_empty
    row['factual_id'].should == FACTUAL_ID
  end
  it "should be able to do a table query" do
    rows = @factual.table("places").search("sushi", "sashimi")
      .filters("category" => "Food & Beverage > Restaurants")
      .geo("$circle" => {"$center" => [LAT, LNG], "$meters" => 5000})
      .sort("name").page(2, :per => 10).rows
    rows.class.should == Array
    rows.each do |row|
      row.class.should == Hash
      row.keys.should_not be_empty
    end
  end

  it "should be able to do a match query" do
    matched = @factual.match("name" => "McDonalds",
                            "address" => "10451 Santa Monica Blvd",
                            "region" => "CA",
                            "postcode" => "90025").first
    if matched
      matched.class.should == Hash
      matched["factual_id"].should_not be_empty
    end
  end

  it "should be able to do a resolve query" do
    rows = @factual.resolve("name" => "McDonalds",
                            "address" => "10451 Santa Monica Blvd",
                            "region" => "CA",
                            "postcode" => "90025").rows
    rows.class.should == Array
    rows.each do |row|
      row.class.should == Hash
      row.keys.should_not be_empty
    end
  end

  it "should be able to do a crosswalk query" do
    rows = @factual.table("crosswalk").filters(:factual_id => FACTUAL_ID).rows
    rows.class.should == Array
    rows.each do |row|
      row.class.should == Hash
      row.keys.should_not be_empty
    end
  end

  it "should be able to do a geocode query" do
    row = @factual.geocode(LAT, LNG).first
    row.class.should == Hash
    row['address'].should_not be_empty
  end

  it "should be able to do geopulse queries" do
    query = @factual.geopulse(LAT, LNG)
    row = query.data['demographics']
    row.class.should == Hash
    row['area_statistics'].class.should == Hash
    row['income'].class.should == Hash
    row['race_and_ethnicity'].class.should == Hash

    query = query.select('area_statistics', 'income')
    row = query.data['demographics']
    row.class.should == Hash
    row['area_statistics'].class.should == Hash
    row['income'].class.should == Hash
    row['race_and_ethnicity'].class.should == NilClass
  end

  it "should be able to do a monetize query" do
    rows = @factual.monetize.rows
    rows.class.should == Array
    rows.each do |row|
      row.class.should == Hash
      row.keys.should_not be_empty
    end
  end

  it "should be able to report a invalid field error" do
    begin
      @factual.monetize.filters("country" => "US").rows
    rescue StandardError => e
      JSON.parse(e.to_s)["error_type"].should == "InvalidFilterArgument"
    end
  end

end
