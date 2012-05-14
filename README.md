![Sellbot](http://ryanfunduk.com/assets/sellbot/logo.png)

#### A micro-app for DIY digital product sales.

This project is a smallish Padrino web application. It has plenty of
configuration options, and it's pretty approachable for plain old
hack-it-to-be-what-you-want. Flexible digital product sales where
you only pay for exactly the amount of storage and bandwidth you require.


## Why

My motivation for writing this is the front-loaded cost of the hosted
solutions to selling digital products (such as
[FetchApp](http://fetchapp.com)). This is not to say these
apps are very expensive, or that they aren't worth the price, just
that I wanted a DIY option.

### Pricing

If I want to try selling some screencasts, and say I have 5GB of files
to sell over the first few months (multiple versions of HD screencasts),
I have to commit to spending $50/month (using FetchApp's pricing as an example)
just to have them _available_ for purchase.

Let's do a calculation to figure out how running Sellbot vs FetchApp might
compare price-wise in some ficticious 1 month periods. Let's also assume
that each purchase is $10, and each sale results in 1GB of downloads.

<table>
  <tr>
    <th colspan=2>&nbsp;</th>
    <th colspan=2>FetchApp</th>
    <th colspan=2>Sellbot</th>
  </tr>
  <tr>
    <th>Storage</th>
    <th>Sales</th>
    <th>Revenue</th>
    <th>Costs</th>
    <th>Revenue</th>
    <th>Costs</th>
  </tr>
  <tr>
    <td>10GB</td>
    <td>0</td>
    <td>$0</td>
    <td>$50</td>
    <td>$0</td>
    <td>$1.25</td>
  </tr>
  <tr>
    <td>10GB</td>
    <td>10</td>
    <td>$100</td>
    <td>$50</td>
    <td>$100</td>
    <td>$2.33</td>
  </tr>
  <tr>
    <td>10GB</td>
    <td>50</td>
    <td>$500</td>
    <td>$50</td>
    <td>$500</td>
    <td>$7.13</td>
  </tr>
  <tr>
    <td>20GB</td>
    <td>500</td>
    <td>$5000</td>
    <td>$100</td>
    <td>$5000</td>
    <td>$62.37</td>
  </tr>
  <tr>
    <td>20GB</td>
    <td>1000</td>
    <td>$10000</td>
    <td>$100</td>
    <td>$10000</td>
    <td>$122.38</td>
  </tr>
  <tr>
    <td>60GB</td>
    <td>5000</td>
    <td>$50000</td>
    <td>$300</td>
    <td>$50000</td>
    <td>$607.38</td>
  </tr>
</table>

So as you can see, the download volume is what really matters. With S3
and most other DIY cloud storage the amount you store is basically
insignificant compared to how much downloading you do. Also it seems to
me that, at $50k in sales, you are hardly going to care about the
difference between spending $300 or $600 on your bandwidth charges.

In the first few months selling your new screencasts you could easily
be losing money with FetchApp. Also it's worth pointing out that FetchApp
is probably not making any money if you're serving 5TB of downloads at
$300/month.

### Trade-offs

There is a clear trade-off here. You have to run the thing myself. You
set it up on [Heroku](http://heroku.com) or run it on your own VPS (I already
have one, so this is easy) and you have to manage it yourself, make sure it
doesn't go down or that there's an issue with payments going through/etc.

Obviously many people will simply opt to outsource that stuff to FetchApp
and that's great. But if you want to do it yourself, now you can!


---

## How It Works

Currently the idea is that you have your product pages separate, in whatever
sort of application you are already using (e.g. static files, a wordpress
blog, craigslist posts?, whatever). You then write a `config.yml` and a
`store.yml` (examples provided) and deploy the app somewhere - possibly
`purchase.yourdomain.com` makes sense here - and you're done! Sellbot can:

- collect an email address from the user
- take payment via a few different sources
- provide secure, time- and count- limited download links
- permalink to the user's order
- <strike>send an email receipt</strike>
- show you reports and <strike>graphs</strike> in an admin panel
- be configured or simply just edited to your preferences


---

## Application Configuration

You'll need to write a fairly thorough `config.yml`. There is an example
in the source (`config/config.yml.sample`) you can use to start with.

In general it looks like this, brace yourself:

    common: &common
      title: "QuickCasts Checkout"
      file_key_map:
        ...
      support: "ryan.funduk@gmail.com"

You'll want to define some stuff the same for both development
and production modes. `title` is just the actual site name,
`file_key_map` describes what each type of download should be called
(we'll get to that later) and `support` is an email address that is
used all over the place for the user to contact you.

Next we have a block for the `development` environment. Likely you'll have
a similar one for production, of course.

    development:
      <<: *common
      home: 'http://example.dev'
      host: 'http://purchase.example.dev'
      logo: "http://example.dev/img/logo.png"
      session: "SECRET"
      payment:
        ...
      db:
        ...
      storage:
        ...
      mail:
        ...
      admin:
        username: password

First we include the `common` block. Then we define what the originating
site is (this is where you've presumably listed your products and links
into this app). The hostname of this purchase app itself, so it can write
permalinks to orders/etc. A logo image (you could just replace the sellbot
logo in `/img/logo.png` and make the logo url just a path, too). A session
secret (maybe `SecureRandom.base64(256)` or similar?). At the end
we have N username/password combinations for access to admin. Why is this
in plain text? Because you don't have this file in version control, and
other stuff like AWS keys are much more valuable and scary anyway!

The stuff in the middle, `payment`, `db`, `storage`, `mail`... These
are explained in the sections below.

### Sensitive Information

Putting AWS keys and so on in a yml file in your repository might not
sound like a good idea to you. In that case you can use `env.sample` to write
a set of environment variables that you can do the right thing with.
For example Heroku's [heroku-config](https://devcenter.heroku.com/articles/config-vars)
plugin makes this approach a good one. You'll find `.env` and `.powenv`
symlinks are already in place if you write `config/env`.


---

## Store Configuration

`store.yml` contains information about your store, what products and 'packages'
are available, how much they cost, and so on. Here's a quick example:

    products:
      screencast1:
        name: "A Screencast"
        subtitle: "A short description!"
        price: 9
        files:
          high: screencast1-high.mov
          low: screencast1-low.mov
          code: screencast1-code.zip
      screencast2:
        name: "Another Screencast"
        subtitle: "It's the best screencast ever."
        price: 9
        files:
          high: screencast2-high.mov
          low: screencast2-low.mov

    packages:
      all-screencasts:
        name: "All Screencasts"
        price: 15
        contents:
          - screencast1
          - screencast2

If you visit `http://example.com/all-screencasts` you'll get an entry page
that explains what you're buying, how much it costs and asks for their
email address. Like so:

![](http://ryanfunduk.com/assets/sellbot/screenshots/all-screencasts-purchase.png)

After this, depending on your configuration, the flow will be slightly
different (they may have to go through Paypal's horrendous checkout
process, etc) but eventually they will end up on a thanks page with
download links.

### Downloads

Download links are derived from the value of the `files` key and
the `file_key_map` key in `config.yml`. It should be obvious how it works
from this example:

    file_key_map:
      high: "High Quality MP4"
      low: "Low Quality MP4"
      code: "Source Code"

So assuming the store example above, and a user having bought
'screencast1' they will see this:

![](http://ryanfunduk.com/assets/sellbot/screenshots/thank-you-download-links.png)

You can configure how many downloads the user is allowed for each
file, and the links on the page expire in 5 minutes detering people
from just emailing them around. Or, you can just disable all that
and go with the honor sytem :)

---

## Payment Options

Right now Sellbot 'officially' supports [Stripe](http://stripe.com) and
[Paypal](http://paypal.com) as payment processors. Configuration for
Paypal is significantly more complex and cumbersome than Stripe, but of course
Stripe can't be used outside of the US :/

### Stripe Configuration

_TODO_

### Paypal Configuration

_TODO_


---

## Database Options

Sellbot's data layer is pretty simple: storing orders, email addresses,
payment processor responses and download counts.

- Full support for [Redis](http://redis.io)
- Experimental [DynamoDB](http://aws.amazon.com/dynamodb) adapter
- Working on more generic [MongoDB](http://mongodb.org) and
  [Sequel](http://sequel.rubyforge.org/) adapters


### Redis Configuration

In your `config.yml` you simply need to specify your options like so:

    db:
      adapter: Redis
      config:
        uri: http://127.0.0.1:6379
        namespace: a-namespace

### DynamoDB Configuration

_Note_ The DynamoDB adapter sort of 'technically' works, but it's
a bit odd and not exactly production ready. Experiment. Contribute? :)

The section in `config.yml` looks like so:

    db:
      adapter: DynamoDB
      config:
        table: table-name
        read: 10
        write: 5

Where read/write refer to the same parameters described in the
[DynamoDB FAQs](http://aws.amazon.com/dynamodb/faqs/#What_is_a_read/write_capacity_unit_How_do_I_estimate_how_many_read_and_write_capacity_units_I_need_for_my_application)

### MongoDB Configuration

_Not Yet Implemented_

### Sequel Configuration

_Not Yet Implemented_


---

## Storage Options

Right now only [S3](http://aws.amazon.com/s3) is supported because it has
easy support for secure/expiring links and is super cheap and convenient.
Planned is also just a generic permalink style storage option (e.g. host
and serve the files yourself) where you'd lose some of the features like
download restrictions.

Maybe there are some other good options like CDN networks or
[CloudFiles](http://www.rackspace.com/cloud/cloud_hosting_products/files/)?

### S3 Configuration

All you need here is the bucket your files live in and your AWS credentials:

    storage:
      provider: S3
      config:
        access_key_id: "ACCESS"
        secret_access_key: "SECRET"
        bucket: bucket-name


---

## Mailer Options

_Not Yet Implemented_

Aiming to start with [SES](http://aws.amazon.com/ses) but this is a bit of
a pain so planning to also support plain SMTP and probably also
[Postmark](http://postmarkapp.com).
