#noinspection RubyResolve
require File.join(Rails.root.to_s, "lib", "os_captive_portals", "os_captive_portal")

class CaptivePortalWorker < BackgrounDRb::MetaWorker
  set_worker_name :captive_portal_worker

  private

  def CaptivePortalWorker.finalize()
    begin
      puts "[#{Time.now()}] Backgroundrb worker is dying"

      @@os_firewall.stop

      puts "[#{Time.now()}] Backgroundrb worker stopped"
    rescue SystemExit
      # Dirty workaround ... 
      puts "Exit exception caught..."
      retry
    rescue Exception => e
      puts "[#{Time.now()}] Backgroundrb worker finalization failed! (#{e})"
    end

  end

  public 

  def create(args = nil)

    # TO DO: select the appropriate class based on the O.S. type and version
    @@os_firewall = OsControl.get_os_control

    at_exit {
      CaptivePortalWorker.finalize()
    }

    puts "[#{Time.now()}] Starting captive portals"

    start

    CaptivePortal.all.each do |cp|
      puts "[#{Time.now()}] Setting up captive portal '#{cp.name}' for interface #{cp.cp_interface}"

      add_cp(
          {
              :cp_interface => cp.cp_interface,
              :wan_interface => cp.wan_interface,
              :local_http_port => cp.local_http_port,
              :local_https_port => cp.local_https_port,
              :total_upload_bandwidth => cp.total_upload_bandwidth,
              :total_download_bandwidth => cp.total_download_bandwidth,
              :total_upload_bandwidth => cp.total_upload_bandwidth,
              :total_download_bandwidth => cp.total_download_bandwidth
          }
      )
      cp.online_users.each do |ou|
        puts "[#{Time.now()}] Adding user '#{ou.username}'"

        add_user(
            {  :cp_interface => cp.cp_interface,
               :address => ou.ip_address,
               :mac => ou.mac_address,
               :max_upload_bandwidth => ou.max_upload_bandwidth,
               :max_download_bandwidth => ou.max_download_bandwidth
            }
        )
      end
      puts "[#{Time.now()}] captive portal '#{cp.name}' for interface #{cp.cp_interface} added"
    end

  end

  def captive_portals_upkeep
    puts "[#{Time.now()}] Online users upkeep started"

    CaptivePortal.all.each do |cp|
      cp.online_users.each do |ou|
        uploaded_octets, downloaded_octets = get_user_bytes_counters(
            :cp_interface => cp.cp_interface,
            :address => ou.ip_address,
            :mac => ou.mac_address
        )
        uploaded_packets, downloaded_packets = get_user_packets_counters(
            :cp_interface => cp.cp_interface,
            :address => ou.ip_address,
            :mac => ou.mac_address

        )
        ou.update_activity!(uploaded_octets, downloaded_octets, uploaded_packets, downloaded_packets)
      end
      puts "[#{Time.now()}] Processing online users for cp '#{cp.name}'"
      begin
        cp.online_users_upkeep
      rescue Exception => e
        puts "[#{Time.now()}] Exception! (#{e})"
      end
      puts "[#{Time.now()}] Done processing online users for cp '#{cp.name}'"
    end
  end

  def stop

    begin
      @@os_firewall.stop
    rescue Exception => e
      puts "[#{Time.now()}] Problem stopping captive portal firewalling infrastructure! (#{e})"
    end

  end

  def start

    begin
      @@os_firewall.start
    rescue Exception => e
      puts "[#{Time.now()}] Problem starting captive portal firewalling infrastructure!"
    end

  end

  def add_cp(options =  {})
    options[:cp_interface] || raise("BUG: Missing 'cp_interface'")
    options[:wan_interface] || raise("BUG: Missing 'wan_interface'")
    options[:local_http_port] || raise("BUG: Missing 'local_http_port'")
    options[:local_https_port] || raise("BUG: Missing 'local_https_port'")
    # options[:total_upload_bandwidth]
    # options[:total_download_bandwidth]
    # options[:default_upload_bandwidth]
    # options[:default_download_bandwidth]

    begin
      os_cp = @@os_firewall.add_captive_portal(
          options[:cp_interface], options[:wan_interface], options[:local_http_port], options[:local_https_port],
          {
              :total_upload_bandwidth => options[:total_upload_bandwidth],
              :total_download_bandwidth => options[:total_download_bandwidth],
              :default_upload_bandwidth => options[:default_upload_bandwidth],
              :default_download_bandwidth => options[:default_download_bandwidth]
          }
      )
      os_cp.start
    rescue Exception => e
      puts "Problem adding captive portal for interface #{options[:cp_interface]}! (#{e})"
    end
  end

  def remove_cp(options =  {})
    options[:cp_interface] || raise("BUG: Missing 'cp_interface'")

    begin
      os_cp = @@os_firewall.remove_captive_portal(options[:cp_interface])
      os_cp.stop
    rescue Exception => e
      puts "Problem removing captive portal for interface #{options[:cp_interface]}! (#{e})"
    end

  end

  def add_user(options = {})
    options[:cp_interface] || raise("BUG: Missing 'cp_interface'")
    options[:address] || raise("BUG: Missing 'ip'")
    options[:mac] || raise("BUG: Missing 'mac'")
    # options[:max_upload_bandwidth]
    # options[:max_download_bandwidth]

    os_cp = @@os_firewall.get_captive_portal(options[:cp_interface])

    begin
      os_cp.add_user(options[:address], options[:mac],
                     {
                         :max_upload_bandwidth => options[:max_upload_bandwidth],
                         :max_download_bandwidth => options[:max_download_bandwidth]
                     }
      )
    rescue Exception => e
      puts "Problem adding user for captive portal on interface #{options[:cp_interface]}! (#{e})"
    end

  end

  def remove_user(options = {})
    options[:cp_interface] || raise("BUG: Missing 'cp_interface'")
    options[:address] || raise("BUG: Missing 'ip'")
    options[:mac] || raise("BUG: Missing 'mac'")

    os_cp = @@os_firewall.get_captive_portal(options[:cp_interface])

    begin
      os_cp.remove_user(options[:address], options[:mac])
    rescue Exception => e
      puts "Problem removing user for captive portal on interface #{options[:cp_interface]}! (#{e})"
    end

  end

  def get_user_bytes_counters(options = {})
    options[:cp_interface] || raise("BUG: Missing 'cp_interface'")
    options[:address] || raise("BUG: Missing 'address'")
    options[:mac] || raise("BUG: Missing 'mac'")

    os_cp = @@os_firewall.get_captive_portal(options[:cp_interface])

    begin
      os_cp.get_user_bytes_counters(options[:address])
    rescue Exception => e
      puts "Problem getting user bytes counter for '#{options[:address]}-#{options[:mac]}', captive portal on interface #{options[:cp_interface]}! (#{e})"
    end

  end

  def get_user_packets_counters(options = {})
    options[:cp_interface] || raise("BUG: Missing 'cp_interface'")
    options[:address] || raise("BUG: Missing 'ip'")
    options[:mac] || raise("BUG: Missing 'mac'")

    os_cp = @@os_firewall.get_captive_portal(options[:cp_interface])

    begin
      os_cp.get_user_packets_counters(options[:address])
    rescue Exception => e
      puts "Problem getting user packets counter for '#{options[:address]}-#{options[:mac]}', captive portal on interface #{options[:cp_interface]}! (#{e})"
    end

  end

  def get_host_mac_address(options = {})
    options[:address] || raise("BUG: Missing 'address'")

    begin
      mac = @@os_firewall.get_host_mac_address(options[:address])
    rescue Exception => e
      puts "Problem getting MAC address for host '#{options[:address]}' (#{e})"
    end

    mac
  end

  def get_interface(options = {})
    options[:address] || raise("BUG: Missing 'address'")

    begin
      int = @@os_firewall.get_interface(options[:address])
    rescue Exception => e
      puts "Problem getting interface for address '#{options[:address]}' (#{e})"
    end

    int

  end

end
