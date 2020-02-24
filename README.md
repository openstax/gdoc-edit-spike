A spike to show how google docs can be used to edit customized versions of OpenStax book pages, and how OpenStax can facilitate generation, sharing, publication, and hosting of these GDocs

## Requirements

* Python 3
* Ruby 2.5+
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

## Setup

* Run `pip3 install -r requirements.txt`
* Run `cd aws; bundle install`
* Set and export `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables in your shell, where those secrets give you access to an AWS account for creating CloudFormation stacks, buckets, distributions, etc.

## Run it

First create the AWS stack so we have a place to stick our published customized pages:

```
$> cd aws
$ aws> ./create_env --env_name some-name-here --do_it
```

Note if you leave off the `--do_it` option the run will be a dry run.

This will take a while to complete (around half an hour); most of the time is waiting for the CloudFront distribution to be created.

After it completes, verify that the distribution is up and working.  Visit https://customized-some-name-here.sandbox.openstax.org/robots.txt and you should see some text.

```
./do_it --filename docx/1.4\ Inverse\ Functions.docx --name "1.4 Inverse Functions" --email bob@example.com --env_name sun1
```

## Limitations

* Ownership of the Google Doc cannot be transferred to another account.  The Google account that created the document via this script will remain the owner.  Apparently this is a common annoyance to folks.
