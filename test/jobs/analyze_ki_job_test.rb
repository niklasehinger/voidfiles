require "test_helper"

class AnalyzeKiJobTest < ActiveJob::TestCase
  test "JSON parsing improvements work with markdown backticks" do
    # Test der verbesserten JSON-Parsing-Logik
    analyzer = OpenaiXmlAnalyzer.new

    # Simuliere eine KI-Antwort mit Markdown-Backticks
    mock_response = <<~JSON
      ```json
      {
        "used": [
          "file://localhost/test1.mp4",
          "file://localhost/test2.mp4"
        ],
        "unused": [
          "file://localhost/test3.mp4"
        ]
      }
      ```
    JSON

    # Teste die private Methode durch Reflection
    result = analyzer.send(:parse_json_response, mock_response)

    assert_not_nil result
    assert_equal [ "file://localhost/test1.mp4", "file://localhost/test2.mp4" ], result["used"]
    assert_equal [ "file://localhost/test3.mp4" ], result["unused"]
  end

  test "JSON parsing works with truncated responses" do
    analyzer = OpenaiXmlAnalyzer.new

    # Simuliere eine abgeschnittene Antwort
    truncated_response = <<~JSON
      ```json
      {
        "used": [
          "file://localhost/test1.mp4",
          "file://localhost/test2.mp4"
        ],
        "unused": [
          "file://localhost/test3.mp4",
          "file://localhost/test4.mp4"
    JSON

    result = analyzer.send(:parse_json_response, truncated_response)

    assert_not_nil result
    assert_equal [ "file://localhost/test1.mp4", "file://localhost/test2.mp4" ], result["used"]
    assert_equal [ "file://localhost/test3.mp4", "file://localhost/test4.mp4" ], result["unused"]
  end

  test "JSON parsing works with plain JSON" do
    analyzer = OpenaiXmlAnalyzer.new

    # Simuliere eine normale JSON-Antwort ohne Backticks
    plain_json = <<~JSON
      {
        "used": ["file://localhost/test1.mp4"],
        "unused": ["file://localhost/test2.mp4"]
      }
    JSON

    result = analyzer.send(:parse_json_response, plain_json)

    assert_not_nil result
    assert_equal [ "file://localhost/test1.mp4" ], result["used"]
    assert_equal [ "file://localhost/test2.mp4" ], result["unused"]
  end
end
