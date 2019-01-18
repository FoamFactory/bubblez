require 'bubbles/endpoint'

describe Bubbles::Endpoint do
  it 'should allow the creation of an endpoint with a type of GET and a location of version' do
    ep = Bubbles::Endpoint.new(:get, 'version')

    expect(ep.get_key_string).to eq('get-version-unauthenticated')
  end

  it 'should allow the creation of a new endpoint with a type of POST and a location of login that requires no authentication, but an API key' do
    ep = Bubbles::Endpoint.new(:post, 'login', false, true)

    expect(ep.get_key_string).to eq('post-login-unauthenticated-with-api-key')
  end

  it 'should allow the creation of a new endpoint that requires authentication, has a type of get and a location of versions' do
    ep = Bubbles::Endpoint.new(:get, 'versions', true)

    expect(ep.get_key_string).to eq('get-versions-authenticated')
  end

  it 'should show that a location of "/versions/new" is a complex endpoint' do
    ep = Bubbles::Endpoint.new(:get, '/versions/new')

    expect(ep.location).to eq('versions/new')
    expect(ep.is_complex).to eq(true)
  end

  it 'should replace all instances of "/" in the location with "_" when get_location_string is called' do
    ep = Bubbles::Endpoint.new :get, 'versions'

    expect(ep.get_location_string).to eq('versions')

    ep = Bubbles::Endpoint.new :get, '/management/clients/new'

    expect(ep.get_location_string).to eq('management_clients_new')
  end

end