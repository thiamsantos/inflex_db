defmodule InflexDB.CurrentTime do
  @moduledoc false
  @behaviour InflexDB.CurrentTime.Behaviour

  @impl InflexDB.CurrentTime.Behaviour
  def epoch_now do
    adapter().epoch_now()
  end

  defp adapter do
    :inflex_db
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(:adapter, InflexDB.CurrentTime.SystemAdapter)
  end
end
