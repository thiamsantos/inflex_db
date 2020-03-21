defmodule InflexDB.CurrentTime.Behaviour do
  @callback epoch_now() :: non_neg_integer()
end
