# Bumblebee :bee:

Use ActiveRecord-like models to interact with a REST API.

## What is Bumblebee?

It's just like [Her](https://github.com/remiprev/her) or [Spyke](https://github.com/balvig/spyke), but designed to address some of the shortcomings of those gems.

* **Her**
  * has serious performance issues
  * is no longer actively maintained
* **Spyke**
  * does not support pagination
  * is overly difficult to hack on because...
  * its code is a little more complicated than it needs to be

Disclaimer: both Her and Spyke totally rock otherwise. :metal: This code could not have been written in a few days if they hadn't figured out most of the hard stuff for me.

## How does it work?

Bumblebee supports a lovely interface similar to Spyke:

```ruby
# you can configure a connection on the base class, or on specific models
Bumblebee::Model.connection = Faraday.new(url: "http://example.com") do |c|
  c.adapter Faraday.default_adapter
end

class Article < Bumblebee::Model
  has_many :comments
  scope :recent, ->{ where(recent: true) }
  scope :published, ->{ where(published: true) }
end

class Comment < Bumblebee::Model
  belongs_to :article
end

# GET /articles
Article.all

# GET /articles?recent=true&published=true
Article.recent.published

# GET /articles/123
article = Article.find(123)
article.title #=> "Writing a ORM in Ruby"

# GET /articles/123/comments
Article.find(123).comments
```

The 2 big differences between Bumblebee and Spyke are **pagination** and **response parsing**.

### Pagination

Most APIs return data one page at a time, so Bumblebee provides first-class support for paginated data. Given an endpoint that takes a `page` query param like this

```
GET /articles?page=2
```

Bumblebee lets you interact with pages of data like this:

```ruby
Article.all.pages.count
#=> 31

Article.all.pages.first
#=> [ #<Article id: 1>, #<Article id: 2>, ... ]

Article.all.pages.last
#=> [ ..., #<Article id: 770>, #<Article id: 771> ]

Article.all.pages.at(2)
Article.all.pages[2]
#=> [ #<Article id: 26>, #<Article id: 27>, ... ]

Article.all.pages.each do |page|
  # fetch every page, yielding 1 at a time
end
```

Bumblebee also lets you ignore pages entirely and work with the entire dataset of the scope as if it were returned in 1 response.

```ruby
Article.all.count
#=> 771

Article.all.first
#=> #<Article id: 1>

Article.all.last
#=> #<Article id: 771>

Article.all.each do |article|
  # fetches 1 page at a time
  # but yields to each record
end

Article.all.to_a
# fetches every page, and stiches together into an array
#=> [ #<Article id: 1>, ..., #<Article id: 771> ]
```

### Response parsing

Both Her and Spyke rely on Faraday middleware to handle response parsing.

But our responses contain more than just JSON with models. It also contains metadata required to make our dream pagination interface work: # of total results, # of pages, etc.

Some APIs return this information in the response body JSON, in a `metadata` section. Other APIs return this information in custom response headers:

```
X-Page: 2
X-Per-Page: 25
X-Total-Pages: 31
X-Total: 771
```

This could theoretically be handled via Faraday middleware, but the way Her and Spyke access the parsed data takes "kludgy" to the next level. They both *replace* the response body with the parsed hash, adding arbitrary keys to this hash that are later retrieved to populate models. This mixing of core logic and low-level HTTP details seemed like a bad idea.

So we've replaced this with the concept of a **parser method**. You can specify the response parser for a model (or a base class) by overriding a single method.

```ruby
class MyModel < Bumblebee::Model
  def parse(response)
    # default implementation.
    { data: parse_data(response) }.merge(parse_pagination(response))
  end
end
```
The `parse` method should return a hash (or hash-like object) that contains the
following keys:
```ruby
data        # a hash or array with the data we're looking for
page        # the current page
total       # the total # of records available in this scope
total_pages # the # of pages available in this scope
```

The default `parse` implementation makes use of two template method - `parse_data` and `parse_pagination`. If you only need to adjust one aspect of the parsing, you can override the appropriate template method. The default methods are:

```ruby
def parse_data(response)
  if response.status == 204
    {}
  else
    JSON.parse(response.body, symbolize_names: true)
  end
end

def parse_pagination(response)
  {
    page:        response.headers['X-Page'],
    total:       response.headers['X-Total'],
    total_pages: response.headers['X-Total-Pages']
  }
end
```

### Save Errors

If a `save`, `save!`, `update`, or `update!` on an instance of a Bumblebee model
fails with a 4xx or 5xx response, and if the server responds with JSON in the
following format

```
{
  "errors": {
    ...error information...
  }
}
```

then error information from the response will be stored as a hash on the
instance, and exposed through an `#errors` method on the instance.

```ruby
class TestModel < Bumblebee::Model
end

model = TestModel.new(email: "invalid email")
model.save #=> false
model.errors #=> { email: 'is invalid' }
```

This functionality makes use of a `parse_errors` template instance method that
accepts a response object and returns a hash. This method can be overridden if
the server you are interacting with provides error information in a different
format, or you wish to store errors on the instance in a different format. The
default implementation is

```ruby
def parse_errors(response)
  JSON.parse(response.body, symbolize_names: true).fetch(:errors, nil)
rescue JSON::ParserError
  nil
end
```

## Attribute types

Bumblebee has some simple support for handling types in models.
Attributes are declared with their types inside the model class, and Bumblebee
will then convert to the desired type when you access the attribute.

```ruby
class TestModel < Bumblebee::Model
  attribute :created_at, DateTime
end

a = TestModel.new(name: "Hello", created_at: "20160902T19:34:11")
a.created_at.class #=> DateTime
```

Bumblebee comes with support for the following types:
```
Integer
String
Float
JSON
Date
Time
DateTime
```

### Registering a custom type

If you need to add use a type that isn't currently supported by Bumblebee, you
can register it with a conversion lambda.

```ruby
Bumblebee::Types.register_type CustomType, ->(value) { CustomType.convert(value) }
```

This will call the conversion block when the value isn't already the correct type and you attempt to read or write the attribute.

Any types used in a Bumblebee model should have a valid `to_json` representation to allow
Bumblebee to generate a payload to send to the API endpoints.

## Updating models

Bumblebee supports an ActiveRecord-inspired API for creating, saving and updating data in models. This support comes down to 3 methods:
```
Bumblebee::Model.create(attributes)
Bumblebee::Model#update(attributes)
Bumblebee::Model#save
```

These also support the `!` suffix to cause exceptions to be raised if errors occur.

The save process defaults to the following:

* If the model has been persisted, make a `PUT` request to persist the model attributes using the model's URI
* If the model hasn't been persisted, make a `POST` request to persist the model attributes using the model's URI

The URI is generated by merging the model's attributes with the class-level URI template. This defaults to `/model-name/:id` so the above defaults become
```
POST /model/
PUT /model/id
```
as expected, as a newly created model will lack an `id` attribute.

If you need to alter this behaviour, there are two template methods to override in your model:
```ruby
# defaults
def save_new
  request :post, attributes
end

def save_existing
  request :put, attributes
end
```

Overriding these will allow you to customise any pre-request attribute processing, the request method used or anything else required. All update interfaces are implemented using these methods to make requests.

## Destroying models

Bumblebee also has an ActiveRecord-inspired API for destroying models:
```
Bumblebee::Model#destroy
Bumblebee::Model#destroy!
```

The `destroy!` version of this method will raise an exception if something goes
wrong with the request. The `destroy` version will return `false` and set the
error to `Bumblebee::Model#errors`.

The destroy process defaults to the following:

* If the model hasn't been persisted, nothing occurs.
* If the model has been persisted, make a `DELETE` request to destroy the remote
  model's data. This also sets `persisted?` to false and `id` to `nil`.

If you need to alter this behaviour, there are two template methods to override
in your model:
```ruby
def destroy_new
end

def destroy_existing
  request :delete
  self.id = nil
end
```

Overriding these will allow you to customise your process for deleting remote
data, such as clearing more or different attributes or performing an action on
attempting to delete an unpersisted model.

## Why "bumblebee"?

* Every time I see an "apis" folder in one of our projects, I think of _apis_, the Latin word for "bee". (The scientific name of the [western honeybee](https://en.wikipedia.org/wiki/Western_honey_bee) is _Apis mellifera_.)
* As a metaphor, bees [something, something] emergent complexity [something, something] microservices.

