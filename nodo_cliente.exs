defmodule NodoCliente do
  def main do
    servidor_node = :"servidor@#{:net_adm.localhost()}"
    Node.connect(servidor_node)
    IO.inspect(Node.list(), label: "Nodos conectados")
    Util.mostrar_mensaje("Conectado al servidor")
    :timer.sleep(500)

    usuario = Usuario.autenticar()
    send({:servidor, servidor_node}, {:autenticacion, self(), usuario})

    IO.puts("Nodo cliente: #{inspect(Node.self())}")
    IO.puts("Intentando conectar a: #{inspect(servidor_node)}")

    esperar_autenticacion(usuario, servidor_node)
  end

  defp esperar_autenticacion(usuario, servidor_node) do
    receive do
      {:autenticado, true} ->
        Util.mostrar_mensaje("Bienvenido #{usuario.nombre} :D")
        loop(usuario, nil, servidor_node, true)

      {:autenticado, false} ->
        Util.mostrar_error("Credenciales incorrectas. Intenta de nuevo.")
        main()
    end
  end

  defp loop(usuario, sala_actual, servidor_node, mostrar_menu?) do
    if mostrar_menu?, do: mostrar_menu(sala_actual)

    receive do
      {:mensaje_nuevo, mensaje} ->
        [fecha_hora | contenido] = String.split(mensaje, "] ", parts: 2)
        case String.split(Enum.join(contenido), ": ", parts: 2) do
          [usuario, mensaje_cifrado] ->
            mensaje_descifrado = Util.descifrar_mensaje(mensaje_cifrado)
            IO.puts("\n[#{String.trim_leading(fecha_hora, "[")}] #{usuario}: #{mensaje_descifrado}")
          _ ->
            IO.puts("\n[#{String.trim_leading(fecha_hora, "[")}] #{Enum.join(contenido)}") # fallback
        end

        loop(usuario, sala_actual, servidor_node, false)

      {:historial, mensajes} ->
        IO.puts("\nHistorial de mensajes:")
        Enum.each(mensajes, fn linea ->
          case String.split(linea, "] ", parts: 2) do
            [fecha_hora, contenido] ->
              case String.split(contenido, ": ", parts: 2) do
                [usuario, mensaje_cifrado] ->
                  mensaje_descifrado = Util.descifrar_mensaje(mensaje_cifrado)
                  IO.puts("  - [#{String.trim_leading(fecha_hora, "[")}] #{usuario}: #{mensaje_descifrado}")
                _ ->
                  IO.puts("  - [#{String.trim_leading(fecha_hora, "[")}] #{contenido}") # fallback si el formato es raro
              end
            end
        end)
        loop(usuario, sala_actual, servidor_node, false)

      {:resultados_busqueda, resultados} ->
        IO.puts("\nResultados encontrados:")
        if resultados == [] do
          IO.puts("  - No se encontraron mensajes que contengan la palabra buscada.")
        else
          Enum.each(resultados, fn linea ->
            case String.split(linea, "] ", parts: 2) do
              [fecha_hora, contenido] ->
                case String.split(contenido, ": ", parts: 2) do
                  [usuario, mensaje_cifrado] ->
                    mensaje_descifrado = Util.descifrar_mensaje(mensaje_cifrado)
                    IO.puts("  - [#{String.trim_leading(fecha_hora, "[")}] #{usuario}: #{mensaje_descifrado}")
                  _ ->
                    IO.puts("  - [#{String.trim_leading(fecha_hora, "[")}] #{contenido}") # fallback si el formato es raro
                end
              end
          end)
        end
        loop(usuario, sala_actual, servidor_node, false)

      {:usuarios, lista} ->
        IO.puts("\nUsuarios conectados:")
        Enum.each(lista, &IO.puts("  - #{&1}"))
        loop(usuario, sala_actual, servidor_node, false)

      {:sala_creada, nombre_sala} ->
        Util.mostrar_mensaje("Sala #{nombre_sala} creada.")
        loop(usuario, sala_actual, servidor_node, false)

      {:unido, nombre_sala} ->
        Util.mostrar_mensaje("Te has unido a la sala #{nombre_sala}.")
        loop(usuario, nombre_sala, servidor_node, true)

      {:salida_sala, nombre_sala} ->
        Util.mostrar_mensaje("Has salido de la sala #{nombre_sala}.")
        loop(usuario, nil, servidor_node, true)

      {:error, mensaje} ->
        Util.mostrar_error(mensaje)
        loop(usuario, sala_actual, servidor_node, false)

      after 100 ->
        prompt = if sala_actual, do: "[#{sala_actual}] > ", else: "> "
        input = Util.ingresar(prompt, :texto)
        procesar_comando(input, usuario, sala_actual, servidor_node)
    end
  end

  defp procesar_comando(input, usuario, sala_actual, servidor_node) do
    case String.split(input, " ", parts: 2) do
      ["/crear", nombre_sala] ->
        send({:servidor, servidor_node}, {:crear_sala, self(), nombre_sala})

      ["/crear"] ->
        Util.mostrar_error("Debes proporcionar un nombre para la sala.")

      ["/unirse", nombre_sala] ->
        if sala_actual == nil do
          send({:servidor, servidor_node}, {:unirse_sala, self(), usuario, nombre_sala})
        else
          Util.mostrar_error("No puedes unirte a una sala sin salir de la actual.")
        end

      ["/unirse"] ->
        Util.mostrar_error("Debes proporcionar el nombre de la sala a unirte.")

      ["/msg", mensaje] ->
        cond do
          sala_actual == nil ->
            Util.mostrar_error("Debes unirte a una sala antes de enviar mensajes.")

          String.trim(mensaje) == "" ->
            Util.mostrar_error("El mensaje no puede estar vacío.")

          true ->
            mensaje_cifrado = Util.cifrar_mensaje(mensaje)
            send({:servidor, servidor_node}, {:mensaje_sala, sala_actual, usuario.nombre, mensaje_cifrado})
        end

      ["/msg"] ->
        Util.mostrar_error("Debes unirte a una sala antes de enviar mensajes.")
        mostrar_menu(nil)

      ["/history"] ->
        if (sala_actual != nil) do
        send({:servidor, servidor_node}, {:historial, self(), sala_actual})
        else
          Util.mostrar_error("Debes estar en una sala para ver el historial.")
          mostrar_menu(nil)
        end

      ["/buscar", palabra] ->
        if (sala_actual != nil) do
        send({:servidor, servidor_node}, {:buscar_mensaje, self(), sala_actual, palabra})
        else
          Util.mostrar_error("Debes estar en una sala para buscar mensajes.")
        end

      ["/buscar"] ->
        Util.mostrar_error("Debes proporcionar una palabra para buscar en el historial.")

      ["/list"] ->
        send({:servidor, servidor_node}, {:listar_usuarios, self()})

      ["/help"] ->
        mostrar_menu(sala_actual)

      ["/salir"] when sala_actual != nil ->
        send({:servidor, servidor_node}, {:salir_sala, usuario, sala_actual})

      ["/cerrar"] ->
        Util.mostrar_mensaje("Cerrando sesión...")
        :timer.sleep(500)
        exit(:normal)

      _ ->
        Util.mostrar_error("Comando inválido o no disponible en esta sala.")
        mostrar_menu(sala_actual)
    end

    loop(usuario, sala_actual, servidor_node, false)
  end

  defp mostrar_menu(nil) do
    IO.puts("\nComandos disponibles:")
    IO.puts("/crear <nombre de la sala> - Crear una nueva sala")
    IO.puts("/unirse <nombre de la sala> - Unirse a una sala existente")
    IO.puts("/list - Ver usuarios conectados")
    IO.puts("/help - Mostrar este menú")
    IO.puts("/cerrar - Salir del sistema")
  end

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

NodoCliente.main()
