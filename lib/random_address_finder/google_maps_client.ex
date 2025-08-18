defmodule RandomAddressFinder.GoogleMapsClient do
  @moduledoc """
  Client for interacting with Google Maps APIs to geocode locations and find nearby places.
  """

  @geocoding_url "https://maps.googleapis.com/maps/api/geocode/json"
  @places_url "https://maps.googleapis.com/maps/api/place/nearbysearch/json"

  def geocode_location(location) do
    api_key = get_api_key()
    
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
    
    params = %{
      location: "#{lat},#{lng}",
      radius: radius,
      type: "establishment",
      key: api_key
    }

    case Req.get(@places_url, params: params) do
      {:ok, %{status: 200, body: %{"status" => "OK", "results" => results}}} ->
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
