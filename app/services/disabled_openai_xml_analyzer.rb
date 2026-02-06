require "json"

class DisabledOpenaiXmlAnalyzer
  def initialize(prompt = nil)
    @prompt = prompt
    @client = OPENAI_CLIENT
  end

  def analyze(prompt = nil)
    prompt ||= @prompt

    unless @client
      Rails.logger.error "[OpenaiXmlAnalyzer] OpenAI client not configured. Please set OPENAI_API_KEY."
      return nil
    end

    begin
      Rails.logger.info "[OpenaiXmlAnalyzer] Sende Prompt an OpenAI:\n#{prompt}"
      response = @client.chat.completions.create(
        messages: [ { role: "user", content: prompt } ],
        model: :"gpt-4o",
        temperature: 0.0,
        max_tokens: 4096
      )
      Rails.logger.info "[OpenaiXmlAnalyzer] OpenAI-Response: #{response.inspect}"
      result = response.choices.first.message.content
      Rails.logger.info "[OpenaiXmlAnalyzer] KI-Rohantwort: #{result.inspect}"

      # Robusteres JSON-Parsing
      parsed = parse_json_response(result)

      Rails.logger.info "[OpenaiXmlAnalyzer] Geparstes Ergebnis: #{parsed.inspect}"
      parsed
    rescue => e
      Rails.logger.error "[OpenaiXmlAnalyzer] Fehler bei OpenAI-Request: #{e.class}: #{e.message}\n#{e.backtrace&.first(10)&.join("\n")}"
      nil
    end
  end

  private

  def parse_json_response(result)
    # Schritt 1: Versuche direktes JSON-Parsing
    begin
      return JSON.parse(result)
    rescue JSON::ParserError => e
      Rails.logger.warn "[OpenaiXmlAnalyzer] Direktes JSON-Parsing fehlgeschlagen: #{e.message}"
    end

    # Schritt 2: Entferne Markdown-Backticks
    clean_result = remove_markdown_backticks(result)
    begin
      return JSON.parse(clean_result)
    rescue JSON::ParserError => e
      Rails.logger.warn "[OpenaiXmlAnalyzer] Bereinigte Antwort fehlgeschlagen: #{e.message}"
    end

    # Schritt 3: Versuche JSON zu reparieren (bei abgeschnittenen Antworten)
    repaired_result = repair_truncated_json(clean_result)
    begin
      return JSON.parse(repaired_result)
    rescue JSON::ParserError => e
      Rails.logger.warn "[OpenaiXmlAnalyzer] Reparierte JSON fehlgeschlagen: #{e.message}"
    end

    # Schritt 4: Extrahiere JSON aus dem Text
    extracted_result = extract_json_from_text(result)
    begin
      return JSON.parse(extracted_result)
    rescue JSON::ParserError => e
      Rails.logger.error "[OpenaiXmlAnalyzer] JSON-Extraktion fehlgeschlagen: #{e.message}"
    end

    # Schritt 5: Fallback - versuche das beste verfügbare JSON zu finden
    fallback_result = find_best_json_candidate(result)
    begin
      return JSON.parse(fallback_result)
    rescue JSON::ParserError => e
      Rails.logger.error "[OpenaiXmlAnalyzer] Fallback JSON fehlgeschlagen: #{e.message}"
    end

    nil
  end

  def remove_markdown_backticks(result)
    # Entferne ```json am Anfang und ``` am Ende
    cleaned = result.gsub(/^```json\s*/, "").gsub(/\s*```$/, "").strip
    # Entferne auch ``` ohne json am Anfang
    cleaned = cleaned.gsub(/^```\s*/, "").gsub(/\s*```$/, "").strip
    cleaned
  end

  def repair_truncated_json(json_text)
    lines = json_text.lines
    return json_text if lines.empty?

    # Finde die letzte vollständige Zeile
    last_complete_line = lines.length - 1
    while last_complete_line >= 0
      line = lines[last_complete_line].strip
      # Eine Zeile ist vollständig, wenn sie mit ", }, ], oder , endet
      if line.end_with?('"') || line.end_with?("}") || line.end_with?("]") || line.end_with?(",")
        break
      end
      last_complete_line -= 1
    end

    # Verwende nur vollständige Zeilen
    repaired_lines = lines[0..last_complete_line]
    repaired_json = repaired_lines.join

    # Zähle Klammern und füge fehlende hinzu
    open_braces = repaired_json.count("{")
    close_braces = repaired_json.count("}")
    open_brackets = repaired_json.count("[")
    close_brackets = repaired_json.count("]")

    # Füge fehlende schließende Klammern hinzu
    while close_brackets < open_brackets
      repaired_json += "\n  ]"
      close_brackets += 1
    end
    while close_braces < open_braces
      repaired_json += "\n}"
      close_braces += 1
    end

    # Entferne trailing comma vor schließenden Klammern
    repaired_json = repaired_json.gsub(/,\s*([}\]])/, '\1')

    Rails.logger.info "[OpenaiXmlAnalyzer] Reparierte JSON: #{repaired_json}"
    repaired_json
  end

  def extract_json_from_text(text)
    # Suche nach JSON-Struktur im Text
    if text.include?("{") && text.include?("}")
      json_start = text.index("{")
      json_end = text.rindex("}") + 1
      json_text = text[json_start...json_end]
      Rails.logger.info "[OpenaiXmlAnalyzer] Extrahierte JSON: #{json_text}"
      return json_text
    end
    text
  end

  def find_best_json_candidate(text)
    # Suche nach dem längsten JSON-ähnlichen String
    candidates = []

    # Suche nach JSON-Objekten
    text.scan(/\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}/) do |match|
      candidates << match
    end

    # Suche nach JSON-Arrays
    text.scan(/\[[^\[\]]*(?:\[[^\[\]]*\][^\[\]]*)*\]/) do |match|
      candidates << match
    end

    # Wähle den längsten Kandidaten
    best_candidate = candidates.max_by(&:length)
    Rails.logger.info "[OpenaiXmlAnalyzer] Bester JSON-Kandidat: #{best_candidate}"
    best_candidate || text
  end
end
