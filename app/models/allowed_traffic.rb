class AllowedTraffic < ActiveRecord::Base

  belongs_to :captive_portal

  validates_inclusion_of :protocol, :in => [ 'tcp', 'udp' ], :allow_nil => true, :allow_blank => true
  validates_format_of :source_mac_address, :with => /\A([0-9a-f]{2}:){5}[0-9a-f]{2}\Z/, :allow_nil => true, :allow_blank => true
  validates_format_of :source_host, :with => /\A[a-zA-Z0-9:\-\.]+\Z/, :allow_nil => true, :allow_blank => true
  validates_numericality_of :source_port, :greater_than => 0, :less_than_or_equal_to => 65535,
                            :allow_nil => true, :allow_blank => true

  validates_format_of :destination_host, :with => /\A[a-zA-Z0-9:\-\.]+\Z/, :allow_nil => true, :allow_blank => true
  validates_numericality_of :destination_port, :greater_than => 0, :less_than_or_equal_to => 65535,
                            :allow_nil => true, :allow_blank => true

  after_create {
    worker = MiddleMan.worker(:captive_portal_worker)
    worker.add_allowed_traffic(
        :args => {
            :cp_interface => self.captive_portal.cp_interface,
            :source_mac => self.source_mac_address,
            :source_host => self.source_host,
            :destination_host => self.destination_host,
            :protocol => self.protocol,
            :source_port => self.source_port,
            :destination_port => self.destination_port
        }
    )
  }

  before_destroy {
      # This could be invoked from a worker, so we must use async_ here to avoid deadlocks
    worker = MiddleMan.worker(:captive_portal_worker)
    worker.async_remove_allowed_traffic(
        :args => {
            :cp_interface => self.captive_portal.cp_interface,
            :source_mac => self.source_mac_address,
            :source_host => self.source_host,
            :destination_host => self.destination_host,
            :protocol => self.protocol,
            :source_port => self.source_port,
            :destination_port => self.destination_port
        }
    )
  }

end
