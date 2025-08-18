import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :random_address_finder, RandomAddressFinderWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "dFiMIlxeFHwCI0RQsVrMFNNdiTUjLj5fVAn6Q7mmEiBOTfoM4Dh0JhN0yov+uGR+",
  server: false

# In test we don't send emails
config :random_address_finder, RandomAddressFinder.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Use mock client for tests
config :random_address_finder, :google_maps_client, MockGoogleMapsClient
