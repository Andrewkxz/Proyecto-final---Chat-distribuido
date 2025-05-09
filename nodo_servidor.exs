defmodule NodoServidor do
  def main do
    Process.register(self(), :servidor)
    Util.mostrar_mensaje("Servidor iniciado en #{node()}")

    usuarios = Usuario.cargar_usuarios()
    loop(%{}, %{}, usuarios) # Salas, historial, usuarios
  end

  defp loop(salas, historial, usuarios) do
    receive do
      {:autenticacion, pid, usuario= %Usuario{nombre: nombre}} ->
        nuevos_usuarios = Map.put(usuarios, nombre, usuario)
        send(pid, {:autenticado, true})
        loop(salas, historial, nuevos_usuarios)

      {:crear_sala, pid_cliente, nombre_sala} ->
        if Map.has_key?(salas, nombre_sala) do
          send(pid_cliente, {:error, "La sala ya existe."})
          loop(salas, historial, usuarios)
        else
          Util.mostrar_mensaje("Creando sala '#{nombre_sala}'")
          pid_sala = Sala.iniciar(nombre_sala)
          send(pid_cliente, {:sala_creada, nombre_sala})
          loop(Map.put(salas, nombre_sala, pid_sala), historial, usuarios)
        end

      {:unirse_sala, pid_cliente, usuario, nombre_sala} ->
        case Map.get(salas, nombre_sala) do
          nil -> send(pid_cliente, {:error, "La sala no existe."})
          sala_pid ->
            send(sala_pid, {:unir, usuario})
            send(pid_cliente, {:unido, nombre_sala})
        end
        loop(salas, historial, usuarios)

      {:mensaje_sala, nombre_sala, de, mensaje} ->
        case Map.get(salas, nombre_sala) do
          nil -> :ignorar
          sala_pid -> send(sala_pid, {:mensaje_sala, de, mensaje})
        end
        loop(salas, historial, usuarios)

      {:listar_usuarios, pid_cliente} ->
        nombres = Map.keys(usuarios)
        send(pid_cliente, {:usuarios, nombres})
        loop(salas, historial, usuarios)

      {:salir_sala, usuario, nombre_sala} ->
        case Map.get(salas, nombre_sala) do
          nil -> :ignorar
          sala_pid -> send(sala_pid, {:salir, usuario})
        end
        loop(salas, historial, usuarios)

      {:historial, pid_cliente, nombre_sala} ->
        case File.read("historial_#{nombre_sala}.txt") do
          {:ok, contenido} ->
            mensajes = String.split(contenido, "\n", trim: true)
            send(pid_cliente, {:historial, mensajes})
          {:error, _} ->
            send(pid_cliente, {:historial, []})
          end
        loop(salas, historial, usuarios)
    end
  end
end

NodoServidor.main()
