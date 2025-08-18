defmodule RandomAddressFinder.AddressFinderTest do
  use ExUnit.Case, async: true

  alias RandomAddressFinder.AddressFinder

  describe "find_random_address/1" do
    test "returns a random address for city and state" do
      location = "San Francisco, CA"
      
      assert {:ok, address} = AddressFinder.find_random_address(location)
      assert Map.has_key?(address, :street)
      assert Map.has_key?(address, :city)
      assert Map.has_key?(address, :state)
      assert Map.has_key?(address, :zip)
      assert is_binary(address.street)
      assert is_binary(address.city)
      assert is_binary(address.state)
      assert is_binary(address.zip)
    end

    test "returns a random address for zip code" do
      zip_code = "94102"
      
      assert {:ok, address} = AddressFinder.find_random_address(zip_code)
      assert Map.has_key?(address, :street)
      assert Map.has_key?(address, :city)
      assert Map.has_key?(address, :state)
      assert Map.has_key?(address, :zip)
      # The zip should be in the same area (CA zip codes start with 9)
      assert String.starts_with?(address.zip, "9")
      assert address.state == "CA"
    end

    test "returns a random address for city only" do
      city = "Austin"
      
      assert {:ok, address} = AddressFinder.find_random_address(city)
      assert Map.has_key?(address, :street)
      assert Map.has_key?(address, :city)
      assert Map.has_key?(address, :state)
      assert Map.has_key?(address, :zip)
    end

    test "returns error for invalid location" do
      invalid_location = "InvalidLocationThatDoesNotExist123456"
      
      assert {:error, reason} = AddressFinder.find_random_address(invalid_location)
      assert reason == "Location not found"
    end

    test "returns different addresses on multiple calls" do
      location = "Austin, TX"
      
      {:ok, address1} = AddressFinder.find_random_address(location)
      {:ok, address2} = AddressFinder.find_random_address(location)
      
      # Should be different addresses (randomness test)
      refute address1.street == address2.street
    end

    test "returns realistic zip codes for known cities" do
      location = "San Francisco, CA"
      
      {:ok, address} = AddressFinder.find_random_address(location)
      
      # San Francisco zip codes should start with 94
      assert String.starts_with?(address.zip, "94")
      assert String.length(address.zip) == 5
      
      # Test Austin zip codes
      {:ok, austin_address} = AddressFinder.find_random_address("Austin, TX")
      assert String.starts_with?(austin_address.zip, "78") or String.starts_with?(austin_address.zip, "73")
      assert String.length(austin_address.zip) == 5
    end
  end
end