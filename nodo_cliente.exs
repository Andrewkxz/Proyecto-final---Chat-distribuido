 @moduledoc """
  Módulo principal del cliente que se conecta al servidor y maneja la interacción con el usuario.
  """
defmodule NodoCliente do
  def main do
    #crea el nombre completo del nodo servidor usando el localhost
    servidor_node = :"servidor@#{:net_adm.localhost()}"
    #Intenta conectar este nodo cliente al servidor remoto
    Node.connect(servidor_node)
    #Muestra la lista de los nodos conectados
    IO.inspect(Node.list(), label: "Nodos conectados")
    #imprime el mensaje de conexión
    Util.mostrar_mensaje("Conectado al servidor")
    #pausa 0.5 segundos para que visualices la conexión
    :timer.sleep(500)

    #pide al usuario que se autentique con nombre y contraseña
    usuario = Usuario.autenticar()
    # Envia el mensaje al proceso :servidor en el nodo servidor con la información del usuario y el pid del cliente
    send({:servidor, servidor_node}, {:autenticacion, self(), usuario})

    # Imprime información del nodo cliente y del servidor
    IO.puts("Nodo cliente: #{inspect(Node.self())}")
    IO.puts("Intentando conectar a: #{inspect(servidor_node)}")

    # Llama a la función para saber si acepta al usuario
    esperar_autenticacion(usuario, servidor_node)
  end

  @doc """
  Espera la respuesta del servidor sobre la autenticación del usuario.
  """
  defp esperar_autenticacion(usuario, servidor_node) do
    receive do
      {:autenticado, true} ->
        # Si la autenticación es exitosa, muestra un mensaje de bienvenida y entra al bucle principal
        Util.mostrar_mensaje("Bienvenido #{usuario.nombre} :D")
        loop(usuario, nil, servidor_node, true)

      {:autenticado, false} ->
        # Si la autenticación falla, muestra un mensaje de error y vuelve a empezar
        Util.mostrar_error("Credenciales incorrectas. Intenta de nuevo.")
        main()
    end
  end

  @doc """
  Bucle principal que escucha eventos del servidor o comandos del usuario.
  Parametros: struct del usuario, nombre de la sala actual, nombre del nodo servidor y un booleano para mostrar el menú de comandos.
  """
  defp loop(usuario, sala_actual, servidor_node, mostrar_menu?) do
    # Si se debe mostrar el menú, lo hace con base en si el usuario está en una sala o no.
    if mostrar_menu?, do: mostrar_menu(sala_actual)

    receive do
      # Mensaje recibido en la sala
      {:mensaje_nuevo, mensaje} ->
        # Separa la fecha y hora del contenido del mensaje
        [fecha_hora | contenido] = String.split(mensaje, "] ", parts: 2)
        # Separa el contenido en usuario y mensaje cifrado
        case String.split(Enum.join(contenido), ": ", parts: 2) do
          [usuario, mensaje_cifrado] ->
            # Descifra el mensaje y lo imprime
            mensaje_descifrado = Util.descifrar_mensaje(mensaje_cifrado)
            IO.puts("\n[#{String.trim_leading(fecha_hora, "[")}] #{usuario}: #{mensaje_descifrado}")
          _ ->
            # Si el formato no es correcto, imprime el mensaje tal cual
            IO.puts("\n[#{String.trim_leading(fecha_hora, "[")}] #{Enum.join(contenido)}") # fallback
        end

        loop(usuario, sala_actual, servidor_node, false)

        # Imprime todo el historial de mensajes de la sala
      {:historial, mensajes} ->
        IO.puts("\nHistorial de mensajes:")
        Enum.each(mensajes, fn linea ->
          case String.split(linea, "] ", parts: 2) do
            # Separa la fecha y hora del contenido del mensaje
            [fecha_hora, contenido] ->
              # Separa el contenido en usuario y mensaje cifrado
              case String.split(contenido, ": ", parts: 2) do
                [usuario, mensaje_cifrado] ->
                  # Descifra el mensaje y lo imprime
                  mensaje_descifrado = Util.descifrar_mensaje(mensaje_cifrado)
                  IO.puts("  - [#{String.trim_leading(fecha_hora, "[")}] #{usuario}: #{mensaje_descifrado}")
                _ ->
                  # Si el formato no es correcto, imprime el mensaje tal cual
                  IO.puts("  - [#{String.trim_leading(fecha_hora, "[")}] #{contenido}") # fallback si el formato es raro
              end
            end
        end)
        # Pausa de 0.5 segundos para que el usuario pueda leer el historial
        :timer.sleep(500)
        loop(usuario, sala_actual, servidor_node, false)

        # Muestra los resultados de busqueda en el historial de mensajes de la sala
      {:resultados_busqueda, resultados} ->
        IO.puts("\nResultados encontrados:")
        # Si no se encontraron resultados, muestra un mensaje
        if resultados == [] do
          IO.puts("  - No se encontraron mensajes que contengan la palabra buscada.")
        else
          # Si se encontraron resultados, los imprime
          Enum.each(resultados, fn linea ->
            # Separa la fecha y hora del contenido del mensaje
            case String.split(linea, "] ", parts: 2) do
              [fecha_hora, contenido] ->
                # Separa el contenido en usuario y mensaje cifrado
                case String.split(contenido, ": ", parts: 2) do
                  [usuario, mensaje_cifrado] ->
                    # Descifra el mensaje y lo imprime
                    mensaje_descifrado = Util.descifrar_mensaje(mensaje_cifrado)
                    IO.puts("  - [#{String.trim_leading(fecha_hora, "[")}] #{usuario}: #{mensaje_descifrado}")
                  _ ->
                    # Si el formato no es correcto, imprime el mensaje tal cual
                    IO.puts("  - [#{String.trim_leading(fecha_hora, "[")}] #{contenido}") # fallback si el formato es raro
                end
              end
          end)
        end
        # Pausa de 0.5 segundos para que el usuario pueda leer los resultados
        :timer.sleep(500)
        loop(usuario, sala_actual, servidor_node, false)

        # Muestra la lista de usuarios conectados en el servidor (usuarios activos)
      {:usuarios, lista} ->
        IO.puts("\nUsuarios conectados:")
        Enum.each(lista, &IO.puts("  - #{&1}"))
        :timer.sleep(500)
        loop(usuario, sala_actual, servidor_node, false)

        # Confirma la creación de una nueva sala
      {:sala_creada, nombre_sala} ->
        Util.mostrar_mensaje("Sala #{nombre_sala} creada.")
        loop(usuario, sala_actual, servidor_node, false)

        # Confirma la unión de un usuario a una sala
      {:unido, nombre_sala} ->
        Util.mostrar_mensaje("Te has unido a la sala #{nombre_sala}.")
        loop(usuario, nombre_sala, servidor_node, true)

        # Confirma la salida de un usuario de una sala
      {:salida_sala, nombre_sala} ->
        Util.mostrar_mensaje("Has salido de la sala #{nombre_sala}.")
        loop(usuario, nil, servidor_node, true)

        # Muestra un mensaje de error
      {:error, mensaje} ->
        Util.mostrar_error(mensaje)
        loop(usuario, sala_actual, servidor_node, false)

        # Si no llega nada, espera 100 milisegundos y vuelve a mostrar el menú
      after 100 ->
        prompt = if sala_actual, do: "[#{sala_actual}] > ", else: "> "
        input = Util.ingresar(prompt, :texto)
        procesar_comando(input, usuario, sala_actual, servidor_node)
    end
  end

  @doc """
  Procesa el comando ingresado por el usuario.
  Dependiendo del comando, envía un mensaje al servidor o muestra un error.
  """
  defp procesar_comando(input, usuario, sala_actual, servidor_node) do
    # Separa el comando y los argumentos
    case String.split(input, " ", parts: 2) do
      # Se ingresa el comando y el argumento (nombre de la sala)
      ["/crear", nombre_sala] ->
        # Se comunica con el proceso del servidor para crear una nueva sala
        send({:servidor, servidor_node}, {:crear_sala, self(), nombre_sala})

      ["/crear"] ->
        # Si no se proporciona un nombre de sala, muestra un error
        Util.mostrar_error("Debes proporcionar un nombre para la sala.")

      # Se ingresa el comando y el argumento (nombre de la sala)
      ["/unirse", nombre_sala] ->
        if sala_actual == nil do
          # Se comunica con el proceso del servidor para unirse a una sala
          send({:servidor, servidor_node}, {:unirse_sala, self(), usuario, nombre_sala})
        else
          # Si el usuario ya está en una sala, muestra un error
          Util.mostrar_error("No puedes unirte a una sala sin salir de la actual.")
        end

      ["/unirse"] ->
        # Si no se proporciona un nombre de sala, muestra un error
        Util.mostrar_error("Debes proporcionar el nombre de la sala a unirte.")

      # Se ingresa el comando y el argumento (mensaje)
      ["/msg", mensaje] ->
        cond do
          sala_actual == nil ->
            # Si el usuario no está en una sala, muestra un error
            Util.mostrar_error("Debes unirte a una sala antes de enviar mensajes.")

          String.trim(mensaje) == "" ->
            # Si el mensaje está vacío, muestra un error
            Util.mostrar_error("El mensaje no puede estar vacío.")

          true ->
            # Si el mensaje es válido, lo envía al servidor
            mensaje_cifrado = Util.cifrar_mensaje(mensaje)
            # Se comunica con el proceso del servidor para enviar el mensaje a la sala
            send({:servidor, servidor_node}, {:mensaje_sala, sala_actual, usuario.nombre, mensaje_cifrado})
        end

      ["/msg"] ->
        # Si no se proporciona un mensaje, muestra un error
        Util.mostrar_error("Debes unirte a una sala antes de enviar mensajes.")
        # Se muestra el menú de comandos nuevamente
        mostrar_menu(nil)

      # Se ingresa el comando para ver el historial de mensajes
      ["/history"] ->
        if (sala_actual != nil) do
          # Se comunica con el proceso del servidor para obtener el historial de mensajes
        send({:servidor, servidor_node}, {:historial, self(), sala_actual})
        else
          # Si el usuario no está en una sala, muestra un error
          Util.mostrar_error("Debes estar en una sala para ver el historial.")
          # Se muestra el menú de comandos nuevamente
          mostrar_menu(nil)
        end

      # Se ingresa el comando y el argumento (palabra a buscar)
      ["/buscar", palabra] ->
        if (sala_actual != nil) do
          # Se comunica con el proceso del servidor para buscar mensajes en el historial
        send({:servidor, servidor_node}, {:buscar_mensaje, self(), sala_actual, palabra})
        else
          # Si el usuario no está en una sala, muestra un error
          Util.mostrar_error("Debes estar en una sala para buscar mensajes.")
        end

      ["/buscar"] ->
        # Si no se proporciona una palabra para buscar, muestra un error
        Util.mostrar_error("Debes proporcionar una palabra para buscar en el historial.")

      # Se ingresa el comando para listar usuarios conectados
      ["/list"] ->
        # Se comunica con el proceso del servidor para listar los usuarios conectados
        send({:servidor, servidor_node}, {:listar_usuarios, self()})

      # Se ingresa el comando para mostrar el menú de comandos
      ["/help"] ->
        # Se muestra el menú de comandos
        mostrar_menu(sala_actual)

      # Se ingresa el comando para salir de la sala actual
      ["/salir"]  ->
        if sala_actual != nil do
          # Se comunica con el proceso del servidor para salir de la sala
          send({:servidor, servidor_node}, {:salir_sala, usuario, sala_actual})
          # Llama a la función loop nuevamente para seguir escuchando eventos
          loop(usuario, nil, servidor_node, true)
        else
          # Si el usuario no está en una sala, muestra un error
          Util.mostrar_error("No estás en ninguna sala.")
          # Llama a la función loop nuevamente para seguir escuchando eventos
          loop(usuario, sala_actual, servidor_node, false)
        end

      # Se ingresa el comando para cerrar sesión (nodo cliente)
      ["/cerrar"] ->
        Util.mostrar_mensaje("Cerrando sesión...")
        :timer.sleep(500)
        # Se comunica con el proceso del servidor para cerrar sesión y salir del nodo cliente
        send({:servidor, servidor_node}, {:salir, self()})
        # Se cierra el nodo cliente
        exit(:normal)

      _ ->
        # Si el comando no es válido, muestra un error
        Util.mostrar_error("Comando inválido o no disponible en esta sala.")
        # Se muestra el menú de comandos nuevamente
        mostrar_menu(sala_actual)
    end

    # Llama a la función loop nuevamente para seguir escuchando eventos
    loop(usuario, sala_actual, servidor_node, false)
  end

  @doc """
  Muestra el menú de comandos disponibles según si el usuario está en una sala o no.
  """
  defp mostrar_menu(nil) do
    IO.puts("\nComandos disponibles:")
    IO.puts("/crear <nombre de la sala> - Crear una nueva sala")
    IO.puts("/unirse <nombre de la sala> - Unirse a una sala existente")
    IO.puts("/list - Ver usuarios conectados")
    IO.puts("/help - Mostrar este menú")
    IO.puts("/cerrar - Salir del sistema")
  end

  @doc """
  Muestra el menú de comandos disponibles cuando el usuario está en una sala.
  """
  defp mostrar_menu(_sala) do
    IO.puts("\nComandos disponibles:")
    IO.puts("/msg <mensaje> - Enviar un mensaje a la sala")
    IO.puts("/history - Ver el historial de mensajes")
    IO.puts("/buscar <palabra> - Buscar mensajes en la sala")
    IO.puts("/salir - Salir de la sala actual")
    IO.puts("/help - Mostrar este menú")
    IO.puts("/cerrar - Cerrar sesión por completo")
  end
end

# Inicia el nodo cliente
NodoCliente.main()
