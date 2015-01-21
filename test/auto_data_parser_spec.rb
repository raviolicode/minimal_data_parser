require 'minitest/autorun'
require_relative '../auto_data_parser.rb'

describe AutoDataParser do
  it "should read all data" do
    dir_path = "fixtures"
    data = AutoDataParser.read_all(dir_path, "criterium1", "criterium2", "criterium3")

    grouped_data = [
      [{:id=>1, :criterium1=>{:a=>1, :b=>2}},   {:id=>2, :criterium1=>{:a=>10, :b=>20}}],
      [{:id=>1, :criterium2=>{:d=>3, :e=>4}},  {:id=>2, :criterium2=>{:d=>30, :e=>40}}],
      [{:id=>1, :criterium3=>{:f=>"a5", :g=>"a6"}}, {:id=>2, :criterium3=>{:f=>"a50", :g=>"a60"}}]
    ]
    data.must_equal grouped_data
  end

  it "should get all data into an array of objects" do
    grouped_data = [
      [{:id=>1, :criterium1=>{:a=>1, :b=>2}},   {:id=>2, :criterium1=>{:a=>10, :b=>20}}],
      [{:id=>1, :criterium2=>{:d=>3, :e=>4}},  {:id=>2, :criterium2=>{:d=>30, :e=>40}}],
      [{:id=>1, :criterium3=>{:f=>"a5", :g=>"a6"}}, {:id=>2, :criterium3=>{:f=>"a50", :g=>"a60"}}]
    ]

    data  = AutoDataParser.condense(*grouped_data)
    condensed_hash = [
      {:id=>1, :criterium1=>{:a=>1, :b=>2},
                :criterium2=>{:d=>3, :e=>4},
                :criterium3=>{:f=>"a5", :g=>"a6"}},
      {:id=>2, :criterium1=>{:a=>10, :b=>20},
                 :criterium2=>{:d=>30, :e=>40},
                 :criterium3=>{:f=>"a50", :g=>"a60"}}
      ]

    data.must_equal condensed_hash
  end
end
