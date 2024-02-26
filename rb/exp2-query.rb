require 'themoviedb-api'
require 'rsolr'
require 'langchain'
require 'pry'
require 'pry-byebug'
require 'faraday'
require 'faraday/request/timer'
require 'persistent-cache'
require 'readline'

require_relative 'lib/spectrum_client.rb'
require_relative 'lib/tmdb_matcher.rb'
require_relative 'lib/monkey_patches.rb'

tmdb_config = YAML.load_file('themoviedb.org.yml')

cache = {
  search: Persistent::Cache.new('/app/cache/search', nil),
  catalog: Persistent::Cache.new('/app/cache/catalog', nil),
  themoviedb: Persistent::Cache.new('/app/cache/themoviedb', nil),
  embedding: Persistent::Cache.new('/app/cache/embedding', nil),
}

matcher = Tmdb::Matcher.new(tmdb_config, cache[:themoviedb])

llm = Langchain::LLM::Ollama.new(url: 'http://llm:11434')
solr = RSolr.connect(url: 'http://solr:8983/solr/genai')

catalog = SpectrumClient::Catalog.new


uri = URI('http://solr:8983/solr/genai/select?fl=*,score')
connection = Faraday.new("#{uri.scheme}://#{uri.hostname}:#{uri.port}",
  request: {timeout: 60, open_timeout: 60},
  headers: {'Content-Type' => 'application/json'}
)


top_k = 10
while input = Readline.readline("search> ", true)
  embedding = llm.embed(text: input, model: 'tinyllama').embedding
  data = {
    query: "{!knn f=embedding_2k topK=#{top_k}}#{embedding.to_json}",
    fields: ["*", "score"],
  }
  response = connection.post(uri.path) do |req|
    req.body = data.to_json
  end
  results = JSON.parse(response.body)
  results['response']['docs'].each_with_index do |doc, i|
    puts
    puts "#{i}. #{doc['title_s']}"
    puts "  https://search.lib.umich.edu/catalog/record/#{doc['id']}"
    puts "  Score: #{doc['score']}"
  end
  puts
end
