require "openai"

class OpenaiXmlAnalyzer
  def initialize(xml_string)
    @xml_string = xml_string
    @client = OpenAI::Client.new(access_token: Rails.application.credentials.dig(:openai, :api_key))
  end

  def analyze
    prompt = <<~PROMPT
      Analysiere die folgende Adobe Premiere Pro XML-Datei. Gib mir als JSON zwei Arrays zurück:
      1. Alle Medienpfade, die im Schnitt (in einer Timeline/Sequence) verwendet werden.
      2. Alle Medienpfade, die zwar importiert, aber nicht verwendet werden.
      Beispiel-Output: {"used":["/Pfad/zu/clip1.mov"],"unused":["/Pfad/zu/clip2.mov"]}
      XML:
      #{@xml_string}
    PROMPT

    response = @client.chat(
      parameters: {
        model: "gpt-4o",
        messages: [{role: "user", content: prompt}],
        temperature: 0.2
      }
    )
    content = response.dig("choices", 0, "message", "content")
    JSON.parse(content[/\{.*\}/m])
  rescue => e
    Rails.logger.error("OpenAI-Analyse fehlgeschlagen: #{e.message}")
    nil
  end
end 