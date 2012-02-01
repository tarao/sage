require 'app'
require 'worker'
require 'fileutils'

class Worker
  class Batch < Worker
    def initialize(user, algorithm) @user=user; @algorithm=algorithm end

    def [](x)
      script = App::SCRIPT['batch_recommend_curators']
      FileUtils.mkdir_p(App.user_dir(@user))
      log = App::Path.new(@user, @algorithm).log
      ENV['DEBUG'] = 1.to_s
      system("#{script} '#{@user}' '#{@algorithm}' 2> #{log}")
    end
  end
end
