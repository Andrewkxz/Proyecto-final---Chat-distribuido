defmodule NodoServidor do
  def main do
    Process.register(self(), :servidor)
    Util.mostrar_mensaje("Servidor iniciado en #{node()}")
    log_evento("Servidor iniciando en #{node()}")

    usuarios = Usuario.cargar_usuarios()
    loop(%{}, %{}, usuarios, %{}) # Salas, historial, usuarios, usuarios conectados
  end

  defp loop(salas, historial, usuarios, conectados) do
    conectados_vivos =conectados
    receive do
      {:autenticacion, pid, usuario = %Usuario{nombre: nombre}} ->
        if Map.has_key?(conectados, pid) do
          send(pid, {:error, "Ya estás autenticado."})
          log_evento("El usuario #{nombre} ya está autenticado.")
          loop(salas, historial, usuarios, conectados_vivos)
        else
          Process.monitor(pid) # Monitorea el proceso del cliente
          nuevos_usuarios = Map.put(usuarios, nombre, usuario)
          conectados_actualizados = Map.put(conectados, pid, nombre)
          send(pid, {:autenticado, true})
          log_evento("Usuario #{nombre} autenticado correctamente.")
          loop(salas, historial, nuevos_usuarios, conectados_actualizados)
        end

      {:crear_sala, pid, nombre_sala} ->
        if Map.has_key?(salas, nombre_sala) do
          send(pid, {:error, "La sala ya existe."})
        else
          Util.mostrar_mensaje("Creando sala '#{nombre_sala}'")
          pid_sala = Sala.iniciar(nombre_sala)
          send(pid, {:sala_creada, nombre_sala})
          log_evento("Sala '#{nombre_sala}' creada por #{Map.get(conectados, pid)}.")
          loop(Map.put(salas, nombre_sala, pid_sala), historial, usuarios, conectados_vivos)
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
        loop(salas, historial, usuarios, conectados_vivos)

      {:mensaje_sala, nombre_sala, de, mensaje_cifrado} ->
        case Map.get(salas, nombre_sala) do
          nil -> loop(salas, historial, usuarios, conectados_vivos)
          sala_pid ->
            send(sala_pid, {:mensaje_sala, de, mensaje_cifrado})
            log_evento("Mensaje de #{de} en la sala #{nombre_sala}")
            loop(salas, historial, usuarios, conectados_vivos)
        end

      {:listar_usuarios, pid} ->
        nombres = Map.values(conectados)
        send(pid, {:usuarios, nombres})
        loop(salas, historial, usuarios, conectados_vivos)

      {:salir_sala, usuario, nombre_sala} ->
        case Map.get(salas, nombre_sala) do
          nil -> :ok
          sala_pid -> send(sala_pid, {:salir, usuario})
        end
        log_evento("#{usuario.nombre} salió de la sala #{nombre_sala}.")
        loop(salas, historial, usuarios, conectados_vivos)

      {:historial, pid, nombre_sala} ->
        case File.read("historial_#{nombre_sala}.txt") do
          {:ok, contenido} ->
            mensajes = String.split(contenido, "\n", trim: true)
            send(pid, {:historial, mensajes})
          {:error, _} ->
            send(pid, {:historial, []})
        end
        loop(salas, historial, usuarios, conectados_vivos)

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
        loop(salas, historial, usuarios, conectados_vivos)

      {:salir, pid} ->
        nombre = Map.get(conectados_vivos, pid, "desconocido")
        log_evento("El usuario #{nombre} se ha desconectado.")
        conectados_actualizados = Map.delete(conectados_vivos, pid)
        loop(salas, historial, usuarios, conectados_actualizados)

      {:DOWN, _ref, :process, pid, _motivo} ->
        nombre = Map.get(conectados, pid, "desconocido")
        log_evento("El usuario #{nombre} se ha desconectado inesperadamente.")
        conectados_actualizados = Map.delete(conectados, pid)
        loop(salas, historial, usuarios, conectados_actualizados)
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
