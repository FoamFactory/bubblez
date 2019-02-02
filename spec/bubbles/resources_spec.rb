require 'bubbles'
require 'spec_helper'

describe Bubbles::Resources do
  describe 'Endpoint' do
    context 'accessed with a GET request' do
      before do
        Bubbles.configure do |config|
          config.endpoints = [
            {
              :method => :get,
              :location => :version,
              :authenticated => false,
              :api_key_required => false,
              :expect_json => true
            },
            {
              :method => :get,
              :location => :students,
              :authenticated => true,
              :api_key_required => false,
              :name => :list_students,
              :expect_json => true
            },
            {
              :method => :get,
              :location => 'students/{id}',
              :authenticated => true,
              :name => :get_student,
              :expect_json => true
            }
          ]

          config.local_environment = {
            :scheme => 'http',
            :host => '127.0.0.1',
            :port => '1234'
          }

          config.staging_environment = {
            :scheme => 'http',
            :host => '127.0.0.1',
            :port => '1234'
          }
        end
      end

      context 'that require no authentication' do
        context 'when using the local environment' do
          it 'should be able to retrieve a version from the API' do
            VCR.use_cassette('get_version_unauthenticated') do
              resources = Bubbles::Resources.new
              local_env = resources.local_environment

              response = local_env.version
              expect(response).to_not be_nil
              expect(response.name).to eq('Sinking Moon API')
              expect(response.versionName).to eq('2.0.0')

              deploy_date = Date.parse(response.deployDate)
              expect(deploy_date.year).to eq(2018)
              expect(deploy_date.month).to eq(1)
              expect(deploy_date.day).to eq(2)
            end
          end
        end
      end

      context 'that require an authorization token' do
        context 'when using the local environment' do
          it 'should be able to list students' do
            VCR.use_cassette('get_students_authenticated') do
              auth_token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjcmVhdGlvbl9kYXRlIjoiMjAxNy0xMC0xNVQxMToyNjozMS0wNTowMCIsImV4cGlyYXRpb25fZGF0ZSI6IjIwMTctMTEtMTRUMTE6MjY6MzEtMDU6MDAiLCJ1c2VyX2lkIjoxfQ.dyCWwE4wk7aTfjnGncsqp_jq5QyICKYQPkBh5nLQwFU'
              resources = Bubbles::Resources.new
              local_env = resources.local_environment

              response = local_env.list_students(auth_token)
              expect(response).to_not be_nil

              students = response.students
              expect(students.length).to eq(1)
              expect(students[0].name).to eq('Joe Blow')
              expect(students[0].zip).to eq('90263')
            end
          end

          it 'should be able to retrieve a single student by id' do
            VCR.use_cassette('get_student_by_id') do
              auth_token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjcmVhdGlvbl9kYXRlIjoiMjAxNy0xMC0xNVQxMToyNjozMS0wNTowMCIsImV4cGlyYXRpb25fZGF0ZSI6IjIwMTctMTEtMTRUMTE6MjY6MzEtMDU6MDAiLCJ1c2VyX2lkIjoxfQ.dyCWwE4wk7aTfjnGncsqp_jq5QyICKYQPkBh5nLQwFU'

              resources = Bubbles::Resources.new
              local_env = resources.local_environment

              student = local_env.get_student(auth_token, {:id => 2})
              expect(student).to_not be_nil

              expect(student.id).to eq(2)
            end
          end
        end
      end
    end

    context 'accessed with a POST request' do
      before do
        Bubbles.configure do |config|
          config.endpoints = [
            {
              :method => :post,
              :location => :login,
              :authenticated => false,
              :api_key_required => true,
              :expect_json => true,
              :encode_authorization => [:username, :password]
            },
            {
              :method => :post,
              :location => :students,
              :authenticated => true,
              :expect_json => true,
              :name => 'create_student'
            }
          ]

          config.local_environment = {
            :scheme => 'http',
            :host => '127.0.0.1',
            :port => '1234',
            :api_key => 'e4150c01953cd24ac18084b1cb0ddcb3766de03a'
          }
        end
      end

      context 'when using the local environment' do
        context 'with a valid authorization token' do
          before do
            @resources = Bubbles::Resources.new
            @local_env = @resources.local_environment

            VCR.use_cassette('login') do
              data = { :username => 'scottj', :password => '123qwe456' }
              login_object = @local_env.login data

              @auth_token = login_object.auth_token
            end
          end

          context 'when the host is not available' do
            it 'should respond with an error message' do
              # NOTE: The following cassette file should NOT exist.
              VCR.use_cassette('create_student_unable_to_connect') do
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

                student = @local_env.create_student @auth_token, data

                expect(student).to_not be_nil
                expect(student.error).to eq('Unable to connect to host 127.0.0.1:1234')
              end
            end
          end

          context 'when the host response is available' do
            it 'should respond with the correct API response' do
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

                student = @local_env.create_student @auth_token, data
                expect(student.name).to eq('Scott Klein')
                expect(student.address).to eq('871 Anywhere St. #109')
                expect(student.waiverSigned).to be_truthy
              end
            end
          end
        end

        context 'with a valid API key' do
          context 'with a valid username and password' do
            it 'should successfully login' do
              VCR.use_cassette('login') do
                resources = Bubbles::Resources.new
                local_env = resources.local_environment


                data = { :username => 'scottj', :password => '123qwe456' }
                login_object = local_env.login data

                expect(login_object.id).to eq(1)
                expect(login_object.name).to eq('Scott Johnson')
                expect(login_object.username).to eq('scottj')
                expect(login_object.email).to eq('scottj@sinkingmoon.com')
                expect(login_object.auth_token).to_not be_nil
              end
            end
          end
        end
      end
    end

    context 'accessed with a DELETE request' do
      before do
        Bubbles.configure do |config|
          config.endpoints = [
            {
              :method => :delete,
              :location => 'students/{id}',
              :authenticated => true,
              :expect_json => true,
              :name => 'delete_student'
            }
          ]

          config.local_environment = {
            :scheme => 'http',
            :host => '127.0.0.1',
            :port => '1234',
            :api_key => 'e4150c01953cd24ac18084b1cb0ddcb3766de03a'
          }
        end
      end

      context 'when using the local environment' do
        before do
          @resources = Bubbles::Resources.new
          @local_env = @resources.local_environment
        end

        context 'with a valid authorization token' do
          before do
            @auth_token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjcmVhdGlvbl9kYXRlIjoiMjAxNy0xMC0xNVQxMToyNjozMS0wNTowMCIsImV4cGlyYXRpb25fZGF0ZSI6IjIwMTctMTEtMTRUMTE6MjY6MzEtMDU6MDAiLCJ1c2VyX2lkIjoxfQ.dyCWwE4wk7aTfjnGncsqp_jq5QyICKYQPkBh5nLQwFU'
          end

          it 'should successfully delete a student' do
            VCR.use_cassette('delete_student_by_id') do
              response = @local_env.delete_student @auth_token, {:id => 2}

              expect(response.success).to eq(true)
            end
          end
        end
      end
    end

    context 'accessed with a PATCH request' do
      before do
        Bubbles.configure do |config|
          config.endpoints = [
            {
              :method => :patch,
              :location => 'students/{id}',
              :authenticated => true,
              :expect_json => true,
              :name => 'update_student'
            }
          ]

          config.local_environment = {
            :scheme => 'http',
            :host => '127.0.0.1',
            :port => '1234'
          }
        end
      end

      context 'when using the local environment' do

        before do
          @resources = Bubbles::Resources.new
          @local_env = @resources.local_environment
        end

        context 'with a valid authorization token' do

          before do
            @auth_token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjcmVhdGlvbl9kYXRlIjoiMjAxNy0xMC0xNVQxMToyNjozMS0wNTowMCIsImV4cGlyYXRpb25fZGF0ZSI6IjIwMTctMTEtMTRUMTE6MjY6MzEtMDU6MDAiLCJ1c2VyX2lkIjoxfQ.dyCWwE4wk7aTfjnGncsqp_jq5QyICKYQPkBh5nLQwFU'
          end

          it 'should successfully update the student record' do
            VCR.use_cassette('patch_update_student') do
              response = @local_env.update_student @auth_token, {:id => 3}, {:student => { :email => 'mike_morib@gmail.com' } }

              expect(response.id).to eq(3)
              expect(response.name).to eq('Michael Moribsu')
              expect(response.address).to eq('123 Anywhere St.')
              expect(response.city).to eq('Onetown')
              expect(response.state).to eq('MN')
              expect(response.zip).to eq('55081')
              expect(response.phone).to eq('5551239045')
              expect(response.emergencyContactPhone).to eq('76519281234')
              expect(response.emergencyContactName).to eq('Katie Moribsu')
            end
          end
        end
      end
    end

    context 'accessed with a PUT request' do
      before do
        Bubbles.configure do |config|
          config.endpoints = [
            {
              :method => :put,
              :location => 'students/{id}',
              :authenticated => true,
              :expect_json => true,
              :name => 'update_student'
            }
          ]

          config.local_environment = {
            :scheme => 'http',
            :host => '127.0.0.1',
            :port => '1234'
          }
        end
      end

      context 'when using the local environment' do

        before do
          @resources = Bubbles::Resources.new
          @local_env = @resources.local_environment
        end

        context 'with a valid authorization token' do

          before do
            @auth_token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjcmVhdGlvbl9kYXRlIjoiMjAxNy0xMC0xNVQxMToyNjozMS0wNTowMCIsImV4cGlyYXRpb25fZGF0ZSI6IjIwMTctMTEtMTRUMTE6MjY6MzEtMDU6MDAiLCJ1c2VyX2lkIjoxfQ.dyCWwE4wk7aTfjnGncsqp_jq5QyICKYQPkBh5nLQwFU'
          end

          it 'should successfully update the student record' do
            VCR.use_cassette('put_update_student') do
              response = @local_env.update_student @auth_token, {:id => 3}, {:student => { :email => 'mike_morib@gmail.com' } }

              expect(response.id).to eq(3)
              expect(response.name).to eq('Michael Moribsu')
              expect(response.address).to eq('123 Anywhere St.')
              expect(response.city).to eq('Onetown')
              expect(response.state).to eq('MN')
              expect(response.zip).to eq('55081')
              expect(response.phone).to eq('5551239045')
              expect(response.emergencyContactPhone).to eq('76519281234')
              expect(response.emergencyContactName).to eq('Katie Moribsu')
            end
          end
        end
      end
    end
  end
end