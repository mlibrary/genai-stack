module Langchain::LLM
  class Ollama < Base
    def client
      @client ||= Faraday.new(url: url, request: {timeout: 3600, open_timeout: 3600}) do |conn|
        conn.request :json
        conn.response :json
        conn.response :raise_error
      end
    end
  end
end
