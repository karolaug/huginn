require 'net/ping'
require 'date'

module Agents
  class PingAgent < Agent
    cannot_receive_events!
    default_schedule "every_5m"
    
    description <<-MD
      Use this Agent to check if remote host is pingable and generate msg events.
    MD

    event_description "Ping result"

    def default_options
      {
        "host" => "127.0.0.1",
        "readable_name" => "localhost",
        "count" => '3',
        "expected_update_period_in_days" => '288',
        "mode" => "on_change",
        "message_type" => "presence"
      }
    end
    def validate_options
      errors.add(:base, 'host is required') unless options['host'].present?
      errors.add(:base, 'readable_name is required') unless options['readable_name'].present?
      errors.add(:base, 'count is required') unless options['count'].present?
      errors.add(:base, "mode must be set to on_change, all, on, or off") unless %w[on_change all].include?(options['mode'])
      errors.add(:base, "message_type must be set to presence, status, reminder_on reminder_off or ping") unless %w[presence status reminder_on reminder_off ping].include?(options['message_type'])
      
    end

    def check
      for i in 1..options['count'].to_i
        if Net::Ping::External.new(options['host']).ping
          ping_event(true)
          pingable = true
          break
        else
          pingable = false
        end
      end
      if not pingable
        ping_event(false)
      end
    end

    def ping_event(ping)
      if (defined?(memory['last'])).nil?
        options['mode'] = "all"
        memory['last'] = ping
      end
      if options['mode'] === "all"
        send_event(ping)
        memory['last'] = ping
      end
      if options['mode'] === "on_change"
        if ping
          if not memory['last']
            send_event(ping)
            memory['last'] = ping
          end
        end
        if not ping
          if memory['last']
            send_event(ping)
            memory['last'] = ping
          end
        end
      end
      if options['mode'] === "on"
        if ping
          send_event(ping)
        end
      end
      if options['mode'] === "off"
        if not ping
          send_event(ping)
        end
      end
    end

    def send_event(ping)
      dateTime = DateTime.now()
      if options['message_type'] === 'presence'
        if ping
          presence = "arrived"
        else
          presence = "left"
        end
        create_event :payload => {
                       "hostname" => options['host'],
                       "readable_name" => options['readable_name'],
                       "pingable" => ping,
                       "subject" => options['readable_name'] + ' presence notification',
                       "message" => dateTime + ' ' + options['readable_name'] + ' has just ' + presence,
                       "dateTime" => dateTime
                     }
      end
      if options['message_type'] === 'status'
        if ping
          presence = "turned ON"
        else
          presence = "turned OFF"
        end
        create_event :payload => {
                       "hostname" => options['host'],
                       "readable_name" => options['readable_name'],
                       "pingable" => ping,
                       "subject" => options['readable_name'] + ' status notification',
                       "message" => dateTime + ' ' + options['readable_name'] + ' has just been ' + presence,
                       "dateTime" => dateTime
                     }
      end
      if options['message_type'] === 'reminder_on'
        if ping
          presence = "ON"
          create_event :payload => {
                         "hostname" => options['host'],
                         "readable_name" => options['readable_name'],
                         "pingable" => ping,
                         "subject" => options['readable_name'] + ' status notification',
                         "message" => dateTime + ' ' + options['readable_name'] + ' is still ' + presence,
                         "dateTime" => dateTime
                       }
        end
      end
      if options['message_type'] === 'reminder_off'
        if not ping
          presence = "OFF"
          create_event :payload => {
                         "hostname" => options['host'],
                         "readable_name" => options['readable_name'],
                         "pingable" => ping,
                         "subject" => options['readable_name'] + ' status notification',
                         "message" => dateTime + ' ' + options['readable_name'] + ' is still ' + presence,
                         "dateTime" => dateTime
                       }
        end
      end
        if options['message_type'] === "ping"
          create_event :payload => {
                       "hostname" => options['host'],
                       "readable_name" => options['readable_name'],
                       "pingable" => ping,
                       "dateTime" => dateTime
                     }
      end
    end


    
    def working?
      event_created_within?(interpolated['expected_update_period_in_days']) && !recent_error_logs?
    end

  end
end
