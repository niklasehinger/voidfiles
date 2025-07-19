require "openai"

OPENAI_CLIENT = OpenAI::Client.new(
  api_key: ENV["OPENAI_API_KEY"] || Rails.application.credentials.dig(:openai, :api_key)
) 