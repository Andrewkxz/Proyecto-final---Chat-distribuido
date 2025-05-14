@moduledoc """
  Módulo principal del servidor que maneja la lógica de autenticación y gestión de salas.
  """
defmodule NodoServidor do
  def main do
    # Registra el proceso actual con el nombre :servidor para que otros procesos puedan referenciarlo.
    Process.register(self(), :servidor)
    # Imprime un mensaje en la consola indicando que el servidor ha iniciado.
    Util.mostrar_mensaje("Servidor iniciado en #{node()}")
    # loguea el evento de inicio del servidor en un archivo (log.txt)
    log_evento("Servidor iniciando en #{node()}")

    # Carga los usuarios desde un archivo (usuarios.txt) los usuarios registrados en el sistema.
    usuarios = Usuario.cargar_usuarios()
    # Llama al bucle principal que mantiene el servidor en ejecución.
    # pasando: un mapa vacío de salas, historial vacío, el mapa de usuarios cargados y un mapa vacío de usuarios conectados.
    loop(%{}, %{}, usuarios, %{}) # Salas, historial, usuarios, usuarios conectados
  end

  @doc """
  Bucle principal del servidor que maneja la lógica de autenticación y gestión de salas.
  """
  defp loop(salas, historial, usuarios, conectados) do
    # Alias para no modificar accidentalmente el mapa de conectados
    conectados_vivos =conectados
    receive do
      # Recibe una solicitud de autenticación de un cliente.
      {:autenticacion, pid, usuario = %Usuario{nombre: nombre}} ->
        # Si el cliente ya está autenticado, envía un mensaje de error.
        if Map.has_key?(conectados, pid) do
          send(pid, {:error, "Ya estás autenticado."})
          log_evento("El usuario #{nombre} ya está autenticado.")
          loop(salas, historial, usuarios, conectados_vivos)
          # Si el cliente no está autenticado, lo autentica.
        else
          # Empieza a monitorear el proceso del cliente: si se cae, el servidor sabrá como actuar.
          Process.monitor(pid)

          # Guarda al usuario
          nuevos_usuarios = Map.put(usuarios, nombre, usuario)
          # Lo añade en el mapa de conectados
          conectados_actualizados = Map.put(conectados, pid, nombre)
          # Confirma su atenticación
          send(pid, {:autenticado, true})
          # Envia un mensaje con la confirmación de autenticación
          log_evento("Usuario #{nombre} autenticado correctamente.")
          # Vuelve a llamar al bucle principal con el nuevo estado.
          loop(salas, historial, nuevos_usuarios, conectados_actualizados)
        end

        # Recibe una solicitud para crear una sala de chat.
      {:crear_sala, pid, nombre_sala} ->
        # Verifica si la sala ya existe.
        if Map.has_key?(salas, nombre_sala) do
          # Si la sala ya existe, envía un mensaje de error al cliente.
          send(pid, {:error, "La sala ya existe."})
          # Si la sala no existe, crea una nueva sala.
        else
          # Imprime un mensaje en la consola indicando que se está creando una sala.
          Util.mostrar_mensaje("Creando sala '#{nombre_sala}'")
          # Crea un nuevo proceso de sala y lo registra en el mapa de salas.
          pid_sala = Sala.iniciar(nombre_sala)
          # Envía un mensaje al cliente confirmando la creación de la sala.
          send(pid, {:sala_creada, nombre_sala})
          # Logue el evento de creación de la sala en un archivo (log.txt)
          log_evento("Sala '#{nombre_sala}' creada por #{Map.get(conectados, pid)}.")
          # Vuelve a llamar al bucle principal con el nuevo estado.
          loop(Map.put(salas, nombre_sala, pid_sala), historial, usuarios, conectados_vivos)
        end

        # Recibe una solicitud para unirse a una sala de chat.
      {:unirse_sala, pid, usuario, nombre_sala} ->
        # Hace un mapeo de las salas y verifica que la sala existe.
        case Map.get(salas, nombre_sala) do
          nil ->
            # Si la sala no existe, envía un mensaje de error al cliente.
            send(pid, {:error, "La sala no existe."})
            # Si la sala existe
          sala_pid ->
            # Envia un mensaje al proceso de la sala para que el usuario se una.
            send(sala_pid, {:unir, usuario})
            # Envia un mensaje al cliente confirmando que se ha unido a la sala.
            send(pid, {:unido, nombre_sala})
            # Loguea el evento de unión del usuario a la sala en un archivo (log.txt)
            log_evento("#{usuario.nombre} se unió a la sala #{nombre_sala}.")
        end
        # Vuelve a llamar al bucle principal con el nuevo estado.
        loop(salas, historial, usuarios, conectados_vivos)

        # Recibe una solicitud para enviar un mensaje a una sala de chat.
      {:mensaje_sala, nombre_sala, de, mensaje_cifrado} ->
        # Verifica si la sala existe.
        case Map.get(salas, nombre_sala) do
          # Si la sala no existe, vuelve a llamar al bucle principal.
          nil -> loop(salas, historial, usuarios, conectados_vivos)
          # Si la sala existe
          sala_pid ->
            # Envia un mensaje al proceso de la sala para que el usaurio envíe el mensaje.
            send(sala_pid, {:mensaje_sala, de, mensaje_cifrado})
            # Loguea el evento de envio del mensaje en un archivo (log.ex)
            log_evento("Mensaje de #{de} en la sala #{nombre_sala}")
            # Vuelve a llamar al bucle principal con el nuevo estado.
            loop(salas, historial, usuarios, conectados_vivos)
        end

        # Recibe una solicitud para listar los mensajes de una sala de chat.
      {:listar_usuarios, pid} ->
        nombres = Map.values(conectados)
        # Envia un mensaje al cliente con la losta de usuarios conectados. (usuarios activos)
        send(pid, {:usuarios, nombres})
        # Vuelve a llamar al bucle principal con el nuevo estado.
        loop(salas, historial, usuarios, conectados_vivos)

        # Recibe una solicitud para salir de una sala de chat.
      {:salir_sala, usuario, nombre_sala} ->
        # Verifica si la sala existe.
        case Map.get(salas, nombre_sala) do
          nil -> :ok
          # Si la sala existe, envía un mensaje al proceso de la sala para que el usuario salga.
          sala_pid -> send(sala_pid, {:salir, usuario})
        end
        # Envia un mensaje al cliente confirmando que ha salido de la sala.
        log_evento("#{usuario.nombre} salió de la sala #{nombre_sala}.")
        # Vuelve a llamar al bucle principal con el nuevo estado.
        loop(salas, historial, usuarios, conectados_vivos)

        # Recibe una solicitud para guardar el historial de mensajes de una sala de chat.
      {:historial, pid, nombre_sala} ->
        # Verifica si existe el archivo de historial de la sala.
        case File.read("historial_#{nombre_sala}.txt") do
          {:ok, contenido} ->
            # Si el archivo existe, lo lee y lo divide en líneas.
            mensajes = String.split(contenido, "\n", trim: true)
            # Envia un mensaje al cliente con el historial de mensajes.
            send(pid, {:historial, mensajes})
          {:error, _} ->
            # Si el archivo no existe, envia un mensaje vacío al cliente.
            send(pid, {:historial, []})
        end
        # Vuelve a llamar al bucle principal con el nuevo estado.
        loop(salas, historial, usuarios, conectados_vivos)

        # Recibe una solicitud para buscar un mensaje en el historial de una sala de chat.
      {:buscar_mensaje, pid, nombre_sala, palabra} ->
        # Verifica si existe el archivo de historial de la sala.
        case File.read("historial_#{nombre_sala}.txt") do
          {:ok, contenido} ->
            # Si el archivo existe, lo lee y lo divide en líneas.
            mensajes = String.split(contenido, "\n", trim: true)

            # Filtra los mensajes que contienen la palabra buscada.
            resultados = Enum.filter(mensajes, fn linea ->
              # Divide la línea en fecha y hora, y contenido.
              case String.split(linea, "] ", parts: 2) do
                # Si la línea tiene el formato correcto, verifica si contiene la palabra buscada.
                [_fecha_hora, contenido] ->
                  # Divide el contenido en usuario y mensaje cifrado.
                  case String.split(contenido, ": ", parts: 2) do
                    # Si el contenido tiene el formato correcto, verifica si contiene la palabra buscada.
                    [_usuario, mensaje_cifrado] ->
                      # Descifra el mensaje cifrado y verifica si contiene la palabra buscada.
                      mensaje_descifrado = Util.descifrar_mensaje(mensaje_cifrado)
                      String.contains?(mensaje_descifrado, palabra)

                    _ -> false
                  end
                _ -> false
              end
            end)
            # Envia un mensaje al cliente con los resultados de la búsqueda.
            send(pid, {:resultados_busqueda, resultados})
          {:error, _} ->
            # Si el archivo no existe, envia un mensaje vacío al cliente.
            send(pid, {:resultados_busqueda, []})
          end
        # Vuelve a llamar al bucle principal con el nuevo estado.
        loop(salas, historial, usuarios, conectados_vivos)

      # Recibe una solicitud para cerrar la sesión del usuario.
      {:salir, pid} ->
        # Verifica si el usuario está conectado.
        nombre = Map.get(conectados_vivos, pid, "desconocido")
        # Loguea el evento de cierre de sesión en un archivo (log.txt)
        log_evento("El usuario #{nombre} se ha desconectado.")
        # Se actualiza el mapa de conectados eliminando al usuario.
        conectados_actualizados = Map.delete(conectados_vivos, pid)
        # Vuelve a llamar al bucle principal con el nuevo estado.
        loop(salas, historial, usuarios, conectados_actualizados)

        # Recibe una solicitud para cerrar la sesión del usuario inactivo.
      {:DOWN, _ref, :process, pid, _motivo} ->
        # Verifica si el usuario está conectado.
        nombre = Map.get(conectados, pid, "desconocido")
        # Loguea el evento de desconexión inesperada en un archivo (log.txt)
        log_evento("El usuario #{nombre} se ha desconectado inesperadamente.")
        # Se actualiza el mapa de conectados eliminando al usuario.
        conectados_actualizados = Map.delete(conectados, pid)
        # Vuelve a llamar al bucle principal con el nuevo estado.
        loop(salas, historial, usuarios, conectados_actualizados)
    end
  end


  @doc """
  Registra un evento en un archivo de log (log.txt) con la fecha y hora actual.
  """
  defp log_evento(mensaje) do
    # Obtiene la fecha y hora actual en la zona horaria de Colombia (UTC-5).
    # Se resta 5 horas para ajustar a la zona horaria de Colombia.
    # Se utiliza DateTime.utc_now() para obtener la fecha y hora actual en UTC.
    # Se utiliza DateTime.add(-5 * 3600, :second) para ajustar a la zona horaria de Colombia.
    # Se utiliza Calendar.strftime para formatear la fecha y hora en el formato deseado.
    # Se utiliza String.downcase() para convertir a minúsculas.
    # Se utiliza String.replace() para reemplazar "am" por "a.m." y "pm" por "p.m.".
    hora_colombia = DateTime.utc_now() |> DateTime.add(-5 * 3600, :second)
    fecha_hora = Calendar.strftime(hora_colombia, "%I:%M %p")
    |> String.downcase()
    |> String.replace("am", "a.m.")
    |> String.replace("pm", "p.m.")
    # Se utiliza File.write! para escribir el mensaje en el archivo de log (log.txt).
    # Se utiliza [:append] para agregar el mensaje al final del archivo sin sobrescribirlo.
    File.write!("log.txt", "[#{fecha_hora}] #{mensaje}\n", [:append])
  end
end

# Inicia el servidor.
NodoServidor.main()
