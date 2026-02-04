require "openai"

api_key = ENV["OPENAI_API_KEY"] || Rails.application.credentials.dig(:openai, :api_key)

if api_key.present?
  OPENAI_CLIENT = OpenAI::Client.new(api_key: api_key)
else
  Rails.logger.warn "[OpenAI] No API key configured. AI features will be disabled."
  OPENAI_CLIENT = nil
end 