defmodule MockGoogleMapsClient do
  @moduledoc """
  Mock implementation of GoogleMapsClient for testing purposes.
  """

  def geocode_location(location) do
    cond do
      String.contains?(String.downcase(location), "san francisco") or location == "94102" ->
        {:ok, %{lat: 37.7749, lng: -122.4194}}

      String.contains?(String.downcase(location), "austin") ->
        {:ok, %{lat: 30.2672, lng: -97.7431}}

      String.match?(location, ~r/^\d{5}$/) ->
        {:ok, %{lat: 39.8283, lng: -98.5795}}

      String.contains?(String.downcase(location), "invalid") ->
        {:error, "Location not found"}

      true ->
        {:ok, %{lat: 39.8283, lng: -98.5795}}
    end
  end

  def find_nearby_places(lat, lng, _radius \\ 1000) do
    places = cond do
      # San Francisco area
      lat > 37.0 and lat < 38.0 and lng < -122.0 and lng > -123.0 ->
        [
          %{name: "Union Square", address: "333 Post Street, San Francisco", street_address: "333 Post Street", city: "San Francisco", state: "CA", zip: nil, lat: 37.7880, lng: -122.4074},
          %{name: "Chinatown Gate", address: "Grant Avenue & Bush Street, San Francisco", street_address: "Grant Avenue & Bush Street", city: "San Francisco", state: "CA", zip: nil, lat: 37.7909, lng: -122.4056},
          %{name: "Ferry Building", address: "1 Ferry Building, San Francisco", street_address: "1 Ferry Building", city: "San Francisco", state: "CA", zip: nil, lat: 37.7955, lng: -122.3937},
          %{name: "Lombard Street", address: "1000 Lombard Street, San Francisco", street_address: "1000 Lombard Street", city: "San Francisco", state: "CA", zip: nil, lat: 37.8021, lng: -122.4187},
          %{name: "Golden Gate Park", address: "501 Stanyan Street, San Francisco", street_address: "501 Stanyan Street", city: "San Francisco", state: "CA", zip: nil, lat: 37.7694, lng: -122.4862}
        ]

      # Austin area
      lat > 30.0 and lat < 31.0 and lng < -97.0 and lng > -98.0 ->
        [
          %{name: "Texas State Capitol", address: "1100 Congress Avenue, Austin", street_address: "1100 Congress Avenue", city: "Austin", state: "TX", zip: nil, lat: 30.2747, lng: -97.7404},
          %{name: "South by Southwest", address: "301 6th Street, Austin", street_address: "301 6th Street", city: "Austin", state: "TX", zip: nil, lat: 30.2672, lng: -97.7431},
          %{name: "Zilker Park", address: "2100 Barton Springs Road, Austin", street_address: "2100 Barton Springs Road", city: "Austin", state: "TX", zip: nil, lat: 30.2642, lng: -97.7731},
          %{name: "Lady Bird Lake", address: "900 Town Lake Circle, Austin", street_address: "900 Town Lake Circle", city: "Austin", state: "TX", zip: nil, lat: 30.2500, lng: -97.7500},
          %{name: "University of Texas", address: "110 Inner Campus Drive, Austin", street_address: "110 Inner Campus Drive", city: "Austin", state: "TX", zip: nil, lat: 30.2849, lng: -97.7341}
        ]

      true ->
        [
          %{name: "City Hall", address: "123 Main Street, Anytown", street_address: "123 Main Street", city: "Anytown", state: "US", zip: nil, lat: 39.8283, lng: -98.5795},
          %{name: "Public Library", address: "456 Oak Avenue, Anytown", street_address: "456 Oak Avenue", city: "Anytown", state: "US", zip: nil, lat: 39.8290, lng: -98.5800},
          %{name: "Community Park", address: "789 Pine Road, Anytown", street_address: "789 Pine Road", city: "Anytown", state: "US", zip: nil, lat: 39.8300, lng: -98.5790}
        ]
    end

    {:ok, places}
  end

  def reverse_geocode_for_zip(_street_address, city, state) do
    # Return realistic zip codes for known cities
    case {city, state} do
      {"San Francisco", "CA"} -> {:ok, Enum.random(["94102", "94103", "94104", "94105", "94107", "94108", "94109", "94110", "94111", "94112"])}
      {"Austin", "TX"} -> {:ok, Enum.random(["78701", "78702", "78703", "78704", "78705", "78712", "78717", "78721", "78722", "78723"])}
      {"Louisville", "KY"} -> {:ok, Enum.random(["40202", "40203", "40204", "40205", "40206", "40207", "40208", "40210", "40211", "40212"])}
      {_, "CA"} -> {:ok, Enum.random(["90210", "90211", "91901", "92101", "93101", "94102", "95101"])}
      {_, "TX"} -> {:ok, Enum.random(["75201", "77001", "78701", "79901", "73301"])}
      {_, "KY"} -> {:ok, Enum.random(["40202", "41001", "42101", "43081"])}
      {_, "NY"} -> {:ok, Enum.random(["10001", "10002", "10003", "10004", "10005"])}
      {_, "FL"} -> {:ok, Enum.random(["33101", "32801", "33301", "34601"])}
      _ -> {:ok, Enum.random(["12345", "23456", "34567", "45678", "56789"])}
    end
  end
end