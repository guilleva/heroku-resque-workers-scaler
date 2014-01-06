module Resque
  module Plugins
    module Valve
      module Callbacks
        def after_perform_scale_down(*args)
          unless Config.use_ibis?
            scale_down
          end
        end

        def on_failure_scale_down(exception, *args)
          scale_down
        end

        def after_enqueue_scale_up(*args)
          Config.thresholds.reverse_each do |scale_info|
            # Run backwards so it gets set to the highest value first
            # Otherwise if there were 70 jobs, it would get set to 1, then 2, then 3, etc

            # If we have a job count greater than or equal to the job limit for this scale info
            if Scaler.job_count >= scale_info[:job_count]
              # Set the number of workers unless they are already set to a level we want. Don't scale down here!
              if Scaler.workers <= scale_info[:workers]
                Scaler.workers = scale_info[:workers]
              end
              break # We've set or ensured that the worker count is high enough
            end
          end
        end

      end
    end
  end
end