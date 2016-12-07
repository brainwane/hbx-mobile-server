module HbxMobileServer
  module Filter

    def self.included base
      base.before do
        content_type :json
      end
    end

  end
end