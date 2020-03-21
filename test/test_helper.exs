Mox.defmock(InflexDB.CurrentTimeMock, for: InflexDB.CurrentTime.Behaviour)
Application.put_env(:inflex_db, InflexDB.CurrentTime, adapter: InflexDB.CurrentTimeMock)
ExUnit.start()
