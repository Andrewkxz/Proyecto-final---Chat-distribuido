defmodule NodoServidor do
  def main do
    Process.register(self(), :servidor)
    Util.mostrar_mensaje("Servidor iniciado en #{node()}")
    log_evento("Servidor iniciando en #{node()}")

    usuarios = Usuario.cargar_usuarios()
    loop(%{}, %{}, usuarios) # Salas, historial, usuarios
  end

  defp loop(salas, historial, usuarios) do
    receive do
      {:autenticacion, pid, usuario = %Usuario{nombre: nombre}} ->
        nuevos_usuarios = Map.put(usuarios, nombre, usuario)
        send(pid, {:autenticado, true})
        log_evento("Usuario #{nombre} autenticado correctamente.")
        loop(salas, historial, nuevos_usuarios)

      {:crear_sala, pid, nombre_sala} ->
        if Map.has_key?(salas, nombre_sala) do
          send(pid, {:error, "La sala ya existe."})
        else
          Util.mostrar_mensaje("Creando sala '#{nombre_sala}'")
          pid_sala = Sala.iniciar(nombre_sala)
          send(pid, {:sala_creada, nombre_sala})
          loop(Map.put(salas, nombre_sala, pid_sala), historial, usuarios)
        end

      {:unirse_sala, pid, usuario, nombre_sala} ->
        case Map.get(salas, nombre_sala) do
          nil ->
            send(pid, {:error, "La sala no existe."})
          sala_pid ->
            send(sala_pid, {:unir, usuario})
            send(pid, {:unido, nombre_sala})
            log_evento("#{usuario.nombre} se unió a la sala #{nombre_sala}.")
        end
        loop(salas, historial, usuarios)

      {:mensaje_sala, nombre_sala, de, mensaje_cifrado} ->
        case Map.get(salas, nombre_sala) do
          nil -> loop(salas, historial, usuarios)
          sala_pid ->
            send(sala_pid, {:mensaje_sala, de, mensaje_cifrado})
            loop(salas, historial, usuarios)
        end

      {:listar_usuarios, pid} ->
        nombres = Map.keys(usuarios)
        send(pid, {:usuarios, nombres})
        loop(salas, historial, usuarios)

      {:salir_sala, usuario, nombre_sala} ->
        case Map.get(salas, nombre_sala) do
          nil -> :ok
          sala_pid -> send(sala_pid, {:salir, usuario})
        end
        loop(salas, historial, usuarios)

      {:historial, pid, nombre_sala} ->
        case File.read("historial_#{nombre_sala}.txt") do
          {:ok, contenido} ->
            mensajes = String.split(contenido, "\n", trim: true)
            send(pid, {:historial, mensajes})
          {:error, _} ->
            send(pid, {:historial, []})
        end
        loop(salas, historial, usuarios)

      {:buscar_mensaje, pid, nombre_sala, palabra} ->
        case File.read("historial_#{nombre_sala}.txt") do
          {:ok, contenido} ->
            mensajes = String.split(contenido, "\n", trim: true)

            resultados = Enum.filter(mensajes, fn linea ->
              case String.split(linea, "] ", parts: 2) do
                [_fecha_hora, contenido] ->
                  case String.split(contenido, ": ", parts: 2) do
                    [_usuario, mensaje_cifrado] ->
                      mensaje_descifrado = Util.descifrar_mensaje(mensaje_cifrado)
                      String.contains?(mensaje_descifrado, palabra)
                    _ -> false
                  end
                _ -> false
              end
            end)
            send(pid, {:resultados_busqueda, resultados})
          {:error, _} ->
            send(pid, {:resultados_busqueda, []})
          end
        loop(salas, historial, usuarios)
        end
  end


  defp log_evento(mensaje) do
    hora_colombia = DateTime.utc_now() |> DateTime.add(-5 * 3600, :second)
    fecha_hora = Calendar.strftime(hora_colombia, "%I:%M %p")
    |> String.downcase()
    |> String.replace("am", "a.m.")
    |> String.replace("pm", "p.m.")
    File.write!("log.txt", "[#{fecha_hora}] #{mensaje}\n", [:append])
  end
end


NodoServidor.main()
