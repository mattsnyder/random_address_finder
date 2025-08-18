defmodule RandomAddressFinder.GoogleMapsClient do
  @moduledoc """
  Client for interacting with Google Maps APIs to geocode locations and find nearby places.
  """

  @geocoding_url "https://maps.googleapis.com/maps/api/geocode/json"
  @places_url "https://maps.googleapis.com/maps/api/place/nearbysearch/json"

  def geocode_location(location) do
    api_key = get_api_key()

    if api_key == "your_api_key_here" or Mix.env() == :test do
      mock_geocode(location)
    else
      real_geocode(location, api_key)
    end
  end

  defp mock_geocode(location) do
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

  defp real_geocode(location, api_key) do
    params = %{
      address: location,
      key: api_key
    }

    case Req.get(@geocoding_url, params: params) do
      {:ok, %{status: 200, body: %{"status" => "OK", "results" => [result | _]}}} ->
        lat = get_in(result, ["geometry", "location", "lat"])
        lng = get_in(result, ["geometry", "location", "lng"])
        {:ok, %{lat: lat, lng: lng}}

      {:ok, %{status: 200, body: %{"status" => "ZERO_RESULTS"}}} ->
        {:error, "Location not found"}

      {:ok, %{status: 200, body: %{"status" => status}}} ->
        {:error, "API error: #{status}"}

      {:error, reason} ->
        {:error, "HTTP error: #{inspect(reason)}"}
    end
  end

  def find_nearby_places(lat, lng, radius \\ 1000) do
    api_key = get_api_key()

    if api_key == "your_api_key_here" or Mix.env() == :test do
      mock_nearby_places(lat, lng)
    else
      real_nearby_places(lat, lng, radius, api_key)
    end
  end

  defp mock_nearby_places(lat, lng) do
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

  defp real_nearby_places(lat, lng, radius, api_key) do
    params = %{
      location: "#{lat},#{lng}",
      radius: radius,
      type: "establishment",
      key: api_key
    }

    case Req.get(@places_url, params: params) do
      {:ok, %{status: 200, body: %{"status" => "OK", "results" => results}}} ->
        IO.inspect(results, label: "Nearby Places Results")
        places = Enum.map(results, &parse_place/1)
        {:ok, places}

      {:ok, %{status: 200, body: %{"status" => "ZERO_RESULTS"}}} ->
        {:ok, []}

      {:ok, %{status: 200, body: %{"status" => status}}} ->
        {:error, "API error: #{status}"}

      {:error, reason} ->
        {:error, "HTTP error: #{inspect(reason)}"}
    end
  end

  defp parse_place(place_data) do
    vicinity = Map.get(place_data, "vicinity", "Unknown Address")
    plus_code = get_in(place_data, ["plus_code", "compound_code"])
    
    {street_address, city, state, zip} = extract_location_info(vicinity, plus_code)
    
    %{
      name: Map.get(place_data, "name", "Unknown"),
      address: vicinity,
      street_address: street_address,
      lat: get_in(place_data, ["geometry", "location", "lat"]),
      lng: get_in(place_data, ["geometry", "location", "lng"]),
      city: city,
      state: state,
      zip: zip
    }
  end

  defp extract_location_info(vicinity, plus_code) do
    # Parse vicinity which has format like "Egan Leadership Center, 901 South 4th Street, Louisville"
    # or "901 South 4th Street, Louisville"
    {street_address, city} = parse_vicinity_address(vicinity)
    
    # Extract state from plus_code compound_code
    # Format: "78C3+36 Louisville, KY, USA"
    state = extract_state_from_plus_code(plus_code)
    
    {street_address, city, state, nil}  # ZIP not available in API response
  end

  defp parse_vicinity_address(vicinity) when is_binary(vicinity) do
    parts = String.split(vicinity, ", ")
    
    case parts do
      # Format: "Egan Leadership Center, 901 South 4th Street, Louisville"
      [_business_name, street_address, city] ->
        {street_address, city}
      
      # Format: "901 South 4th Street, Louisville" 
      [street_address, city] ->
        {street_address, city}
      
      # Format: just "Louisville" or single part
      [city] ->
        {"Unknown Address", city}
      
      # Fallback for any other format
      _ ->
        {"Unknown Address", "Unknown City"}
    end
  end

  defp parse_vicinity_address(_), do: {"Unknown Address", "Unknown City"}

  defp extract_state_from_plus_code(plus_code) when is_binary(plus_code) do
    # Extract state from compound code like "78C3+36 Louisville, KY, USA"
    case String.split(plus_code, " ", parts: 2) do
      [_code, location_part] ->
        case String.split(location_part, ", ") do
          [_city, state, _country] -> state
          [_city, state] -> state
          _ -> nil
        end
      _ -> nil
    end
  end

  defp extract_state_from_plus_code(_), do: nil

  def reverse_geocode_for_zip(street_address, city, state) do
    api_key = get_api_key()
    
    if api_key == "your_api_key_here" or Mix.env() == :test do
      mock_reverse_geocode(street_address, city, state)
    else
      real_reverse_geocode(street_address, city, state, api_key)
    end
  end

  defp mock_reverse_geocode(_street_address, city, state) do
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

  defp real_reverse_geocode(street_address, city, state, api_key) do
    full_address = "#{street_address}, #{city}, #{state}"
    
    params = %{
      address: full_address,
      key: api_key
    }
    
    case Req.get(@geocoding_url, params: params) do
      {:ok, %{status: 200, body: %{"status" => "OK", "results" => [result | _]}}} ->
        zip = extract_zip_from_geocode_result(result)
        if zip, do: {:ok, zip}, else: {:error, "No zip code found"}
        
      {:ok, %{status: 200, body: %{"status" => "ZERO_RESULTS"}}} ->
        {:error, "Address not found"}
        
      {:ok, %{status: 200, body: %{"status" => status}}} ->
        {:error, "API error: #{status}"}
        
      {:error, reason} ->
        {:error, "HTTP error: #{inspect(reason)}"}
    end
  end

  defp extract_zip_from_geocode_result(result) do
    address_components = Map.get(result, "address_components", [])
    
    Enum.find_value(address_components, fn component ->
      types = Map.get(component, "types", [])
      if "postal_code" in types do
        Map.get(component, "short_name")
      end
    end)
  end

  defp get_api_key do
    Application.get_env(:random_address_finder, :google_maps)[:api_key]
  end
end
