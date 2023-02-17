
# Stabilizing via URL Encoding

The UrlEncoded stabilizer is a little different than the [Database Stabilizer](/stabilizers/database) in that it doesn't _save_ anything anywhere. What this stabilizer does is takes the filter's state and turns it into a `rawurlencode` encoded string which then gets sent back to the frontend under the `stable_id` key. 

The common use case for the UrlEncoded stabilizer is to receive the `stable_id` on the frontend, and then update the user's window location to include that id, eg `example.com/users?filter={stable_id}`. Putting that stable id into the URL allows the user to copy, share, refresh, or otherwise store the URL and navigate back to exactly where they were before.

If your app sees high usage, then the UrlEncoded stabilizer is a great way to allow users to not lose all of their progress without having to save every filter to the database.

## A Warning!

There is one extremely important consideration when using the UrlEncoded stabilizer: **the size of the encoded string is directly proportional to the size of the filter's state**. If your end user adds many conditions with very long values, then it is possible that your encoded state could end up being greater than 2,000 characters. 

This consideration is so important because it is generally recommended that URLs [not exceed 2,000 characters](https://stackoverflow.com/a/417184/1408651). If you're not putting the entire UrlEncoded string in the URL, then this consideration is irrelevant. If you are, however, you will need to consider the possibility of a user creating a filter that encodes to an extremely long string.

By default the string is gzipped before it's encoded, but you still need to consider the potential length of string.
