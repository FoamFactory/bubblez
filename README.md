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
