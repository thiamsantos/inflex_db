defmodule InflexDB.CurrentTime.Behaviour do
  @moduledoc false
  @callback epoch_now() :: non_neg_integer()
end
