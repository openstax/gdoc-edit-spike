class Deployment < OpenStax::Aws::DeploymentBase

  template_directory __dir__, "."

  stack :hosted_edited

  def initialize(env_name:, region:, in_aws_sandbox: true, dry_run: true)
    @in_aws_sandbox = in_aws_sandbox
    super(env_name: env_name, region: region, name: "hosted_edited", dry_run: dry_run)
  end

  def hosted_zone_name
    @in_aws_sandbox ? "sandbox.openstax.org" : "openstax.org"
  end

  def create
    hosted_edited_stack.create(wait: true, params: {domain: domain})
  end

  def update
    hosted_edited_stack.apply_change_set(params: {})
  end

  def delete
    hosted_edited_stack.delete(wait: true)
  end

  def parameter_default(parameter_name)
    case parameter_name
    when "HostedZoneName"
      hosted_zone_name
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

end
