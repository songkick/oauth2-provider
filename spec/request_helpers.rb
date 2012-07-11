module RequestHelpers
  require 'net/http'

  def get(query_params)
    qs  = params.map { |k,v| "#{ CGI.escape k.to_s }=#{ CGI.escape v.to_s }" }.join('&')
    uri = URI.parse('http://localhost:8000/authorize?' + qs)
    Net::HTTP.get_response(uri)
  end

  def allow_or_deny(query_params)
    Net::HTTP.post_form(URI.parse('http://localhost:8000/allow'), query_params)
  end

  def post_basic_auth(auth_params, query_params)
    url = "http://#{ auth_params['client_id'] }:#{ auth_params['client_secret'] }@localhost:8000/authorize"
    Net::HTTP.post_form(URI.parse(url), query_params)
  end

  def post(query_params)
    Net::HTTP.post_form(URI.parse('http://localhost:8000/authorize'), query_params)
  end

  def validate_json_response(response, status, body)
    response.code.to_i.should be == status
    JSON.parse(response.body).should be == body
    response['Content-Type'].should be == 'application/json'
    response['Cache-Control'].should be == 'no-store'
  end

  def mock_request(request_class, stubs = {})
    mock_request = mock(request_class)
    method_stubs = {
      :redirect?        => false,
      :response_body    => nil,
      :response_headers => {},
      :response_status  => 200
    }.merge(stubs)

    method_stubs.each do |method, value|
      mock_request.should_receive(method).and_return(value)
    end

    mock_request
  end
end

