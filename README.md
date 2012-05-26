![Sellbot](http://ryanfunduk.com/assets/sellbot/logo.png)

#### A micro-app for DIY digital product sales.

This project is a smallish [Padrino](http://padrinorb.com) web application.
It has plenty of configuration options, and it's pretty approachable for
plain old hack-it-to-be-what-you-want. Flexible digital product sales where
you only pay for exactly the amount of storage and bandwidth you require.


## Why

My motivation for writing this is the front-loaded cost of the hosted
solutions to selling digital products (such as
[FetchApp](http://fetchapp.com)). This is not to say these
apps are very expensive, or that they aren't worth the price, just
that I wanted a DIY option.

Let's say I want to try selling some screencasts, and say I have 5GB of files
to sell over the first few months (multiple versions of HD screencasts),
I have to commit to spending $50/month (using FetchApp's pricing as an example)
just to have them _available_ for purchase.

Here's a comparison, price-wise, in some ficticious 1 month periods.
Here I'll assume that each purchase is $10, and each sale results
in 1GB of downloads.

<table>
  <tr>
    <th>Storage</th>
    <th>Sales</th>
    <th>Revenue</th>
    <th colspan=2>Costs</th>
  </tr>
  <tr>
    <th colspan=3>&nbsp;</th>
    <th colspan=1>FetchApp</th>
    <th colspan=1>Sellbot</th>
  </tr>
  <tr>
    <td>10GB</td>
    <td>0</td>
    <td>$0</td>
    <td>$50</td>
    <td>$1.25</td>
  </tr>
  <tr>
    <td>10GB</td>
    <td>10</td>
    <td>$100</td>
    <td>$50</td>
    <td>$2.33</td>
  </tr>
  <tr>
    <td>10GB</td>
    <td>50</td>
    <td>$500</td>
    <td>$50</td>
    <td>$7.13</td>
  </tr>
  <tr>
    <td>20GB</td>
    <td>500</td>
    <td>$5000</td>
    <td>$100</td>
    <td>$62.37</td>
  </tr>
  <tr>
    <td>20GB</td>
    <td>1000</td>
    <td>$10000</td>
    <td>$100</td>
    <td>$122.38</td>
  </tr>
  <tr>
    <td>60GB</td>
    <td>5000</td>
    <td>$50000</td>
    <td>$300</td>
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

There is a clear trade-off here. You have to run the thing yourself. You
set it up on [Heroku](http://heroku.com) or run it on your own VPS (I already
have one, so this is easy) and you have to manage it yourself, make sure it
doesn't go down or that there's an issue with payments going through/etc.

Obviously many people will simply opt to outsource that stuff to FetchApp
and that's great. But if you want to do it yourself, you can use Sellbot!


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
- <strike>send an email receipt</strike> (not yet)
- show you reports and <strike>graphs</strike> (not yet) in an admin panel
- be configured or simply just edited to your preferences


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


## Application Configuration

You'll need to write a fairly thorough `config.yml`. There is an example
in the source (`config/config.yml.sample`) you can use to start with.
Let's jump in... You'll want to define some stuff the same for both development
and production modes.

  <pre><code>common: &common
  title: "QuickCasts Checkout" <i>-- site title</i>
  email_optional: false        <i>-- require an email address</i>
  max_downloads: 5             <i>-- omit for unlimited</i>
  logo: "/img/logo.png"
  price:
    unit: '$'
    precision: 0
  file_key_map:                <i>-- as above in store config</i>
    ...
  support: "ryan.funduk@gmail.com"</code></pre>

Next we have a block for the `development` environment. Likely you'll have
a similar one for production, of course.

    development:
      <<: *common
      home: 'http://example.dev'
      host: 'http://purchase.example.dev'
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

The stuff in the middle, `payment`, `db`, `storage`, `mail`, etc
are explained in the sections below.

### Sensitive Information

Putting AWS keys and so on in a yml file in your repository might not
sound like a good idea to you. In that case you can use `env.sample` to write
a set of environment variables that you can do the right thing with.
For example Heroku's [heroku-config](https://devcenter.heroku.com/articles/config-vars)
plugin makes this approach a good one. You'll find `.env` and `.powenv`
symlinks are already in place if you write `config/env`.


## Payment Options

Right now Sellbot 'officially' supports [Stripe](http://stripe.com) and
[Paypal](http://paypal.com) as payment processors. Configuration for
Paypal is significantly more complex and cumbersome than Stripe, but of course
Stripe can't be used outside of the US :/

### Stripe Configuration

Stripe is easy because all you really need is an account. Simply login
and find the settings modal via the 'Your Account' menu. On the 'Api Keys'
tab you'll find both your test and production keys. You can use them like so:

    payment:
      processor: Stripe
      config:
        publishable: ABC
        secret: XYZ

Uncomment the Stripe gem in `Gemfile` and run `bundle install`.

That's it.

### Paypal Configuration

Oh boy this is a tricky one. Wouldn't it be great if Stripe was supported
outside the US? Do yourself a favor and check right now before bothering with
this PayPal junk, I'll wait...

Ok, so sorry to see that you have to go the PayPal route. It's a long one :(

These instructions are for making a sandbox account so you can test
that this thing works. If you want to skip that part you can follow
similar steps to do this for your real seller account.

- Uncomment [Nestful](https://github.com/maccman/nestful) in
  `Gemfile` and run `bundle install`.
- Go to [developer.paypal.com](http://developer.paypal.com) and sign
  up for a new account.
- Confirm the account in the email they send.
- Create a 'preconfigured account' for both the seller and a
  fictitious 'buyer'.
- On the 'Test Accounts' page you'll see your new users. Copy the email
  of the one which will be your seller, this is your
  <strong><code>business_id</strong></code>.
- Decide if you're using the `ENV` approach or simply `config.yml`
- If using `config.yml`:

        mkdir -p etc/certs; cd etc/certs

    Otherwise see `env.sample` for how to define this stuff. It's
    _very_ whitespace sensitive.

- Generate a private key:

        openssl genrsa -out app_key.pem 1024

- Generate a public certificate:

        openssl req -new -key app_key.pem -x509 -days 365 -out app_cert.pem

    <small><em>Note</em>: If you don't specify `-days` the default
    appears to be something like 1 month. You can specify huge
    numbers in the thousands, I will leave this as an exercise to
    the reader to choose an appropriate length of time.</small>

- From the top bar choose 'Profile' and then 'Encrypted Payment Settings'.
- Add the public certificate (`app_cert.pem`) we just created.
- Take note of the 'Cert ID' afterwards, this becomes the
  <strong><code>cert_id</strong></code> config option.
- Just above the area where you upload your cert you will find a download
  link for PayPal's public cert. Put this along side your other certs, but
  rename it to `paypal_cert.pem` because... wow.
- Back on the 'Profile' page choose 'Website Payment Preferences'.
- Turn on 'Auto Return' and 'Payment Data Transfer'.
- You will also need to fill out the 'Return URL' field even though
  we will obviously be overriding it with each request...
- Enable 'Block Non-encrypted Website Payment'.
- Now save, and if you did that bit correctly, the resulting page
  should have a yellow box on it that says, in teeny letters,
  'please use the follow identity token'... Copy that because it will
  become the <strong><code>identity_token</code></strong> config option.
- Back on 'Profile', choose 'Instant Payment Notification Preferences'.
- Again we will ender a bogus URL here (like just the root, for example)
  and enable the option, each request will override the URL specified.
- If you're doing the sandbox thing you will need wait for
  PayPal to redirect you back to the `/complete/:order_id` url
  in order for the order to be marked as completed. Alternatively you
  can find the 'IPN History' page on PayPal, copy the parameters and
  the notify url and spoof the request yourself. The IPN handler
  actually _doesn't_ rely on any parameters other than the order id
  in the URL and `txn_id`. It then uses a PayPal API to check
  the status of the transaction authoritatively. So you don't need to
  worry about someone spoofing a successful transaction IPN in production.

Once that's all done, and the certs in place your config might
look like:

    payment:
      processor: PayPal
      config:
        cert_id: '...'
        identity_token: '...'
        business_id: '...'
        currency_code: 'CAD'


### Free Configuration

There is also a 'free' option which is really just a stub to bypass
any checkout flow. Just specify 'Free' as the processor:

    payment:
      processor: Free


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

Then uncomment `redis-namespace` in `Gemfile`, run `bundle install`,
and you're done!

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


## Mailer Options

_Not Yet Implemented_

Aiming to start with [SES](http://aws.amazon.com/ses) but this is a bit of
a pain so planning to also support plain SMTP and probably also
[Postmark](http://postmarkapp.com).
