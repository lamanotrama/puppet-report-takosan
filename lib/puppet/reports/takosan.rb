require 'puppet'
require 'puppet/network/http_pool'
require 'uri'

Puppet::Reports.register_report(:takosan) do
  def process
    configdir = File.dirname(Puppet.settings[:config])

    configfile = %w(takosan.yaml ikachan.yaml).
      map {|f| File.join(configdir, f) }.
      find {|f| File.exists?(f) }

    raise(Puppet::ParseError, "Slack(takosan) report config file #{configfile} not readable") unless configfile

    @config = YAML.load_file(configfile)

    return if self.status == "unchanged"

    message = sprintf "Puppet status: %s on %s [%s]", self.status, self.host, Puppet.settings[:environment]

    if self.status == "changed"
      message = ":white_check_mark: #{message}"
    else
      message = ":warning: #{message}"
    end

    @config["channels"].each do |channel|
      channel.gsub!(/^\\/, '')
      Net::HTTP.start(@config["host"], @config["port"]) {|http|
        body = "channel=#{channel}&message=#{message}"
        http.post('/notice', body)
      }
    end
  end
end

