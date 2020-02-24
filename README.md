A spike to show how google docs can be used to edit customized versions of OpenStax book pages, and how OpenStax can facilitate generation, sharing, publication, and hosting of these GDocs

## Requirements

* Docker
* Docker Compose
* A Google app with the Drive and Docs API enabled, with its `credentials.json` file downloaded into this source directory
* A \*.docx file generated from an OpenStax book page (one is provided in the `docx/` folder)
* The ARN of an appropriate wildcard SSL Cert in the AWS Parameter Store under a `/certs/wildcard` key (this is already done for the OpenStax sandbox account).

## File Descriptions

* `/aws` - contains the scripts for deploying the required S3 bucket and CloudFront distribution (this is all Ruby code to take advantage of our `aws-ruby` gem developed for other projects)
  * `create_env` - The script to create the deployment, see `create_env --help`
  * `deployment.rb` - A Ruby class that points to the main CloudFormation stack and exposes methods to manipulate it
  * `Gemfile`, `Gemfile.lock` - Tells `bundle install` which Ruby gems to install
  * `init_openstax_aws.rb` - code used by the deployment scripts to initialize the `aws-ruby` gem.
  * `main.yml` - The CloudFormation template (sets up the bucket, distribution, SSL stuff, Route 53 DNS entry, etc)
  * `script_requires.rb` - by requiring this one file, the three scripts don't have to repeat a bunch of common requires.
  * `standard_slop_args.rb` - shared code for command-line arguments that all scripts share.
  * `update_env` - The script to update an existing deployment, see `update_env --help`
* `/docx` - contains example versions of OpenStax pages converted to \*.docx for uploading to Google Docs.  Note that the one example in there now has math that renders well in Google Docs but not when published; this is due to the math being wrapped in a Cambria font, if that font is manually removed it renders well when published.
* `/docker` - some Docker helper scripts
* `/scripts` - utility scripts
* `do_it` - the main script containing Google and AWS API calls to make a gdoc, publish it, modify it, share it, and deploy its published version to AWS
* `published_page_wrapper_template.html` - The HTML template that wraps the published Google Doc

## Setup

Run

```
$> docker-compose up
```

This will build the container and start it.  You'll probably see lots of locale warnings during the build.

Drop into the container with

```
$> ./docker/bash
```

Next, set and export `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables in your shell, where those secrets give you access to an AWS account for creating CloudFormation stacks, buckets, distributions, etc.  If you have an AWS `credentials` file in `~/.aws` on your host machine, you can use the following from within the container:

```
$> source ./scripts/set_aws_env_vars profile-name-here
```

## Test out the spike

First, from within the container, create the AWS stack so we have a place to stick our published customized pages:

```
$> cd aws
$ aws> ./create_env --env_name some-name-here --do_it
```

Note if you leave off the `--do_it` option the run will be a dry run.

This will take a while to complete (around half an hour); most of the time is waiting for the CloudFront distribution to be created.

After it completes, verify that the distribution is up and working.  Visit https://customized-some-name-here.sandbox.openstax.org/robots.txt and you should see some text.

```
$ aws> cd ..
$> ./do_it --filename docx/1.4\ Inverse\ Functions.docx --name "1.4 Inverse Functions" --email bob@example.com --env_name some-name-here
```

Of course you should replace `bob@example.com` with an email address you control (other than the one you authorize in below) and you should use some other env_name, e.g. `mike1`.

The first time you run this, you'll be prompted to paste a Google authorization URL into your web browser (on your host).  Successfully logging in and granting access to the app will provide you with a code that you will paste into the docker terminal at the prompt.  This will create a `token.pickle` file (gitignored) that is used when making API calls.

You'll then see output like:

```
Uploaded GDoc with ID 1w-ErDmv8wNjlIv-00000000000-JrV7VdcS8KTHZIl0
Published file
Set the footer
Set the description
Shared with bob@example.com
```

Now if you go to Google Drive (with either the account you authorized through Google or the account attached to the email you gave in place of bob@example.com), you'll see the new Google Doc titled "1.4 Inverse Functions".

If you open it, you'll see that it has been shared.  In the footer you'll see a link to the gdoc and its published version on our CloudFront distribution.  If you visit the published version link, you'll see an embedded version of the gdoc with a custom header (set in `published_page_wrapper_template.html`) and you'll see the footer.  The footer is there to provide the author with a way to get from the gdoc to the published version and back again.

The published version is not pretty in the slightest, but we can add whatever styling / content / javascript we want to the wrapper portion of the page and we can investigate our options in styling the contents of the page.  The page updates every 5 minutes from changes in the GDoc (this is a Google thing, not something we set).

You can use `update_env` and `delete_env` to update and delete the AWS stack, respectively.

## Limitations

* Ownership of the Google Doc cannot be transferred to another account.  The Google account that created the document via this script will remain the owner.  Apparently this is a common annoyance to folks.  So if we productionized this code some Google account of ours would remain the owner of all customized Google docs.
* Some things are hardcoded, e.g. no matter which docx file you specify the link in the upper right of the published HTML page will point to OpenStax Calculus.
