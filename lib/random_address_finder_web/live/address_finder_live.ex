defmodule RandomAddressFinderWeb.AddressFinderLive do
  use RandomAddressFinderWeb, :live_view

  alias RandomAddressFinder.AddressFinder

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:location, "")
      |> assign(:address, nil)
      |> assign(:error, nil)
      |> assign(:loading, false)

    {:ok, socket}
  end

  def handle_event("search", %{"location" => location}, socket) do
    location = String.trim(location)
    
    cond do
      String.length(location) < 2 ->
        socket = assign(socket, :error, "Please enter at least 2 characters")
        {:noreply, socket}
      
      String.length(location) > 100 ->
        socket = assign(socket, :error, "Location must be less than 100 characters")
        {:noreply, socket}
        
      true ->
        socket = 
          socket
          |> assign(:location, location)
          |> assign(:loading, true)
          |> assign(:error, nil)
        send(self(), {:find_address, location})
        {:noreply, socket}
    end
  end

  def handle_info({:find_address, location}, socket) do
    case AddressFinder.find_random_address(location) do
      {:ok, address} ->
        socket =
          socket
          |> assign(:address, address)
          |> assign(:error, nil)
          |> assign(:loading, false)

        {:noreply, socket}

      {:error, reason} ->
        socket =
          socket
          |> assign(:address, nil)
          |> assign(:error, reason)
          |> assign(:loading, false)

        {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 py-12 px-4">
      <div class="max-w-4xl mx-auto">
        <!-- Header Section -->
        <div class="text-center mb-12">
          <div class="flex justify-center mb-6">
            <div class="p-4 bg-blue-600 rounded-full">
              <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path>
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path>
              </svg>
            </div>
          </div>
          <h1 class="text-5xl font-bold text-gray-900 mb-4">
            Random Address Finder
          </h1>
          <p class="text-xl text-gray-600 max-w-2xl mx-auto">
            Discover real addresses from any location. Perfect for testing, demos, or exploring different areas.
          </p>
        </div>

        <!-- Search Form -->
        <div class="bg-white rounded-xl shadow-lg p-8 mb-8">
          <form phx-submit="search">
            <div class="space-y-4">
              <div>
                <label for="location" class="block text-sm font-medium text-gray-700 mb-2">
                  Enter Location
                </label>
                <div class="flex gap-4">
                  <div class="flex-1 relative">
                    <input
                      type="text"
                      id="location"
                      name="location"
                      placeholder="e.g., San Francisco, CA or 94102"
                      value={@location}
                      class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent text-lg text-gray-900 placeholder-gray-500"
                      required
                    />
                  </div>
                  <button
                    type="submit"
                    class="px-8 py-3 bg-blue-600 text-white font-semibold rounded-lg hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200"
                    disabled={@loading}
                  >
                    <%= if @loading do %>
                      <div class="flex items-center">
                        <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                        </svg>
                        Finding...
                      </div>
                    <% else %>
                      Find Address
                    <% end %>
                  </button>
                </div>
              </div>
              
              <div class="text-sm text-gray-500">
                Supports: City and State (e.g., "Austin, TX"), ZIP codes (e.g., "94102"), or City only (e.g., "Miami")
              </div>
            </div>
          </form>
        </div>

        <!-- Error Message -->
        <%= if @error do %>
          <div class="bg-white rounded-xl shadow-lg mb-8">
            <div class="p-6">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <svg class="h-6 w-6 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                  </svg>
                </div>
                <div class="ml-3">
                  <h3 class="text-sm font-medium text-red-800">
                    <%= @error %>
                  </h3>
                </div>
              </div>
            </div>
          </div>
        <% end %>

        <!-- Address Result -->
        <%= if @address do %>
          <div class="bg-white rounded-xl shadow-lg">
            <div class="p-8">
              <div class="flex items-center justify-between mb-6">
                <h2 class="text-2xl font-bold text-gray-900">Random Address Found!</h2>
                <div class="p-2 bg-green-100 rounded-full">
                  <svg class="w-6 h-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                  </svg>
                </div>
              </div>
              
              <div class="bg-gray-50 rounded-lg p-6 mb-6">
                <div class="space-y-3">
                  <div class="text-2xl font-semibold text-gray-900">
                    <%= @address.street %>
                  </div>
                  <div class="text-lg text-gray-700">
                    <%= @address.city %>, <%= @address.state %> <%= @address.zip %>
                  </div>
                </div>
              </div>
              
              <div class="flex flex-col sm:flex-row gap-4">
                <button
                  phx-click="search"
                  phx-value-location={@location}
                  class="flex-1 px-6 py-3 bg-blue-600 text-white font-medium rounded-lg hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 transition-colors duration-200"
                >
                  Get Another Random Address
                </button>
                <button
                  onclick={"navigator.clipboard.writeText('#{@address.street}, #{@address.city}, #{@address.state} #{@address.zip}')"}
                  class="flex-1 px-6 py-3 bg-gray-200 text-gray-800 font-medium rounded-lg hover:bg-gray-300 focus:ring-2 focus:ring-gray-500 transition-colors duration-200"
                >
                  Copy to Clipboard
                </button>
              </div>
            </div>
          </div>
        <% end %>

        <!-- Instructions -->
        <div class="mt-12 text-center">
          <div class="max-w-2xl mx-auto">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">How it works</h3>
            <div class="grid md:grid-cols-3 gap-6 text-sm text-gray-600">
              <div>
                <div class="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-2">1</div>
                <p>Enter a city, state, or ZIP code</p>
              </div>
              <div>
                <div class="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-2">2</div>
                <p>We find real locations in that area</p>
              </div>
              <div>
                <div class="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-2">3</div>
                <p>Get a random valid address</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end