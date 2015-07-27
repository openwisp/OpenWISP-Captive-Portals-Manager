namespace :allow_traffic do
  # allow traffic to all the ip space assigned to an AS
  task :autonomous_system, [:as_number,
                            :captive_portal_id,
                            :protocol,
                            :source_mac_address,
                            :source_host,
                            :source_port,
                            :destination_port,
                            :note] => :environment do |t, args|
    captive_portal = CaptivePortal.find(args[:captive_portal_id])
    protocol = args[:protocol]
    source_mac_address = args[:source_mac_address]
    source_host = args[:source_host]
    source_port =  args[:source_port] != "" ? args[:source_port].to_i : ""
    destination_port = args[:destination_port] != "" ? args[:destination_port].to_i : ""
    note = args[:note]

    output = `whois -h whois.radb.net -- '-i origin #{args[:as_number]}' | grep route:`
    if output == ""
      raise 'no output from whois command, is whois installed?'
    end

    for route in output.split("\n")
      route = route.split("route:")[1].strip()
      rule = AllowedTraffic.new(:protocol => protocol,
                                :source_mac_address => source_mac_address,
                                :source_host => source_host,
                                :source_port => source_port,
                                :destination_host => route,
                                :destination_port => destination_port,
                                :note => note)
      rule.captive_portal = captive_portal

      if rule.valid?
        rule.save!
      else
        raise "Error: #{rule.errors}"
      end
    end
  end
end
