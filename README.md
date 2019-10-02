# bubbles
A gem for easily defining client REST interfaces in ruby

## Project Goals
When working in an Android environment, [Retrofit](https://square.github.io/retrofit/) provides a simple and effective way of annotating methods so that you can define your REST interface:
```java
public interface GitHubService {
  @GET("users/{user}/repos")
  Call<List<Repo>> listRepos(@Path("user") String user);
}
```

You can then instantiate your REST client as follows:
```java
Retrofit retrofit = new Retrofit.Builder()
    .baseUrl("https://api.github.com/")
    .build();

GitHubService service = retrofit.create(GitHubService.class);
```

What this does is allow you to focus on your _handling_ of the REST responses, rather than worrying about the boilerplate code required to set up the client side of the REST API.

_bubbles_ is a Gem that seeks to provide this same behavior.

## :warning: Limitations
**Please read this section before using!**

Currently, bubbles has a number of limitations that make it likely not suitable for use in a production environment. Each of these is tracked by an issue on our [issues page](https://github.com/FoamFactory/bubbles/issues).

  - Passing an API key with a request is restricted to using `X-Api-Key` as a header key (#10).
  - Some request methods (specifically `DELETE`) do not currently allow unauthenticated access. In other words, it is not possible to perform a `DELETE` request on your API without passing an authorization token. (#16)
  - Not all possible combinations of `has_uri_params`, `authenticated`, and `api_key_required` are tested. In some cases, such as with `GET` requests, there aren't any tests for possible configuration cases that might cause issues when combined. (#12)

If you're interested in working on any of the issues above, please feel free to submit a pull request and a member of our team will review that pull request within a couple of days.

## Usage
If you're using Rails, it's suggested to have a `config/initializers/bubbles.rb` configuration file where you can easily configure your endpoints and environments. If you're not using Rails, then you can put this configuration just about anywhere, provided it's executed before where you want to use it.

## Quickstart
In `config/initializers/bubbles.rb`, add the following:
```ruby
require 'bubbles'

Bubbles.configure do |config|
  config.endpoints = [
    {
      :method => :get,
      :location => :version,
      :authenticated => false,
      :api_key_required => false
    }
  ]

  config.local_environment = {
    :scheme => 'http',
    :host => '0.0.0.0',
    :port => '1234'
  }
end
```

The `config.endpoints` section is where you configure which endpoints you want to support. The `config.local_environment` defines an environment, or remote configuration, for accessing the endpoint on a specific remote destination.

Now, you can use this endpoint with:
```ruby
require 'bubbles'

...

def version
  resources = Bubbles::Resources.new

  # The following will make a GET request to
  # http://0.0.0.0:1234/version and return the result.
  result = resources.local_environment.version

  puts(result)
end
```

## Detailed Documentation
There are currently two parts to a bubbles configuration: the _environments_ and the _endpoints_. Bubbles is configured in a _bubbles configuration block_:
```ruby
Bubbles.configure do |config|
...
end
```

This configuration block can be run at any time, but is typically set up in the initializer section of an app's startup. If desired, configuration can happen separately. That is, you can initialize environments within your initializer file and then initialize endpoints within another section of the application. Just note that when endpoints are defined, it overwrites _all_ endpoints of a configuration, not just the ones you choose to change.

### Environments
Three environments are currently available to be set up within bubbles. These are:
  - `local_environment` : Designed to be used for a local API for development testing.
  - `staging_environment` : Designed to be used for a remote API for second-stage testing or production-like deployment.
  - `production_environment` : Designed to be used for a production environment.

While the names are hardcoded, the environments can be used for anything - you could easily use a `local_environment` to store the information for one of your production servers.

#### Configuration of Environments
Environments are configured as part of the _bubbles configuration block_ and can have the following parameters:

  - `scheme`: The scheme for accessing endpoints on this host. Should be one of `http` or `https`. Defaults to `http`.
  - `host`: A domain name or IP address for the remote host to access for the environment.  Defaults to `127.0.0.1`.
  - `port`: The port to use to access the remote host. Defaults to `1234`.
  - `api_key`: The API key to send along with requests for a given environment, if an API key is required. This is optional, and defaults to `nil`.
  - `headers`: A `Hash` of key-value pairs that contain additional headers to pass to every call to this endpoint. Defaults to `{}`.

You can configure all three environments at once in the _bubbles configuration block_:
```ruby
Bubbles.configure do |config|
  config.local_environment = {
    :scheme => 'http',
    :host => '0.0.0.0',
    :port => '1234'
  }

  config.staging_environment = {
    :scheme => 'http',
    :host => 'stage.api.foamfactory.com',
    :port => '80'
  }

  config.production_environment = {
    :scheme => 'https',
    :host => 'api.foamfactory.com',
    :port => '443'
  }
end
```

If you choose a scheme of `http` and leave off the `port` configuration variable, it will default to `80`. Similarly, `https` will default to a port of `443`.

#### Configuration of Endpoints
Endpoints are the meat and potatoes of REST interaction. By indicating a _method_, _uri_, _body_, and _headers_, you are effectively making a function call on a remote server.

_Endpoints_ are specified as an array of objects within the _bubbles configuration block_:

```ruby
config.endpoints = [
  # Individual endpoint definitions go here
]
```

When processing each of these endpoint definitions, a method is created on instances of `RestEnvironment` that allows you to call the method in question. For example, an endpoint defined as:
```ruby
{
  :method => :get,
  :location => :version,
  :authenticated => false,
  :api_key_required => false
}
```

will create a method on instances of `RestEnvironment` called `version`, which will execute the appropriate REST call (via `RestClient`) and return a `RestClient::Response` object.

Each _endpoint_ object can have the following attributes:

| Name    | Description         | Required? | Default |
| :---    | :------------------ | :-------: | :-----: |
| `method`| The HTTP method to use to access the API for this endpoint. Must be one of `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, or `HEAD`. | Yes | N/A |
| `location`| The path to access the endpoint. This is placed after the `host:port` section to build the URI. It may have URI parameters in the form of `{paramName}`. If a URI parameter is specified within the `location`, a `uri_params` hash will be expected to be passed to the calling method to replace the placeholder values. | Yes | N/A |
| `name` | The name to give the method created to make this REST call. | No | The value of the `location` parameter, with slashes (`/`) replaced with underscores (`_`). |
| `authorization` | Whether or not this endpoint requires authentication prior to executing the call. If true, then an `authorization_token` will be added to the method as a parameter to be passed when the method is called. This parameter will be placed in an `Authorization` header when the REST call is executed. | No | `false` |
| `api_key_required` | Whether or not an API key is required. If `true`, a parameter will be added to the method created to execute the REST API call named `api_key`. The value of this parameter will be set as the value of the `X-Api-Key` header when making the REST API call. | No | `false` |
| `return_type` | Must be one of: `[full_response, body_as_object, body_as_string]`. This specifies what type of response is expected from the `Endpoint`. A value of `full_response` will return the full `RestClient::Response` object to the client. A value of `body_as_string` will return the `RestClient::Response.body` value as a `String`. A value of `body_as_object` will take the `RestClient::Response.body` parameter and parse it as an `OpenStruct` object, and return the result of this parsing operation. | No | `body_as_string` |
| `encode_authorization` | Whether the `data` passed as part of the request should be re-encoded as an `Authorization: Basic` header (and Base64 encoded). Typically, this is only used for initial username/password authentication. | No | `false` |
| `headers` | A `Hash` of key-value pairs specifying additional headers (the `key` specifies the name of the header, and the `value` specifies the value) that should be passed with each call to this `Endpoint`. Defaults to `{}`.

### Examples
#### GET the version of the software (unauthenticated, no API key required)


#### GET a specific user by id (authentication required)

#### POST a login (i.e. retrieve an authorization token)

#### DELETE a user by id

#### PATCH a user's information by providing a body containing information to update
