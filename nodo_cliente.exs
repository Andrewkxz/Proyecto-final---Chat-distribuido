defmodule NodoCliente do
  def main do
    Node.connect(:servidor@servidor)
    Util.mostrar_mensaje("Conectado al servidor")
    :timer.sleep(500)

    usuario = Usuario.autenticar()
    send({:servidor, :servidor@servidor}, {:autenticacion, self(), usuario})

    esperar_autenticacion(usuario)
  end

  defp esperar_autenticacion(usuario) do
    receive do
      {:autenticado, true} ->
        Util.mostrar_mensaje("Bienvenido #{usuario.nombre} :D")
        loop(usuario, nil)

      {:autenticado, false} ->
        Util.mostrar_error("Credenciales incorrectas. Intenta de nuevo.")
        esperar_autenticacion(usuario)
    end
  end

  defp loop(usuario, sala_actual) do
    mostrar_menu(sala_actual)
    input = Util.ingresar("\n> ", :texto)

    case String.split(input, " ", parts: 2) do
      ["/crear", nombre_sala] ->
        send({:servidor, :servidor@servidor}, {:crear_sala, self(), nombre_sala})

      ["/unirse", nombre_sala] ->
        send({:servidor, :servidor@servidor}, {:unirse_sala, self(), usuario, nombre_sala})

      ["/msg", mensaje] ->
        if sala_actual != nil do
          send({:servidor, :servidor@servidor}, {:mensaje_sala, sala_actual, usuario.nombre, mensaje})
        else
          Util.mostrar_error("Debes unirte a una sala para enviar mensajes.")
        end

      ["/salir"] when sala_actual != nil ->
        send({:servidor, :servidor@servidor}, {:salir_sala, usuario, sala_actual})
        Util.mostrar_mensaje("Has salido de la sala #{sala_actual}")
        :timer.sleep(300)
        loop(usuario, nil)

      ["/list"] ->
        send({:servidor, :servidor@servidor}, {:listar_usuarios, self()})

      ["/history"] ->
        if sala_actual != nil do
          send({:servidor, :servidor@servidor}, {:historial, self(), sala_actual})
        else
          Util.mostrar_error("Debes unirte a una sala para ver el historial.")
        end

      ["/buscar", palabra] ->
        if sala_actual != nil do
          send({:servidor, :servidor@servidor}, {:buscar_mensaje, self(), sala_actual, palabra})
        else
          Util.mostrar_error("Debes unirte a una sala para buscar mensajes.")
        end

      ["/ayuda"] ->
        mostrar_menu(sala_actual)

      ["/cerrar"] ->
        Util.mostrar_mensaje("Saliendo del sistema...")
        :timer.sleep(500)
        exit(:normal)

      _ ->
        Util.mostrar_error("Comando invalido o no te encuentras en una sala.")
        mostrar_menu(sala_actual)
      end


      recibir_respuesta(usuario, sala_actual)
    end

    defp recibir_respuesta(usuario, sala_actual) do
      receive do
        {:sala_creada, nombre_sala} ->
          Util.mostrar_mensaje("Sala #{nombre_sala} creada.")
          loop(usuario, sala_actual)

        {:unido, nombre_sala} ->
          Util.mostrar_mensaje("Te has unido a la sala #{nombre_sala}.")
          loop(usuario, nombre_sala)

        {:mensaje_nuevo, mensaje} ->
          [fecha_hora | contenido] = String.split(mensaje, "] ", parts: 2)
          IO.puts("[#{String.trim_leading(fecha_hora, "[")}] #{Enum.join(contenido)}")
          loop(usuario, sala_actual)

        {:historial, mensajes} ->
          IO.puts("\nHistorial de mensajes:")
          Enum.each(mensajes, &IO.puts("  - " <> &1))
          loop(usuario, sala_actual)

        {:resultados_busqueda, resultados} ->
          IO.puts("\nResultados encontrados:")
          Enum.each(resultados, &IO.puts("  * " <> &1))
          loop(usuario, sala_actual)

        {:usuarios, lista} ->
          IO.puts("\nUsuarios conectados:")
          Enum.each(lista, &IO.puts("  - #{&1}"))
          loop(usuario, sala_actual)

        {:salida_sala, nombre_sala} ->
          Util.mostrar_mensaje("Has salido de la sala #{nombre_sala}.")
          loop(usuario, nil)

        {:error, mensaje} ->
          Util.mostrar_error(mensaje)
          loop(usuario, sala_actual)
        end
    end

    defp mostrar_menu(nil) do
      IO.puts("\nComandos disponibles:")
      IO.puts("/crear <nombre de la sala> - Crear una nueva sala")
      IO.puts("/unirse <nombre de la sala> - Unirse a una sala existente")
      IO.puts("/list - Ver usuarios conectados")
      IO.puts("/cerrar - Salir del sistema")
    end

    defp mostrar_menu(_sala) do
      IO.puts("\nComandos disponibles:")
      IO.puts("/msg <mensaje> - Enviar un mensaje a la sala")
      IO.puts("/history - Ver el historial de mensajes")
      IO.puts("/buscar <palabra> - Buscar mensajes en la sala")
      IO.puts("/salir - Salir de la sala")
  end
end

NodoCliente.main()
