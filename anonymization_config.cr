# This is an empty anonymization config
# It can be used for databases which do not need anonymization or in dump-only mode

require "./src/crystal-sync/runner"

AnonymizationConfig.define {}

CrystalSync::Runner.run
