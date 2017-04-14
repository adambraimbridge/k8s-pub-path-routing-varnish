## UPP Publishing Cluster Path routing Varnish

The Publishing Varnish routing proxy placed after the publishing auth varnish.
Its role is to route traffic based on the context path in the URL to appropriate services.

See [default.vcl](/default.vcl) for the Varnish routing policies.
