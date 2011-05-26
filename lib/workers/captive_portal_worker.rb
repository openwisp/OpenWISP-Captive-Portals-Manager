#noinspection RubyResolve
require File.join(Rails.root.to_s, "lib", "os_captive_portals", "os_captive_portal")
require 'sync'

class CaptivePortalWorker < BackgrounDRb::MetaWorker
  set_worker_name :captive_portal_worker

  @@sync = Sync.new


  #
  # Internal/private methods
  #

  private

  def CaptivePortalWorker.finalize(instance)
    begin
      puts "[#{Time.now()}] Backgroundrb worker is dying"

      CaptivePortal.all.each do |cp|
        puts "[#{Time.now()}] Shutting down captive portal '#{cp.name}' for interface #{cp.cp_interface}"

        instance.remove_cp(
            :cp_interface => cp.cp_interface,
            :wan_interface => cp.wan_interface,
            :local_http_port => cp.local_http_port,
            :local_https_port => cp.local_https_port,
            :total_upload_bandwidth => cp.total_upload_bandwidth,
            :total_download_bandwidth => cp.total_download_bandwidth,
            :default_upload_bandwidth => cp.default_upload_bandwidth,
            :default_download_bandwidth => cp.default_download_bandwidth
        )

      end

      @@os_firewall.stop

      puts "[#{Time.now()}] Backgroundrb worker stopped"
    rescue SystemExit
      # Dirty workaround ...
      puts "[#{Time.now()}] Exiting, exception caught..."
      retry
    rescue Exception => e
      puts "[#{Time.now()}] Backgroundrb worker finalization failed! (#{e})"
    end

  end

  def bootstrap_cp(args = {})
    args[:cp_interface] || raise("BUG: Missing 'cp_interface'")

    cp = CaptivePortal.find_by_cp_interface(args[:cp_interface]) || raise("BUG: Can't find a CP for interface '#{args[:cp_interface]}'")

    puts "[#{Time.now()}] Setting up allowed traffic for '#{cp.name}' - interface #{cp.cp_interface}"
    cp.allowed_traffics.each do |at|
      puts "[#{Time.now()}] Adding allowed traffic ('#{at.source_mac_address}','#{at.source_host}','#{at.destination_host}','#{at.protocol}','#{at.source_port}','#{at.destination_port}')"

      add_allowed_traffic(
          :cp_interface => cp.cp_interface,
          :source_mac => at.source_mac_address,
          :source_host => at.source_host,
          :destination_host => at.destination_host,
          :protocol => at.protocol,
          :source_port => at.source_port,
          :destination_port => at.destination_port
      )
    end

    puts "[#{Time.now()}] Setting up online users for '#{cp.name}' - interface #{cp.cp_interface}"
    cp.online_users.each do |ou|
      puts "[#{Time.now()}] Adding user '#{ou.username}'"

      add_user(
          :cp_interface => cp.cp_interface,
          :address => ou.ip_address,
          :mac => ou.mac_address,
          :max_upload_bandwidth => ou.max_upload_bandwidth,
          :max_download_bandwidth => ou.max_download_bandwidth
      )
    end
  end

  def shutdown_cp(args = {})
    args[:cp_interface] || raise("BUG: Missing 'cp_interface'")

    cp = CaptivePortal.find_by_cp_interface(args[:cp_interface]) || raise("BUG: Can't find a CP for interface '#{args[:cp_interface]}'")

    puts "[#{Time.now()}] Removing allowed traffics for '#{cp.name}' - interface #{cp.cp_interface}"
    cp.allowed_traffics.each do |at|
      puts "[#{Time.now()}] Removing traffic ('#{at.source_mac_address}','#{at.source_host}','#{at.destination_host}','#{at.protocol}','#{at.source_port}','#{at.destination_port}')"

      remove_allowed_traffic(
          :cp_interface => cp.cp_interface,
          :source_mac => at.source_mac_address,
          :source_host => at.source_host,
          :destination_host => at.destination_host,
          :protocol => at.protocol,
          :source_port => at.source_port,
          :destination_port => at.destination_port
      )
    end

    puts "[#{Time.now()}] Removing online users for '#{cp.name}' - interface #{cp.cp_interface}"
    cp.online_users.each do |ou|
      puts "[#{Time.now()}] Removing user '#{ou.username}'"

      remove_user(
          :cp_interface => cp.cp_interface,
          :address => ou.ip_address,
          :mac => ou.mac_address,
          :max_upload_bandwidth => ou.max_upload_bandwidth,
          :max_download_bandwidth => ou.max_download_bandwidth
      )
    end
  end


  def stop
    @@sync.lock(:EX)

    @@os_firewall.stop

  rescue Exception => e
    puts "[#{Time.now()}] Problem stopping captive portal firewalling infrastructure! (#{e})"
  ensure
    @@sync.unlock
  end

  def start
    @@sync.lock(:EX)

    @@os_firewall.start

  rescue Exception => e
    puts "[#{Time.now()}] Problem starting captive portal firewalling infrastructure!"
  ensure
    @@sync.unlock
  end

  public

  def create(args = nil)

    # Automatically select the appropriate class for the operating system in use
    @@os_firewall = OsControl.get_os_control

    at_exit {
      CaptivePortalWorker.finalize(self)
    }

    puts "[#{Time.now()}] Starting captive portals"

    start

    CaptivePortal.all.each do |cp|
      puts "[#{Time.now()}] Setting up captive portal '#{cp.name}' for interface #{cp.cp_interface}"

      add_cp(
          :cp_interface => cp.cp_interface,
          :wan_interface => cp.wan_interface,
          :local_http_port => cp.local_http_port,
          :local_https_port => cp.local_https_port,
          :total_upload_bandwidth => cp.total_upload_bandwidth,
          :total_download_bandwidth => cp.total_download_bandwidth,
          :default_upload_bandwidth => cp.default_upload_bandwidth,
          :default_download_bandwidth => cp.default_download_bandwidth
      )

      puts "[#{Time.now()}] captive portal '#{cp.name}' for interface #{cp.cp_interface} added"
    end

  end

  #
  # Following methods are called from the web app
  #

  def add_cp(options = {})
    options[:cp_interface] || raise("BUG: Missing 'cp_interface'")
    options[:wan_interface] || raise("BUG: Missing 'wan_interface'")
    options[:local_http_port] || raise("BUG: Missing 'local_http_port'")
    options[:local_https_port] || raise("BUG: Missing 'local_https_port'")
    # options[:total_upload_bandwidth]
    # options[:total_download_bandwidth]
    # options[:default_upload_bandwidth]
    # options[:default_download_bandwidth]

    @@sync.lock(:EX)

    @@os_firewall.add_captive_portal(
        options[:cp_interface], options[:wan_interface], options[:local_http_port], options[:local_https_port],
        {
            :total_upload_bandwidth => options[:total_upload_bandwidth],
            :total_download_bandwidth => options[:total_download_bandwidth],
            :default_upload_bandwidth => options[:default_upload_bandwidth],
            :default_download_bandwidth => options[:default_download_bandwidth]
        }
    )
    bootstrap_cp(:cp_interface => options[:cp_interface])

  rescue Exception => e
    puts "[#{Time.now()}] Problem adding captive portal for interface #{options[:cp_interface]}! (#{e})"
  ensure
    @@sync.unlock
  end

  def remove_cp(options = {})
    options[:cp_interface] || raise("BUG: Missing 'cp_interface'")

    @@sync.lock(:EX)

    shutdown_cp(:cp_interface => options[:cp_interface])
    @@os_firewall.remove_captive_portal(options[:cp_interface])

  rescue Exception => e
    puts "[#{Time.now()}] Problem removing captive portal for interface #{options[:cp_interface]}! (#{e})"
  ensure
    @@sync.unlock
  end

  def add_allowed_traffic(options = {})
    options[:cp_interface] || raise("BUG: Missing 'cp_interface'")

    @@sync.lock(:EX)

    os_cp = @@os_firewall.get_captive_portal(options[:cp_interface])
    os_cp.add_allowed_traffic(
        :source_mac => options[:source_mac],
        :source_host => options[:source_host],
        :destination_host => options[:destination_host],
        :protocol => options[:protocol],
        :source_port => options[:source_port],
        :destination_port => options[:destination_port]
    )

  rescue Exception => e
    puts "[#{Time.now()}] Problem adding exception for captive portal on interface #{options[:cp_interface]}! (#{e})"
  ensure
    @@sync.unlock
  end

  def remove_allowed_traffic(options = {})
    options[:cp_interface] || raise("BUG: Missing 'cp_interface'")

    @@sync.lock(:EX)

    os_cp = @@os_firewall.get_captive_portal(options[:cp_interface])
    os_cp.remove_allowed_traffic(
        :source_mac => options[:source_mac],
        :source_host => options[:source_host],
        :destination_host => options[:destination_host],
        :protocol => options[:protocol],
        :source_port => options[:source_port],
        :destination_port => options[:destination_port]
    )

  rescue Exception => e
    puts "[#{Time.now()}] Problem removing exception for captive portal on interface #{options[:cp_interface]}! (#{e})"
  ensure
    @@sync.unlock
  end

  def add_user(options = {})
    options[:cp_interface] || raise("BUG: Missing 'cp_interface'")
    options[:address] || raise("BUG: Missing 'ip'")
    options[:mac] || raise("BUG: Missing 'mac'")
    # options[:max_upload_bandwidth]
    # options[:max_download_bandwidth]

    @@sync.lock(:EX)

    os_cp = @@os_firewall.get_captive_portal(options[:cp_interface])
    os_cp.add_user(options[:address], options[:mac],
                   {
                       :max_upload_bandwidth => options[:max_upload_bandwidth],
                       :max_download_bandwidth => options[:max_download_bandwidth]
                   }
    )

  rescue Exception => e
    puts "[#{Time.now()}] Problem adding user for captive portal on interface #{options[:cp_interface]}! (#{e})"
  ensure
    @@sync.unlock
  end

  def remove_user(options = {})
    options[:cp_interface] || raise("BUG: Missing 'cp_interface'")
    options[:address] || raise("BUG: Missing 'ip'")
    options[:mac] || raise("BUG: Missing 'mac'")
    # options[:max_upload_bandwidth]
    # options[:max_download_bandwidth]

    @@sync.lock(:EX)

    os_cp = @@os_firewall.get_captive_portal(options[:cp_interface])
    os_cp.remove_user(options[:address], options[:mac],
                      {
                          :max_upload_bandwidth => options[:max_upload_bandwidth],
                          :max_download_bandwidth => options[:max_download_bandwidth]
                      }
    )

  rescue Exception => e
    puts "[#{Time.now()}] Problem removing user for captive portal on interface #{options[:cp_interface]}! (#{e})"
  ensure
    @@sync.unlock
  end

  def get_user_bytes_counters(options = {})
    options[:cp_interface] || raise("BUG: Missing 'cp_interface'")
    options[:address] || raise("BUG: Missing 'address'")
    options[:mac] || raise("BUG: Missing 'mac'")

    @@sync.lock(:SH)

    os_cp = @@os_firewall.get_captive_portal(options[:cp_interface])
    os_cp.get_user_bytes_counters(options[:address])

  rescue Exception => e
    puts "[#{Time.now()}] Problem getting user bytes counter for '#{options[:address]}-#{options[:mac]}', captive portal on interface #{options[:cp_interface]}! (#{e})"
  ensure
    @@sync.unlock
  end

  def get_user_packets_counters(options = {})
    options[:cp_interface] || raise("BUG: Missing 'cp_interface'")
    options[:address] || raise("BUG: Missing 'ip'")
    options[:mac] || raise("BUG: Missing 'mac'")

    @@sync.lock(:SH)

    os_cp = @@os_firewall.get_captive_portal(options[:cp_interface])
    os_cp.get_user_packets_counters(options[:address])

  rescue Exception => e
    puts "[#{Time.now()}] Problem getting user packets counter for '#{options[:address]}-#{options[:mac]}', captive portal on interface #{options[:cp_interface]}! (#{e})"
  ensure
    @@sync.unlock
  end

  def get_host_mac_address(options = {})
    options[:address] || raise("BUG: Missing 'address'")

    @@sync.lock(:SH)

    mac = @@os_firewall.get_host_mac_address(options[:address])
    return mac

  rescue Exception => e
    puts "[#{Time.now()}] Problem getting MAC address for host '#{options[:address]}' (#{e})"
  ensure
    @@sync.unlock
  end

  def get_interface(options = {})
    options[:address] || raise("BUG: Missing 'address'")

    @@sync.lock(:SH)

    int = @@os_firewall.get_interface(options[:address])
    return int

  rescue Exception => e
    puts "[#{Time.now()}] Problem getting interface for address '#{options[:address]}' (#{e})"
  ensure
    @@sync.unlock
  end

  def accounting_start(options = {})
    options[:acct_server_id] || raise("BUG: Missing 'acct_server_id'")
    options[:username] || raise("BUG: Missing 'username'")
    options[:sessionid] || raise("BUG: Missing 'sessionid'")
    options[:ip] || raise("BUG: Missing 'ip'")
    options[:mac] || raise("BUG: Missing 'mac'")

    radius_acct_server = RadiusAcctServer.find(options[:acct_server_id])
    radius_acct_server.accounting_start(
        :username => options[:username],
        :sessionid => options[:sessionid],
        :ip => options[:ip],
        :mac => options[:mac],
        :radius => options[:radius]
    )

  rescue Exception => e
    puts "[#{Time.now()}] Problem sending accounting start RADIUS message for '#{options[:username]}-#{options[:ip]}-#{options[:mac]}' (#{e})"
  end

  def accounting_stop(options = {})
    options[:acct_server_id] || raise("BUG: Missing 'acct_server_id'")
    options[:username] || raise("BUG: Missing 'username'")
    options[:sessionid] || raise("BUG: Missing 'sessionid'")
    options[:ip] || raise("BUG: Missing 'ip'")
    options[:mac] || raise("BUG: Missing 'mac'")
    options[:session_time] || raise("BUG: Missing 'session_time'")
    options[:session_uploaded_octets] || raise("BUG: Missing 'session_uploaded_octets'")
    options[:session_uploaded_packets] || raise("BUG: Missing 'session_uploaded_packets'")
    options[:session_downloaded_octets] || raise("BUG: Missing 'session_downloaded_octets'")
    options[:session_downloaded_packets] || raise("BUG: Missing 'session_downloaded_packets'")

    radius_acct_server = RadiusAcctServer.find(options[:acct_server_id])
    radius_acct_server.accounting_stop(
        :username => options[:username],
        :sessionid => options[:sessionid],
        :ip => options[:ip],
        :mac => options[:mac],
        :radius => options[:radius],
        :session_time => options[:session_time],
        :session_uploaded_octets => options[:session_uploaded_octets],
        :session_uploaded_packets => options[:session_uploaded_packets],
        :session_downloaded_octets => options[:session_downloaded_octets],
        :session_downloaded_packets => options[:session_downloaded_packets],
        :termination_cause => options[:termination_cause]
    )

  rescue Exception => e
    puts "[#{Time.now()}] Problem sending accounting stop RADIUS message for '#{options[:username]}-#{options[:ip]}-#{options[:mac]}' (#{e})"
  end


  #
  # Cron jobs methods
  #

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
        cp.online_users.each do |online_user|

          to_be_disconnected = false
          reason = nil

          if online_user.inactive?
            to_be_disconnected = true
            reason = RadiusAcctServer::SESSION_TERMINATE_CAUSE[:Idle_timeout]
            puts "[#{Time.now()}] Inactive user detected for cp '#{cp.name}': '#{online_user.username}'"
          elsif online_user.expired?
            to_be_disconnected = true
            reason = RadiusAcctServer::SESSION_TERMINATE_CAUSE[:Session_timeout]
            puts "[#{Time.now()}] Session timeout hit by '#{online_user.username}' for cp '#{cp.name}'"
          elsif online_user.RADIUS_user?
            reply = cp.radius_auth_server.authenticate(
                :username => online_user.username,
                :password => online_user.password,
                :ip => online_user.ip_address,
                :mac => online_user.mac_address
            )
            to_be_disconnected = !reply[:authenticated]
            if to_be_disconnected
              puts "[#{Time.now()}] User '#{online_user.username}' lost can't stay logged in anymore for cp '#{cp.name}'"
              reason = RadiusAcctServer::SESSION_TERMINATE_CAUSE[:User_Error]
            end
          end

          if to_be_disconnected
            cp.deauthenticate_user(online_user, reason)
            next
          else
            unless cp.radius_acct_server.nil?
              cp.radius_acct_server.accounting_update(
                  :username => online_user.username,
                  :sessionid => online_user.cp_session_token,
                  :session_time => online_user.session_time_interval,
                  :session_uploaded_octets => online_user.uploaded_octets,
                  :session_uploaded_packets => online_user.uploaded_packets,
                  :session_downloaded_octets => online_user.downloaded_octets,
                  :session_downloaded_packets => online_user.downloaded_packets,
                  :ip => online_user.ip_address,
                  :mac => online_user.mac_address,
                  :radius => online_user.RADIUS_user?
              )
            end
          end
        end
      rescue Exception => e
        puts "[#{Time.now()}] Exception! (#{e})"
      end
      puts "[#{Time.now()}] Done processing online users for cp '#{cp.name}'"
    end
  end

end
