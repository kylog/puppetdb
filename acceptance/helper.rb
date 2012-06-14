#!/usr/bin/env ruby

require 'cgi'

module PuppetDBExtensions
  def start_puppetdb(host)
    on host, "service puppetdb start"
    on host, "curl http://localhost:8080", :acceptable_exit_codes => [0,7]
    until exit_code == 0
      sleep 1
      on host, "curl http://localhost:8080", :acceptable_exit_codes => [0,7]
    end
  end

  def stop_puppetdb(host)
    on host, "service puppetdb stop"
  end

  def sleep_until_queue_empty(host, timeout=nil)
    metric = "org.apache.activemq:BrokerName=localhost,Type=Queue,Destination=com.puppetlabs.puppetdb.commands"
    queue_size = nil

    begin
      Timeout.timeout(timeout) do
        until queue_size == 0
          result = on host, %Q(curl -H 'Accept: application/json' http://localhost:8080/metrics/mbean/#{CGI.escape(metric)} 2> /dev/null | ruby -rjson -e 'puts JSON.parse(STDIN.read)["QueueSize"]')
          queue_size = Integer(result.stdout.chomp)
        end
      end
    rescue Timeout::Error => e
      raise "Queue took longer than allowed #{timeout} seconds to empty"
    end
  end
end

PuppetAcceptance::TestCase.send(:include, PuppetDBExtensions)
