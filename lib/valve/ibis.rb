module Resque
  module Plugins
    module Valve
      module Ibis
        ## Legend has it Ibis are the last birds out before a hurricane,
        ## and the first birds back.
        class IbisJob

          @queue = "~scaling-ibis"

          def self.perform(timeout)
            unless self.pending == 0
              go_around_again
              return "Oops. There are new jobs pending."
            end

            ## Pending is 0, because the previous conditional wasn't met.
            pending_before = 0

            ## How many are processing?
            processing_before = self.processing

            if processing_before.count == 0
              ## Nothing is processing or pending.
              ## Our work is done
              shut_it_down
            else
              ## Wait to see if anything finishes up.
              wait_a_bit

              ## What about now?
              pending_after = self.pending
              processing_after = self.processing

              ## Did anything change?
              ## If there are still no pending jobs and
              ## processing jobs haven't changed then
              if pending_before == pending_after && hung?(processing_before, processing_after) && self.pending == 0
                shut_it_down # Scale down
              else
                go_around_again
              end
            end
          end

          def self.ibis_jobs_outstanding
            Resque.size(@queue) + Resque.workers.find_all{ |w| w.processing["queue"] == @queue }.count
          end

          def self.pending
            Resque.queues.reject{ |q| q == @queue}.inject(0){ |accum, item| accum += Resque.size(item) }
          end

          def self.processing
            Resque.workers.find_all{ |w| w.processing["queue"] and w.processing["queue"] != @queue }
          end



          private
            def wait_a_bit
              ## Wait a bit
              Kernel.sleep Config.polling_interval
            end

            def shut_it_down
              # Scale it down
              Scaler.workers = 0
            end

            def go_around_again
              Resque.enqueue(self, timeout)
            end

            def frequency
              p = Hash.new(0); each{ |v| p[v] += 1 }; p
            end

            def hung?(before, after)
              before.frequency == after.frequency
            end

        end
      end
    end
  end
end