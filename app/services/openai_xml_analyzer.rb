require "openai"
require "json"

class OpenaiXmlAnalyzer
  def initialize(xml_string)
    @xml_string = xml_string
    @client = ::OpenAI::Client.new
  end

  def analyze
    prompt = <<~PROMPT
      Analysiere die folgende Adobe Premiere Pro XML-Datei. Gib **ausschließlich** ein JSON-Objekt im folgenden Format zurück – ohne jeglichen Erklärungstext, ohne Einleitung, ohne Kommentare, ohne Markdown, nur reines JSON:
      {"used": ["/Pfad/zu/clip1.mov"], "unused": ["/Pfad/zu/clip2.mov"]}
      XML:
      #{@xml_string}
    PROMPT
    response = @client.chat.completions.create(
      messages: [{role: "user", content: prompt}],
      model: :"gpt-4o"
    )
    puts "OpenAI Antwort: #{response.inspect}"
    text = response.choices[0].message[:content] || response.choices[0].message["content"]
    if text.nil?
      puts "OpenAI-Antwort leer oder nicht wie erwartet: #{response.inspect}"
      return nil
    end
    # 1. Versuch: Original-String direkt parsen
    begin
      puts "Parsing Versuch 1 (Original-String): #{text[0..500]}..." if text.length > 500
      return JSON.parse(text)
    rescue JSON::ParserError => e1
      puts "Parsing Versuch 1 fehlgeschlagen: #{e1.message}"
    end
    # 2. Versuch: Backticks und whitespace entfernen, aber Zeilenumbrüche erhalten
    json_str = text.gsub(/```json|```/, '').strip
    begin
      puts "Parsing Versuch 2 (ohne Backticks): #{json_str[0..500]}..." if json_str.length > 500
      return JSON.parse(json_str)
    rescue JSON::ParserError => e2
      puts "Parsing Versuch 2 fehlgeschlagen: #{e2.message}"
    end
    # 3. Versuch: JSON-Block extrahieren
    json_block = json_str[/\{.*\}/m]
    if json_block.nil?
      puts "Kein JSON-Block gefunden in: #{json_str[0..500]}..."
      return nil
    end
    begin
      puts "Parsing Versuch 3 (JSON-Block): #{json_block[0..500]}..." if json_block.length > 500
      return JSON.parse(json_block)
    rescue JSON::ParserError => e3
      puts "Parsing Versuch 3 fehlgeschlagen: #{e3.message}, Antwort: #{json_block[0..500]}..."
      return nil
    end
  rescue => e
    puts "OpenAI-Analyse fehlgeschlagen: #{e.message}"
    nil
  end
end 