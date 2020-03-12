ExUnit.start()

Supervisor.start_link([Lear.TestStore], strategy: :one_for_one, name: Lear.Test)