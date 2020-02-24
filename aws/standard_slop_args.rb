def standard_slop_args(slop, include: [], about: "")
  include = [include].flatten

  slop.on '--help', 'show this help' do
    puts about + "\n" if !about.blank?
    puts slop
    exit
  end
  slop.bool   '--production_aws', 'use production (non-sandbox) AWS account'
  slop.bool('--do_it', 'when missing, does a dry run') if include.include?(:do_it)
end
