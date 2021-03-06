#
# Report
#
# :fields is a comma seperated list of fields to report on,
# and are taken from the RestConnection Server objects directly.
#
# Example: ip-address,name,href,private-ip-address,aws-id,ec2-instance-type,dns-name,locked
#
module Chimp
  class ExecReport < Executor
    attr_reader :server, :fields
    attr_writer :server, :fields
    
    def info
      return "report on server #{fields.inspect}"
    end

    def run
      run_with_retry do
        output = []
        
        #
        # The API and rest_connection return very different data
        # depending on the API call made (here, tag query vs. array)
        # so the logic to load the server information and tags is
        # messy.
        #
        begin
          s = Server.find(@server.href)
          s.settings
          response = ::Tag.search_by_href(s.current_instance_href)
        rescue Exception => ex
          s = @server
          response = ::Tag.search_by_href(s.href)
        end

        s.tags = [] unless s.tags
        response.each do |t|
          s.tags += [ t['name'] ]
        end
        
        @fields.split(",").each do |f|
          if f =~ /^tag=([^,]+)/
            tag_search_string = $1
            s.tags.each do |tag|
              output << tag if tag =~ /^#{tag_search_string}/
            end
          else
            output << s.params[f]
          end
        end
        
        puts output.join(",")
      end
    end
  end
end
