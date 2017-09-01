defmodule Astarte.RealmManagement.API.InterfaceNotFoundError do

  defexception plug_status: 404,
    message: "Interface Not Found"

    def exception(_opts) do
      %Astarte.RealmManagement.API.InterfaceNotFoundError{
      }
    end
end

