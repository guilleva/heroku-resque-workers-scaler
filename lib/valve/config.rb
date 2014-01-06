require 'heroku-api'

module Resque
  module Plugins
    module Valve
      module Config
        extend self

        CONFIG_FILE_NAME = 'scaler_config.yml'

        def heroku_client
          @@heroku ||= Heroku::API.new(api_key: ENV['HEROKU_API_KEY'])
        end

        def thresholds
          @thresholds ||= begin
            if config_file?
              config['thresholds']
            else
              [{workers:1,job_count:1},{workers:2,job_count:15},{workers:3,job_count:25},{workers:4,job_count:40},{workers:5,job_count:60}]
            end
          end
        end

        def environments
          @environments ||= begin
            if config_file?
              config['environments']
            else
              [ 'production' ]
            end
          end
        end

        def polling_interval
          60.seconds
        end

        def use_ibis?
          ENV['USE_IBIS'] and ENV['USE_IBIS'] == 'true'
        end

        def safe_mode?
          ENV['SAFE_MODE'] and ENV['SAFE_MODE'] == 'true'
        end

        private

        def config_file?
          @config_file ||= override? || File.exists?(CONFIG_FILE_NAME)
        end

        def config
          @config ||= override? ? YAML.load_file(Rails.root.join("config/#{CONFIG_FILE_NAME}").to_s) : YAML.load_file(CONFIG_FILE_NAME)
        end

        def override?
          File.exists?(Rails.root.join("config/#{CONFIG_FILE_NAME}").to_s) rescue false
        end
      end
    end
  end
end
