def init_openstax_aws(is_production:)
  OpenStax::Aws::verify_secrets_populated!

  OpenStax::Aws.configure do |config|
    if is_production
      config.cfn_template_bucket_name = "openstax-cfn-templates"
      config.cfn_template_bucket_region = "us-east-1"
    else
      config.cfn_template_bucket_name = "openstax-sandbox-cfn-templates"
      config.cfn_template_bucket_region = "us-west-2"
    end

    config.logger = Logger.new(STDOUT)
    config.logger.formatter = proc do |severity, datetime, progname, msg|
      date_format = datetime.strftime("%Y-%m-%d %H:%M:%S.%3N")
      if severity == "INFO" or severity == "WARN"
          "[#{date_format}] #{severity}  | #{msg}\n"
      else
          "[#{date_format}] #{severity} | #{msg}\n"
      end
    end
  end

  OpenStax::Aws::verify_template_bucket_access!
end
