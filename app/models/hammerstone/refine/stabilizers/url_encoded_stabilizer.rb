module Hammerstone::Refine::Stabilizers
  class UrlEncodedStabilizer

    def to_stable_id(filter:)
      compressed_state = ActiveSupport::Gzip.compress(filter.state)
      encoded_state = Base64.encode64(compressed_state)
      CGI.escape(encoded_state)
    end

    def from_stable_id(id:, initial_query: nil)
      url_decoded = CGI.unescape(id)
      base_64_decoded = Base64.decode64(url_decoded)
      uncompress = ActiveSupport::Gzip.decompress(base_64_decoded)
      state = ActiveSupport::JSON.decode(uncompress).deep_symbolize_keys
      Hammerstone::Refine::Filter.from_state(state, initial_query)
    end
  end
end