#### URL input validation
The spec says
> Only allow valid URLs (e.g., start with http(s)://{domain}/ )

From a usability perspective, I would probably allow users to omit the `http`/`https` scheme and would assume `http` if it didn't exist.  Most sites these days will automatically redirect you from `http` to `https` if they support it, and it would make for a cleaner user experience.  Since the specs were explicit though, I require the scheme to be present and one of `http` or `https` and give a specific error message otherwise.

## CI/CD
I added a github actions workflow that runs the test suite after each push to the `main` branch.  I figured this would be the easiest way for the reviewer to assess this requirement, as the results are publically visible on Github.  Alternatives would be to use CircleCI, Jenkins, or any of the many other CI providers.

I did not set up code coverage stats - this would be a great follow up task if this needed to be productionized.

The github actions workflow also deploys the site to heroku, specifically [https://afternoon-castle-16818.herokuapp.com](https://afternoon-castle-16818.herokuapp.com).  It will only deploy on pushes to the `main` branch that successfully pass the test suite.

## Performance
I used apache bench (ab) to send load test the site running in production on a free heroku instance, with a free postgres hobby instance.  The results weren't great, but I think that's to be expected of the free heroku tier.  Still, 80% of requests served in under 120 ms is decent for the homepage.

```
✔ ~/dev/strd [main|✔]
03:53 $ ab -n 100 -c 5 https://strd.ryoung.info/links/twtr
This is ApacheBench, Version 2.3 <$Revision: 1879490 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking strd.ryoung.info (be patient).....done


Server Software:        cloudflare
Server Hostname:        strd.ryoung.info
Server Port:            443
SSL/TLS Protocol:       TLSv1.2,ECDHE-ECDSA-CHACHA20-POLY1305,256,256
Server Temp Key:        ECDH X25519 253 bits
TLS Server Name:        strd.ryoung.info

Document Path:          /links/twtr
Document Length:        1840 bytes

Concurrency Level:      5
Time taken for tests:   6.520 seconds
Complete requests:      100
Failed requests:        0
Total transferred:      303782 bytes
HTML transferred:       184000 bytes
Requests per second:    15.34 [#/sec] (mean)
Time per request:       326.012 [ms] (mean)
Time per request:       65.202 [ms] (mean, across all concurrent requests)
Transfer rate:          45.50 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:       35  241 471.7     41    2049
Processing:    48   57   6.4     55      85
Waiting:       48   57   6.3     55      81
Total:         87  298 471.1     99    2113

Percentage of the requests served within a certain time (ms)
  50%     99
  66%    103
  75%    110
  80%    119
  90%   1096
  95%   1102
  98%   2102
  99%   2113
 100%   2113 (longest request)
```

## Alternative Architectures Considered
There were two other architectures I considered before settling on the current implementation, mostly out of time constraints.

### Short URL as a primary key
In the current implementation, I'm using the short url as just another field on the links table, which happens to have a unique index set up against it.  The id field acts as the primary key, but really isn't used anywhere in the application.

Instead, I could have made the short url the primary key of the table and not bothered with an id field at all.  My only hangup with this is that it just feels wrong to have a table without an explicit id field -- discoverability in BI tools, data analysts, or anyone not already familiar with the project would have to think twice.  I've also found ubiquitous id fields really useful for debugging, like when sifting through logs or internal tools.

All in all, I could be convinced either way.  Perhaps if we expected the app to be extremely high traffic, we could save a bit on cost by not storing ids, but that seems like premature optimization.

### Async short url generation
The specs mention a performance requirement of 5 req/s.  One place we could cut time is generating the random short urls.  Instead of computing new ones on demand each request and potentially re-generating them on failed db inserts, we could generate them asyncronously and always keep a pool available.  I envisioned a separate service that can be queried for another chunk of new random short urls.  That service could be checking them against the db to guarantee their uniqueness.  Upon a new app server booting up, it could grab 1000 or so (whatever amount is appropriate given historical traffic) from the service and just keep it in a genserver.  That way, when someone wants to create a new link, the app can pop one off the top of its pool and that's it.

This is probably the approach I'd go with if we were really serious about performance and scalability.  But for the purposes of the weekend take-home, it was much easier implement the generation of random strings and retries on collisions.


## View Stats
I implemented this as a simple integer column on the existing links table, out of simplicity and time constraints.  The main problem with this approach for a production system is that the stats will be written to constantly, and putting that kind of write load on the same table needed for link lookups could provide problems.  The first thing I'd do is batch up views.  Write them to a cache like ETS, Redis, or Memcache as an aggregated value `%{link_id => views}`, and then flush periodically to the database.

As a side note, this is a really good use case for Telemetry, and it'd be fun to extend this into time-series data that we could then show the user in the application.  That way the user could get a sense of not just how many views their link has, but also _when_ it became popular or started declining in popularity.
