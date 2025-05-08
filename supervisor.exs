defmodule Supervisor do
  def iniciarSupervisor do
    Process.flag(:trap_exit, true)
    spawn_link(fn -> iniciar_servidor() end)
    loop()
  end

defp iniciar_servidor() do
  spawn_link(fn -> nodo_servidor.main() end)
end

defp loop() do
  receive do
    {:EXIT, _pid, motivo} ->
      IO.puts("El servidor murió por el siguiente motivo: #{motivo}. Reiniciando...")
      iniciar_servidor()
      loop()

    end
  end
end

Supervisor.iniciarSupervisor()
