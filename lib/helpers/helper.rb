#Add common helper methods here.
module Helper

  # Includes the nested modules dynamically.
  def include_modules parent_module
    parent_module.constants.each { |const|
      _module = parent_module.const_get(const)
      if _module.instance_of? Module
        include _module
      end
    }
  end

  # Returns the HTTP header fields
  def request_http_headers env
    env.inject({}) { |acc, (k, v)| acc[$1.downcase] = v if k =~ /^http_(.*)/i; acc }
  end

end