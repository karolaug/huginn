require 'ruby-notify-my-android'

module Agents
  class NMAAgent < Agent

    cannot_be_scheduled!
    cannot_create_events!

    description <<-MD
      Sent NMA notifications.
    MD

    def default_options
      {
          'expected_receive_period_in_days' => "2",
          'body' => 'Your message',
          'apikey' => 'abc'
      }
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        log "Sending notificaction with event #{event.id}"
        NMA.notify do |n|
          n.apikey = options['apikey']
          n.priority = NMA::Priority::MODERATE
          n.application = "Huginn"
          n.event = "Notification"
          n.description = interpolated(event)['body']
        end
      end
    end
  end
end
