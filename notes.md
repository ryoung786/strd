#### URL input validation
The spec says
> Only allow valid URLs (e.g., start with http(s)://{domain}/ )

From a usability perspective, I would probably allow users to omit the `http`/`https` scheme and would assume `http` if it didn't exist.  Most sites these days will automatically redirect you from `http` to `https` if they support it, and it would make for a cleaner user experience.  Since the specs were explicit though, I require the scheme to be present and one of `http` or `https` and give a specific error message otherwise.

## CI
I added a github actions workflow that runs the test suite after each push to the `main` branch.  I figured this would be the easiest way for the reviewer to assess this requirement, as the results are publically visible on Github.  Alternatives would be to use CircleCI, Jenkins, or any of the many other CI providers.

I did not set up code coverage stats - this would be a great follow up task if this needed to be productionized.

## Performance

## Alternative Architectures Considered
There were two other architectures I considered before settling on the current implementation, mostly out of time constraints.

### Short URL as a primary key
In the current implementation, I'm using the short url as just another field on the links table, which happens to have a unique index set up against it.  The id field acts as the primary key, but really isn't used anywhere in the application.

Instead, I could have made the short url the primary key of the table and not bothered with an id field at all.  My only hangup with this is that it just feels wrong to have a table without an explicit id field -- discoverability in BI tools, data analysts, or anyone not already familiar with the project would have to think twice.  I've also found ubiquitous id fields really useful for debugging, like when sifting through logs or internal tools.

All in all, I could be convinced either way.  Perhaps if we expected the app to be extremely high traffic, we could save a bit on cost by not storing ids, but that seems like premature optimization.

### Async short url generation
The specs mention a performance requirement of 5 req/s.  One place we could cut time is generating the random short urls.  Instead of computing new ones on demand each request and potentially re-generating them on failed db inserts, we could generate them asyncronously and always keep a pool available.  I envisioned a separate service that can be queried for another chunk of new random short urls.  That service could be checking them against the db to guarantee their uniqueness.  Upon a new app server booting up, it could grab 1000 or so (whatever amount is appropriate given historical traffic) from the service and just keep it in a genserver.  That way, when someone wants to create a new link, the app can pop one off the top of its pool and that's it.

This is probably the approach I'd go with if we were really serious about performance and scalability.  But for the purposes of the weekend take-home, it was much easier implement the generation of random strings and retries on collisions.
