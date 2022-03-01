# bubblez
[![Build Status](https://travis-ci.org/FoamFactory/bubbles.svg?branch=master)](https://travis-ci.org/FoamFactory/bubbles)

A gem for easily defining client REST interfaces in ruby

## Project Goals
When working in an Android environment, [Retrofit](https://square.github.io/retrofit/) provides a simple and effective
way of annotating methods so that you can define your REST interface:
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

What this does is allow you to focus on your _handling_ of the REST responses, rather than worrying about the
boilerplate code required to set up the client side of the REST API.

_bubblez_ is a Gem that seeks to provide this same behavior.

## Usage
If you're using Rails, it's suggested to have a `config/initializers/bubblez.rb` configuration file where you can
easily configure your endpoints and environments. If you're not using Rails, then you can put this configuration just
about anywhere, provided it's executed before where you want to use it.

## Quickstart
In `config/initializers/bubblez.rb`, add the following:
```ruby
require 'bubblez'

Bubblez.configure do |config|
  config.endpoints = [
    {
      :method => :get,
      :location => :version,
      :authenticated => false,
      :api_key_required => false
    }
  ]

  config.environments = [{
    :scheme => 'http',
    :host => '0.0.0.0',
    :port => '1234'
  }]
end
```

The `config.endpoints` section is where you configure which endpoints you want to support. The `config.environments`
defines the environments, or remote configurations, for accessing the endpoint on specific remote destinations.

Now, you can use this endpoint with:
```ruby
require 'bubblez'
...

def version
  resources = Bubbles::Resources.new

  # The following will make a GET request to
  # http://0.0.0.0:1234/version and return the result.
  result = resources.environment.version

  puts(result)
end
```

## Detailed Documentation
For more examples and detailed documentation, please see [the Bubbles GitHub page](http://foamfactory.github.io/bubblez).
