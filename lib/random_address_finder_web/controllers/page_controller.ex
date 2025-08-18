defmodule RandomAddressFinderWeb.PageController do
  use RandomAddressFinderWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
