defmodule DeeperServerWeb.LiveComponentTest do
  use DeeperServerWeb.ConnCase, async: true
  import Phoenix.LiveView.Test

  test "renderiza o componente corretamente" do
    render_live(conn, DeeperServerWeb.Components.CoreComponents, :modal, id: "my-modal", show: true) do
      assert has_element?("div#my-modal-container")
      assert has_element?("div#my-modal-bg")
      assert has_element?("div#my-modal-content")
    end
  end
end
