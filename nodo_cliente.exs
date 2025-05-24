defmodule NodoCliente do
  def main do
    servidor_node = :"servidor@192.168.100.91"
    Node.connect(servidor_node)
    IO.inspect(Node.list(), label: "Nodos conectados")
    Util.mostrar_mensaje("Conectado al servidor")
    :timer.sleep(500)

    usuario = Usuario.autenticar()
    send({:servidor, servidor_node}, {:autenticacion, self(), usuario})

    esperar_autenticacion(usuario, servidor_node)
  end

  defp esperar_autenticacion(usuario, servidor_node) do
    receive do
      {:autenticado, true} ->
        :timer.sleep(500)
        IO.puts("\nAutenticación exitosa")
        Util.mostrar_mensaje("Bienvenido, #{usuario.nombre} :D")
        IO.puts("\nNodo cliente: #{inspect(Node.self())}")
        IO.puts("Intentando conectar a: #{inspect(servidor_node)}")

        spawn(fn -> escuchar_mensajes(usuario, servidor_node) end)
        loop_comandos(usuario, nil, servidor_node)

      {:autenticado, false} ->
        Util.mostrar_error("El usuario ya está en linea desde otra maquina o terminal.")
        :timer.sleep(1000)
        main()
    end
  end

  defp escuchar_mensajes(usuario, servidor_node) do
    receive do
      {:mensaje_nuevo, mensaje} ->
      mostrar_mensaje(mensaje)

      {:historial, mensajes} ->
        IO.puts("\nHistorial de mensajes:")
        Enum.each(mensajes, &mostrar_mensaje/1)

      {:resultados_busqueda, resultados} ->
        IO.puts("\nResultados encontrados:")
        if resultados == [], do: IO.puts("  - No se encontraron mensajes que contengan la palabra buscada.")
        Enum.each(resultados, &mostrar_mensaje/1)

      {:usuarios, lista} ->
        IO.puts("\nUsuarios conectados:")
        Enum.each(lista, &IO.puts("  - #{&1}"))

      {:sala_creada, nombre_sala} ->
        Util.mostrar_mensaje("Sala #{nombre_sala} creada.")

      {:unido, nombre_sala} ->
        Util.mostrar_mensaje("Te has unido a la sala #{nombre_sala}.")

      {:salida_sala, nombre_sala} ->
        Util.mostrar_mensaje("Has salido de la sala #{nombre_sala}.")

      {:error, mensaje} ->
        Util.mostrar_error(mensaje)
      end
      escuchar_mensajes(usuario, servidor_node)
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
        :timer.sleep(500)
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
        :timer.sleep(500)
        loop(usuario, sala_actual, servidor_node, false)

      {:usuarios, lista} ->
        IO.puts("\nUsuarios conectados:")
        Enum.each(lista, &IO.puts("  - #{&1}"))
        :timer.sleep(500)
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
        solicitud = if sala_actual, do: "[#{sala_actual}] > ", else: "> "
        salida = Util.ingresar(solicitud, :texto)
        procesar_comando(salida, usuario, sala_actual, servidor_node)
    end
  end

  defp loop_comandos(usuario, sala_actual, servidor_node) do
    loop(usuario, sala_actual, servidor_node, true)
  end

  defp mostrar_mensaje(mensaje) do
    [fecha_hora | contenido] = String.split(mensaje, "] ", parts: 2)
    case String.split(Enum.join(contenido), ": ", parts: 2) do
      [usuario, mensaje_cifrado] ->
        mensaje_descifrado = Util.descifrar_mensaje(mensaje_cifrado)
        IO.puts("\n[#{String.trim_leading(fecha_hora, "[")}] #{usuario}: #{mensaje_descifrado}")
      _ ->
        IO.puts("\n[#{String.trim_leading(fecha_hora, "[")}] #{Enum.join(contenido)}") # fallback
    end
  end

  defp procesar_comando(salida, usuario, sala_actual, servidor_node) do
    case String.split(salida, " ", parts: 2) do
      ["/create", nombre_sala] ->
        send({:servidor, servidor_node}, {:crear_sala, self(), nombre_sala})

      ["/create"] ->
        Util.mostrar_error("Debes proporcionar un nombre para la sala.")

      ["/join", nombre_sala] ->
        if sala_actual == nil do
          send({:servidor, servidor_node}, {:unirse_sala, self(), usuario, nombre_sala})
        else
          Util.mostrar_error("No puedes unirte a una sala sin salir de la actual.")
        end

      ["/join"] ->
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

      ["/search", palabra] ->
        if (sala_actual != nil) do
        send({:servidor, servidor_node}, {:buscar_mensaje, self(), sala_actual, palabra})
        else
          Util.mostrar_error("Debes estar en una sala para buscar mensajes.")
        end

      ["/search"] ->
        Util.mostrar_error("Debes proporcionar una palabra para buscar en el historial.")

      ["/list"] ->
        send({:servidor, servidor_node}, {:listar_usuarios, self()})

      ["/help"] ->
        mostrar_menu(sala_actual)

      ["/exit"]  ->
        if sala_actual != nil do
          send({:servidor, servidor_node}, {:salir_sala, usuario, sala_actual})
          loop(usuario, nil, servidor_node, true)
        else
          Util.mostrar_error("No estás en ninguna sala.")
          loop(usuario, sala_actual, servidor_node, false)
        end

      ["/close"] ->
        Util.mostrar_mensaje("Cerrando sesión...")
        :timer.sleep(500)
        send({:servidor, servidor_node}, {:salir, self()})
        exit(:normal)

      _ ->
        Util.mostrar_error("Comando inválido o no disponible en esta sala.")
        mostrar_menu(sala_actual)
    end

    loop(usuario, sala_actual, servidor_node, false)
  end

  defp mostrar_menu(nil) do
    IO.puts("\nComandos disponibles:")
    IO.puts(IO.ANSI.format([:bright, :underline, "/create <nombre de la sala>", :reset, " - Crear una nueva sala"]))
    IO.puts(IO.ANSI.format([:bright, :underline, "/join <nombre de la sala>", :reset, " - Unirse a una sala exitente"]))
    IO.puts(IO.ANSI.format([:bright, :underline, "/list", :reset, " - Ver usuarios conectados"]))
    IO.puts(IO.ANSI.format([:bright, :underline, "/help", :reset, " - Mostrar este menú"]))
    IO.puts(IO.ANSI.format([:bright, :underline, "/close", :reset, " - Cerrar sesión"]))
  end

  defp mostrar_menu(_sala) do
    IO.puts("\nComandos disponibles:")
    IO.puts(IO.ANSI.format([:bright, :underline, "/msg <mensaje>", :reset, " - Enviar un mensaje a la sala"]))
    IO.puts(IO.ANSI.format([:bright, :underline, "/history", :reset, " - Ver el historial de mensajes"]))
    IO.puts(IO.ANSI.format([:bright, :underline, "/search <palabra>", :reset, " - Buscar mensajes en la sala"]))
    IO.puts(IO.ANSI.format([:bright, :underline, "/exit", :reset, " - Salir de la sala actual"]))
    IO.puts(IO.ANSI.format([:bright, :underline, "/help", :reset, " - Mostrar este menú"]))
    IO.puts(IO.ANSI.format([:bright, :underline, "/close", :reset, " - Cerrar sesión"]))
  end
end

NodoCliente.main()
