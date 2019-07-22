require 'bubbles'
require 'spec_helper'

describe Bubbles::Resources do
  context 'when using the local environment or a previously recorded call' do
    before do
      Bubbles.configure do |config|
        config.environment = {
          :scheme => 'http',
          :host => '127.0.0.1',
          :port => '9002',
          :api_key => 'e5528cb7ee0c5f6cb67af63c8f8111dce91a23e6'
        }
      end
    end

    context 'when accessed with a POST request' do
      context 'when the host is unavailable' do
        before do
          Bubbles.configure do |config|
            config.endpoints = [
              {
                :method => :post,
                :location => :students,
                :authenticated => true,
                :name => 'create_student',
                :return_type => :body_as_object
              }
            ]

            config.environment = {
              :scheme => 'https',
              :host => '127.0.0.1',
              :port => '1234',
              :api_key => 'blah'
            }
          end
        end

        it 'should fail gracefully' do
          # NOTE: We don't want to use a cassette for this next test.
          VCR.eject_cassette do
            data = {
              :name => 'Scott Klein',
              :address => '871 Anywhere St. #109',
              :city => 'Minneapolis',
              :state => 'MN',
              :zip => '55412',
              :phone => '(612) 761-8172',
              :email => 'scotty.kleiny@gmail.com',
              :preferredContact => 'text',
              :emergencyContactName => 'Nancy Klein',
              :emergencyContactPhone => '(701) 762-5442',
              :rank => 'white',
              :joinDate => Date.today,
              :lastAdvancementDate => Date.today,
              :waiverSigned => true
            }

            resources = Bubbles::Resources.new
            environment = resources.environment
            student = environment.create_student 'someauthtoken', data

            expect(student).to_not be_nil
            expect(student.error).to eq('Unable to connect to host 127.0.0.1:1234')
          end
        end
      end

      context 'when one of the endpoints has a slash in its path' do
        before do
          Bubbles.configure do |config|
            config.endpoints = [
              {
                :method => :post,
                :location => 'password/forgot',
                :name => :forgot_password,
                :authenticated => false,
                :api_key_required => true,
                :return_type => :body_as_object
              }
            ]
          end
        end

        it 'should successfully send a request to the server at the correct location' do
          VCR.use_cassette('post_unauthenticated_slash_in_path') do
            resources = Bubbles::Resources.new
            environment = resources.environment

            data = { :email => 'eat@example.com' }
            response = environment.forgot_password data

            expect(response).to_not be_nil
            expect(response.success).to be_truthy
          end
        end
      end

      context 'when the endpoint has encoded authorization' do
        before do
          Bubbles.configure do |config|
            config.endpoints = [
              {
                :method => :post,
                :location => :login,
                :authenticated => false,
                :api_key_required => true,
                :encode_authorization => [:username, :password],
                :return_type => :body_as_object
              }
            ]
          end
        end

        it 'should retrieve an authorization token' do
          VCR.use_cassette('login') do
            resources = Bubbles::Resources.new
            environment = resources.environment

            data = { :username => 'scottj', :password => '123qwe456' }
            login_object = environment.login data

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
                :method => :post,
                :location => :students,
                :authenticated => true,
                :name => 'create_student',
                :return_type => :body_as_object
              },
              {
                :method => :post,
                :location => :login,
                :authenticated => false,
                :api_key_required => true,
                :encode_authorization => [:username, :password],
                :return_type => :body_as_object
              }
            ]
          end
        end

        context 'with a valid authorization token' do
          before do
            @resources = Bubbles::Resources.new
            @environment = @resources.environment

            VCR.use_cassette('login') do
              data = { :username => 'scottj', :password => '123qwe456' }
              login_object = @environment.login data

              @auth_token = login_object.auth_token
            end
          end

          it 'should correctly add a record using a POST request' do
            VCR.use_cassette('post_student_authenticated') do
              data = {
                :name => 'Scott Klein',
                :address => '871 Anywhere St. #109',
                :city => 'Minneapolis',
                :state => 'MN',
                :zip => '55412',
                :phone => '(612) 761-8172',
                :email => 'scotty.kleiny@gmail.com',
                :preferredContact => 'text',
                :emergencyContactName => 'Nancy Klein',
                :emergencyContactPhone => '(701) 762-5442',
                :rank => 'white',
                :joinDate => Date.today,
                :lastAdvancementDate => Date.today,
                :waiverSigned => true
              }

              student = @environment.create_student @auth_token, data
              expect(student.name).to eq('Scott Klein')
              expect(student.address).to eq('871 Anywhere St. #109')
              expect(student.waiverSigned).to be_truthy
            end
          end
        end
      end
    end

    context 'when accessed with a GET request' do
      context 'when using a return type of body_as_object' do
        context 'for an endpoint that requires no authentication' do
          before do
            Bubbles.configure do |config|
              config.endpoints = [
                {
                  :method => :get,
                  :location => :version,
                  :authenticated => false,
                  :api_key_required => false,
                  :return_type => :body_as_object
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

        context 'that requires an authorization token' do
          before do
            Bubbles.configure do |config|
              config.endpoints = [
                {
                  :method => :get,
                  :location => :students,
                  :authenticated => true,
                  :api_key_required => false,
                  :name => :list_students,
                  :return_type => :body_as_object
                },
                {
                  :method => :get,
                  :location => 'students/{id}',
                  :authenticated => true,
                  :name => :get_student,
                  :return_type => :body_as_object
                },
                {
                  :method => :post,
                  :location => :login,
                  :authenticated => false,
                  :api_key_required => true,
                  :encode_authorization => [:username, :password],
                  :return_type => :body_as_object
                }
              ]
            end
          end

          context 'with a valid authorization token' do
            before do
              @resources = Bubbles::Resources.new
              @environment = @resources.environment

              VCR.use_cassette('login') do
                data = { :username => 'scottj', :password => '123qwe456' }
                login_object = @environment.login data

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

                student = @environment.get_student(@auth_token, {:id => 4})
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
                  :method => :get,
                  :location => :version,
                  :authenticated => false,
                  :api_key_required => false,
                  :return_type => :body_as_string
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
                  :method => :get,
                  :location => :students,
                  :authenticated => true,
                  :api_key_required => false,
                  :name => :list_students,
                  :return_type => :body_as_string
                },
                {
                  :method => :get,
                  :location => 'students/{id}',
                  :authenticated => true,
                  :name => :get_student,
                  :return_type => :body_as_string
                },
                {
                  :method => :post,
                  :location => :login,
                  :authenticated => false,
                  :api_key_required => true,
                  :encode_authorization => [:username, :password],
                  :return_type => :body_as_object
                }
              ]
            end
          end

          context 'with a valid authorization token' do
            before do
              @resources = Bubbles::Resources.new
              @environment = @resources.environment

              VCR.use_cassette('login') do
                data = { :username => 'scottj', :password => '123qwe456' }
                login_object = @environment.login data

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

                response = @environment.get_student(@auth_token, {:id => 4})
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
                  :method => :get,
                  :location => :version,
                  :authenticated => false,
                  :api_key_required => false,
                  :return_type => :full_response
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
                  :method => :get,
                  :location => :students,
                  :authenticated => true,
                  :api_key_required => false,
                  :name => :list_students,
                  :return_type => :full_response
                },
                {
                  :method => :get,
                  :location => 'students/{id}',
                  :authenticated => true,
                  :name => :get_student,
                  :return_type => :full_response
                },
                {
                  :method => :post,
                  :location => :login,
                  :authenticated => false,
                  :api_key_required => true,
                  :encode_authorization => [:username, :password],
                  :return_type => :body_as_object
                }
              ]
            end
          end

          context 'with a valid authorization token' do
            before do
              @resources = Bubbles::Resources.new
              @environment = @resources.environment

              VCR.use_cassette('login') do
                data = { :username => 'scottj', :password => '123qwe456' }
                login_object = @environment.login data

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

                response = @environment.get_student(@auth_token, {:id => 4})
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
      context 'when using a return type of body_as_object' do
        context 'for an endpoint that requires authorization' do
          before do
            Bubbles.configure do |config|
              config.endpoints = [
                {
                  :method => :delete,
                  :location => 'students/{id}',
                  :authenticated => true,
                  :name => 'delete_student',
                  :return_type => :body_as_object
                }
              ]
            end
          end

          context 'with a valid authorization token' do
            before do
              @resources = Bubbles::Resources.new
              @environment = @resources.environment

              VCR.use_cassette('login') do
                data = { :username => 'scottj', :password => '123qwe456' }
                login_object = @environment.login data

                @auth_token = login_object.auth_token
              end
            end

            it 'should be able to successfully delete a record' do
              VCR.use_cassette('delete_student_by_id') do
                response = @environment.delete_student @auth_token, {:id => 2}

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
          before do
            Bubbles.configure do |config|
              config.endpoints = [
                {
                  :method => :patch,
                  :location => 'students/{id}',
                  :authenticated => true,
                  :name => 'update_student',
                  :return_type => :body_as_object
                },
                {
                  :method => :post,
                  :location => :login,
                  :authenticated => false,
                  :api_key_required => true,
                  :encode_authorization => [:username, :password],
                  :return_type => :body_as_object
                }
              ]
            end
          end

          context 'with a valid authorization token' do
            before do
              @resources = Bubbles::Resources.new
              @environment = @resources.environment

              VCR.use_cassette('login') do
                data = { :username => 'scottj', :password => '123qwe456' }
                login_object = @environment.login data

                @auth_token = login_object.auth_token
              end
            end

            it 'should update part of a record' do
              VCR.use_cassette('patch_update_student') do
                response = @environment.update_student @auth_token, {:id => 4}, {:student => {:email => 'kleinhammer@gmail.com' } }

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
                  :method => :patch,
                  :location => 'password/change',
                  :authenticated => false,
                  :name => 'change_forgotten_password',
                  :return_type => :body_as_object
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

            it 'should allow the successful execution of the request' do
              VCR.use_cassette('patch_change_password_unauthenticated') do
                data = {
                  :one_time_login_hash => @hash,
                  :new_password => @new_password,
                  :password_confirmation => @new_password
                }

                response = @environment.change_forgotten_password data

                expect(response).to_not be_nil
                expect(response.success).to be_truthy
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
                    :method => :patch,
                    :location => 'password/change',
                    :authenticated => false,
                    :name => 'change_forgotten_password',
                    :return_type => :full_response
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
                  :one_time_login_hash => @hash,
                  :new_password => @new_password,
                  :password_confirmation => @new_password
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
          before do
            Bubbles.configure do |config|
              config.endpoints = [
              {
                :method => :put,
                :location => 'students/{id}',
                :authenticated => true,
                :name => 'update_student',
                :return_type => :body_as_object
              },
              {
                  :method => :post,
                  :location => :login,
                  :authenticated => false,
                  :api_key_required => true,
                  :encode_authorization => [:username, :password],
                  :return_type => :body_as_object
                }
              ]
            end
          end

          context 'with a valid authorization token' do
            before do
              @resources = Bubbles::Resources.new
              @environment = @resources.environment

              VCR.use_cassette('login') do
                data = { :username => 'scottj', :password => '123qwe456' }
                login_object = @environment.login data

                @auth_token = login_object.auth_token
              end
            end

            it 'should update the entire record' do
              VCR.use_cassette('put_update_student') do
                data = {
                  :student => {
                    :email => 'michael.moribs@mikesmail-moribss.com',
                    :name => 'Michael Moribsu',
                    :address => '123 Anywhere St.',
                    :city => 'Onetown',
                    :state => 'MN',
                    :zip => '55081',
                    :phone => '(555) 123-9045',
                    :emergencyContactName => 'Katie Moribsu',
                    :emergencyContactPhone => '(765) 192-8123'
                  }
                }

                response = @environment.update_student @auth_token, {:id => 4}, data

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
                  :method => :put,
                  :location => 'password/change',
                  :authenticated => false,
                  :name => 'change_forgotten_password_put',
                  :return_type => :body_as_object
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

            it 'should allow the successful execution of the request' do
              VCR.use_cassette('put_change_password_unauthenticated') do
                data = {
                  :one_time_login_hash => @hash,
                  :new_password => @new_password,
                  :password_confirmation => @new_password
                }

                response = @environment.change_forgotten_password_put data

                expect(response).to_not be_nil
                expect(response.success).to be_truthy
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
                    :method => :put,
                    :location => 'password/change',
                    :authenticated => false,
                    :name => 'change_forgotten_password_put',
                    :return_type => :full_response
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
                  :one_time_login_hash => @hash,
                  :new_password => @new_password,
                  :password_confirmation => @new_password
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
            config.environment = {
              :scheme => 'http',
              :host => '127.0.0.1',
              :port => '1234'
            }
          end
        end

        context 'after redefining the environment to use Google' do
          # NOTE - this is required so we know that we can redefine environments without issues
          before do
            Bubbles.configure do |config|
              config.environment = {
                :scheme => 'http',
                :host => 'www.google.com',
                :port => '80'
              }

              config.endpoints = [
                {
                  :method => :head,
                  :location => '/',
                  :authenticated => false,
                  :name => 'head_google',
                  :return_type => :full_response
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

      context 'for an endpoint that requires authorization' do
        before do
          Bubbles.configure do |config|
            config.endpoints = [
              {
                :method => :head,
                :location => '/students',
                :authenticated => true,
                :name => 'head_students'
              },
              {
                :method => :post,
                :location => :login,
                :authenticated => false,
                :api_key_required => true,
                :encode_authorization => [:username, :password],
                :return_type => :body_as_object
              }
            ]
          end
        end

        context 'with a valid authorization token' do
          before do
            @resources = Bubbles::Resources.new
            @environment = @resources.environment

            VCR.use_cassette('login') do
              data = { :username => 'scottj', :password => '123qwe456' }
              login_object = @environment.login data

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