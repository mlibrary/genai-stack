module SpectrumClient
  class Base
    HEADERS = {"Content-Type" => "application/json"}
    CONNECT_OPTIONS = { timeout: 360, open_timeout: 360 }
    REQUEST_TEMPLATE = {
      "request_id": 1,
      "field_tree": {},
      "settings":{},
    }
    attr_accessor :uri, :connection

    def initialize(url:)
      self.uri = URI(url)
      self.connection = connect
    end

    def connect
      Faraday.new(
       "#{uri.scheme}://#{uri.hostname}",
       request: CONNECT_OPTIONS,
       headers: HEADERS
      ) do |builder|
        builder.request :timer
        builder.adapter Faraday.default_adapter
      end
    end

    def post(body)
      try = 0
      begin
        JSON.parse(connection.post(uri.path) do |req|
          req.body = body.to_json
        end.body)
      rescue Faraday::ConnectionFailed, Net::ReadTimeout => e
        if try < 10
          try += 1
          sleep(try * 10)
          retry
        end
        raise
      end
    end

    def search_by_hash(hash)
      search(query: hash['query'], start: hash['start'], count: hash['count'], facets: hash['facets'], uid: hash['uid'])
    end

    def search(query: "*", start: 0, count: 10, facets: {}, uid: self.class::UID)
      body = REQUEST_TEMPLATE.merge(
        'raw_query' => query,
        'start' => start,
        'count' => count,
        'uid' => uid,
        'facets' => facets,
      )
      Response.new(post(body), body)
    end
  end

  class Catalog < Base
    UID = 'mirlyn'
    def initialize(url: "https://search.lib.umich.edu/spectrum/mirlyn")
      super
    end
  end

  class Response
    attr_accessor :raw_response, :records, :num_results, :query, :start, :count

    def initialize(raw_response, query)
      self.raw_response 
      self.query = query
      self.records = raw_response['response'].map do |record|
        Record.new(record)
      end
      self.start = query['start']
      self.count = query['count']
      self.num_results = raw_response['total_available']
    end

    def first
      records.first
    end

    def each(&blk)
      records.each(&blk)
    end

    def done?
      num_results <= start + records.length
    end

    def next
      {
        'query' => query['raw_query'],
        'start' => query['start'] + query['count'],
        'count' => query['count'],
        'facets' => query['facets'],
        'uid' =>  query['uid'],
      }
    end
  end

  class Record
  #  SKIP_INCLUDE = ["z3988", "csl", "ris"]
  #  SKIP_FIELDS = ["related_items", "marc_ris_title", "marc_record", "resource_access"]
  SKIP_FIELDS = []
  SKIP_INCLUDE = []

    attr_accessor :raw_record, :fields

    def initialize(raw_record)
      self.raw_record = raw_record
      self.fields = raw_record['fields'].inject({}) do |acc, field|
        unless SKIP_FIELDS.include?(field['uid'] )
          unless SKIP_INCLUDE.any? {|str| field['uid'].include?(str)}
            acc[field['uid']] = field['value']
          end
        end
        acc
      end
    end

    def id
      fields['id']
    end

    def title
      [fields['marc_ris_title']].flatten.first
    end

    def format
      [fields['format']].flatten.compact
    end

    def author
      [fields['author']].flatten.compact
    end

    def performers
      [fields['performers']].flatten.compact
    end

    def production_credits
      [fields['production_credits']].flatten.compact
    end

    def summary
      [fields['summary']].flatten.compact
    end

    def extended_summary
      [fields['extended_summary']].flatten.compact
    end

    def note
      [fields['note']].flatten.compact
    end

    def publisher
      [fields['csl_publisher']].flatten.compact
    end

    def contributors
      fields['contributors']&.map do |contributor|
        (contributor.find {|display| display['uid'] == 'display'} || {})['value']
      end
    end

    def year
      [fields['display_date']].flatten.first
    end

    def [](name)
      fields[name]
    end
  end
end

