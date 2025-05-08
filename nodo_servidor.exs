defmodule NodoServidor do
  def main do
    Process.register(self(), :servidor)
    Util.mostrar_mensaje("Servidor iniciado en #{node()}")
    loop(%{}, %{})
  end

  defp loop(salas, historial) do
    receive do
      {:crear_sala, pid_cliente, nombre_sala} ->
        Util.mostrar_mensaje("Creando sala '#{nombre_sala}'")
        pid_sala = Sala.iniciar(nombre_sala)
        send(pid_cliente, {:sala_creada, nombre_sala})
        loop(Map.put(salas, nombre_sala, pid_sala), historial)

      {:unirse_sala, pid_cliente, usuario, nombre_sala} ->
        case Map.get(salas, nombre_sala) do
          nil -> send(pid_cliente, {:error, "La sala noe existe."})
          sala_pid ->
            send(sala_pid, {:unir, usuario})
            send(pid_cliente, {:unido, nombre_sala})
        end
        loop(salas, historial)

      {:mensaje_sala, nombre_sala, de, mensaje} ->
        case Map.get(salas, nombre_sala) do
          nil -> :ignorar
          sala_pid -> send(sala_pid, {:mensaje_sala, de, mensaje})
          historial = Map.update(historial, nombre_Sala, [mensaje], &[mensaje | &1])
        end
        loop(salas, historial)

      {:salir_sala, usuario, nombre_sala} ->
        case Map.get(salas, nombre_sala) do
          nil -> :ignorar
          sala_pid -> send(sala_pid, {:salir, usuario})
        end
        loop(salas, historial)

      {:consultar_historial, pid_cliente, nombre_sala} ->
        historial_mensajes = Map.get(historial, nombre_sala, [])
        send(pid_cliente, {:historial_mensajes, historial_mensajes})
        loop(salas, historial)
    end
  end
end

NodoServidor.main()
