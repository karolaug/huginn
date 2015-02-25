require 'net/ping'

module Agents
  class PingAgent < Agent
    cannot_receive_events!
    default_schedule "every_5m"

    
    description <<-MD
      Use this Agent to check if remote host is pingable.
    MD

    event_description "Ping result"

    def default_options
      {
        "host" => "127.0.0.1",
        "count" => '3',
        "expected_update_period_in_days" => '288',
        "mode" => "on_change"
      }
    end
    def validate_options
      errors.add(:base, 'host is required') unless options['host'].present?
      errors.add(:base, 'count is required') unless options['count'].present?
      errors.add(:base, "mode must be set to on_change or all") unless %w[on_change all].include?(options['mode'])
    end

    def check
      for i in 1..options['count'].to_i
        if Net::Ping::External.new(options['host']).ping
          create_event(:payload => {"pingable" => true})
          pingable = true
          break
        end
      end
      if not pingable
        create_event(:payload => {"pingable" => false})
      end
    end

    def ping_event(ping)
      if (defined?(memory['last'])).nil?
        options['mode'] = "all"
      end
      if options['mode'] === "all"
        create_event(:payload => {"pingable" => ping})
      else
        if ping
          if not memory['last']
            create_event(:payload => {"pingable" => true})
            memory['last'] = true
          end
        end
        if not ping
          if memory['last']
            create_event(:payload => {"pingable" => false})
            memory['last'] = false
          end
        end
      end
    end
    
    def working?
      event_created_within?(interpolated['expected_update_period_in_days']) && !recent_error_logs?
    end

  end
end
