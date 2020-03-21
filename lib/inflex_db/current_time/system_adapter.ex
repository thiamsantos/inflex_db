defmodule InflexDB.CurrentTime.SystemAdapter do
  @moduledoc false
  @behaviour InflexDB.CurrentTime.Behaviour

  @impl InflexDB.CurrentTime.Behaviour

  def epoch_now do
    DateTime.to_unix(DateTime.utc_now())
  end
end
