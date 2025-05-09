defmodule Supervisor do
  def iniciarSupervisor do
    Process.flag(:trap_exit, true)
    spawn_link(fn -> iniciar_servidor() end)
    loop()
  end

  defp iniciar_servidor do
  spawn_link(fn -> NodoServidor.main() end)
  end

  defp loop do
    receive do
      {:EXIT, _pid, motivo} ->
        log_evento("El servidor murió por el siguiente motivo: #{motivo}. Reiniciando...")
        iniciar_servidor()
        loop()
      end
    end

    defp log_evento(mensaje) do
      File.write!("log.txt", "[#{DateTime.utc_now()}] #{mensaje}\n", [:append])
    end
  end

  Supervisor.iniciarSupervisor()
