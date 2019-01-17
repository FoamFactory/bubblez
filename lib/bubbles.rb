require "bubbles/version"
require 'bubbles/config'
require 'base64'
require 'bubbles/RestClientResources'
require 'bubbles/RestEnvironment'
require 'bubbles/version'
# require 'exceptions'
require 'rest-client'
require 'json'

module Bubbles
  class Resources < RestClientResources
    def initialize
    # def initialize(env, api_key)
      # @environment = get_environment env
      # @api_key = api_key
      # @auth_token = nil
      @packageName = Bubbles::VersionInformation.package_name
      @versionName = Bubbles::VersionInformation.version_name
      @versionCode = Bubbles::VersionInformation.version_code
    end

    def get_version_info
      {
        :name => @packageName,
        :versionName => @versionName,
        :versionCode => @versionCode
      }
    end

    # def local_environment
    #   LOCAL_ENVIRONMENT
    # end

    ###### BEGIN API METHODS ######

    def version
      execute_get_unauthenticated(@environment.version_endpoint)
    end

    # def login(username, password)
    #   encoded_auth = Base64.strict_encode64(username + ':' + password)
    #
    #   response = execute_post_unauthenticated(@environment.login_endpoint, nil,
    #                                           {
    #                                             :authorization => 'Basic ' + encoded_auth
    #                                           })
    #
    #   @auth_token = JSON.parse(response, object_class: OpenStruct).auth_token
    #
    #   response
    # end
  end
end

# module SinkingMoonRestClient
#   class Resources
#     attr_accessor :environment, :api_key
#
#     def check_for_expired_token
#       begin
#         yield
#       rescue RestClient::Forbidden => e
#         response_json = JSON.parse(e.response.to_s, object_class: OpenStruct)
#         if response_json.error == 'Auth token is expired; You will need to login again'
#           raise SinkingMoonRestClient::AuthTokenExpiredException.new
#         end
#
#         raise e
#       end
#     end
#
#
#     ###### BEGIN API METHODS ######
#
#     def version
#       execute_get_unauthenticated(@environment.version_endpoint)
#     end
#
#     def login(username, password)
#       encoded_auth = Base64.strict_encode64(username + ':' + password)
#
#       response = execute_post_unauthenticated(@environment.login_endpoint, nil,
#                                               {
#                                                 :authorization => 'Basic ' + encoded_auth
#                                               })
#
#       @auth_token = JSON.parse(response, object_class: OpenStruct).auth_token
#
#       response
#     end
#
#     def list_students(auth_token=nil)
#       check_for_expired_token do
#         response = execute_get_authenticated(@environment.students_endpoint, auth_token)
#         return response
#       end
#     end
#
#     def get_student(id, auth_token=nil)
#       check_for_expired_token do
#         url_components = [@environment.students_endpoint, id]
#         url = url_components.join('/')
#         execute_get_authenticated(url, auth_token)
#       end
#     end
#
#     def forgot_password(email=nil)
#       unless email
#         raise 'Method requires a valid email address to be passed in'
#       end
#
#       response = execute_post_unauthenticated(@environment.forgot_password_endpoint,
#                                               {
#                                                 :email => email
#                                               })
#       response
#     end
#
#     def change_password(login_hash, password, password_confirm)
#       unless login_hash and password and password_confirm
#         raise 'Method requires a valid login hash, password, and password confirmation to be passed in'
#       end
#
#       unless password == password_confirm
#         raise 'Password and password confirmation do not match'
#       end
#
#       response = execute_put_unauthenticated(@environment.change_password_endpoint,
#                                              {
#                                                :one_time_login_hash => login_hash,
#                                                :new_password => password,
#                                                :password_confirmation => password_confirm
#                                              })
#       response
#     end
#
#     def create_student(student, auth_token = nil)
#       check_for_expired_token do
#         token = get_auth_token(auth_token)
#
#         unless student
#           raise 'Unable to create student with empty body'
#         end
#
#         response = execute_post_authenticated(@environment.students_endpoint, token,
#                                               {
#                                                 :name => student[:name],
#                                                 :address => student[:address],
#                                                 :city => student[:city],
#                                                 :state => student[:state],
#                                                 :zip => student[:zip],
#                                                 :phone => student[:phone],
#                                                 :email => student[:email],
#                                                 :preferredContact => student[:preferredContact].downcase,
#                                                 :emergencyContactName => student[:emergencyContactName],
#                                                 :emergencyContactPhone => student[:emergencyContactPhone],
#                                                 :rank => student[:rank].downcase,
#                                                 :joinDate => student[:joinDate],
#                                                 :lastAdvancementDate => student[:lastAdvancementDate],
#                                                 :waiverSigned => student[:waiverSigned]
#                                               })
#
#         response
#       end
#     end
#
#     def delete_student(id, auth_token = nil)
#       check_for_expired_token do
#         token = get_auth_token(auth_token)
#
#         unless id
#           raise 'Unable to delete a student without an id'
#         end
#
#         url_components = [@environment.students_endpoint, id]
#         execute_delete_authenticated(url_components.join('/'), token)
#       end
#     end
#
#     def update_student(id, new_record, auth_token = nil)
#       check_for_expired_token do
#         token = get_auth_token(auth_token)
#
#         unless id
#           raise 'Unable to update a student without the student id'
#         end
#
#         unless new_record
#           raise 'Unable to update a student record without the record body'
#         end
#
#         url_components = [@environment.students_endpoint, id]
#         execute_put_authenticated(url_components.join('/'), token, new_record)
#       end
#     end
#
#     ##
#     # :method: activate_student
#     #
#     # Activate a student by his/her student id. This method requires administrative privileges to call.
#     #
#     # :param: [Integer] id The identifier of the student to activate
#     # :param: [String] auth_token The authentication token to use to identify yourself as an admin to the server.
#     def activate_student(id, auth_token = nil)
#       check_for_expired_token do
#         token = get_auth_token(auth_token)
#
#         unless id
#           raise 'Unable to activate a student without an id'
#         end
#
#         url_components = [@environment.students_endpoint, 'activate', id]
#         execute_patch_authenticated(url_components.join('/'), token)
#       end
#     end
#
#     ##
#     # :method: deactivate_student
#     #
#     # Deactivate a student by his/her student id. This method requires administrative privileges to call.
#     #
#     # :param: [Integer] id The identifier of the student to deactivate
#     # :param: [String] auth_token The authentication token to use to identify yourself as an admin to the server.
#     def deactivate_student(id, auth_token = nil)
#       check_for_expired_token do
#         token = get_auth_token(auth_token)
#
#         unless id
#           raise 'Unable to deactivate a student without an id'
#         end
#
#         url_components = [@environment.students_endpoint, 'deactivate', id]
#         execute_patch_authenticated(url_components.join('/'), token)
#       end
#     end
#
#     def get_user(id, auth_token = nil)
#       check_for_expired_token do
#         token = get_auth_token(auth_token);
#         url_components = [@environment.users_endpoint, id]
#         url = url_components.join('/')
#         execute_get_authenticated(url, token)
#       end
#     end
#
#     def create_user(user, auth_token = nil)
#       check_for_expired_token do
#         token = get_auth_token(auth_token)
#
#         unless user
#           raise SinkingMoonRestClient::InvalidBodyException.new
#         end
#
#         response = execute_post_authenticated(@environment.users_endpoint, token,
#                                               {
#                                                 :name => user[:name],
#                                                 :email => user[:email],
#                                                 :username => user[:username],
#                                                 :role => user[:role]
#                                               })
#
#         response
#       end
#     end
#
#     def update_user(id, new_record, auth_token = nil)
#       check_for_expired_token do
#         token = get_auth_token(auth_token)
#
#         unless id
#           raise 'Unable to update a user record without the user id'
#         end
#
#         unless new_record
#           raise 'Unable to update a user record without the record body'
#         end
#
#         url_components = [@environment.users_endpoint, id]
#         execute_put_authenticated(url_components.join('/'), token, new_record)
#       end
#     end
#
#     def list_advancements(auth_token = nil)
#       check_for_expired_token do
#         token = get_auth_token(auth_token)
#         response = execute_get_authenticated(@environment.advancements_endpoint, token)
#         return response
#       end
#     end
#
#     def create_advancement (advancement, auth_token = nil)
#       check_for_expired_token do
#         token = get_auth_token(auth_token)
#
#         unless advancement
#           raise 'Unable to create advancement with empty body'
#         end
#
#         response = execute_post_authenticated(@environment.advancements_endpoint, token,
#                                               {
#                                                 :date => advancement[:date],
#                                                 :student_id => advancement[:student_id],
#                                                 :rank => advancement[:rank]
#                                               })
#
#         response
#       end
#     end
#
#     def delete_advancement(id, auth_token = nil)
#       check_for_expired_token do
#         token = get_auth_token(auth_token)
#
#         unless id
#           raise 'Unable to delete an advancement without an id'
#         end
#
#         url_components = [@environment.advancements_endpoint, id]
#         execute_delete_authenticated(url_components.join('/'), token)
#       end
#     end
#
#     def update_advancement(id, new_record, auth_token = nil)
#       check_for_expired_token do
#         token = get_auth_token(auth_token)
#
#         unless id
#           raise 'Unable to update an advancement record without the advancement id'
#         end
#
#         unless new_record
#           raise 'Unable to update an advancement record without the record body'
#         end
#
#         url_components = [@environment.advancements_endpoint, id]
#         execute_put_authenticated(url_components.join('/'), token, new_record)
#       end
#     end
#
#     def get_advancement(id, auth_token = nil)
#       check_for_expired_token do
#         token = get_auth_token(auth_token)
#
#         unless id
#           raise 'Unable to retrieve an advancement record without the advancement id'
#         end
#
#         url_components = [@environment.advancements_endpoint, id]
#         execute_get_authenticated(url_components.join('/'), token)
#       end
#     end
#
#     def list_tournament_registrations(auth_token = nil)
#       check_for_expired_token do
#         token = get_auth_token(auth_token)
#
#         url_components = [@environment.tournament_registrations_endpoint]
#         execute_get_authenticated(url_components.join('/'), token)
#       end
#     end
#
#     def delete_tournament_registration(id, auth_token = nil)
#       check_for_expired_token do
#         token = get_auth_token(auth_token)
#
#         unless id
#           raise 'Unable to delete a tournament registration without an id'
#         end
#
#         url_components = [@environment.tournament_registrations_endpoint, id]
#         execute_delete_authenticated(url_components.join('/'), token)
#       end
#     end
#
#     def create_tournament_registration(registration)
#       check_for_expired_token do
#
#         unless registration
#           raise 'Unable to create tournament registration with empty body'
#         end
#
#         begin
#           data =
#             {
#               :name => registration[:name],
#               :address => registration[:address],
#               :city => registration[:city],
#               :state => registration[:state],
#               :zip => registration[:zip],
#               :email => registration[:email],
#               :birthDate => registration[:birthDate],
#               :tShirtSize => registration[:tShirtSize],
#               :registrationType => registration[:registrationType],
#               :studentsExpected => registration[:studentsExpected],
#               :noPrivateLessons => registration[:noPrivateLessons],
#               :rank => registration[:rank],
#               :permissionToSpar => registration[:permissionToSpar],
#               :school => registration[:school],
#               :formsCompetitionParticipant => registration[:formsCompetitionParticipant],
#               :skillsCombineParticipant => registration[:skillsCombineParticipant],
#               :sparringParticipant => registration[:sparringParticipant],
#               :liabilityWaiverNeeded => registration[:liabilityWaiverNeeded],
#               :privateLessonDesired => registration[:privateLessonDesired],
#               :spectatorConfirmation => registration[:spectatorConfirmation],
#               :donationAmount => registration[:donationAmount],
#               :paymentToken => registration[:paymentToken]
#             }
#
#           response = execute_post_unauthenticated(@environment.tournament_registrations_endpoint, data)
#         rescue RestClient::Exception => e
#           responseObj = JSON.parse(e.response, object_class: OpenStruct)
#           raise InsufficientDataException.new(responseObj.error)
#         end
#
#         response
#       end
#     end
#
#     ###### End API Methods ######
#
#     def get_auth_token(auth_token = nil)
#       if @auth_token.nil? and auth_token.nil?
#         raise 'Method requires authentication. Use login() first or pass in an authorization token.'
#       end
#
#       token = auth_token
#       token = @auth_token if auth_token == nil
#
#       token
#     end
#
#     private
#
#     def execute_post_unauthenticated(endpoint, data, headers=nil)
#       additionalHeaders = {
#         'X-Api-Key' => @api_key,
#         :content_type => :json,
#         :accept => :json
#       }
#
#       unless headers.nil?
#         headers.each { |nextHeader|
#           additionalHeaders[nextHeader[0]] = nextHeader[1]
#         }
#       end
#
#       begin
#         if @environment.scheme == 'https'
#           response = RestClient::Resource.new(endpoint, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
#             .post(data.to_json, additionalHeaders)
#         else
#           response = RestClient.post endpoint, data.to_json, additionalHeaders
#         end
#       rescue Errno::ECONNREFUSED
#         return { :error => 'Unable to connect to host ' + @environment.host.to_s + ":" + @environment.port.to_s }.to_json
#       end
#
#       response
#     end
#
#     def execute_post_authenticated(endpoint, token, data)
#       if token.nil?
#         raise 'Cannot execute an authenticated POST request with no auth_token'
#       end
#
#       if data.nil?
#         raise 'Cannot execute POST command with an empty data set'
#       end
#
#       begin
#         if @environment.scheme == 'https'
#           response = RestClient::Resource.new(endpoint, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
#             .post(data.to_json,
#                   {
#                     :content_type => :json,
#                     :accept => :json,
#                     :authorization => 'Bearer ' + token
#                   })
#
#         else
#           response = RestClient.post(endpoint,
#                                      data.to_json,
#                                      {
#                                        :content_type => :json,
#                                        :accept => :json,
#                                        :authorization => 'Bearer ' + token
#                                      })
#         end
#       rescue Errno::ECONNREFUSED
#         return { :error => 'Unable to connect to host ' + @environment.host.to_s + ':' + @environment.port.to_s }.to_json
#       end
#
#       response
#     end
#
#
#     def execute_get_authenticated(endpoint, auth_token)
#       token = get_auth_token(auth_token)
#
#       begin
#         if @environment.scheme == 'https'
#           response = RestClient::Resource.new(endpoint, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
#             .get({
#                    :authorization => 'Bearer ' + token,
#                    :content_type => :json,
#                    :accept => :json
#                  })
#         else
#           response = RestClient.get(endpoint,
#                                     {
#                                       :authorization => 'Bearer ' + token,
#                                       :content_type => :json
#                                     })
#         end
#       rescue Errno::ECONNREFUSED
#         return {:error => 'Unable to connect to host ' + @environment.host.to_s + ':' + @environment.port.to_s}.to_json
#       end
#
#       response
#     end
#
#     def execute_put_unauthenticated(endpoint, data)
#       begin
#         if @environment.scheme == 'https'
#           response = RestClient::Resource.new(endpoint, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
#             .put(data.to_json,
#                  {
#                    :content_type => :json,
#                    :accept => :json
#                  })
#
#         else
#           response = RestClient.put(endpoint,
#                                     data.to_json,
#                                     {
#                                       :content_type => :json,
#                                       :accept => :json
#                                     })
#         end
#       rescue Errno::ECONNREFUSED
#         return {:error => 'Unable to connect to host ' + @environment.host.to_s + ':' + @environment.port.to_s}.to_json
#       end
#
#       response
#     end
#
#     def execute_put_authenticated(endpoint, token, data)
#       if token.nil?
#         raise 'Cannot execute an authenticated PUT request with no auth_token'
#       end
#
#       if data.nil?
#         raise 'Cannot execute PUT command with an empty data set'
#       end
#
#       begin
#         if @environment.scheme == 'https'
#           response = RestClient::Resource.new(endpoint, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
#             .put(data.to_json,
#                  {
#                    :content_type => :json,
#                    :accept => :json,
#                    :authorization => 'Bearer ' + token
#                  })
#
#         else
#           response = RestClient.put(endpoint,
#                                     data.to_json,
#                                     {
#                                       :content_type => :json,
#                                       :accept => :json,
#                                       :authorization => 'Bearer ' + token
#                                     })
#         end
#       rescue Errno::ECONNREFUSED
#         return { :error => 'Unable to connect to host ' + @environment.host.to_s + ':' + @environment.port.to_s }.to_json
#       end
#
#       response
#     end
#
#     def execute_patch_authenticated(endpoint, token)
#       if token.nil?
#         raise 'Cannot execute an authenticated PATCH request with no auth_token'
#       end
#
#       begin
#         if @environment.scheme == 'https'
#           response = RestClient::Resource.new(endpoint, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
#             .patch(nil,
#                    {
#                      :content_type => :json,
#                      :accept => :json,
#                      :authorization => 'Bearer ' + token
#                    })
#
#         else
#           response = RestClient.patch(endpoint, nil,
#                                       {
#                                         :content_type => :json,
#                                         :accept => :json,
#                                         :authorization => 'Bearer ' + token
#                                       })
#         end
#       rescue Errno::ECONNREFUSED
#         return { :error => 'Unable to connect to host ' + @environment.host.to_s + ':' + @environment.port.to_s }.to_json
#       end
#
#       response
#     end
#
#     def execute_delete_authenticated(endpoint, auth_token)
#       token = get_auth_token(auth_token)
#
#       begin
#         if @environment.scheme == 'https'
#           response = RestClient::Resource.new(endpoint, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
#             .delete({
#                       :authorization => 'Bearer ' + token,
#                       :content_type => :json,
#                       :accept => :json
#                     })
#         else
#           response = RestClient.delete(endpoint,
#                                        {
#                                          :authorization => 'Bearer ' + token,
#                                          :content_type => :json
#                                        })
#         end
#       rescue Errno::ECONNREFUSED
#         return {:error => 'Unable to connect to host ' + @environment.host.to_s + ':' + @environment.port.to_s}.to_json
#       end
#
#       response
#     end
#
#     def get_environment(environment)
#       if !environment || environment == 'production'
#         return PRODUCTION_ENVIRONMENT
#       elsif environment == 'staging'
#         return STAGING_ENVIRONMENT
#       end
#
#
#       LOCAL_ENVIRONMENT
#     end
#   end # Class Resources
# end # Module SinkingMoonRestClient

