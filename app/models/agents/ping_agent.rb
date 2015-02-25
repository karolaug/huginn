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
        "count" => 3,
        "expected_update_period_in_days" => 288
      }
    end
    def validate_options
      errors.add(:base, 'host is required') unless options['host'].present?
      errors.add(:base, 'count is required') unless options['count'].present?
    end

    def check_ping(host, count)
      for i in 1..count
        if Net::PingExternal.new(host).ping
          create_event(:payload => {"pingable" => true})
          pingable = true
          break
        end
        if pingable
          create_event(:payload => {"pingable" => false})
        end
      end
    end

    def working?
      event_created_within?(interpolated['expected_update_period_in_days']) && !recent_error_logs?
    end

  end
end
