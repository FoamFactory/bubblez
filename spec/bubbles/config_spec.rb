require 'bubbles'
require 'spec_helper'

describe 'Bubbles.config' do
  context 'with a defined local RESTEnvironment' do
    Bubbles.configure do |config|
      config.local_environment = {
        :scheme => :https,
        :host => '127.0.0.1',
        :port => '1234'
      }
    end

    context 'when setting up a GET request' do
      context 'that is not authenticated' do
        context 'that does not require an API key' do
          context 'that expects JSON as a response' do
            context 'that has a name of version' do
              before do
                Bubbles.configure do |config|
                  config.endpoints = [
                    {
                      :method => :get,
                      :location => :version,
                      :authenticated => false,
                      :api_key_required => false,
                      :expect_json => true
                    }
                  ]
                end
              end

              it 'should have a local environment defined' do
                resources = Bubbles::Resources.new

                expect(resources.local_environment.scheme).to eq(:https)
                expect(resources.local_environment.host).to eq('127.0.0.1')
                expect(resources.local_environment.port).to eq('1234')
              end

              it 'should add a method to the RestEnvironment class called version that takes no parameters' do
                resources = Bubbles::Resources.new

                expect(Bubbles::RestEnvironment.instance_methods(false).include?(:version)).to eq(true)
                expect(resources.local_environment.method(:version).arity()).to eq(0)
              end
            end
          end
        end
      end
    end

    context 'when setting up a POST request' do
      context 'that is not authenticated' do
        context 'that does not require an API key' do
          it 'should raise an exception' do
            expect do
              Bubbles.configure do |config|
                config.endpoints = [
                  {
                    :method => :post,
                    :location => :student,
                    :authenticated => false,
                    :api_key_required => false,
                    :expect_json => true
                  }
                ]
              end
            end.to raise_error(RuntimeError, 'Unauthenticated POST requests without an API key are not allowed')
          end
        end
      end
    end

    context 'when setting up a DELETE request' do
      context 'that is not authenticated' do
        it 'should raise an exception' do
          expect do
            Bubbles.configure do |config|
              config.endpoints = [
                {
                  :method => :delete,
                  :location => :student,
                  :authenticated => false,
                  :api_key_required => false,
                  :expect_json => true
                }
              ]
            end.to raise_error(RuntimeError, 'Unauthenticated DELETE requests are not allowed')
          end
        end
      end

      context 'that is authenticated' do
        context 'that does not require URI parameters' do
          it 'should raise an exception' do
            expect do
              Bubbles.configure do |config|
                config.endpoints = [
                  {
                    :method => :delete,
                    :location => :student,
                    :authenticated => true,
                    :api_key_required => false,
                    :expect_json => true
                  }
                ]
              end.to raise_error(RuntimeError, 'DELETE requests without URI parameters are not allowed')
            end
          end
        end
      end
    end

    context 'when setting up a PUT request' do
      context 'that uses the local environment' do
        context 'that is authenticated' do
          context 'that requires URI parameters' do
            before do
              Bubbles.configure do |config|
                config.endpoints = [
                  {
                    :method => :put,
                    :location => 'student/{id}',
                    :authenticated => true,
                    :api_key_required => false,
                    :expect_json => true,
                    :name => :update_student
                  }
                ]

                config.local_environment = {
                  :scheme => 'http',
                  :host => '127.0.0.1',
                  :port => '8888'
                }
              end
            end

            it 'should create a method on RestEnvironment taking two parameters' do
              resources = Bubbles::Resources.new

              expect(Bubbles::RestEnvironment.instance_methods(false).include?(:update_student)).to eq(true)
              expect(resources.local_environment.method(:update_student).arity()).to eq(3)
            end
          end

          context 'that does not require URI parameters' do
            before do
              Bubbles.configure do |config|
                config.endpoints = [
                  {
                    :method => :put,
                    :location => :students,
                    :authenticated => true,
                    :api_key_required => false,
                    :expect_json => true,
                    :name => :update_student
                  }
                ]

                config.local_environment = {
                  :scheme => 'http',
                  :host => '127.0.0.1',
                  :port => '8888'
                }
              end
            end

            it 'should create a method on RestEnvironment taking two parameters' do
              resources = Bubbles::Resources.new

              expect(Bubbles::RestEnvironment.instance_methods(false).include?(:update_student)).to eq(true)
              expect(resources.local_environment.method(:update_student).arity()).to eq(2)
            end
          end
        end
      end
    end

    context 'when setting up a PATCH request' do
      context 'that uses the local environment' do
        context 'that is authenticated' do
          context 'that requires URI parameters' do
            before do
              Bubbles.configure do |config|
                config.endpoints = [
                  {
                    :method => :patch,
                    :location => 'student/{id}',
                    :authenticated => true,
                    :api_key_required => false,
                    :expect_json => true,
                    :name => :update_student
                  }
                ]

                config.local_environment = {
                  :scheme => 'http',
                  :host => '127.0.0.1',
                  :port => '8888'
                }
              end
            end

            it 'should create a method on RestEnvironment taking two parameters' do
              resources = Bubbles::Resources.new

              expect(Bubbles::RestEnvironment.instance_methods(false).include?(:update_student)).to eq(true)
              expect(resources.local_environment.method(:update_student).arity()).to eq(3)
            end
          end

          context 'that does not require URI parameters' do
            before do
              Bubbles.configure do |config|
                config.endpoints = [
                  {
                    :method => :patch,
                    :location => :students,
                    :authenticated => true,
                    :api_key_required => false,
                    :expect_json => true,
                    :name => :update_student
                  }
                ]

                config.local_environment = {
                  :scheme => 'http',
                  :host => '127.0.0.1',
                  :port => '8888'
                }
              end
            end

            it 'should create a method on RestEnvironment taking two parameters' do
              resources = Bubbles::Resources.new

              expect(Bubbles::RestEnvironment.instance_methods(false).include?(:update_student)).to eq(true)
              expect(resources.local_environment.method(:update_student).arity()).to eq(2)
            end
          end
        end
      end
    end

    context 'when setting up a HEAD request' do
      context 'that uses the local environment' do
        before do
          Bubbles.configure do |config|
            config.local_environment = {
              :scheme => 'http',
              :host => '127.0.0.1',
              :port => '8888'
            }
          end
        end
        context 'that is authenticated' do
          context 'that does not require an API key' do
            before do
              Bubbles.configure do |config|
                config.endpoints = [
                  {
                    :method => :head,
                    :location => :students,
                    :authenticated => true,
                    :api_key_required => false,
                    :name => :list_students_head
                  }
                ]
              end
            end

            it 'should create a method on RestEnvironment that takes 1 argument' do
              resources = Bubbles::Resources.new

              expect(Bubbles::RestEnvironment.instance_methods(false).include?(:list_students_head)).to eq(true)
              expect(resources.local_environment.method(:list_students_head).arity()).to eq(1)
            end
          end
        end

        context 'that is not authenticated' do
          context 'that does not require an API key' do
            before do
              Bubbles.configure do |config|
                config.endpoints = [
                  {
                    :method => :head,
                    :location => :students,
                    :authenticated => false,
                    :api_key_required => false,
                    :name => :list_students_head
                  }
                ]
              end
            end

            it 'should create a method on RestEnvironment that takes 0 arguments' do
              resources = Bubbles::Resources.new

              expect(Bubbles::RestEnvironment.instance_methods(false).include?(:list_students_head)).to eq(true)
              expect(resources.local_environment.method(:list_students_head).arity()).to eq(0)
            end
          end

          context 'that does require an API key' do
            before do
              Bubbles.configure do |config|
                config.endpoints = [
                  {
                    :method => :head,
                    :location => :students,
                    :authenticated => false,
                    :api_key_required => true,
                    :name => :list_students_head
                  }
                ]
              end
            end
            it 'should create a method on RestEnvironment that takes 1 argument' do
              resources = Bubbles::Resources.new

              expect(Bubbles::RestEnvironment.instance_methods(false).include?(:list_students_head)).to eq(true)
              expect(resources.local_environment.method(:list_students_head).arity()).to eq(1)
            end
          end
        end
      end
    end
  end
end