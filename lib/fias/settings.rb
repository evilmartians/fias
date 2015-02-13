module Fias
  class Settings
    def initialize(yaml)
      @yaml = YAML.load_file(yaml)
    end
  end
end
