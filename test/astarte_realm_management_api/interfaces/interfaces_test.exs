#
# This file is part of Astarte.
#
# Copyright 2018 Ispirata Srl
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

defmodule Astarte.RealmManagement.API.InterfacesTest do
  use Astarte.RealmManagement.API.DataCase

  alias Astarte.RealmManagement.API.Interfaces
  alias Astarte.Core.Interface
  alias Astarte.Core.Mapping
  @realm "testrealm"
  @interface_name "com.Some.Interface"
  @interface_major 2
  @valid_attrs %{
    "interface_name" => @interface_name,
    "version_major" => 2,
    "version_minor" => 1,
    "type" => "properties",
    "ownership" => "device",
    "mappings" => [
      %{
        "endpoint" => "/test",
        "type" => "integer"
      }
    ]
  }
  @invalid_attrs %{
    "interface_name" => @interface_name,
    "version_major" => 2,
    "version_minor" => 1,
    "type" => "INVALID",
    "ownership" => "device",
    "mappings" => [
      %{
        "endpoint" => "/test",
        "type" => "integer"
      }
    ]
  }

  describe "interface creation" do
    test "succeeds with valid attrs" do
      assert {:ok, %Interface{} = interface} = Interfaces.create_interface(@realm, @valid_attrs)

      assert %Interface{
               name: @interface_name,
               major_version: @interface_major,
               minor_version: 1,
               type: :properties,
               ownership: :device,
               mappings: [mapping]
             } = interface

      assert %Mapping{
               endpoint: "/test",
               value_type: :integer
             } = mapping

      assert {:ok, [@interface_name]} = Interfaces.list_interfaces(@realm)
    end

    test "fails with already installed interface" do
      assert {:ok, %Interface{} = _interface} = Interfaces.create_interface(@realm, @valid_attrs)

      assert {:error, :already_installed_interface} =
               Interfaces.create_interface(@realm, @valid_attrs)
    end

    test "fails with invalid attrs" do
      assert {:error, %Ecto.Changeset{errors: [type: _]}} =
               Interfaces.create_interface(@realm, @invalid_attrs)
    end
  end

  describe "interface update" do
    setup do
      {:ok, %Interface{}} = Interfaces.create_interface(@realm, @valid_attrs)
      :ok
    end

    test "succeeds with valid attrs" do
      doc = "some doc"

      update_attrs =
        @valid_attrs
        |> Map.put("version_minor", 10)
        |> Map.put("doc", doc)

      assert {:ok, :started} ==
               Interfaces.update_interface(
                 @realm,
                 @interface_name,
                 @interface_major,
                 update_attrs
               )

      assert {:ok, interface_source} =
               Interfaces.get_interface(@realm, @interface_name, @interface_major)

      assert {:ok, map} = Poison.decode(interface_source)

      assert {:ok, interface} =
               Interface.changeset(%Interface{}, map) |> Ecto.Changeset.apply_action(:insert)

      assert %Interface{
               name: "com.Some.Interface",
               major_version: 2,
               minor_version: 10,
               type: :properties,
               ownership: :device,
               mappings: [mapping],
               doc: ^doc
             } = interface

      assert %Mapping{
               endpoint: "/test",
               value_type: :integer
             } = mapping

      assert {:ok, ["com.Some.Interface"]} = Interfaces.list_interfaces(@realm)
    end

    test "fails with not installed interface" do
      update_attrs =
        @valid_attrs
        |> Map.put("interface_name", "com.NotExisting")

      assert {:error, :interface_major_version_does_not_exist} =
               Interfaces.update_interface(
                 @realm,
                 "com.NotExisting",
                 @interface_major,
                 update_attrs
               )
    end

    test "fails with invalid attrs" do
      assert {:error, %Ecto.Changeset{errors: [type: _]}} =
               Interfaces.create_interface(@realm, @invalid_attrs)
    end
  end
end
