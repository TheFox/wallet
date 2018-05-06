
require 'pp'

module TheFox::Wallet
	
	class NagiosCommand < Command
		
		NAME = 'nagios'
		STATES = ['OK', 'WARNING', 'CRITICAL', 'UNKNOWN']
		
		def run
			if @options[:entry_type].nil?
				raise '--type option needed.'
			end
			type = @options[:entry_type].to_s
			
			wallet = Wallet.new(@options[:wallet_path])
			entries = wallet.entries(@options[:entry_date], @options[:entry_category].to_s)
			
			sum = entries.inject(0){ |sum1, x|
				s2 = x[1].inject(0){ |sum2, y|
					sum2 + y[type]
				}
				sum1 + s2
			}.to_f
			
			state = 0
			if @options[:nagios_above]
				if sum > @options[:nagios_critical]
					state = 2
				elsif sum > @options[:nagios_warning]
					state = 1
				end
			else
				if sum < @options[:nagios_critical]
					state = 2
				elsif sum < @options[:nagios_warning]
					state = 1
				end
			end
			
			state_name = STATES[state]
			
			perf_data = [
				state_name,	type, sum, # Normal Output
				type, sum, @options[:nagios_warning], @options[:nagios_critical]
			]
			puts '%s: %s=%.2f | %s=%.2f;%.2f;%.2f' % perf_data
			
			state
		end
	end
	
end
