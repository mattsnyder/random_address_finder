defmodule RandomAddressFinderWeb.HomePageTest do
  use RandomAddressFinderWeb.ConnCase
  import Phoenix.LiveViewTest

  test "GET /", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/")
    assert html =~ "Random Address Finder"
    assert html =~ "Enter Location"
  end
end
