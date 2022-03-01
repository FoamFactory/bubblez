require 'spec_helper'
require 'bubblez'

describe 'Bubblez Configuration' do
  context '#endpoints' do
    context 'when we specify an environment with two endpoints' do
      before do
        Bubblez.configure do |config|
          config.environments = [
            {
              scheme: 'http',
              host: '127.0.0.1',
              port: '9002'
            }
          ]

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
            },
            {
              method: :post,
              location: :students,
              authenticated: true,
              name: 'create_student',
              return_type: :body_as_object
            }
          ]
        end
      end

      it 'should return that two endpoints were defined' do
        config = Bubblez.configuration
        expect(config).to_not be_nil
        expect(config.endpoints.length).to eq(2)
      end
    end
  end
end