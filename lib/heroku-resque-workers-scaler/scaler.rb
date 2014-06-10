require 'platform-api'

module HerokuResqueAutoScale
  module Scaler

    class << self
      @@heroku = PlatformAPI.connect(ENV['HEROKU_API_KEY'])

      def workers(queue)
        return -1 unless authorized?(queue)
        puts "#{ENV['HEROKU_API_KEY']} #{app_name} #{worker_name(queue)}"
        result = @@heroku.formation.info(app_name, worker_name(queue))
        result['quantity']
      end

      def scale(queue, quantity)
        return unless authorized?(queue)

        quantity = quantity.to_i

        if safe_mode? and setting_this_number_of_workers_will_scale_down?(queue, quantity)
          return unless all_jobs_hve_been_processed?(queue)
        end
        result = @@heroku.formation.update(app_name, worker_name(queue), {quantity: quantity})
        result['quantity'] == quantity
      end

      def job_count(queue)
        Resque.size(queue).to_i
      end

      def working_job_count(queue)
        Resque::Worker.working.count{|worker| worker.queues.include?(queue) }
      end

      protected

      def app_name
        ENV['HEROKU_APP_NAME']
      end

      def setting_this_number_of_workers_will_scale_down?(queue, quantity)
        quantity < workers(queue)
      end

      def safe_mode?
        ENV['SAFE_MODE'] and ENV['SAFE_MODE'] == 'true'
      end

      def all_jobs_hve_been_processed?(queue)
        job_count(queue) + working_job_count(queue) == 0
      end

      private

      def authorized?(queue)
        HerokuResqueAutoScale::Config.environments(queue).include? Rails.env.to_s
      end

      def worker_name(queue)
        HerokuResqueAutoScale::Config.worker_name(queue)
      end
    end
  end

  def after_perform_scale_down(*args)
    scale_down
  end

  def on_failure_scale_down(exception, *args)
    scale_down
  end

  def after_enqueue_scale_up(*args)
    HerokuResqueAutoScale::Config.thresholds(@queue.to_s).reverse_each do |scale_info|
      # Run backwards so it gets set to the highest value first
      # Otherwise if there were 70 jobs, it would get set to 1, then 2, then 3, etc

      # If we have a job count greater than or equal to the job limit for this scale info
      if Scaler.job_count(@queue.to_s) >= scale_info[:job_count]
        # Set the number of workers unless they are already set to a level we want. Don't scale down here!
        if Scaler.workers(@queue.to_s) <= scale_info[:workers]
          Scaler.scale @queue.to_s, scale_info[:workers]
        end
        break # We've set or ensured that the worker count is high enough
      end
    end
  end

  private

  def scale_down
    # Nothing fancy, just shut everything down if we have no pending jobs
    # and one working job (which is this job)
    Scaler.scale(@queue.to_s,  0) if Scaler.job_count(@queue.to_s).zero? && Scaler.working_job_count(@queue.to_s) == 1
  end
end