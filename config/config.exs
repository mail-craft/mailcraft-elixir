import Config

# The Swoosh adapter sends through Req, so Swoosh's own HTTP client isn't needed.
config :swoosh, :api_client, false
