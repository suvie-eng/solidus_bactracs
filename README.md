# Solidus Bactracs


This gem integrates [Bactracs](http://www.bactracs.com) with [Solidus](http://solidus.io). It
enables your Solidus system to push shipment RMAs to the system.

> Currently this requires Solidus ~ 4.x

> This integration was cloned from [spree_shipstation](https://github.com/DynamoMTL/spree_shipstation) to provide some consistency with other Solidus<-->Shipping related patterns.

## Installation

Add solidus_bactracs to your Gemfile:

```ruby
gem 'solidus_bactracs', github: 'suvie-eng/solidus_bactracs'
```

Bundle your dependencies and run the installation generator:

```shell
bin/rails generate solidus_bactracs:install
```

The installer will create a configuration initializer that you'll need to customize.

The installer will also create a migration, which is required by the API integration. If you are
going to use the XML integration, feel free to delete the migration file, as those columns won't be
used by the extension.

## Usage

This extension can integrate with Bactracs via SOAP-based XML API integration.  The gem currently makes SOAP 1.1 format calls, though the API support SOAP 1.2



### XML integration

The [XML integration](https://help.bactracs.com/hc/en-us/articles/360025856192-Custom-Store-Development-Guide)
works by exposing a route in your Solidus application that generates an XML feed of all recently
created and updated shipments in your Solidus store.

#### XML integration: Configuration

⛔️ This section is outdated and inaccurate.

In order to enable the XML integration, make sure to configure the relevant section of the
configuration initializer, and configure your Bactracs/Andlor site accordingly:

- **Username**: the username defined in your configuration.
- **Password**: the password defined in your configuration.
- **URL to custom page**: `https://yourdomain.com/bactracs.xml`.

You can also configure your Bactracs/Andlor site to pull the XML feed automatically on a recurring
basis, or manually by clicking the "Refresh stores" button.

There are five shipment states for an order (= shipment) in Bactracs. These states do not
necessarily align with Solidus, but you can configure Bactracs to create a mapping for your
specific needs. Here's the recommended mapping:

Bactracs RMA Type    | Bactracs status    | Solidus status
------------------------|--------------------|---------------
Type 1        | `unpaid`           | `pending`
Type W       | `paid`             | `ready`
Type 3                 | `shipped`          | `shipped`
Type 4               | `cancelled`        | `cancelled`



#### XML integration: Usage

There's nothing you need to do. Once properly configured, the integration just works!

#### XML integration: Gotchas

There are a few gotchas you need to be aware of:

- If you change the shipping method of an order in Bactracs, the change will not be reflected in
  Solidus and the tracking link might not work properly.
- When `bactracs_capture_at_notification` is enabled, any errors during payment capture will
  prevent the update of the shipment's tracking number.

### API integration

The [API integration](https://www.bactracs.com/docs/api/) works by calling the Bactracs API
to sync all of your shipments continuously.

Because Bactracs has very low rate limits (i.e., 40 reqs/minute at the time of writing), the
API integration does not send an API request for every single shipment update, as you would expect
from a traditional API integration.

Instead, a background job runs on a recurring basis and batches together all the shipments that need
to be created or updated in ShipStation. These shipments are then sent one at a time
to Bactracs [RMA creation endpoint](https://www.bactracs.com/docs/api/orders/create-update-multiple-orders/).

This allows us to work around Bactracs's rate limit and sync up to 4000 shipments/minute.

As you may imagine, this technique also comes at the expense of some additional complexity in the
implementation, but the extension abstracts it all away for you.

#### API integration: Configuration

In order to enable the API integration, make sure to configure the relevant section of the configuration initializer. At the very least, the integration needs to know your API credentials and store ID, but there are additional options you can configure — just look at the initializer!

##### RMA Type

This gem exposes a config var that holds an evaluator for the type of RMA being sent through bactracs.  E.G. `1`, `2`, `W`, etc.

```
config.evaluate_rma_type = proc do |shipment|
 "W"
end
```

You should overwrite this with your own means of determining the RMA type for a given shipment.

##### DF Part
Andlor uses the key "DFPart" to enable the indication of which item was 'defective' and being returned.  This only applies to Type 4 RMAs.

Currently, the DF Part is the `number` on the shipment, and there is not yet an override method.

#### API integration: Usage

Once you've configured the integration, you will also need to enqueue the `ScheduleShipmentSyncsJob`
on a recurring basis, to kick off the synchronization process. Because every app uses a different
background processing library, this is left up to the user.

Here's what an example with [sidekiq-scheduler](https://github.com/moove-it/sidekiq-scheduler) might
look like:

```yaml
# config/sidekiq.yml
:schedule:
  schedule_shipment_syncs:
    every: ['1m', first_in: '0s']
    class: 'SolidusBactracs::Api::ScheduleShipmentSyncsJob'
```

This will schedule the job to run every minute. This is generally a good starting point, but feel
free to adjust it as needed.

#### API integration: Gotchas

One of the main issues to be aware of is that the Bactracs API *always* responds with an HTTP 200, even if the request failed.  This may be a SOAP convention, or just the idiosyncrasies of the API design.

⚠️ You must always inspect the `Message` component of the response in order to determine success/fail.  THe e.g. `Result` field can say "true" but the Message states a failure.

----

There other factor you need to be aware of when integrating via the API:  the interval between your syncs is, on average, larger than your latency in processing background jobs, or you are going to experience sync overlaps.

As an example, if it takes your Sidekiq process 10 seconds to execute a job from the time it's
scheduled, but you schedule a shipment sync every 5 seconds, your sync jobs will start overlapping,
making your latency even worse.

This is a problem that is faced by all recurring jobs. The solution is two-fold:

1. Monitor the latency of your background processing queues. Seriously, do it.
2. Make sure your sync interval is not too aggressive: unless you really need to, there's no point
   in syncing your shipments more often than once a minute.

## Development

Because of the object abstractions in this gem, some find it difficult to test API responses vis the console.  To ease such console work, a 'console harness' was developed that provides several affordances to exploratory development.

Create a new harness in the console via

```ruby
h = SolidusBactracs::ConsoleHarness.new
```

#### `.try_one`

The easiest way to test the API, seeing both the output of the shipment when serialized as a XML SOAP request, and the result from the Bactracs API.

```ruby
h.try_one
```

or try a few

```ruby
h.try_batch(4)
```

maybe you have a shipment with particular issues, e.g. shipment number `H123456789`

```ruby
h.shipment_number('H123456789')

h.try_one(h.shipment_number('H123456789'))
```

`.shipment_number` retries that shipment from the scope of available `h.shipments`.

#### `.refresh`

If that was successful, you may find your list of shipments has one or more shipments that are already synced

```ruby
h.shipments.size # => 7
h.refresh
h.shipments.size # => 6
```

#### `.cursor`

You can set where in the recordset you want to continue trying from

```
h.cursor = 5
h.try_one
```

#### `.batch`

You can also change the default batch size

```
h.batch = 10
h.try_batch
# output from 10 runs, if not errors occur
```

#### deep objects

Several deeply-nested objects are exposed for convenience

* runner
* syncer
* sync (job)

```
h.serialize(shipment)
# see the output of serialization

h.runner.authenticated_call(shipment: h.shipments[0], serializer: h.syncer.client.shipment_serializer)
```

Remember that you can monkey patch code in the console, to test the improvement the harness or the gem itself.


### Testing the extension


⛔️ This section is outdated and inaccurate.

First bundle your dependencies, then run `bin/rake`. `bin/rake` will default to building the dummy
app if it does not exist, then it will run specs. The dummy app can be regenerated by using
`bin/rake extension:test_app`.

```shell
bin/rake
```

To run [Rubocop](https://github.com/bbatsov/rubocop) static code analysis run

```shell
bundle exec rubocop
```

When testing your application's integration with this extension you may use its factories.
Simply add this require statement to your `spec/spec_helper.rb`:

```ruby
require 'solidus_bactracs/testing_support/factories'
```

Or, if you are using `FactoryBot.definition_file_paths`, you can load Solidus core
factories along with this extension's factories using this statement:

```ruby
SolidusDevSupport::TestingSupport::Factories.load_for(SolidusBactracs::Engine)
```

### Running the sandbox


⛔️ This section is outdated and inaccurate.

To run this extension in a sandboxed Solidus application, you can run `bin/sandbox`. The path for
the sandbox app is `./sandbox` and `bin/rails` will forward any Rails commands to
`sandbox/bin/rails`.

Here's an example:

```
$ bin/rails server
=> Booting Puma
=> Rails 6.0.2.1 application starting in development
* Listening on tcp://127.0.0.1:3000
Use Ctrl-C to stop
```

### Updating the changelog

Before and after releases the changelog should be updated to reflect the up-to-date status of
the project:

```shell
bin/rake changelog
git add CHANGELOG.md
git commit -m "Update the changelog"
```

### Releasing new versions

Please refer to the dedicated [page](https://github.com/solidusio/solidus/wiki/How-to-release-extensions) on Solidus wiki.

## License

Copyright (c) 2022 Suvie, released under the New BSD License.
