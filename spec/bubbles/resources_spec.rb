require 'spec_helper'
require 'bubbles'

describe Bubbles::Resources do
  context 'internal plumbing' do
    describe '#get_headers_with_api_key' do
      before do
        @environment = Bubbles::RestEnvironment.new('http', 'blorf', 80, nil, 'X-API-Key')
        @endpoint = Bubbles::Endpoint.new(:get, 'somewhere/over/the/rainbow', false, false, nil, :body_as_object)
      end
      context 'with no additional headers' do
        context 'with no api key' do
          it 'should return an empty hash' do
            headers = Bubbles::RestClientResources.get_headers_with_api_key(@endpoint, nil, nil)

            expect(headers).to_not be_nil
            expect(headers.keys.length).to eq(2)
            expect(headers[:content_type]).to eq(:json)
            expect(headers[:accept]).to eq(:json)
          end
        end

        context 'with an api key and api key name' do
          before do
            @endpoint = Bubbles::Endpoint.new(:get, 'somewhere/over/the/rainbow', false, true, nil, :body_as_object)
            @api_key_name = 'X-Something-Wonderful'
            @api_key = 'blahblahblah'
          end

          it 'should return a hash with an API key in it' do
            headers = Bubbles::RestClientResources.get_headers_with_api_key(@endpoint, @api_key, @api_key_name)

            expect(headers).to_not be_nil
            expect(headers.keys.length).to eq(3)
            expect(headers[@api_key_name]).to eq(@api_key)
            expect(headers[:content_type]).to eq(:json)
            expect(headers[:accept]).to eq(:json)
          end
        end
      end
    end

    context '#execute_rest_call' do
      context 'without a block' do
        it 'should raise an exception' do
          expect { Bubbles::RestClientResources.execute_rest_call(nil, nil, nil, nil, {}) }.to raise_error(an_instance_of(ArgumentError).and having_attributes(message: 'This method requires that a block is given'))
        end
      end

      context 'without headers' do
        it 'should raise an exception' do
          environment = Bubbles::RestEnvironment.new('http', 'blorf', 80, nil, 'X-API-Key')
          endpoint = Bubbles::Endpoint.new(:get, 'somewhere/over/the/rainbow', false, false, nil, :body_as_object)

          expect { Bubbles::RestClientResources.execute_rest_call(environment, endpoint, nil, nil, nil) }.to raise_error(an_instance_of(ArgumentError).and having_attributes(message: 'Expected headers to be non-nil'))
        end
      end

      context 'with an invalid host' do
        it 'should return an error that the host is not accessible' do
          VCR.turned_off do
            WebMock.allow_net_connect!
            environment = Bubbles::RestEnvironment.new('http', 'blorf', 80, nil, 'X-API-Key')
            endpoint = Bubbles::Endpoint.new(:get, 'somewhere/over/the/rainbow', false, false, nil, :body_as_object)

            response = Bubbles::RestClientResources.execute_rest_call(environment, endpoint, nil, nil, {}) do |env, url, data, headers|
              next RestClient.get(url.to_s, headers)
            end

            expect(response).to_not be_nil
            expect(response.error).to eq('Unable to connect to host blorf:80')
            WebMock.disable_net_connect!
          end
        end
      end
    end
  end

  context 'when using the listmonk API' do
    context 'when accessed using http' do
      context 'when a GET request is used' do
        before do
          Bubbles.configure do |config|
            config.environments = [{
                                     scheme: 'http',
                                     host: 'listmonk.example.com'
                                   }]
            config.endpoints = [
              {
                location: '/api/lists',
                method: :get,
                api_key_required: false,
                authenticated: true,
                encode_authorization: %i[username password],
                name: "get_lists"
              }
            ]
          end
        end

        it 'should return a 200 ok' do
          VCR.use_cassette 'get_lists_authenticated' do
            env = Bubbles::Resources.new.environment

            # Use a dummy login and password
            response = env.get_lists 'someone', '7162jahd89'
            expect(response).to_not be_nil
          end
        end
      end
    end
  end

  context 'when using a dummy manufactured API' do
    context 'when accessed using https' do
      context 'when accessed using a HEAD request' do
        before do
          Bubbles.configure do |config|
            config.environments = [{
              scheme: 'https',
              host: 'www.somewhere.com',
              api_key: 'somemadeupkey2'
            }]
          end
        end

        context 'when using an authorization token' do
          before do
            @auth_token = 'eyJhbGciOiJIUzI1NiJ9.eyJjcmVhdGlvbl9kYXRlIjoiMjAxOS0wNC0yOFQxMDo0NDo0MS0wNTowMCIsImV4cGlyYXRpb25fZGF0ZSI6IjIwMTktMDUtMjhUMTA6NDQ6NDEtMDU6MDAiLCJ1c2VyX2lkIjoxfQ.C1mSYJ7ho6Cly8Ik_BcDzfC6rKb6cheY-NMbXV7QWvE'
          end

          context 'when an api key is required' do
            before do
              Bubbles.configure do |config|
                config.endpoints = [
                  {
                    location: '/',
                    method: :head,
                    api_key_required: true,
                    authenticated: true,
                    name: :head_somewhere
                  }
                ]
              end
            end

            it 'should return a 200 ok' do
              VCR.use_cassette 'head_madeup_api_key_authenticated_https' do
                env = Bubbles::Resources.new.environment
                response = env.head_somewhere @auth_token
                expect(response).to_not be_nil
              end
            end
          end
        end

        context 'when authentication is not necessary' do
          context 'when an API key is required' do
            before do
              Bubbles.configure do |config|
                config.endpoints = [
                  {
                      location: '/',
                      method: :head,
                      api_key_required: true,
                      authenticated: false,
                      name: :head_somewhere
                  }
                ]
              end
            end

            it 'should return a 200 ok' do
              VCR.use_cassette 'head_madeup_api_key_https' do
                env = Bubbles::Resources.new.environment
                response = env.head_somewhere
                expect(response).to_not be_nil
              end
            end
          end
        end
      end
    end

    context 'when accessed using http' do
      context 'when accessed using a POST request' do
        before do
          Bubbles.configure do |config|
            config.environments = [{
              scheme: 'https',
              host: '127.0.0.1',
              port: '9002'
            }]
          end
        end

        context 'when authentication is not required' do
          context 'when an api key is not required' do
            before do
              Bubbles.configure do |config|
                config.endpoints = [
                  {
                    location: :blah,
                    api_key_required: false,
                    authenticated: false,
                    method: :post,
                    return_type: :body_as_object
                  }
                ]
              end
            end

            it 'should respond with 200 ok' do
              VCR.use_cassette('post_unauthenticated_no_api_key') do
                env = Bubbles::Resources.new.environment
                data = {
                  email: 'eat@example.com'
                }

                response = env.blah data
                expect(response).to_not be_nil
                expect(response.success).to be_truthy
              end
            end
          end
        end
      end

      context 'when accessed using a HEAD request' do
        before do
          Bubbles.configure do |config|
            config.environments = [{
              scheme: 'http',
              host: 'www.somewhere.com',
              api_key: 'somemadeupkey'
            }]
          end
        end

        context 'when authentication is not necessary' do
          context 'when an API key is required' do
            before do
              Bubbles.configure do |config|
                config.endpoints = [
                  {
                    location: '/',
                    method: :head,
                    api_key_required: true,
                    authenticated: false,
                    name: :head_somewhere
                  }
                ]
              end
            end

            it 'should return a 200 ok' do
              VCR.use_cassette 'head_madeup_api_key' do
                env = Bubbles::Resources.new.environment
                response = env.head_somewhere
                expect(response).to_not be_nil
              end
            end
          end
        end

        context 'when using an authorization token' do
          before do
            @auth_token = 'eyJhbGciOiJIUzI1NiJ9.eyJjcmVhdGlvbl9kYXRlIjoiMjAxOS0wNC0yOFQxMDo0NDo0MS0wNTowMCIsImV4cGlyYXRpb25fZGF0ZSI6IjIwMTktMDUtMjhUMTA6NDQ6NDEtMDU6MDAiLCJ1c2VyX2lkIjoxfQ.C1mSYJ7ho6Cly8Ik_BcDzfC6rKb6cheY-NMbXV7QWvE'
          end

          context 'when an api key is required' do
            before do
              Bubbles.configure do |config|
                config.endpoints = [
                  {
                      location: '/',
                      method: :head,
                      api_key_required: true,
                      authenticated: true,
                      name: :head_somewhere
                  }
                ]
              end
            end

            it 'should return a 200 ok' do
              VCR.use_cassette 'head_madeup_api_key_authenticated' do
                env = Bubbles::Resources.new.environment
                response = env.head_somewhere @auth_token
                expect(response).to_not be_nil
              end
            end
          end
        end
      end
    end
  end

  context 'when using the dummy reqres API' do
    context 'accessed using https' do
      before do
        Bubbles.configure do |config|
          config.environments = [{
            scheme: 'https',
            host: 'reqres.in'
          }]
        end
      end

      context 'when accessing the users endpoint without authentication' do
        before do
          Bubbles.configure do |config|
            config.endpoints = [
              {
                method: :get,
                location: 'api/users/{id}',
                name: 'get_user_by_id',
                return_type: :body_as_object,
                authenticated: false,
                api_key_required: false
              }
            ]

            @resources = Bubbles::Resources.new
          end
        end

        it 'should return a single user with id=1' do
          require 'openssl'
          VCR.use_cassette('reqres_get_user_by_id') do
            environment = @resources.environment

            data = {id: 1}
            response = environment.get_user_by_id data

            expect(response).to_not be_nil
            expect(response.data).to_not be_nil
            expect(response.data.id).to be(1)
            expect(response.data.first_name).to eq('George')
          end
        end
      end
    end
  end

  context 'when using the joke API' do
    before do
      @host = 'jokeapi.p.rapidapi.com'
    end

    context 'when accessed with a GET request' do
      context 'with a valid API key in the header X-RapidAPI-Key' do
        before do
          @api_key = 'f950bc6c01msh14699dc76e5c505p1299d6jsncc2bf32a60af'

          Bubbles.configure do |config|
            config.endpoints = [
              {
                method: :get,
                location: 'categories',
                name: 'get_categories',
                return_type: :body_as_object,
                authenticated: false,
                api_key_required: true,
                headers: {
                  'X-RapidAPI-Host': @host
                }
              }
            ]

            config.environments = [{
              scheme: 'https',
              host: @host,
              api_key: @api_key,
              api_key_name: 'X-RapidAPI-Key'
            }]
          end
        end

        it 'should return four categories for jokes that can be retrieved' do
          VCR.use_cassette('get_jokeapi_categories') do
            resources = Bubbles::Resources.new
            environment = resources.environment
            response = environment.get_categories

            expect(response).to_not be_nil
            expect(response.categories.length).to eq(4)
          end
        end
      end
    end
  end

  context 'when using the FoamFactory API, accessed remotely' do
    before do
      Bubbles.configure do |config|
        config.environments = [{
          scheme: 'https',
          host: 'api.foamfactory.io',
          api_key: '0c4e97c2f7af608117e519d941f1d2fbc25fe46a'
        }]
      end
    end

    context 'when accessed with a GET request' do
      context 'listing users' do
        context 'with an authenticated endpoint requiring an API key' do
          before do
            Bubbles.configure do |config|
              config.endpoints = [
                {
                  location: :login,
                  method: :post,
                  encode_authorization: %i[username password],
                  api_key_required: true,
                  return_type: :body_as_object
                },
                {
                  location: :users,
                  method: :get,
                  authenticated: true,
                  api_key_required: true,
                  return_type: :body_as_object
                }
              ]
            end
          end

          it 'should successfully list all users in the system' do
            VCR.use_cassette('get_all_users_foamfactory_remote') do
              env = Bubbles::Resources.new.environment

              authenticated_user = env.login 'scottj', '123qwe456'
              expect(authenticated_user).to_not be_nil
              expect(authenticated_user.auth_token).to_not be_nil

              users = env.users authenticated_user.auth_token
              expect(users).to_not be_nil
              expect(users.users.length).to eq(2)
            end
          end
        end
      end
    end
  end

  context 'when using the FoamFactory API, accessed locally' do
    before do
      Bubbles.configure do |config|
        config.environments = [{
          scheme: 'http',
          host: 'localhost',
          port: 1234,
          api_key: 'fc411dc1b9bcc75f113951e574e243cca92fbddc'
        }]
      end
    end

    context 'when accessed with a GET request' do
      context 'listing users' do
        context 'with an authenticated API requiring an API key' do
          before do
            Bubbles.configure do |config|
              config.endpoints = [
                {
                  location: :login,
                  method: :post,
                  encode_authorization: %i[username password],
                  api_key_required: true,
                  return_type: :body_as_object
                },
                {
                  location: :users,
                  method: :get,
                  authenticated: true,
                  api_key_required: true,
                  return_type: :body_as_object
                }
              ]
            end
          end

          it 'should successfully list all users in the system' do
            VCR.use_cassette('get_all_users_foamfactory_local') do
              env = Bubbles::Resources.new.environment

              authenticated_user = env.login 'scottj', '123qwe456'
              expect(authenticated_user).to_not be_nil
              expect(authenticated_user.auth_token).to_not be_nil

              users = env.users authenticated_user.auth_token
              expect(users).to_not be_nil
              expect(users.users.length).to eq(9)
            end
          end
        end
      end
    end
  end

  context 'when using the SinkingMoon API' do
    before do
      Bubbles.configure do |config|
        config.environments = [{
          scheme: 'http',
          host: '127.0.0.1',
          port: '9002',
          api_key: 'e5528cb7ee0c5f6cb67af63c8f8111dce91a23e6'
        }]
      end
    end

    context 'when accessed with a POST request' do
      context 'when the host is unavailable' do
        before do
          Bubbles.configure do |config|
            config.endpoints = [
              {
                method: :post,
                location: :students,
                authenticated: true,
                name: 'create_student',
                return_type: :body_as_object
              }
            ]

            config.environments = [{
              scheme: 'https',
              host: '127.0.0.1',
              port: '1234',
              api_key: 'blah'
            }]
          end
        end

        it 'should fail gracefully' do
          # NOTE: We don't want to use a cassette for this next test.
          VCR.turned_off do
            WebMock.allow_net_connect!
            data = {
              name: 'Scott Klein',
              address: '871 Anywhere St. #109',
              city: 'Minneapolis',
              state: 'MN',
              zip: '55412',
              phone: '(612) 761-8172',
              email: 'scotty.kleiny@gmail.com',
              preferredContact: 'text',
              emergencyContactName: 'Nancy Klein',
              emergencyContactPhone: '(701) 762-5442',
              rank: 'white',
              joinDate: Date.today,
              lastAdvancementDate: Date.today,
              waiverSigned: true
          }

            resources = Bubbles::Resources.new
            environment = resources.environment
            student = environment.create_student 'someauthtoken', data

            expect(student).to_not be_nil
            expect(student.error).to eq('Unable to connect to host 127.0.0.1:1234')
            WebMock.disable_net_connect!
          end
        end
      end

      context 'when one of the endpoints has a slash in its path' do
        context 'and accessed using https' do
          before do
            Bubbles.configure do |config|
              config.endpoints = [
                {
                  method: :post,
                  location: 'password/forgot',
                  name: :forgot_password,
                  authenticated: false,
                  api_key_required: true,
                  return_type: :body_as_object
                }
              ]

              config.environments = [{
                scheme: 'https',
                host: '127.0.0.1',
                port: '9002',
                api_key: 'e5528cb7ee0c5f6cb67af63c8f8111dce91a23e6'
              }]
            end
          end

          it 'should successfully send a request to the server at the correct location' do
            VCR.use_cassette('post_unauthenticated_slash_in_path_https') do
              resources = Bubbles::Resources.new
              environment = resources.environment

              data = { email: 'eat@example.com' }
              response = environment.forgot_password data

              expect(response).to_not be_nil
              expect(response.success).to be_truthy
            end
          end
        end
      end

      context 'when the endpoint has encoded authorization' do
        before do
          Bubbles.configure do |config|
            config.endpoints = [
              {
                  method: :post,
                  location: :login,
                  authenticated: true,
                  api_key_required: true,
                  encode_authorization: %i[username password],
                  return_type: :body_as_object
              }
            ]
          end
        end

        it 'should retrieve an authorization token' do
          VCR.use_cassette('login') do
            resources = Bubbles::Resources.new
            environment = resources.environment

            # data = { username: 'scottj', password: '123qwe456' }
            login_object = environment.login 'scottj', '123qwe456'

            expect(login_object.id).to eq(1)
            expect(login_object.name).to eq('Scott Johnson')
            expect(login_object.username).to eq('scottj')
            expect(login_object.email).to eq('scottj@sinkingmoon.com')
            expect(login_object.auth_token).to_not be_nil
          end
        end
      end

      context 'when an authorization token is required' do
        before do
          Bubbles.configure do |config|
            config.endpoints = [
              {
                  method: :post,
                  location: :students,
                  authenticated: true,
                  name: 'create_student',
                  return_type: :body_as_object
              },
              {
                  method: :post,
                  location: :login,
                  authenticated: true,
                  api_key_required: true,
                  encode_authorization: %i[username password],
                  return_type: :body_as_object
              }
            ]
          end
        end

        context 'with a valid authorization token' do
          before do
            @resources = Bubbles::Resources.new
            @environment = @resources.environment

            VCR.use_cassette('login') do
              login_object = @environment.login 'scottj', '123qwe456'

              @auth_token = login_object.auth_token
            end
          end

          it 'should correctly add a record using a POST request' do
            VCR.use_cassette('post_student_authenticated') do
              data = {
                  name: 'Scott Klein',
                  address: '871 Anywhere St. #109',
                  city: 'Minneapolis',
                  state: 'MN',
                  zip: '55412',
                  phone: '(612) 761-8172',
                  email: 'scotty.kleiny@gmail.com',
                  preferredContact: 'text',
                  emergencyContactName: 'Nancy Klein',
                  emergencyContactPhone: '(701) 762-5442',
                  rank: 'white',
                  joinDate: Date.today,
                  lastAdvancementDate: Date.today,
                  waiverSigned: true
              }

              student = @environment.create_student @auth_token, data
              expect(student.name).to eq('Scott Klein')
              expect(student.address).to eq('871 Anywhere St. #109')
              expect(student.waiverSigned).to be_truthy
            end
          end

          context 'and an API key is required in the header X-Something-Key' do
            before do
              Bubbles.configure do |config|
                config.environments = [{
                  scheme: 'http',
                  host: '127.0.0.1',
                  port: '9002',
                  api_key_name: 'X-Something-Key',
                  api_key: 'blahblahblah'
                }]

                config.endpoints = [
                  {
                    method: :post,
                    location: :students,
                    authenticated: true,
                    name: 'create_student',
                    return_type: :body_as_object,
                    api_key_required: true
                  }
                ]
              end
            end

            it 'should correctly add a record using a POST request' do
              VCR.use_cassette('post_student_authenticated_api_key') do
                env = Bubbles::Resources.new.environment

                data = {
                    name: 'Scott Klein',
                    address: '871 Anywhere St. #109',
                    city: 'Minneapolis',
                    state: 'MN',
                    zip: '55412',
                    phone: '(612) 761-8172',
                    email: 'scotty.kleiny@gmail.com',
                    preferredContact: 'text',
                    emergencyContactName: 'Nancy Klein',
                    emergencyContactPhone: '(701) 762-5442',
                    rank: 'white',
                    joinDate: Date.today,
                    lastAdvancementDate: Date.today,
                    waiverSigned: true
                }

                student = env.create_student @auth_token, data
                expect(student.name).to eq('Scott Klein')
                expect(student.address).to eq('871 Anywhere St. #109')
                expect(student.waiverSigned).to be_truthy
              end
            end
          end

          context 'when using https' do
            before do
              Bubbles.configure do |config|
                config.environments = [{
                    scheme: 'https',
                    host: '127.0.0.1',
                    port: '9002',
                    api_key: 'e5528cb7ee0c5f6cb67af63c8f8111dce91a23e6'
                }]

                config.endpoints = [
                  {
                    method: :post,
                    location: :students,
                    authenticated: true,
                    name: 'create_student_https',
                    return_type: :body_as_object
                  }
                ]

                @auth_token = 'eyJhbGciOiJIUzI1NiJ9.eyJjcmVhdGlvbl9kYXRlIjoiMjAxOS0wNC0yOFQxMDo0NDo0MS0wNTowMCIsImV4cGlyYXRpb25fZGF0ZSI6IjIwMTktMDUtMjhUMTA6NDQ6NDEtMDU6MDAiLCJ1c2VyX2lkIjoxfQ.C1mSYJ7ho6Cly8Ik_BcDzfC6rKb6cheY-NMbXV7QWvE'
              end
            end

            it 'should correctly add a record using a POST request' do
              VCR.use_cassette('post_student_authenticated_https') do
                env = Bubbles::Resources.new.environment

                data = {
                  name: 'Scott Klein',
                  address: '871 Anywhere St. #109',
                  city: 'Minneapolis',
                  state: 'MN',
                  zip: '55412',
                  phone: '(612) 761-8172',
                  email: 'scotty.kleiny@gmail.com',
                  preferredContact: 'text',
                  emergencyContactName: 'Nancy Klein',
                  emergencyContactPhone: '(701) 762-5442',
                  rank: 'white',
                  joinDate: Date.today,
                  lastAdvancementDate: Date.today,
                  waiverSigned: true
                }

                student = env.create_student_https @auth_token, data
                expect(student.name).to eq('Scott Klein')
                expect(student.address).to eq('871 Anywhere St. #109')
                expect(student.waiverSigned).to be_truthy
              end
            end
          end
        end
      end
    end

    context 'when accessed with a GET request' do
      context 'when using a return type of body_as_object' do
        context 'for an endpoint that requires no authentication' do
          context 'for an endpoint that does not require an api key' do
            before do
              Bubbles.configure do |config|
                config.endpoints = [
                  {
                      method: :get,
                      location: :version,
                      authenticated: false,
                      api_key_required: false,
                      return_type: :body_as_object
                  }
                ]
              end
            end

            it 'should be able to retrieve a response from the API' do
              VCR.use_cassette('get_version_unauthenticated') do
                resources = Bubbles::Resources.new
                environment = resources.environment

                response = environment.version
                expect(response).to_not be_nil
                expect(response.name).to eq('Sinking Moon API')
                expect(response.versionName).to eq('4.1.0')

                deploy_date = Date.parse(response.deployDate)
                expect(deploy_date.year).to eq(2019)
                expect(deploy_date.month).to eq(4)
                expect(deploy_date.day).to eq(28)
              end
            end
          end
        end

        context 'that requires an authorization token' do
          before do
            Bubbles.configure do |config|
              config.endpoints = [
                {
                  method: :get,
                  location: :students,
                  authenticated: true,
                  api_key_required: false,
                  name: :list_students,
                  return_type: :body_as_object
                },
                {
                  method: :get,
                  location: 'students/{id}',
                  authenticated: true,
                  name: :get_student,
                  return_type: :body_as_object
                },
                {
                  method: :post,
                  location: :login,
                  authenticated: false,
                  api_key_required: true,
                  encode_authorization: %i[username password],
                  return_type: :body_as_object
                }
              ]
            end
          end

          context 'with a valid authorization token' do
            before do
              @resources = Bubbles::Resources.new
              @environment = @resources.environment

              VCR.use_cassette('login') do
                login_object = @environment.login 'scottj', '123qwe456'

                @auth_token = login_object.auth_token
              end
            end

            it 'should be able to retrieve a listing from the server' do
              VCR.use_cassette('get_students_authenticated') do
                response = @environment.list_students(@auth_token)
                expect(response).to_not be_nil

                students = response.students
                expect(students.length).to eq(2)
                expect(students[0].name).to eq('Joe Blow')
                expect(students[0].zip).to eq('90263')
              end
            end

            it 'should be able to retrieve a single record from the server' do
              VCR.use_cassette('get_student_by_id') do

                student = @environment.get_student(@auth_token, {id: 4})
                expect(student).to_not be_nil

                expect(student.id).to eq(4)
              end
            end
          end
        end
      end

      context 'when using a return type of body_as_string' do
        context 'for an endpoint that requires no authentication' do
          before do
            Bubbles.configure do |config|
              config.endpoints = [
                {
                  method: :get,
                  location: :version,
                  authenticated: false,
                  api_key_required: false,
                  return_type: :body_as_string
                }
              ]
            end
          end

          it 'should be able to retrieve a response from the API' do
            VCR.use_cassette('get_version_unauthenticated') do
              resources = Bubbles::Resources.new
              environment = resources.environment

              response = environment.version
              expect(response).to_not be_nil

              expect(response).to eq('{"name":"Sinking Moon API","versionName":"4.1.0","versionCode":18,"deployDate":"2019-04-28T18:23:05-05:00"}')
            end
          end
        end

        context 'that requires an authorization token' do
          before do
            Bubbles.configure do |config|
              config.endpoints = [
                {
                  method: :get,
                  location: :students,
                  authenticated: true,
                  api_key_required: false,
                  name: :list_students,
                  return_type: :body_as_string
                },
                {
                  method: :get,
                  location: 'students/{id}',
                  authenticated: true,
                  name: :get_student,
                  return_type: :body_as_string
                },
                {
                  method: :post,
                  location: :login,
                  authenticated: false,
                  api_key_required: true,
                  encode_authorization: %i[username password],
                  return_type: :body_as_object
                }
              ]
            end
          end

          context 'with a valid authorization token' do
            before do
              @resources = Bubbles::Resources.new
              @environment = @resources.environment

              VCR.use_cassette('login') do
                login_object = @environment.login 'scottj', '123qwe456'

                @auth_token = login_object.auth_token
              end
            end

            it 'should be able to retrieve a listing from the server' do
              VCR.use_cassette('get_students_authenticated') do
                response = @environment.list_students(@auth_token)
                expect(response).to_not be_nil

                expect(response).to eq('{"students":[{"id":1,"name":"Joe Blow","address":"2234 Bubble Gum Ave. #127","city":"Sometown","state":"CA","zip":"90263","phone":"5558764566","email":"bubblegumbanshee987@bazooka.org","emergencyContactName":"Some Guy","emergencyContactPhone":"5554339182","joinDate":"2018-10-10T00:00:00.000Z","waiverSigned":true,"created_at":"2019-04-28T15:30:59.186Z","updated_at":"2019-04-28T21:48:25.851Z","preferredContact":"phone","rank":"green","active":true,"advancements":[{"id":1,"date":"2018-10-30","rank":"white","student_id":1,"created_at":"2019-04-28T15:30:59.211Z","updated_at":"2019-04-28T15:30:59.211Z"},{"id":2,"date":"2019-01-28","rank":"orange","student_id":1,"created_at":"2019-04-28T15:30:59.215Z","updated_at":"2019-04-28T15:30:59.215Z"},{"id":3,"date":"2019-03-29","rank":"yellow","student_id":1,"created_at":"2019-04-28T15:30:59.218Z","updated_at":"2019-04-28T15:30:59.218Z"},{"id":9,"date":"2019-04-06","rank":"green","student_id":1,"created_at":"2019-04-28T21:49:04.551Z","updated_at":"2019-04-28T21:49:04.551Z"}]},{"id":2,"name":"Scott Klein","address":"871 Anywhere St. #109","city":"Minneapolis","state":"MN","zip":"55412","phone":"(612) 761-8172","email":"scotty.kleiny@gmail.com","emergencyContactName":"Nancy Klein","emergencyContactPhone":"(701) 762-5442","joinDate":"2019-04-28T00:00:00.000Z","waiverSigned":true,"created_at":"2019-04-28T23:07:50.447Z","updated_at":"2019-04-28T23:07:50.447Z","preferredContact":"text","rank":"white","active":true,"advancements":[{"id":10,"date":"2019-04-28","rank":"white","student_id":2,"created_at":"2019-04-28T23:07:50.500Z","updated_at":"2019-04-28T23:07:50.500Z"}]}]}')
              end
            end

            it 'should be able to retrieve a single record from the server' do
              VCR.use_cassette('get_student_by_id') do

                response = @environment.get_student(@auth_token, {id: 4})
                expect(response).to_not be_nil
                expect(response).to eq('{"id":4,"name":"Scott Klein","address":"871 Anywhere St. #109","city":"Minneapolis","state":"MN","zip":"55412","phone":"(612) 761-8172","email":"scotty.kleiny@gmail.com","emergencyContactName":"Nancy Klein","emergencyContactPhone":"(701) 762-5442","joinDate":"2019-04-28T00:00:00.000Z","waiverSigned":true,"created_at":"2019-04-28T23:53:18.013Z","updated_at":"2019-04-28T23:53:18.013Z","preferredContact":"text","rank":"white","active":true,"advancements":[{"id":12,"date":"2019-04-28","rank":"white","student_id":4,"created_at":"2019-04-28T23:53:18.035Z","updated_at":"2019-04-28T23:53:18.035Z"}]}')
              end
            end
          end
        end
      end

      context 'when using a return type of full_response' do
        context 'for an endpoint that requires no authentication' do
          before do
            Bubbles.configure do |config|
              config.endpoints = [
                {
                  method: :get,
                  location: :version,
                  authenticated: false,
                  api_key_required: false,
                  return_type: :full_response
                }
              ]
            end
          end

          it 'should be able to retrieve a response from the API' do
            VCR.use_cassette('get_version_unauthenticated') do
              resources = Bubbles::Resources.new
              environment = resources.environment

              response = environment.version
              expect(response).to_not be_nil
              expect(response.code).to eq(200)

              response_obj = JSON.parse(response.body, object_class: OpenStruct)
              expect(response_obj.name).to eq('Sinking Moon API')
              expect(response_obj.versionName).to eq('4.1.0')

              deploy_date = Date.parse(response_obj.deployDate)
              expect(deploy_date.year).to eq(2019)
              expect(deploy_date.month).to eq(4)
              expect(deploy_date.day).to eq(28)
            end
          end
        end

        context 'that requires an authorization token' do
          before do
            Bubbles.configure do |config|
              config.endpoints = [
                {
                  method: :get,
                  location: :students,
                  authenticated: true,
                  api_key_required: false,
                  name: :list_students,
                  return_type: :full_response
                },
                {
                  method: :get,
                  location: 'students/{id}',
                  authenticated: true,
                  name: :get_student,
                  return_type: :full_response
                },
                {
                  method: :post,
                  location: :login,
                  authenticated: false,
                  api_key_required: true,
                  encode_authorization: %i[username password],
                  return_type: :body_as_object
                }
              ]
            end
          end

          context 'with a valid authorization token' do
            before do
              @resources = Bubbles::Resources.new
              @environment = @resources.environment

              VCR.use_cassette('login') do
                login_object = @environment.login 'scottj', '123qwe456'

                @auth_token = login_object.auth_token
              end
            end

            it 'should be able to retrieve a listing from the server' do
              VCR.use_cassette('get_students_authenticated') do
                response = @environment.list_students(@auth_token)
                expect(response).to_not be_nil
                expect(response.code).to eq(200)

                students = JSON.parse(response.body, object_class: OpenStruct).students
                expect(students.length).to eq(2)
                expect(students[0].name).to eq('Joe Blow')
                expect(students[0].zip).to eq('90263')
              end
            end

            it 'should be able to retrieve a single record from the server' do
              VCR.use_cassette('get_student_by_id') do

                response = @environment.get_student(@auth_token, {id: 4})
                expect(response).to_not be_nil
                expect(response.code).to eq(200);

                student = JSON.parse(response.body, object_class: OpenStruct)
                expect(student.id).to eq(4)
              end
            end
          end
        end
      end
    end

    context 'when accessed with a DELETE request' do
      context 'that does not require uri parameters' do
        it 'should raise an exception' do
          expect {
            Bubbles.configure do |config|
              config.endpoints = [
                {
                    method: :delete,
                    location: 'students',
                    authenticated: true,
                    name: 'delete_student_no_params',
                    return_type: :body_as_object
                }
              ]
            end
          }.to raise_error('DELETE requests without URI parameters are not allowed')
        end
      end

      context 'when using a return type of body_as_object' do
        context 'for an endpoint that does not require authorization' do
          context 'with a valid api key' do
            before do
              Bubbles.configure do |config|
                config.environments = [{
                  scheme: 'http',
                  host: '127.0.0.1',
                  port: 9002,
                  api_key: 'blahblahblah'
                }]

                config.endpoints = [
                  {
                    method: :delete,
                    location: 'students/{id}',
                    name: 'delete_student_no_auth',
                    authenticated: false,
                    api_key_required: true,
                    return_type: :body_as_object
                  }
                ]
              end
            end

            it 'should successfully delete the record' do
              VCR.use_cassette('delete_unauthenticated_student_by_id') do
                uri_params = {
                  id: 2
                }

                env = Bubbles::Resources.new.environment
                response = env.delete_student_no_auth uri_params

                expect(response).to_not be_nil
                expect(response.success).to be_truthy
              end
            end
          end
        end

        context 'for an endpoint that requires authorization' do
          before do
            Bubbles.configure do |config|
              config.endpoints = [
                {
                    method: :delete,
                    location: 'students/{id}',
                    authenticated: true,
                    name: 'delete_student',
                    return_type: :body_as_object
                }
              ]
            end
          end

          context 'when accessing a host via HTTPS that requires an API key' do
            before do
              Bubbles.configure do |config|
                config.environments = [{
                  scheme: 'https',
                  host: 'testbed.foamfactory.io',
                  api_key: 'blahblahblah'
                }]

                config.endpoints = [
                  {
                    method: :delete,
                    location: 'students/{id}',
                    authenticated: true,
                    api_key_required: true,
                    name: 'delete_student_https',
                    return_type: :body_as_object
                  }
                ]
              end
            end

            it 'should successfully delete the record' do
              VCR.use_cassette('delete_student_by_id_api_key_https') do
                auth_token = 'eyJhbGciOiJIUzI1NiJ9.eyJjcmVhdGlvbl9kYXRlIjoiMjAxOS0wNC0yOFQxMDo0NDo0MS0wNTowMCIsImV4cGlyYXRpb25fZGF0ZSI6IjIwMTktMDUtMjhUMTA6NDQ6NDEtMDU6MDAiLCJ1c2VyX2lkIjoxfQ.C1mSYJ7ho6Cly8Ik_BcDzfC6rKb6cheY-NMbXV7QWvE'
                env = Bubbles::Resources.new.environment
                response = env.delete_student_https auth_token, {id: 2}

                expect(response.success).to eq(true)
              end
            end
          end

          context 'with a valid authorization token' do
            before do
              @resources = Bubbles::Resources.new
              @environment = @resources.environment

              VCR.use_cassette('login') do
                login_object = @environment.login 'scottj', '123qwe456'

                @auth_token = login_object.auth_token
              end
            end

            it 'should be able to successfully delete a record' do
              VCR.use_cassette('delete_student_by_id') do
                response = @environment.delete_student @auth_token, {id: 2}

                expect(response.success).to eq(true)
              end
            end
          end
        end
      end
    end

    context 'when accessed with a PATCH request' do
      context 'when using a return type of body_as_object' do
        context 'for an endpoint that requires authorization' do
          context 'for an endpoint that does not have URI parameters' do
            before do
              Bubbles.configure do |config|
                config.endpoints = [
                  {
                      method: :patch,
                      location: 'password/change',
                      authenticated: true,
                      name: 'change_password_no_uri',
                      return_type: :body_as_object
                  }
                ]
              end

              @new_password = '789rty123'
            end

            it 'should execute the request and return a 200 ok' do
              VCR.use_cassette('patch_change_password_authenticated') do
                data = {
                    new_password: @new_password,
                    password_confirmation: @new_password
                }

                env = Bubbles::Resources.new.environment
                response = env.change_password_no_uri 'blahblahblah', data

                expect(response).to_not be_nil
                expect(response.success).to be_truthy
              end
            end
          end

          before do
            Bubbles.configure do |config|
              config.endpoints = [
                {
                  method: :patch,
                  location: 'students/{id}',
                  authenticated: true,
                  name: 'update_student',
                  return_type: :body_as_object
                },
                {
                  method: :post,
                  location: :login,
                  authenticated: false,
                  api_key_required: true,
                  encode_authorization: %i[username password],
                  return_type: :body_as_object
                }
              ]
            end
          end

          context 'with a valid authorization token' do
            before do
              @resources = Bubbles::Resources.new
              @environment = @resources.environment

              VCR.use_cassette('login') do
                login_object = @environment.login 'scottj', '123qwe456'

                @auth_token = login_object.auth_token
              end
            end

            context 'when using https and an api key is required' do
              before do
                Bubbles.configure do |config|
                  config.environments = [{
                    scheme: 'https',
                    host: '127.0.0.1',
                    api_key: 'e5528cb7ee0c5f6cb67af63c8f8111dce91a23e6'
                  }]

                  config.endpoints = [
                    {
                      method: :patch,
                      location: 'students/{id}',
                      authenticated: true,
                      name: 'update_student',
                      return_type: :body_as_object,
                      api_key_required: true
                    }
                  ]
                end
              end

              it 'should update part of a record' do
                VCR.use_cassette('patch_update_student_https') do
                  env = Bubbles::Resources.new.environment
                  response = env.update_student @auth_token, {id: 4}, {student: {email: 'kleinhammer@gmail.com' } }

                  expect(response.id).to eq(4)
                  expect(response.name).to eq('Scott Klein')
                  expect(response.address).to eq('871 Anywhere St. #109')
                  expect(response.city).to eq('Minneapolis')
                  expect(response.state).to eq('MN')
                  expect(response.zip).to eq('55412')
                  expect(response.phone).to eq('(612) 761-8172')
                  expect(response.emergencyContactPhone).to eq('(701) 762-5442')
                  expect(response.emergencyContactName).to eq('Nancy Klein')
                end
              end
            end

            it 'should update part of a record' do
              VCR.use_cassette('patch_update_student') do
                response = @environment.update_student @auth_token, {id: 4}, {student: {email: 'kleinhammer@gmail.com' } }

                expect(response.id).to eq(4)
                expect(response.name).to eq('Scott Klein')
                expect(response.address).to eq('871 Anywhere St. #109')
                expect(response.city).to eq('Minneapolis')
                expect(response.state).to eq('MN')
                expect(response.zip).to eq('55412')
                expect(response.phone).to eq('(612) 761-8172')
                expect(response.emergencyContactPhone).to eq('(701) 762-5442')
                expect(response.emergencyContactName).to eq('Nancy Klein')
              end
            end
          end
        end

        context 'for an endpoint that does not require authentication' do
          before do
            Bubbles.configure do |config|
              config.endpoints = [
                {
                  method: :patch,
                  location: 'password/change',
                  authenticated: false,
                  name: 'change_forgotten_password',
                  return_type: :body_as_object
                }
              ]

              @resources = Bubbles::Resources.new
              @environment = @resources.environment
            end
          end

          context 'with a valid identification parameter and body' do
            before do
              @hash = 'xX3UQ9WYuMGOQ9SQt7DtSR2EOWnPCdMk'
              @new_password = '789rty123'
            end

            context 'when using https and passing an API key' do
              before do
                Bubbles.configure do |config|
                  config.environments = [{
                    scheme: :https,
                    host: 'api.something.com',
                    api_key: 'blahblahblahblah'
                  }]

                  config.endpoints = [
                    {
                      method: :patch,
                      authenticated: false,
                      api_key_required: true,
                      location: 'password/change',
                      name: 'change_forgotten_password',
                      return_type: :body_as_object
                    }
                  ]
                end
              end

              it 'should allow the successful execution of the request' do
                VCR.use_cassette('patch_change_password_unauthenticated_https') do
                  data = {
                    one_time_login_hash: @hash,
                    new_password: @new_password,
                    password_confirmation: @new_password
                  }

                  env = Bubbles::Resources.new.environment
                  response = env.change_forgotten_password data

                  expect(response).to_not be_nil
                  expect(response.success).to be_truthy
                end
              end
            end

            it 'should allow the successful execution of the request' do
              VCR.use_cassette('patch_change_password_unauthenticated') do
                data = {
                  one_time_login_hash: @hash,
                  new_password: @new_password,
                  password_confirmation: @new_password
                }

                response = @environment.change_forgotten_password data

                expect(response).to_not be_nil
                expect(response.success).to be_truthy
              end
            end
          end

          context 'for an endpoint that requires URI parameters' do
            before do
              Bubbles.configure do |config|
                config.endpoints = [
                  {
                      method: :patch,
                      location: 'password/change/{hash}',
                      authenticated: false,
                      name: 'change_forgotten_password_uri',
                      return_type: :body_as_object
                  }
                ]
              end
            end

            context 'with a valid identification parameter and body' do
              before do
                @hash = 'F85QnV7Dus2xt1bAAQ72X2WbcNAqCREU'
                @new_password = '789rty123'
              end

              it 'should allow the successful execution of the request' do
                VCR.use_cassette('patch_change_password_unauthenticated_uri_params') do
                  uri_params = {
                      hash: @hash
                  }

                  data = {
                      new_password: @new_password,
                      password_confirmation: @new_password
                  }

                  env = Bubbles::Resources.new.environment
                  response = env.change_forgotten_password_uri uri_params, data

                  expect(response).to_not be_nil
                  expect(response.success).to be_truthy
                end
              end
            end
          end
        end
      end

      context 'when using a return type of full_response' do
        context 'for an endpoint that does not require authorization' do
          context 'with an invalid identification parameter' do
            before do
              Bubbles.configure do |config|
                config.endpoints = [
                  {
                    method: :patch,
                    location: 'password/change',
                    authenticated: false,
                    name: 'change_forgotten_password',
                    return_type: :full_response
                  }
                ]
              end

              @resources = Bubbles::Resources.new
              @environment = @resources.environment

              @hash = '0xdeadbeef'
              @new_password = 'habsgafat1'
            end

            it 'should respond with a RestClient error indicating a 404 exception was encountered' do
              VCR.use_cassette('patch_change_password_unauthenticated_bad_hash') do
                data = {
                  one_time_login_hash: @hash,
                  new_password: @new_password,
                  password_confirmation: @new_password
                }

                saw_error = false
                begin
                  response = @environment.change_forgotten_password data
                rescue RestClient::NotFound => e
                  saw_error = true
                end

                expect(saw_error).to be_truthy
              end
            end
          end
        end
      end
    end

    context 'when accessed with a PUT request' do
      context 'when using a return type of body_as_object' do
        context 'for an endpoint that requires authorization' do
          context 'for an endpoint that does not have URI parameters' do
            before do
              Bubbles.configure do |config|
                config.endpoints = [
                  {
                      method: :put,
                      location: 'password/change',
                      authenticated: true,
                      name: 'change_password_no_uri',
                      return_type: :body_as_object
                  }
                ]
              end

              @new_password = '789rty123'
            end

            it 'should execute the request and return a 200 ok' do
              VCR.use_cassette('put_change_password_authenticated') do
                data = {
                    new_password: @new_password,
                    password_confirmation: @new_password
                }

                env = Bubbles::Resources.new.environment
                response = env.change_password_no_uri 'blahblahblah', data

                expect(response).to_not be_nil
                expect(response.success).to be_truthy
              end
            end
          end

          before do
            Bubbles.configure do |config|
              config.endpoints = [
                {
                  method: :put,
                  location: 'students/{id}',
                  authenticated: true,
                  name: 'update_student',
                  return_type: :body_as_object
                },
              {
                  method: :post,
                  location: :login,
                  authenticated: false,
                  api_key_required: true,
                  encode_authorization: %i[username password],
                  return_type: :body_as_object
                }
              ]
            end
          end

          context 'with a valid authorization token' do
            before do
              @resources = Bubbles::Resources.new
              @environment = @resources.environment

              VCR.use_cassette('login') do
                login_object = @environment.login 'scottj', '123qwe456'

                @auth_token = login_object.auth_token
              end
            end

            context 'when accessed using https and an api key' do
              before do
                Bubbles.configure do |config|
                  config.endpoints = [
                    {
                        method: :put,
                        location: 'students/{id}',
                        authenticated: true,
                        name: 'update_student',
                        return_type: :body_as_object,
                        api_key_required: true
                    }
                  ]

                  config.environments = [{
                    scheme: :https,
                    host: 'testbed.foamfactory.io',
                    api_key: 'blahblahblah'
                  }]
                end
              end

              it 'should update the entire record' do
                VCR.use_cassette('put_update_student_https') do
                  data = {
                    student: {
                      email: 'michael.moribs@mikesmail-moribss.com',
                      name: 'Michael Moribsu',
                      address: '123 Anywhere St.',
                      city: 'Onetown',
                      state: 'MN',
                      zip: '55081',
                      phone: '(555) 123-9045',
                      emergencyContactName: 'Katie Moribsu',
                      emergencyContactPhone: '(765) 192-8123'
                    }
                  }

                  env = Bubbles::Resources.new.environment
                  response = env.update_student @auth_token, {id: 4}, data

                  expect(response.id).to eq(4)
                  expect(response.email).to eq('michael.moribs@mikesmail-moribss.com')
                  expect(response.name).to eq('Michael Moribsu')
                  expect(response.address).to eq('123 Anywhere St.')
                  expect(response.city).to eq('Onetown')
                  expect(response.state).to eq('MN')
                  expect(response.zip).to eq('55081')
                  expect(response.phone).to eq('(555) 123-9045')
                  expect(response.emergencyContactPhone).to eq('(765) 192-8123')
                  expect(response.emergencyContactName).to eq('Katie Moribsu')
                end
              end
            end

            it 'should update the entire record' do
              VCR.use_cassette('put_update_student') do
                data = {
                  student: {
                    email: 'michael.moribs@mikesmail-moribss.com',
                    name: 'Michael Moribsu',
                    address: '123 Anywhere St.',
                    city: 'Onetown',
                    state: 'MN',
                    zip: '55081',
                    phone: '(555) 123-9045',
                    emergencyContactName: 'Katie Moribsu',
                    emergencyContactPhone: '(765) 192-8123'
                  }
                }

                response = @environment.update_student @auth_token, {id: 4}, data

                expect(response.id).to eq(4)
                expect(response.email).to eq('michael.moribs@mikesmail-moribss.com')
                expect(response.name).to eq('Michael Moribsu')
                expect(response.address).to eq('123 Anywhere St.')
                expect(response.city).to eq('Onetown')
                expect(response.state).to eq('MN')
                expect(response.zip).to eq('55081')
                expect(response.phone).to eq('(555) 123-9045')
                expect(response.emergencyContactPhone).to eq('(765) 192-8123')
                expect(response.emergencyContactName).to eq('Katie Moribsu')
              end
            end
          end
        end

        context 'for an endpoint that does not require authentication' do
          before do
            Bubbles.configure do |config|
              config.endpoints = [
                {
                  method: :put,
                  location: 'password/change',
                  authenticated: false,
                  name: 'change_forgotten_password_put',
                  return_type: :body_as_object
                }
              ]

              @resources = Bubbles::Resources.new
              @environment = @resources.environment
            end
          end

          context 'with a valid identification parameter and body' do
            before do
              @hash = 'F85QnV7Dus2xt1bAAQ72X2WbcNAqCREU'
              @new_password = '789rty123'
            end

            context 'when accessed with https and an API key' do
              before do
                Bubbles.configure do |config|
                  config.environments = [{
                    scheme: :https,
                    host: 'testbed.foamfactory.io',
                    api_key: 'foamfactorybeermaker'
                  }]

                  config.endpoints = [
                    {
                      method: :put,
                      location: 'password/change',
                      authenticated: false,
                      api_key_required: true,
                      name: 'change_forgotten_password_put',
                      return_type: :body_as_object
                    }
                  ]
                end
              end
              it 'should allow the successful execution of the request' do
                VCR.use_cassette('put_change_password_unauthenticated_https') do
                  data = {
                    one_time_login_hash: @hash,
                    new_password: @new_password,
                    password_confirmation: @new_password
                  }

                  env = Bubbles::Resources.new.environment
                  response = env.change_forgotten_password_put data

                  expect(response).to_not be_nil
                  expect(response.success).to be_truthy
                end
              end
            end

            it 'should allow the successful execution of the request' do
              VCR.use_cassette('put_change_password_unauthenticated') do
                data = {
                  one_time_login_hash: @hash,
                  new_password: @new_password,
                  password_confirmation: @new_password
                }

                response = @environment.change_forgotten_password_put data

                expect(response).to_not be_nil
                expect(response.success).to be_truthy
              end
            end
          end

          context 'for an endpoint that requires URI parameters' do
            before do
              Bubbles.configure do |config|
                config.endpoints = [
                  {
                      method: :put,
                      location: 'password/change/{hash}',
                      authenticated: false,
                      name: 'change_forgotten_password_uri',
                      return_type: :body_as_object
                  }
                ]
              end
            end

            context 'with a valid identification parameter and body' do
              before do
                @hash = 'F85QnV7Dus2xt1bAAQ72X2WbcNAqCREU'
                @new_password = '789rty123'
              end

              it 'should allow the successful execution of the request' do
                VCR.use_cassette('put_change_password_unauthenticated_uri_params') do
                  uri_params = {
                      hash: @hash
                  }

                  data = {
                      new_password: @new_password,
                      password_confirmation: @new_password
                  }

                  env = Bubbles::Resources.new.environment
                  response = env.change_forgotten_password_uri uri_params, data

                  expect(response).to_not be_nil
                  expect(response.success).to be_truthy
                end
              end
            end
          end
        end
      end

      context 'when using a return type of full_response' do
        context 'for an endpoint that does not require authorization' do
          context 'with an invalid identification parameter' do
            before do
              Bubbles.configure do |config|
                config.endpoints = [
                  {
                    method: :put,
                    location: 'password/change',
                    authenticated: false,
                    name: 'change_forgotten_password_put',
                    return_type: :full_response
                  }
                ]
              end

              @resources = Bubbles::Resources.new
              @environment = @resources.environment

              @hash = '0xdeadbeef'
              @new_password = 'habsgafat1'
            end

            it 'should respond with a RestClient error indicating a 404 exception was encountered' do
              VCR.use_cassette('put_change_password_unauthenticated_bad_hash') do
                data = {
                  one_time_login_hash: @hash,
                  new_password: @new_password,
                  password_confirmation: @new_password
                }

                saw_error = false
                begin
                  response = @environment.change_forgotten_password_put data
                rescue RestClient::NotFound => e
                  saw_error = true
                end

                expect(saw_error).to be_truthy
              end
            end
          end
        end
      end
    end

    context 'when accessed with a HEAD request' do
      context 'for an endpoint that does not require authorization' do
        before do
          Bubbles.configure do |config|
            config.environments = [{
              scheme: 'http',
              host: '127.0.0.1',
              port: '1234',
              api_key: 'bf414e8accf8155d650fb48500b48c569dc305e8'
            }]
          end
        end

        context 'for an endpoint that does not require an API key' do
          context 'when at least one url parameter is expected' do
            before do
              Bubbles.configure do |config|
              config.environments = [{
                scheme: 'http',
                host: '127.0.0.1',
                port: '1234'
              }]

              config.endpoints = [
                method: :head,
                name: 'validate_login_hash',
                location: '/validate/{hash}',
                authenticated: false,
                return_type: :full_response
              ]
            end

              @resources = Bubbles::Resources.new
            end

            context 'and that url parameter is specified on the url path and is not valid' do
              before do
                @login_hash = 'blah123'
              end

              it 'should return a 401 unauthorized' do
                VCR.use_cassette('head_validate_login_hash_with_invalid_hash') do
                  saw_error = false
                  begin
                    response = @resources.environment.validate_login_hash({hash: @login_hash})
                  rescue RestClient::Unauthorized
                    saw_error = true
                  end

                  expect(saw_error)
                end
              end
            end

            context 'and that url parameter is specified on the url path and is valid' do
              before do
                @login_hash = '87162aslkjabsa'
              end
              it 'should return a 204 no_content' do
                VCR.use_cassette('head_validate_login_hash_with_valid_hash') do
                  response = @resources.environment.validate_login_hash({hash: @login_hash})

                  expect(response).to_not be_nil
                  expect(response.code).to eq(204)
                end
              end
            end
          end
        end

        context 'for an endpoint that requires an API key' do
          context 'when at least one url parameter is expected' do
            before do
              Bubbles.configure do |config|
                config.endpoints = [
                  method: :head,
                  name: 'validate_login_hash',
                  location: '/validate/{hash}',
                  authenticated: false,
                  api_key_required: true,
                  return_type: :full_response
                ]
              end

              @resources = Bubbles::Resources.new
            end

            context 'and that url parameter is specified on the url path and is not valid' do
              before do
                @login_hash = 'blah123'
              end

              it 'should return a 401 unauthorized' do
                VCR.use_cassette('head_api_key_validate_login_hash_with_invalid_hash') do
                  saw_error = false
                  begin
                    response = @resources.environment.validate_login_hash({hash: @login_hash})
                  rescue RestClient::Unauthorized
                    saw_error = true
                  end

                  expect(saw_error)
                end
              end
            end

            context 'and that url parameter is specified on the url path and is valid' do
              before do
                @login_hash = '87162aslkjabsa'
              end
              it 'should return a 204 no_content' do
                VCR.use_cassette('head_api_key_validate_login_hash_with_valid_hash') do
                  response = @resources.environment.validate_login_hash({hash: @login_hash})

                  expect(response).to_not be_nil
                  expect(response.code).to eq(204)
                end
              end
            end
          end
        end

        context 'for an endpoint that does not require an API key' do
          context 'for an endpoint that does not take any URL parameters' do
            context 'after redefining the environment to use Google with additional headers' do
              before do
                Bubbles.configure do |config|
                  config.environments = [{
                    scheme: 'http',
                    host: 'www.google.com',
                    port: '80'
                  }]

                  config.endpoints = [
                    {
                      method: :head,
                      location: '/',
                      authenticated: false,
                      name: 'head_google',
                      return_type: :full_response,
                      headers: {
                        'X-Something': 'anything'
                      }
                    }
                  ]
                end

                @resources = Bubbles::Resources.new
              end

              it 'should add the header to the request' do
                VCR.use_cassette('head_google_with_headers') do
                  response = @resources.environment.head_google
                  request = response.request

                  expect(request).to_not be_nil
                  expect(request.headers).to_not be_nil
                  expect(request.headers).to have_key(:'X-Something')
                end
              end
            end

            context 'after redefining the environment to use Google without any additional headers' do
              # NOTE - this is required so we know that we can redefine environments without issues
              before do
                Bubbles.configure do |config|
                  config.environments = [{
                    scheme: 'http',
                    host: 'www.google.com',
                    port: '80'
                  }]

                  config.endpoints = [
                    {
                      method: :head,
                      location: '/',
                      authenticated: false,
                      name: 'head_google',
                      return_type: :full_response
                    }
                  ]
                end

                @resources = Bubbles::Resources.new
              end

              it 'should return a 200 Ok response' do
                VCR.use_cassette('head_google') do
                  response = @resources.environment.head_google

                  expect(response).to_not be_nil
                  expect(response.code).to eq(200)
                end
              end
            end
          end
        end
      end

      context 'for an endpoint that requires authorization' do
        before do
          Bubbles.configure do |config|
            config.endpoints = [
              {
                method: :head,
                location: '/students',
                authenticated: true,
                name: 'head_students',
                api_key_required: false
              },
              {
                method: :post,
                location: :login,
                authenticated: false,
                api_key_required: true,
                encode_authorization: %i[username password],
                return_type: :body_as_object
              }
            ]
          end
        end

        context 'with a valid authorization token' do
          context 'having URI parameters specified' do
            before do
              Bubbles.configure do |config|
                config.endpoints = [
                  method: :head,
                  authenticated: true,
                  api_key_required: false,
                  location: 'students/{id}',
                  name: 'head_student_by_id'
                ]
              end
            end

            it 'should return a 200 ok response' do
              VCR.use_cassette('head_students_authenticated_uri_params') do
                env = Bubbles::Resources.new.environment
                response = env.head_student_by_id 'blahblahblah', { id: 32 }

                expect(response).to_not be_nil
                expect(response.code).to eq(200)
              end
            end
          end

          context 'with no URI parameters' do
            before do
              @resources = Bubbles::Resources.new
              @environment = @resources.environment

              VCR.use_cassette('login') do
                login_object = @environment.login 'scottj', '123qwe456'

                @auth_token = login_object.auth_token
              end
            end

            it 'should return a 200 ok response' do
              VCR.use_cassette('head_students_authenticated') do
                response = @environment.head_students @auth_token

                expect(response).to_not be_nil
                expect(response.code).to eq(200)
              end
            end
          end
        end
      end
    end
  end
end
