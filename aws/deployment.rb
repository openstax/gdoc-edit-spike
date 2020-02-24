class Deployment < OpenStax::Aws::DeploymentBase

  template_directory __dir__, "."

  stack :main

  def initialize(env_name:, region:, in_aws_sandbox: true, dry_run: true)
    @in_aws_sandbox = in_aws_sandbox
    super(env_name: env_name, region: region, name: "customized_pages", dry_run: dry_run)
  end

  def hosted_zone_name
    @in_aws_sandbox ? "sandbox.openstax.org" : "openstax.org"
  end

  def create
    main_stack.create(wait: true, params: {domain: domain})

    if !dry_run
      # Initialize the "go away" robots.txt file
      robots_file = OpenStax::Aws::S3TextFile.new(bucket_name: bucket_name, bucket_region: region, key: "robots/robots.txt")
      robots_file.write(string_contents: "User-agent: *\nDisallow: /")
    end
  end

  def update
    main_stack.apply_change_set(params: {})
  end

  def delete
    main_stack.delete(wait: true)
  end

  def parameter_default(parameter_name)
    case parameter_name
    when "HostedZoneName"
      hosted_zone_name
    when "BucketName"
      bucket_name
    end
  end

  def domain
    subdomain_with_dot = begin
      subdomain = [
        "customized",
        (env_name unless env_name == "production")
      ].compact.join("-")

      subdomain += "." unless subdomain.blank?
    end

    domain = "openstax.org"
    domain = "sandbox.openstax.org" if @in_aws_sandbox

    "#{subdomain_with_dot}#{domain}"
  end

  def bucket_name
    [env_name, (@in_aws_sandbox ? "sandbox" : nil), "customized-pages"].compact.join("-")
  end

end
