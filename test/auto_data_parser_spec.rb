require 'minitest/autorun'
require_relative '../auto_data_parser.rb'

describe AutoDataParser do
  it "should read all data" do
    dir_path = "fixtures"
    data = AutoDataParser.read_all(dir_path, true, "criterium1", "criterium2", "criterium3")

    grouped_data = [
      [{"id"=>1, "criterium1"=>{"a"=>1, "b"=>2}},   {"id"=>2, "criterium1"=>{"a"=>10, "b"=>20}}],
      [{"id"=>1, "criterium2"=>{"d"=>3, "e"=>4}},  {"id"=>2, "criterium2"=>{"d"=>30, "e"=>40}}],
      [{"id"=>1, "criterium3"=>{"f"=>"a5", "g"=>"a6"}}, {"id"=>2, "criterium3"=>{"f"=>"a50", "g"=>"a60"}}]
    ]
    data.must_equal grouped_data
  end

  it "condense" do
    grouped_data = [
      [{"id"=>1, "criterium1"=>{"a"=>1, "b"=>2}},   {"id"=>2, "criterium1"=>{"a"=>10, "b"=>20}}],
      [{"id"=>1, "criterium2"=>{"d"=>3, "e"=>4}},  {"id"=>2, "criterium2"=>{"d"=>30, "e"=>40}}],
      [{"id"=>1, "criterium3"=>{"f"=>"a5", "g"=>"a6"}}, {"id"=>2, "criterium3"=>{"f"=>"a50", "g"=>"a60"}}]
    ]

    data  = AutoDataParser.condense(*grouped_data)
    condensed_hash = [
      {"id"=>1, "criterium1"=>{"a"=>1, "b"=>2},
                "criterium2"=>{"d"=>3, "e"=>4},
                "criterium3"=>{"f"=>"a5", "g"=>"a6"}},
      {"id"=>2, "criterium1"=>{"a"=>10, "b"=>20},
                 "criterium2"=>{"d"=>30, "e"=>40},
                 "criterium3"=>{"f"=>"a50", "g"=>"a60"}}
      ]

    data.must_equal condensed_hash
  end

  it "should do averages correctly" do
    data = [
      {"id"=>1, "criterium1"=>{"a"=>1, "b"=>2, "c" => 3},
                "criterium2"=>{"d"=>3, "e"=>4, "j" => 33},
                "criterium3"=>{"f"=>"a5", "g"=>"a6"}},
      {"id"=>2, "criterium1"=>{"a"=>10, "b"=>20},
                 "criterium2"=>{"d"=>30, "e"=>40},
                 "criterium3"=>{"f"=>"a50", "g"=>"a60"}}
      ]

      data_with_averages = [
        {"id"=>1, "criterium1"=>{"a"=>1, "b"=>2, "c" => 3,
                                 "averages" => {"avg 1"=>1.5, "avg 2"=>2.0}},
                  "criterium2"=>{"d"=>3, "e"=>4, "j" => 33},
                  "criterium3"=>{"f"=>"a5", "g"=>"a6"}},
        {"id"=>2, "criterium1"=>{"a"=>10, "b"=>20,
                                 "averages" => {"avg 1"=>15.0, "avg 2"=>nil}},
                   "criterium2"=>{"d"=>30, "e"=>40},
                   "criterium3"=>{"f"=>"a50", "g"=>"a60"}}
        ]
      AutoDataParser.add_averages!(data, "fixtures/averages.yml")
      data.must_equal data_with_averages
  end
end
