vcl 4.0;

import dynamic;

# Dummy definitions as we're using dynamic backend declaration
backend default {
    .host = "localhost";
    .port = "8888";
}

sub vcl_init {
    new dynBackend = dynamic.director(port = "8080");
}

acl purge {
    "localhost";
}

sub vcl_recv {

    # allow PURGE from localhost
    if (req.method == "PURGE") {
        if (!client.ip ~ purge) {
            return(synth(405,"Not allowed."));
        }
        return (purge);
    }

    # healthcheck
    if (req.method == "GET" && req.url == "/status") {
           return(synth(200, "OK"));
    }

    if (req.url ~ "^\/content.*$") {
        set req.url = regsub(req.url, "content", "/notify");
        set req.backend_hint = dynBackend.backend("cms-notifier");
    } 
    elif (req.url ~ "^\/video.*$") {
        set req.url = regsub(req.url, "video", "/notify");
        set req.backend_hint = dynBackend.backend("cms-notifier");
    } 
    eif (req.url ~ "^\/metadata.*$") {
        set req.url = regsub(req.url, "metadata", "/notify");
        set req.backend_hint = dynBackend.backend("cms-metadata-notifier");
    } 
    elif (req.url ~ "\/notification\/wordpress.*$") {
        set req.url = regsub(req.url, "notification\/wordpress", "/content");
        set req.backend_hint = dynBackend.backend("wordpress-notifier");
    } 
    elif (req.url ~ "\/notification\/brightcove\/content.*$") {
        set req.url = regsub(req.url, "notification\/brightcove\/content", "/notify");
        set req.backend_hint = dynBackend.backend("brightcove-notifier");
    } 
    elif (req.url ~ "\/notification\/brightcove\/metadata.*$") {
        set req.url = regsub(req.url, "notification\/brightcove\/metadata", "/notify");
        set req.backend_hint = dynBackend.backend("brightcove-metadata-preprocessor");
    } 
    elif (req.url ~ "^\/__[\w-]*\/.*$") {
        # create a new backend dynamically to match the requested URL that will be looked up in the Kubernetes DNS.
        # For example calling the URL /__content-ingester/xyz will forward the request to the service content-ingester with the url /xyz
        set req.backend_hint = dynBackend.backend(regsub(req.url, "^\/__([\w-]*)\/.*$", "\1"));
        set req.url = regsub(req.url, "^\/__[\w-]*\/(.*)$", "/\1");
        set req.http.X-VarnishPassThrough = "true";
    }

    return (pipe);
}