module Resque
  module Plugins
    module Valve
      module Scaler
        class << self

          def workers
            return -1 unless authorized?
            Config.heroku_client.get_app(ENV['HEROKU_APP_NAME']).body['workers'].to_i
          end

          def workers=(qty)
            return unless authorized?
            if safe_mode? and down? qty
              return unless safer?
            end
            Config.heroku_client.post_ps_scale(ENV['HEROKU_APP_NAME'], 'worker', qty.to_s)
          end

          def job_count
            Resque.info[:pending].to_i
          end

          def working_job_count
            Resque.info[:working].to_i
          end

          protected

          def down? qty
            qty < workers
          end

          def safer?
            job_count + working_job_count == 0
          end

          private

          def authorized?
            Config.environments.include? Rails.env.to_s
          end

        end
      end
    end
  end
end
