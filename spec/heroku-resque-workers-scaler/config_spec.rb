require 'spec_helper'

describe HerokuResqueAutoScale::Config do

  before(:each) do
    HerokuResqueAutoScale.send(:remove_const, 'Config')
    load 'lib/heroku-resque-workers-scaler/config.rb'
  end

  context 'using the supplied config file' do
    it { HerokuResqueAutoScale::Config.thresholds('myqueue').should be_instance_of Array }
    it { HerokuResqueAutoScale::Config.environments('myqueue').should eql ['production','staging'] }
    it { HerokuResqueAutoScale::Config.worker_name('myqueue').should eql 'myqueue_worker' }

    it { HerokuResqueAutoScale::Config.thresholds('otherqueue').should be_instance_of Array }
    it { HerokuResqueAutoScale::Config.environments('otherqueue').should eql ['staging'] }
    it { HerokuResqueAutoScale::Config.worker_name('otherqueue').should eql 'worker' }
  end

  context 'with missing config values' do
    before :each do
      HerokuResqueAutoScale::Config.stub(:config).and_return({})
    end

    it { HerokuResqueAutoScale::Config.thresholds('myqueue').should be_instance_of Array }
    it { HerokuResqueAutoScale::Config.environments('myqueue').should eql ['production'] }
    it { HerokuResqueAutoScale::Config.worker_name('myqueue').should eql 'worker' }

    it { HerokuResqueAutoScale::Config.thresholds('otherqueue').should be_instance_of Array }
    it { HerokuResqueAutoScale::Config.environments('otherqueue').should eql ['production'] }
    it { HerokuResqueAutoScale::Config.worker_name('otherqueue').should eql 'worker' }

  end
end

