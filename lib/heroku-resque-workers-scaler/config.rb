module HerokuResqueAutoScale
  module Config
    extend self

    CONFIG_FILE_NAME = 'scaler_config.yml'

    def thresholds(queue)
      @thresholds ||= begin
        if config_file? && config.has_key?(queue) && config[queue].has_key?('thresholds')
          config[queue]['thresholds']
        else
          [{workers:1,job_count:1},{workers:2,job_count:15},{workers:3,job_count:25},{workers:4,job_count:40},{workers:5,job_count:60}]
        end
      end
    end

    def environments(queue)
      @environments ||= begin
        if config_file? && config.has_key?(queue) && config[queue].has_key?('environments')
          config[queue]['environments']
        else
          [ 'production' ]
        end
      end
    end

    def worker_name(queue)
      @worker_name ||= {}
      @worker_name[queue] ||= begin
        if config_file? && config.has_key?(queue) && config[queue].has_key?('worker_name')
          config[queue]['worker_name']
        else
          'worker'
        end
      end
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
