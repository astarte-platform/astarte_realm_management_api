#
# This file is part of Astarte.
#
# Copyright 2017-2018 Ispirata Srl
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

defmodule Astarte.RealmManagement.API.Interfaces do
  alias Astarte.Core.Interface
  alias Astarte.RealmManagement.API.RPC.RealmManagement

  def list_interfaces(realm_name) do
    RealmManagement.get_interfaces_list(realm_name)
  end

  def list_interface_major_versions(realm_name, id) do
    with {:ok, interface_versions_list} <-
           RealmManagement.get_interface_versions_list(realm_name, id),
         interface_majors <- Enum.map(interface_versions_list, fn el -> el[:major_version] end) do
      {:ok, interface_majors}
    end
  end

  def get_interface(realm_name, interface_name, interface_major_version) do
    RealmManagement.get_interface(realm_name, interface_name, interface_major_version)
  end

  def create_interface(realm_name, params) do
    changeset = Interface.changeset(%Interface{}, params)

    with {:ok, %Interface{} = interface} <- Ecto.Changeset.apply_action(changeset, :insert),
         {:ok, interface_source} <- Jason.encode(interface),
         {:ok, :started} <- RealmManagement.install_interface(realm_name, interface_source) do
      {:ok, interface}
    end
  end

  def update_interface(realm_name, interface_name, major_version, params) do
    changeset = Interface.changeset(%Interface{}, params)

    with {:ok, %Interface{} = interface} <- Ecto.Changeset.apply_action(changeset, :insert),
         {:name_matches, true} <- {:name_matches, interface_name == interface.name},
         {:major_matches, true} <- {:major_matches, major_version == interface.major_version},
         {:ok, interface_source} <- Jason.encode(interface) do
      RealmManagement.update_interface(realm_name, interface_source)
    else
      {:name_matches, false} ->
        {:error, :name_not_matching}

      {:major_matches, false} ->
        {:error, :major_version_not_matching}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def delete_interface(realm_name, interface_name, interface_major_version, _attrs \\ %{}) do
    RealmManagement.delete_interface(realm_name, interface_name, interface_major_version)
  end
end
