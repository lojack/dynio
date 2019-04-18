require 'httparty'

abort("Please set DIGITALOCEAN_TOKEN before proceeding") unless ENV.has_key?('DIGITALOCEAN_TOKEN')
abort("Usage: ruby dynio.rb <domain> <subdomain>") unless ARGV.length == 2
DIGITALOCEAN_TOKEN = ENV.fetch('DIGITALOCEAN_TOKEN').freeze
domain = ARGV[0]
subdomain = ARGV[1]

class WanIP
  include HTTParty
  format :json

  def self.ip
    get("https://api.ipify.org?format=json").fetch("ip")
  end

  def self.ip6
    get("https://api6.ipify.org?format=json").fetch("ip")
  end
end

class Domain

  def initialize(domain, subdomain='@')
    @domain = domain
    @subdomain = subdomain
  end

  def set_ip(ip_address)
    DigitalOcean.set_data(@domain, domain_id, ip_address)
  end

  private

  def domain_id
    domain_records = DigitalOcean.domain_records(@domain)
    subdomain_record = domain_records.select { |domain|
      is_subdomain_record?(domain)
    }.first
    raise StandardError, 'Subdomain not found.' if subdomain_record.nil?
    subdomain_record.fetch("id")
  end

  def is_subdomain_record?(domain)
    domain.fetch("type") == "A" &&
      domain.fetch("name") == @subdomain
  end

  class DigitalOcean
    include HTTParty
    format :json
    headers 'Authorization': "Bearer #{DIGITALOCEAN_TOKEN}"

    def self.set_data(domain, record_id, data)
      put(ENTITY_URL % {domain: domain, record_id: record_id}, body: {data: data})
    end

    def self.domain_records(domain)
      res = get(BASE_URL % {domain: domain})
      raise StandardError, res.fetch("message") unless res.has_key?("domain_records")
      res.fetch("domain_records")
    end

    BASE_URL = "https://api.digitalocean.com/v2/domains/%{domain}/records".freeze
    ENTITY_URL = BASE_URL + "/%{record_id}".freeze
  end
end

domain_record = Domain.new(domain, subdomain).set_ip(WanIP.ip)
abort('Failed to update domain record') unless domain_record.has_key?("domain_record")

new_ip = domain_record.fetch('domain_record').fetch('data')
puts "Successfully pointed #{subdomain}.#{domain} to #{new_ip}"
