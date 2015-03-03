require 'ruby-notify-my-android'

module Agents
  class NmaAgent < Agent

    cannot_be_scheduled!
    cannot_create_events!

    description <<-MD
      Sent NMA notifications.
    MD

    def default_options
      {
          'expected_receive_period_in_days' => "2",
          'body' => '{{message}}',
          'title' => '{{subject}}',
          'apikey' => 'abc',
          'priority' => 'moderate'
      }
    end

    def working?
      true
    end

    def validate_options
      errors.add(:base, 'body is required') unless options['body'].present?
      errors.add(:base, 'title is required') unless options['title'].present?
      errors.add(:base, 'apikey is required') unless options['apikey'].present?
      errors.add(:base, "priority must be set to very_low, moderate, normal, high or emergency") unless %w[very_low moderate normal high emergency].include?(options['priority'])
    end
    


    def receive(incoming_events)
      incoming_events.each do |event|
        log "Sending notificaction with event #{event.id}"
        NMA.notify do |n|
          n.apikey = options['apikey']
          if options['priority'] === 'very_low'
            n.priority = NMA::Priority::VERY_LOW
          end
          if options['priority'] === 'moderate'
            n.priority = NMA::Priority::MODERATE
          end
          if options['priority'] === 'normal'
            n.priority = NMA::Priority::NORMAL
          end
          if options['priority'] === 'high'
            n.priority = NMA::Priority::HIGH
          end
          if options['priority'] === 'emergency'
            n.priority = NMA::Priority::EMERGENCY
          end
          n.application = "Huginn"
          n.event = interpolated(event)['title']
          n.description = interpolated(event)['body']
        end
      end
    end
  end
end
