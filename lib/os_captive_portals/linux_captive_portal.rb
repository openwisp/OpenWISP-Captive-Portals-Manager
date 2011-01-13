module OsUtils

  public

  # Test to see if a string contains a valid linux interface name
  def is_interface_name?(interface_name)
    (interface_name =~ /\A[a-z_][a-z0-9_\.\-]*\Z/i) != nil
  end

  # Returns the client mac address associated with the passed ipv4/v6 address
  def get_host_mac_address(address)
    mac = nil

    if IPAddr.new(address).ipv4? or IPAddr.new(address).ipv6?
      res = /lladdr\s+(([0-9a-fA-F]{1,2}:){5}[0-9a-fA-F]{1,2})\s+/.match(%x[ip neighbor show #{address}])
      mac = res[1] unless res.nil?
    end

    mac
  end

  # Returns the interface that will be used to reach the passed ip address
  def get_interface(address)
    interface = nil

    if IPAddr.new(address).ipv4? or IPAddr.new(address).ipv6?
      res = /dev\s+([a-zA-Z_][a-zA-Z0-9_\.\-]*)\s+src/.match(%x[ip route get #{address}])
      interface = res[1] unless res.nil?
    end

    interface
  end

  # Returns the first ipv4 address assigned to the passed interface name
  def get_interface_ipv4_address(interface)
    ipv4_address = nil
    if is_interface_name?(interface)
      res = /\s+inet\s+([0-9a-fA-F:\.]+)\/\d+\s+/.match(%x[ip -f inet addr show #{interface} | grep "scope global" | head -1])
      ipv4_address = res[1] unless res.nil?
    end

    ipv4_address
  end

  # Returns the first non-link-local ipv6 address assigned to the passed interface name
  def get_interface_ipv6_address(interface)
    ipv6_address = nil
    if is_interface_name?(interface)
      res = /inet6\s+([0-9a-fA-F:]+)\/\d+\s+scope/.match(%x[ip -f inet6 addr show #{interface} | grep "scope global | head -1"])
      ipv6_address = res[1] unless res.nil?
    end

    ipv6_address
  end

end

module IpTablesUtils
  IPTABLES = "/sbin/iptables"

  def execute_actions(actions, options = {})
    options[:blind] ||= false
    actions.each do |action|
      unless system(action)
        raise "#{caller[2]} - problem executing action: '#{action}'" unless options[:blind]
      end
    end
  end
end

class OsCaptivePortal

  include OsUtils
  include IpTablesUtils

  MARK = "0x10000000/0x10000000"

  public

  # Adds a new captive portal
  def start
    
    @sync.lock(:EX)

    #TO DO: ip6tables rules!

    cp_ip = get_interface_ipv4_address(@cp_interface)

    create_actions = [
        # creating_cp_chains
    "#{IPTABLES} -t nat    -N '_REDIR_#{@cp_interface}'",
    "#{IPTABLES} -t nat    -N '_DNAT_#{@cp_interface}'",
    "#{IPTABLES} -t nat    -N '_NAUT_#{@cp_interface}'",
    "#{IPTABLES} -t filter -N '_FINP_#{@cp_interface}'",
    "#{IPTABLES} -t filter -N '_FOUT_#{@cp_interface}'",
    "#{IPTABLES} -t mangle -N '_MUP_#{@cp_interface}'",
    "#{IPTABLES} -t mangle -N '_MDN_#{@cp_interface}'",
    # creating_http_redirections
    "#{IPTABLES} -t nat -A '_REDIR_#{@cp_interface}' -p tcp --dport 80  -j DNAT --to-destination '#{cp_ip}:#{@local_http_port}'",
    "#{IPTABLES} -t nat -A '_REDIR_#{@cp_interface}' -p tcp --dport 443 -j DNAT --to-destination '#{cp_ip}:#{@local_https_port}'",
    # creating_dns_redirections
    "#{IPTABLES} -t nat -A '_DNAT_#{@cp_interface}'  -p udp --dport 53  -j DNAT --to-destination '#{cp_ip}:#{DNS_PORT}'",
    "#{IPTABLES} -t nat -A '_DNAT_#{@cp_interface}'  -p tcp --dport 53  -j DNAT --to-destination '#{cp_ip}:#{DNS_PORT}'",
    # creating_auth_users_rules
    "#{IPTABLES} -t nat    -A _PRER_NAT -i '#{@cp_interface}' -j '_DNAT_#{@cp_interface}'",
    "#{IPTABLES} -t nat    -A _PRER_NAT -i '#{@cp_interface}' -j '_NAUT_#{@cp_interface}'",
    # creating_accounting_rules
    "#{IPTABLES} -t mangle -A _PRER_MAN -i '#{@cp_interface}' -j '_MUP_#{@cp_interface}'",
    "#{IPTABLES} -t mangle -A _POSR_MAN -o '#{@cp_interface}' -j '_MDN_#{@cp_interface}'",
    # creating_main_filtering
    "#{IPTABLES} -t filter -A _FORW_FIL -i '#{@cp_interface}' -o '#{@wan_interface}' -m connmark --mark '#{MARK}' -j RETURN",
    "#{IPTABLES} -t filter -A _FORW_FIL -i '#{@cp_interface}' -j DROP",
    # creating_redirection_skip_rules
    "#{IPTABLES} -t nat    -A _PRER_NAT -i '#{@cp_interface}' -m connmark --mark '#{MARK}' -j RETURN",
    "#{IPTABLES} -t nat    -A _PRER_NAT -i '#{@cp_interface}' -j '_REDIR_#{@cp_interface}'",
    # creating_filtering
    "#{IPTABLES} -t filter -A _INPU_FIL -i '#{@cp_interface}' -j '_FINP_#{@cp_interface}'",
    "#{IPTABLES} -t filter -A _OUTP_FIL -o '#{@cp_interface}' -j '_FOUT_#{@cp_interface}'",
    # basic_service_filtering_rules
    "#{IPTABLES} -t filter -A '_FINP_#{@cp_interface}' -p tcp --dport #{@local_http_port}  -m state --state NEW,ESTABLISHED -j ACCEPT",
    "#{IPTABLES} -t filter -A '_FINP_#{@cp_interface}' -p tcp --dport #{@local_https_port} -m state --state NEW,ESTABLISHED -j ACCEPT",
    "#{IPTABLES} -t filter -A '_FINP_#{@cp_interface}' -p tcp --dport #{DNS_PORT}          -m state --state NEW,ESTABLISHED -j ACCEPT",
    "#{IPTABLES} -t filter -A '_FINP_#{@cp_interface}' -p udp --dport #{DNS_PORT}          -m state --state NEW,ESTABLISHED -j ACCEPT",
    "#{IPTABLES} -t filter -A '_FINP_#{@cp_interface}' -p udp --sport #{DHCP_SRC_PORT} --dport #{DHCP_DST_PORT} -j ACCEPT",
    "#{IPTABLES} -t filter -A '_FOUT_#{@cp_interface}' -p udp --dport #{DHCP_SRC_PORT} --sport #{DHCP_DST_PORT} -j ACCEPT",
    "#{IPTABLES} -t filter -A '_FOUT_#{@cp_interface}' -m state --state ESTABLISHED -j ACCEPT",
    "#{IPTABLES} -t filter -A '_FOUT_#{@cp_interface}' -j DROP",
    # user_defined_nat_rules
    "#{IPTABLES} -t nat -A _POSR_NAT -i '#{@cp_interface}' -j RETURN"
    ]

    execute_actions(create_actions)

  ensure
    @sync.unlock
  end

  # Removes a captive portal
  # cp_interface is the name of the interface directly connected the clients
  def stop

    @sync.lock(:EX)

    #TO DO: ip6tables rules!

    destroy_actions = [
        # flushing_chains
    "#{IPTABLES} -t nat    -F '_REDIR_#{@cp_interface}'",
    "#{IPTABLES} -t nat    -F '_DNAT_#{@cp_interface}'",
    "#{IPTABLES} -t nat    -F '_NAUT_#{@cp_interface}'",
    "#{IPTABLES} -t filter -F '_FINP_#{@cp_interface}'",
    "#{IPTABLES} -t filter -F '_FOUT_#{@cp_interface}'",
    "#{IPTABLES} -t mangle -F '_MUP_#{@cp_interface}'",
    "#{IPTABLES} -t mangle -F '_MDN_#{@cp_interface}'",
    # deleting_rules
    "#{IPTABLES} -t nat    -D _PRER_NAT -i '#{@cp_interface}' -j '_DNAT_#{@cp_interface}'",
    "#{IPTABLES} -t nat    -D _PRER_NAT -i '#{@cp_interface}' -j '_NAUT_#{@cp_interface}'",
    "#{IPTABLES} -t nat    -D _PRER_NAT -i '#{@cp_interface}' -m connmark --mark '#{MARK}' -j RETURN",
    "#{IPTABLES} -t nat    -D _PRER_NAT -i '#{@cp_interface}' -j '_REDIR_#{@cp_interface}'",
    "#{IPTABLES} -t nat    -D _POSR_NAT -i '#{@cp_interface}' -j RETURN",
    "#{IPTABLES} -t filter -D _INPU_FIL -i '#{@cp_interface}' -j '_FINP_#{@cp_interface}'",
    "#{IPTABLES} -t filter -D _OUTP_FIL -o '#{@cp_interface}' -j '_FOUT_#{@cp_interface}'",
    "#{IPTABLES} -t filter -D _FORW_FIL -i '#{@cp_interface}' -o '#{@wan_interface}' -m connmark --mark '#{MARK}' -j RETURN",
    "#{IPTABLES} -t filter -D _FORW_FIL -i '#{@cp_interface}' -j DROP",
    "#{IPTABLES} -t mangle -D _PRER_MAN -i '#{@cp_interface}' -j '_MUP_#{@cp_interface}'",
    "#{IPTABLES} -t mangle -D _POSR_MAN -o '#{@cp_interface}' -j '_MDN_#{@cp_interface}'",
    # destroying_chains
    "#{IPTABLES} -t nat    -X '_REDIR_#{@cp_interface}'",
    "#{IPTABLES} -t nat    -X '_DNAT_#{@cp_interface}'",
    "#{IPTABLES} -t nat    -X '_NAUT_#{@cp_interface}'",
    "#{IPTABLES} -t filter -X '_FINP_#{@cp_interface}'",
    "#{IPTABLES} -t filter -X '_FOUT_#{@cp_interface}'",
    "#{IPTABLES} -t mangle -X '_MUP_#{@cp_interface}'",
    "#{IPTABLES} -t mangle -X '_MDN_#{@cp_interface}'"
    ]

    execute_actions(destroy_actions)

  ensure
    @sync.unlock
  end

  # Allows a client through the captive portal
  def add_user(client_address, client_mac_address, options = {})

    # TO DO: Traffic shaping!
    options[:max_upload_bandwidth] ||= @default_upload_bandwidth
    options[:max_download_bandwidth] ||= @default_download_bandwidth

    raise("BUG: Invalid mac address '#{client_mac_address}'") unless is_mac_address?(client_mac_address)

    @sync.lock(:EX)

    paranoid_remove_user_actions = []
    add_user_actions = []


    if is_ipv4_address?(client_address)
      paranoid_remove_user_actions = [
          # paranoid_rules
      "#{IPTABLES} -t nat    -D '_NAUT_#{@cp_interface}' -s '#{client_address}' -m mac --mac-source '#{client_mac_address}' -j CONNMARK --set-mark '#{MARK}'",
      "#{IPTABLES} -t mangle -D '_MUP_#{@cp_interface}'  -s '#{client_address}' -m connmark --mark '#{MARK}'",
      "#{IPTABLES} -t mangle -D '_MDN_#{@cp_interface}'  -d '#{client_address}' -m connmark --mark '#{MARK}'",
      ]
      add_user_actions = [
          # adding_user_marking_rule
      "#{IPTABLES} -t nat    -A '_NAUT_#{@cp_interface}' -s '#{client_address}' -m mac --mac-source '#{client_mac_address}' -j CONNMARK --set-mark '#{MARK}'",
      # creating_accounting_user_rules
      "#{IPTABLES} -t mangle -A '_MUP_#{@cp_interface}'  -s '#{client_address}' -m connmark --mark '#{MARK}'",
      "#{IPTABLES} -t mangle -A '_MDN_#{@cp_interface}'  -d '#{client_address}' -m connmark --mark '#{MARK}'"
      ]

    elsif is_ipv6_address?(client_address)
      #TO DO: ip6tables rules!
      not_implemented
    else
      raise("BUG: unexpected address type '#{client_address}'")
    end

    execute_actions(paranoid_remove_user_actions, :blind => true)
    execute_actions(add_user_actions)

  ensure
    @sync.unlock
  end

  # Removes a client
  def remove_user(client_address, client_mac_address)

    raise("BUG: Invalid mac address '#{client_mac_address}'") unless is_mac_address?(client_mac_address)

    @sync.lock(:EX)

    remove_user_actions = []

    if is_ipv4_address?(client_address)
      remove_user_actions = [
          # removing_user_marking_rule
      "#{IPTABLES} -t nat    -D '_NAUT_#{@cp_interface}' -s '#{client_address}' -m mac --mac-source '#{client_mac_address}' -j CONNMARK --set-mark '#{MARK}'",
      # removing_accounting_user_rules
      "#{IPTABLES} -t mangle -D '_MUP_#{@cp_interface}'  -s '#{client_address}' -m connmark --mark '#{MARK}'",
      "#{IPTABLES} -t mangle -D '_MDN_#{@cp_interface}'  -d '#{client_address}' -m connmark --mark '#{MARK}'"
      ]

    elsif is_ipv6_address?(client_address)
      #TO DO: ip6tables rules!
      not_implemented
    else
      raise("BUG: unexpected address type '#{client_address}'")
    end

    execute_actions(remove_user_actions)

  ensure
    @sync.unlock
  end

  # Returns uploaded and downloaded bytes (respectively) for a given client
  def get_user_bytes_counters(client_address)

    @sync.lock(:SH)

    ret = [0,0]
    if is_ipv4_address?(client_address)
      up_match = /\A\s*(\d+)\s+(\d+)\s+/.match(%x[#{IPTABLES} -t mangle -vnx -L '_MUP_#{@cp_interface}' | grep '#{client_address}'])
      dn_match = /\A\s*(\d+)\s+(\d+)\s+/.match(%x[#{IPTABLES} -t mangle -vnx -L '_MDN_#{@cp_interface}' | grep '#{client_address}'])
      ret = [up_match[2].to_i, dn_match[2].to_i]
    elsif is_ipv6_address?(client_address)
      #TO DO: ip6tables rules!
      not_implemented
    else
      raise("BUG: unexpected address type '#{client_address}'")
    end

    ret

  ensure
    @sync.unlock
  end

  # Returns uploaded and downloaded packets (respectively) for a given client
  def get_user_packets_counters(client_address)

    @sync.lock(:SH)

    ret = [0,0]
    if is_ipv4_address?(client_address)
      up_match = /\A\s*(\d+)\s+(\d+)\s+/.match(%x[#{IPTABLES} -t mangle -vnx -L '_MUP_#{@cp_interface}' | grep '#{client_address}'])
      dn_match = /\A\s*(\d+)\s+(\d+)\s+/.match(%x[#{IPTABLES} -t mangle -vnx -L '_MDN_#{@cp_interface}' | grep '#{client_address}'])
      ret = [up_match[1].to_i, dn_match[1].to_i]
    elsif is_ipv6_address?(client_address)
      #TO DO: ip6tables rules!
      not_implemented
    else
      raise("BUG: unexpected address type '#{client_address}'")
    end

    ret

  ensure
    @sync.unlock
  end

end

# This class implements a singleton object that control main Linux OS commands for
# the captive portals
class OsControl

  include OsUtils
  include IpTablesUtils

  public

  # Initializes captive portal firewalling infrastructure
  def start

    #TO DO: ip6tables rules!

    start_actions = [
        # creating_main_chains
    "#{IPTABLES} -t nat    -N _PRER_NAT",
    "#{IPTABLES} -t nat    -N _POSR_NAT",
    "#{IPTABLES} -t filter -N _FORW_FIL",
    "#{IPTABLES} -t filter -N _INPU_FIL",
    "#{IPTABLES} -t filter -N _OUTP_FIL",
    "#{IPTABLES} -t mangle -N _PRER_MAN",
    "#{IPTABLES} -t mangle -N _POSR_MAN",
    # creating_filtering
    "#{IPTABLES} -t filter -I FORWARD     1 -j _FORW_FIL",
    "#{IPTABLES} -t filter -I INPUT       1 -j _INPU_FIL",
    "#{IPTABLES} -t filter -I OUTPUT      1 -j _OUTP_FIL",
    # creating_nat
    "#{IPTABLES} -t nat    -I PREROUTING  1 -j _PRER_NAT",
    "#{IPTABLES} -t nat    -I POSTROUTING 1 -j _POSR_NAT",
    # creating_mangle
    "#{IPTABLES} -t mangle -I PREROUTING  1 -j _PRER_MAN",
    "#{IPTABLES} -t mangle -I POSTROUTING 1 -j _POSR_MAN"
    ]

    execute_actions(start_actions)

  end

  # Finalize captive portal firewalling infrastructure
  def stop

    @captive_portals.each_value do |cp|
      cp.stop
    end

    @captive_portals = Hash.new

    #TO DO: ip6tables rules!

    stop_actions = [
        # destroying_redirections
    "#{IPTABLES} -t nat    -D PREROUTING  -j _PRER_NAT",
    "#{IPTABLES} -t nat    -F _PRER_NAT",
    "#{IPTABLES} -t nat    -X _PRER_NAT",
    # destroying_filtering
    "#{IPTABLES} -t filter -D FORWARD     -j _FORW_FIL",
    "#{IPTABLES} -t filter -F _FORW_FIL",
    "#{IPTABLES} -t filter -X _FORW_FIL",
    "#{IPTABLES} -t filter -D INPUT       -j _INPU_FIL",
    "#{IPTABLES} -t filter -F _INPU_FIL",
    "#{IPTABLES} -t filter -X _INPU_FIL",
    "#{IPTABLES} -t filter -D OUTPUT      -j _OUTP_FIL",
    "#{IPTABLES} -t filter -F _OUTP_FIL",
    "#{IPTABLES} -t filter -X _OUTP_FIL",
    # destroying_nat
    "#{IPTABLES} -t nat    -D POSTROUTING -j _POSR_NAT",
    "#{IPTABLES} -t nat    -F _POSR_NAT",
    "#{IPTABLES} -t nat    -X _POSR_NAT",
    # destroying_mangle
    "#{IPTABLES} -t mangle -D PREROUTING  -j _PRER_MAN",
    "#{IPTABLES} -t mangle -F _PRER_MAN",
    "#{IPTABLES} -t mangle -X _PRER_MAN",
    "#{IPTABLES} -t mangle -D POSTROUTING -j _POSR_MAN",
    "#{IPTABLES} -t mangle -F _POSR_MAN",
    "#{IPTABLES} -t mangle -X _POSR_MAN"
    ]

    execute_actions(stop_actions)

  end

  def add_captive_portal(cp_interface, wan_interface, local_http_port, local_https_port, options = {})
    raise("[BUG] Captive portal for #{cp_interface} already exists!") unless @captive_portals[cp_interface].nil?

    @captive_portals[cp_interface] = OsCaptivePortal.new(
        cp_interface,
        wan_interface,
        local_http_port,
        local_https_port,
        options
    )
  end

end
