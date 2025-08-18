defmodule RandomAddressFinderWeb.AddressFinderLiveTest do
  use RandomAddressFinderWeb.ConnCase
  import Phoenix.LiveViewTest

  describe "AddressFinderLive" do
    test "displays the form on mount", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/")
      
      assert html =~ "Random Address Finder"
      assert html =~ "Enter Location"
      assert has_element?(view, "form[phx-submit='search']")
      assert has_element?(view, "input[name='location']")
      assert has_element?(view, "button[type='submit']")
    end

    test "form submission triggers search", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      
      html = view
      |> form("form", %{"location" => "San Francisco, CA"})
      |> render_submit()

      # Should show loading state immediately
      assert html =~ "Finding..."
    end
  end
end