# Erlen

Erlen is short for Erlenmeyer, a type of laboratory flask that looks like
Hireology's logo. Erlen is a library that provides a framework for schema
creation, validation, and serialization. A schema is a definition of a
resource or a resource group and describes what is expected in a transaction
regardless of the protocol--e.g., HTTP, RPC, Ruby call, and etc. In other
words, Erlen allows you to define contracts and share them across different
services and also enforce what is defined in the contracts.

## Installation

TBD

## Definitions

### Schema

A formal contract between two parties, defined with a set of of attributes
and validations. It is represented as a class which inherits from
`Erlen::Schema::Base`. Note that a schema is a _portable_ definition so there
is no business logic within a schema.

### Attribute

A property defined within a schema. Zero or more attributes can be defined
in a schema.

### Payload

Also called a _schema object_. An instance of `Erlen::Schema::Base` or its
descendents with actual data.

## Usage

It's easy to use Erlen. In a typical Rails application, you will define a
set of schemas and configure controllers to specify action and schema
associations. Let's look at how one can define a schema.

### Define a Schema

In order to define a schema, just inherit from `Erlen::Schema::Base`. For
example, a user schema can be defined as the following:

    class UserSchema < Erlen::Schema::Base
      attribute :name, String, required: true { |a| a.length > 5 }
      attribute :email, String, required: true
      attribute :nickname, String, required: false
      attribute :organization, OrganizationSchema, required: true

      validate { |payload| payload.name != "fake" }
    end

An attribute can be defined with a name, type, validation, and options.
Name and type are required. A type can be one of the primitive types
(String, Numeric, Integer, and Boolean) or a schema. Currently options
include `required`, which makes the attribute a required attribute, and
`alias`, which is used to make alias for importing from an object. The
validation block can be optionally given to perform an attribute-specific
validation.  The schema itself can have custom validation code aside from
basic type checks and attribute-specific validations.

### Instantiate a Schema

By instantiating the user schema, you get a user payload.

    user_payload = UserSchema.new(
        name: "Joe Smith",
        email: "joe@smith.com",
        organization: {
          id: 1,
          name: "Hireology"
        }
    )

You may pass in a hash object from which attributes will be populated. If
you are using this method, the initial object must be a hash and it must not
contain any attribute that is not defined in the schema. Otherwise,
`Erlen::NoAttributeError` will be thrown.

Alternatively, you may use `import` method instead:

    user_payload = UserSchema.import(user)

User can be any object (including a payload) possibly with some attributes
populated. This method is more graceful than the former that any undefined
attributes from the source object will be simply ignored. It will be
particularly useful to import data from an active record object, for
example.

### Pre-defined Schemas

For your convenience, there are several pre-defined schemas (under `Erlen`
namespace):

* `EmptySchema`: there is nothing in this schema. It will only match empty
payload.
* `AnySchema`: this is a special schema definition that allows _any_
payload
* `ResourceSchema`: This schema represents a resource payload which includes
`id` and timestamp fields, `created_at` and `updated_at`.
* `AnyOf`: This allows any payload whose schema is one of the specified
schemas.
* `ArrayOf`: This schema represents a list of payloads of the specified
type.
* `ResourceListOf`: Similar to `ArrayOf` but has a structure as defined in
our API standard.

Note that `AnyOf` and `ArrayOf` are like functors (as in OCaml) that
dynamically generates a concrete class based on additional type information.
For instance,

    AnyOf.new(DogSchema, CatSchema)

can allow either a dog payload or a cat payload.

    ArrayOf.new(Integer)

The above example restricts elements to be integers. The elements can be
accessed via `element` method.

    ints = ArrayOf.new(Integer)
    ints.elements << 1
    ints.elements << 2
    ints.elements
    # will return [1, 2]

### ControllerHelper

Erlen is shipped with a Rails helper called `Erlen::Rails::ControllerHelper` which
can be included in a controller to associate actions with schemas.

    class UsersController < ApplicationConroller
      include Erlen::Rails::ControllerHelper

      action_schema :index, response: ResourceListOfUsersSchema
      action_schema :create, request: UserCreateRequestSchema, response: UserResponseSchema
      action_schema :update, request: UserUpdateRequestSchema, response: UserResponseSchema
      action_schema :show, response: UserResponseSchema

      def create
        # ...
      end

      def update
        # ...
      end

      def show
        # ...
      end

      def destroy
        # ...
      end

    end

It is important to note that the above example used slightly different
schemas for different actions and between requests and response. This is
typical because different actions and inputs/outputs require different set
of attributes, validations, and etc. We strongly recommend that schemas are
defined in a sense that they are highly resuable and composable because of
this reason.

The magical part of this is that once a schema is defined for an action, the
rest if automated. By defining a request schema, a callback is registered
before the specified action to validate the raw request body and hydrate the
data into a payload. By defining a response schema, another callback is
registered to perform a validation on the response body.

For your convenience, `Erlen::Rails::ControllerHelper` overloads `render`
method so you can easily render a payload.

    render(payload: user_payload, status: 200)

This is not required, however. The advantage of using the above method is
(1) you don't need to serialize the payload into JSON yourself, and (2)
validation is done at the time of `render` call, which is helpful for
debugging purpose.

Note that, if payload is rendered using the above form, the after action
callback will skip the validation (as long as there wasn't any other render
call.)

## License

Erlen is released under the MIT License:
www.opensource.org/licenses/MIT
