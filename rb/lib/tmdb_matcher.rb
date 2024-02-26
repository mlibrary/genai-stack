module Tmdb
  class Matcher
    attr_accessor :cache, :genres
    def initialize(key, cache)
      Api::key(key)
      @cache = cache
      cache['movie_genres'] ||= Tmdb::Genre::movie_list
      @genres = cache['movie_genres'].inject({}) do |acc, genre|
        acc[genre.id] = genre.name
        acc
      end
    end

    def match_record(record)
      puts "  Matching #{record.id} #{record.title} #{record.year}"
      match = match_title_year(record.title, record.year)
      return Match.new(match, genres, cache) if match
      nil
    end

    def match_title_year(title, year)
      cache_key = "movie / #{title} year: #{year}"
      tmdb = cache[cache_key] ||= Tmdb::Search::movie(title, year: year)
      return nil if tmdb.total_results == 0
      return tmdb.results.first if tmdb.total_results == 1

      # Then look for an exact title match.
      selected = narrow_by_title(tmdb.results, title)
      return selected.first if selected.length == 1

      too_many_matches(selected)
      return nil
    end

    def match_title(title)
      cache_key = "movie / #{title}"
      tmdb = cache[cache_key] ||= Tmdb::Search::movie(cache_key)
      return nil if tmdb.total_results == 0
      return tmdb.results.first if tmdb.total_results == 1
      selected = narrow_by_title(title)
    end

    def narrow_by_title(results, title)
      selected = results.select {|result| result.title == title}
      if selected.length == 0
        selected = results.select {|result| result.title.downcase == title.downcase}
      end
      selected
    end

    def too_many_matches(results)
      results.each do |result|
        puts "    #{result.id} #{result.title} #{result.release_date} #{result.original_language}"
      end
    end

  end

  class Match
    attr_accessor :id, :title, :genres, :overview, :release_date, :original_language, :people
    def initialize(record, genres, cache)
      self.id = record.id
      self.title = record.title
      self.overview = record.overview
      self.genres = record.genre_ids.map {|genre_id| genres[genre_id]}
      self.release_date = record.release_date
      self.original_language = record.original_language
      self.people = {}
      
      cache_key = "cast / #{record.id}"
      cast = (cache[cache_key] ||= Tmdb::Movie::cast(record.id))
      cast.each do |member|
        self.people['Actor'] ||= []
        self.people['Actor'] << member.name
      end

      cache_key = "crew / #{record.id}"
      crew = (cache[cache_key] ||= Tmdb::Movie::crew(record.id))
      crew.each do |member|
        self.people[member.job] ||= []
        self.people[member.job] << member.name
      end
      
    end
  end
end
