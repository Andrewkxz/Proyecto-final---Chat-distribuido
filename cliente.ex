defmodule Cliente do
  def inicio do
    case Node.connect(:"servidor@localhost") do
      true -> IO.puts("[Cliente] Conectado al servidor.")
      false -> IO.puts("[Cliente] No se pudo conectar al servidor.")
    end

    servidor = :global.whereis_name(:chat_server)

    spawn(fn -> salida_ciclo(servidor) end)
    escuchar()
  end

  def salida_ciclo(servidor) do
    nombre_usuario = IO.gets("Introduce tu nombre de usuario: ") |> String.trim()
    contrasena = IO.gets("Introduce tu contraseña: ") |> String.trim()

    send(servidor, {:ingresar, nombre_usuario, contrasena, self()})
    :timer.sleep(200)

    receive do
      {:ok, mensaje} -> IO.puts(mensaje)
      {:error, error} -> IO.puts("Error: #{error}"); System.halt(1)
    end

    sala = IO.gets("Introduce el nombre de la sala a la que se desea unir: ") |> String.trim()
    send(servidor, {:crear_sala, nombre_sala, self()})
    :timer.sleep(200)
    send(servidor, {:unirse_sala, nombre_usuario, nombre_sala, self()})

    ciclo(servidor, nombre_usuario, nombre_sala)
  end

  defp ciclo(servidor, nombre_usuario, nombre_sala) do
    mensaje = IO.gets("") |> String.trim()

    case mensaje do
      "/list" -> send(servidor, {:listar_usuarios, self()})
      "/historial" -> send(servidor, {:historial, nombre_sala, self()})
      "/salir" -> IO.puts(Saliendo...); exit(:normal)
      _-> send(servidor, {:enviar_mensaje, nombre_usuario, nombre_sala, mensaje})
    end

    :timer.sleep(200)
    ciclo(servidor, nombre_usuario, nombre_sala)
  end


  defp escuchar() do
    receive do
      any -> IO.inspect(any)
    end
    listen()
  end
end
