require 'themoviedb-api'
require 'rsolr'
require 'langchain'
require 'pry'
require 'pry-byebug'
require 'faraday'
require 'faraday/request/timer'
require 'persistent-cache'
require 'dotenv/load'

require_relative 'lib/spectrum_client.rb'
require_relative 'lib/tmdb_matcher.rb'
require_relative 'lib/monkey_patches.rb'

MODELS = [
  'llama2' => :embedding_4k, #4096,
  'orca-mini' => 3200,
  'phi' => 2560,
  'tinyllama' => :embedding_2k, #2048,
  'qwen:0.5b' => 1024,
]



cache = {
  search: Persistent::Cache.new('/app/cache/search', nil),
  catalog: Persistent::Cache.new('/app/cache/catalog', nil),
  themoviedb: Persistent::Cache.new('/app/cache/themoviedb', nil),
  embedding: Persistent::Cache.new('/app/cache/embedding', nil),
}

matcher = Tmdb::Matcher.new(ENV['TMDB_KEY'], cache[:themoviedb])

llm = Langchain::LLM::Ollama.new(url: 'http://llm:11434')
solr = RSolr.connect(url: 'http://solr:8983/solr/genai')

puts "Fetching from the catalog."

catalog = SpectrumClient::Catalog.new
results = catalog.search(facets: {location: 'Askwith Media Library'}, start: 28510)
loop do
  puts "Starting at #{results.start}"
  results.each do |record|
    title = record.title
    puts "  Matching: #{title}"
    begin
      match = matcher.match_record(record)
    rescue
      match = nil
    end
    document = {
      id: record.id,
      title_s: record.title,
      format_ss: record.format,
      contributors_ss: record.contributors,
      author_ss: record.author,
      performers_ss: record.performers,
      production_credits_ss: record.production_credits,
      summary_ss: record.summary,
      extended_summary_ss: record.extended_summary,
      note_ss: record.note,
      published_year_ss: record.year,
      publisher_ss: record.publisher,
    }
    if match
      document[:overview_s] = match.overview
      document[:people_s] = match.people.to_yaml
    end

    document[:embedding_2k] = llm.embed(text: document.to_yaml, model: 'tinyllama').embedding
    document[:embedding_ss] = ['embedding_2k']
    solr.add(document, add_attributes: {commitWithin: 10})
  end
  break if results.done?
  results = catalog.search_by_hash(results.next)
end

exit

loop do

    if cache[:themoviedb][record['id']]
      puts "  Cache hit."
      cache[:themoviedb][record['id']]
    else
      puts "  ID Cache miss."
      cache_key = "#{title} year: {record['display_date']}"
      if (tmdb = cache[:themoviedb][cache_key])
      else
        tmdb = Tmdb::Search::movie(title, year: record['display_date'])
      if tmdb.total_results == 0
        tmdb = Tmdb::Search::movie(title)
      end

      if tmdb.total_results > 1
        puts "  Too many matches (#{tmdb.total_results}) for #{record['id']} (#{title})"
        matches = tmdb.results.select { |result| result.title == title }
        if matches.length == 0
          tmdb.results.select { |result| result.title.downcase == title.downcase }
        end
        if matches.length == 0
          puts "    No exact matches."
          puts "    Looking for #{title} (#{record['display_date']})"
          tmdb.results.each do |result|
            puts "      #{result.id} #{result.title} #{result.release_date} #{result.original_language}"
          end
        elsif matches.length == 1
          puts "    One exact match, found it."
          data = {
            details: Tmdb::Movie::detail(tmdb.results.first.id),
            cast: Tmdb::Movie::cast(tmdb.results.first.id),
          }
          cache[:themoviedb][record['id']] = data
        else
          puts "    Looking for #{title} (#{record['display_date']})"
          puts "    #{matches.length} exact matches"
          matches.each do |result|
            puts "      #{result.id} #{result.title} #{result.release_date} #{result.original_language}"
          end
        end
        
      elsif tmdb.total_results == 0
        puts "  No matches for #{record['id']}"
      else
        puts "  Found it."
        data = {
          details: Tmdb::Movie::detail(tmdb.results.first.id),
          cast: Tmdb::Movie::cast(tmdb.results.first.id),
        }
        cache[:themoviedb][record['id']] = data
      end
    end
    sleep 5
  end
  break if results.done?
  results = catalog.search_by_hash(results.next)
end


binding.pry

llm = Langchain::LLM::Ollama.new(url: 'http://llm:11434')

catalog_url=URI("https://search.lib.umich.edu/spectrum/mirlyn")

request = {
  "request_id": 3,
  "start": 0,
  "count": 50,
  "field_tree": {},
  "facets": {"location":"Askwith Media Library"},
  "settings": {},
  "raw_query": "",
}







result = llm.embed(text: 'Hello world', model: 'qwen:0.5b')

binding.pry

puts 'Hello world'
